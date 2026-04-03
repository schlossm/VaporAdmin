//
//  AdminController.swift
//  mascomputech
//
//  Created by Michael Schloss on 2/1/26.
//

import PassageFluent
import Foundation
import Passage
import Fluent
import Vapor

final class AdminController : RouteCollection, Sendable
{
    private let databaseManager : ModelCoordinator
    
    init(app: Application)
    {
        databaseManager = app.admin.databaseManager
    }
    
    func boot(routes: any RoutesBuilder) throws
    {
        registerJSFiles(on: routes)
        
        let protected = routes.grouped("admin")
            .grouped(PassageSessionAuthenticator())
            .grouped(PassageBearerAuthenticator())
            .grouped(PassageFluent.UserModel.redirectMiddleware(path: "/admin/login?loginRequired=true"))
            .grouped(PassageGuard())
        
        protected.get { req in
            try await self.root(request: req)
        }
        
        // /admin/<modelName>
        
        protected.get("models", ":modelName") { req in
            let modelName = try req.parameters.require("modelName")
            return try await self.modelEntryListView(model: modelName, request: req)
        }
        
        // /admin/<modelName>/create
        
        protected.get("models", ":modelName", "create") { req in
            let modelName = try req.parameters.require("modelName")
            return try await self.modelEntryCreateView(model: modelName, request: req)
        }
        
        protected.post("models", ":modelName", "create") { req in
            let modelName = try req.parameters.require("modelName")
            return try await self.modelEntryCreateSave(model: modelName, request: req)
        }
        
        // /admin/<modelName>/details/<modelID>
        
        protected.get("models", ":modelName", "details", ":entry") { req in
            let modelName = try req.parameters.require("modelName")
            return try await self.modelEntryDetailView(model: modelName, parameters: req.parameters, request: req)
        }
        
        protected.post("models", ":modelName", "details", ":entry") { req in
            let modelName = try req.parameters.require("modelName")
            return try await self.modelEntryDetailSave(model: modelName, parameters: req.parameters, request: req)
        }
        
        protected.delete("models", ":modelName", "details", ":entry") { req in
            let modelName = try req.parameters.require("modelName")
            return try await self.modelEntryDelete(model: modelName, parameters: req.parameters, request: req)
        }
    }
    
    private func registerJSFiles(on routes: any RoutesBuilder)
    {
        routes.get("adminTheme.js") { (request: Request) in
            guard let resourcePath = Bundle.module.path(forResource: "adminTheme", ofType: "js", inDirectory: "Public") else {
                return Response(status: .notFound)
            }
            return try await request.fileio.asyncStreamFile(at: resourcePath)
        }
        
        routes.get("adminCreate.js") { (request: Request) in
            guard let resourcePath = Bundle.module.path(forResource: "adminCreate", ofType: "js", inDirectory: "Public") else {
                return Response(status: .notFound)
            }
            return try await request.fileio.asyncStreamFile(at: resourcePath)
        }
        
        routes.get("adminDetail.js") { (request: Request) in
            guard let resourcePath = Bundle.module.path(forResource: "adminDetail", ofType: "js", inDirectory: "Public") else {
                return Response(status: .notFound)
            }
            return try await request.fileio.asyncStreamFile(at: resourcePath)
        }
        
        routes.get("adminList.js") { (request: Request) in
            guard let resourcePath = Bundle.module.path(forResource: "adminList", ofType: "js", inDirectory: "Public") else {
                return Response(status: .notFound)
            }
            return try await request.fileio.asyncStreamFile(at: resourcePath)
        }
    }
    
    private func root(request: Request) async throws -> View
    {
        let username = try request.passage.user.username!
        
        let adminRootContext = AdminContext.Root(header: .init(username: username, breadcrumbs: [.init(text: "Admin Panel", relativeHREF: "", isActive: true)]), modelNames: databaseManager.listModels())
        return try await request.view.render("admin-root", adminRootContext)
    }
    
    private func modelEntryListView(model: String, request: Request) async throws -> View
    {
        let username = try request.passage.user.username!
        let entries = try await databaseManager.listEntries(for: model)
        
        let adminEntryListContext = AdminContext.List(header: .init(username: username,
                                                                    breadcrumbs: [
                                                                        .init(text: "Admin Panel", relativeHREF: "/admin", isActive: false),
                                                                        .init(text: model, relativeHREF: "", isActive: true)
                                                                    ]),
                                                      modelName: model,
                                                      entries: entries.map { .init(id: $0.id, text: $0.description) })
        return try await request.view.render("admin-entryList", adminEntryListContext)
    }
    
    private func modelEntryDetailView(model: String, parameters: Parameters, request: Request) async throws -> View
    {
        let username = try request.passage.user.username!
        let details = try await databaseManager.details(for: parameters, model: model)
        let rawModels = details.properties
        
        let adminEntryDetailContext = AdminContext.Detail(header: .init(username: username,
                                                                        breadcrumbs: [
                                                                            .init(text: "Admin Panel", relativeHREF: "/admin", isActive: false),
                                                                            .init(text: model, relativeHREF: "/admin/models/\(model)", isActive: false),
                                                                            .init(text: String(describing: details.id), relativeHREF: "", isActive: true)
                                                                        ]),
                                                          modelName: model,
                                                          displayName: details.description,
                                                          entryID: String(describing: details.id),
                                                          fields: rawModels)
        return try await request.view.render("admin-entryDetail", adminEntryDetailContext)
    }
    
    private func modelEntryDetailSave(model: String, parameters: Parameters, request: Request) async throws -> Response
    {
        _ = try request.passage.user
        
        try await databaseManager.attemptUpdate(for: parameters, model: model, data: request.content)
        return .init(status: .ok)
    }
    
    private func modelEntryCreateView(model: String, request: Request) async throws -> View
    {
        let username = try request.passage.user.username!
        let details = try await databaseManager.newModelInfo(for: model)
        
        let adminEntryDetailContext = AdminContext.Detail.Create(header: .init(username: username,
                                                                               breadcrumbs: [
                                                                                .init(text: "Admin Panel", relativeHREF: "/admin", isActive: false),
                                                                                .init(text: model, relativeHREF: "/admin/models/\(model)", isActive: false),
                                                                                .init(text: "Create New", relativeHREF: "", isActive: true)
                                                                               ]),
                                                                 modelName: model,
                                                                 fields: details)
        return try await request.view.render("admin-entryCreate", adminEntryDetailContext)
    }
    
    private func modelEntryCreateSave(model: String, request: Request) async throws -> Response
    {
        _ = try request.passage.user
        try await databaseManager.attemptCreate(for: model, data: request.content)
        struct Redirect : Codable
        {
            let redirect : String
            
            init(model: String)
            {
                redirect = "/admin/models/\(model)/"
            }
        }
        return .init(body: .init(data: try JSONEncoder().encode(Redirect(model: model))))
    }
    
    private func modelEntryDelete(model: String, parameters: Parameters, request: Request) async throws -> Response
    {
        _ = try request.passage.user
        try await databaseManager.attemptDelete(for: model, parameters: parameters)
        struct Redirect : Codable
        {
            let redirect : String
            
            init(model: String)
            {
                redirect = "/admin/models/\(model)/"
            }
        }
        return .init(body: .init(data: try JSONEncoder().encode(Redirect(model: model))))
    }
}
