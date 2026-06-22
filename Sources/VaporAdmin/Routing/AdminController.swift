#if Passage
import Passage
#if PassageFluent
import PassageFluent
#endif
#endif

import Foundation
import Fluent
import Vapor

private extension Admin.Configuration.Authentication
{
    func routes(builder: any RoutesBuilder, adminSiteBasePath: String) -> RoutesBuilder
    {
        func getMiddleware<UserModel : Authenticatable>(userModelType: UserModel.Type) -> any Middleware
        {
            UserModel.redirectMiddleware(path: "/\(adminSiteBasePath)/login?loginRequired=true")
        }
        
        switch state
        {
        #if Passage
        case .passageClientConfigured(let userModelType),
                .passageUseVaporAdminConfiguration(_, let userModelType, _),
                .passageUseCustomConfiguration(_, _, _, _, let userModelType):
            return builder.grouped("\(adminSiteBasePath)")
                .grouped(PassageSessionAuthenticator())
                .grouped(PassageBearerAuthenticator())
                .grouped(getMiddleware(userModelType: userModelType))
                .grouped(PassageGuard())
                .grouped(MissingUsernameRedirectMiddleware(adminSiteBasePath: adminSiteBasePath))
        #endif
            
        case .customConfiguration(let authenticators, let userModelType, let `guard`, _):
            return builder.grouped("\(adminSiteBasePath)")
                .grouped(authenticators)
                .grouped(getMiddleware(userModelType: userModelType))
                .grouped(`guard`)
                .grouped(MissingUsernameRedirectMiddleware(adminSiteBasePath: adminSiteBasePath))
        }
    }
    
    func usernameFromRequest(_ req: Request, adminSiteBasePath: String) throws -> String
    {
        let username = try {
            switch state
            {
            #if Passage
            case .passageClientConfigured, .passageUseVaporAdminConfiguration, .passageUseCustomConfiguration:
                return try req.passage.user.username
            #endif
                
            case .customConfiguration(_, _, _, let usernameFromRequest):
                return try usernameFromRequest(req)
            }
        }()
        guard let username else {
            throw AdminControllerError.missingUsername
        }
        return username
    }
}

final class AdminController : RouteCollection, Sendable
{
    private let coordinator : ModelCoordinator
    private let configuration : Admin.Configuration
    
    init(app: Application, configuration: Admin.Configuration)
    {
        coordinator = app.admin.databaseManager
        self.configuration = configuration
        
        guard app.routes.all.contains(where: { $0.path == ["\(configuration.base)", "login"] }) else
        {
            app.logger.critical("""
                                The login route is missing, thus the Admin Site is misconfigured:
                                    * If you configured the Admin Site with a `custom` authentication strategy, ensure the "`\(configuration.base)/login`" route is registered BEFORE configuring the Admin Site
                                    * If you configured the Admin Site with a client-configured Passage instance, ensure Passage is configured BEFORE configuring the Admin Site
                                    * If you configured the Admin Site with a custom Passage Configuration object, ensure the login route and/or views are defined
                                """)
            assertionFailure("""
                             The login route is missing, thus the Admin Site is misconfigured:
                                 * If you configured the Admin Site with a `custom` authentication strategy, ensure the "`\(configuration.base)/login`" route is registered BEFORE configuring the Admin Site
                                 * If you configured the Admin Site with a client-configured Passage instance, ensure Passage is configured BEFORE configuring the Admin Site
                                 * If you configured the Admin Site with a custom Passage Configuration object, ensure the login route and/or views are defined
                             """)
            return
        }
    }
    
    func boot(routes: any RoutesBuilder) throws
    {
        registerJSFiles(on: routes)
        let protected = configuration.authentication.routes(builder: routes, adminSiteBasePath: configuration.base)
        
        protected.get { req in
            try await self.root(request: req)
        }
        
        // /<base>/<modelName>
        
        protected.get("models", ":modelName") { req in
            let modelName = try req.parameters.require("modelName")
            return try await self.modelEntryListView(model: modelName, request: req)
        }
        
        // /<base>/<modelName>/create
        
        protected.get("models", ":modelName", "create") { req in
            let modelName = try req.parameters.require("modelName")
            return try await self.modelEntryCreateView(model: modelName, request: req)
        }
        
        protected.post("models", ":modelName", "create") { req in
            let modelName = try req.parameters.require("modelName")
            return try await self.modelEntryCreateSave(model: modelName, request: req)
        }
        
        // /<base>/<modelName>/details/<modelID>
        
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
        let staticGroup = routes.grouped("admin", "static")
        staticGroup.get("adminTheme.js") { (request: Request) in
            let resourcePath = Bundle.module.path(forResource: "adminTheme", ofType: "js", inDirectory: "Public")!
            return try await request.fileio.asyncStreamFile(at: resourcePath)
        }
        
        staticGroup.get("adminCreate.js") { (request: Request) in
            let resourcePath = Bundle.module.path(forResource: "adminCreate", ofType: "js", inDirectory: "Public")!
            return try await request.fileio.asyncStreamFile(at: resourcePath)
        }
        
        staticGroup.get("adminDetail.js") { (request: Request) in
            let resourcePath = Bundle.module.path(forResource: "adminDetail", ofType: "js", inDirectory: "Public")!
            return try await request.fileio.asyncStreamFile(at: resourcePath)
        }
        
        staticGroup.get("adminList.js") { (request: Request) in
            let resourcePath = Bundle.module.path(forResource: "adminList", ofType: "js", inDirectory: "Public")!
            return try await request.fileio.asyncStreamFile(at: resourcePath)
        }
    }
    
    private func root(request: Request) async throws -> View
    {
        let username = try configuration.authentication.usernameFromRequest(request, adminSiteBasePath: configuration.base)
        
        let adminRootContext = AdminContext.Root(header: .init(username: username, breadcrumbs: [.init(text: "Admin Panel", relativeHREF: "", isActive: true)]), modelNames: coordinator.listModels())
        return try await request.view.render("admin-root", adminRootContext)
    }
    
    private func modelEntryListView(model: String, request: Request) async throws -> View
    {
        let username = try configuration.authentication.usernameFromRequest(request, adminSiteBasePath: configuration.base)
        let entries = try await coordinator.listEntries(for: model)
        
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
        let username = try configuration.authentication.usernameFromRequest(request, adminSiteBasePath: configuration.base)
        let details = try await coordinator.details(for: parameters, model: model)
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
        try await coordinator.attemptUpdate(for: parameters, model: model, data: request.content)
        return .init(status: .ok)
    }
    
    private func modelEntryCreateView(model: String, request: Request) async throws -> View
    {
        let username = try configuration.authentication.usernameFromRequest(request, adminSiteBasePath: configuration.base)
        let details = try await coordinator.newModelInfo(for: model)
        
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
        try await coordinator.attemptCreate(for: model, data: request.content)
        return .init(body: .init(data: try JSONEncoder().encode(Redirect(model: model))))
    }
    
    private func modelEntryDelete(model: String, parameters: Parameters, request: Request) async throws -> Response
    {
        try await coordinator.attemptDelete(for: model, parameters: parameters)
        return .init(body: .init(data: try JSONEncoder().encode(Redirect(model: model))))
    }
}

private struct Redirect : Codable
{
    let redirect : String
    
    init(model: String)
    {
        redirect = "/admin/models/\(model)/"
    }
}
