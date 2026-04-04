//
//  ModelBox.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/2/26.
//

import Fluent
import Vapor

protocol ModelBox
{
    func instances() async throws -> [ModelInstanceRepresentation]
    
    func instanceProperties(parameters: Parameters) async throws -> ModelInstancePropertiesRepresentation
    
    func attemptUpdate(for parameters: Parameters, data: any ContentContainer) async throws
    
    func newModelInfo() async throws -> [ModelInstancePropertyRepresentation]
    
    func attemptCreate(data: any ContentContainer) async throws
    
    func attemptDelete(parameters: Parameters) async throws
}

struct _ModelBox<ModelType : FluentAdminDisplay & Model> : ModelBox
{
    typealias IDValue = ModelType.IDValue
    
    private let database : Database
    private let fieldTypeCache = [AnyKeyPath : ModelInstancePropertyRepresentation.FieldType]()
    
    init(database: Database)
    {
        self.database = database
    }
    
    func instances() async throws -> [ModelInstanceRepresentation]
    {
        let entries = try await database.query(ModelType.self).all()
        return entries.map { .init(id: $0.idDescription, description: $0.adminDescription) }
    }
    
    func instanceProperties(parameters: Parameters) async throws -> ModelInstancePropertiesRepresentation
    {
        let entry = try parameters.require("entry", as: IDValue.self)
        let model = try await ModelType.instance(for: entry, on: database)
        
        let fields = try await model.adminFieldRepresentations(database: database)
        return .init(id: model.idDescription, description: model.adminDescription, properties: fields)
    }
    
    func attemptUpdate(for parameters: Parameters, data: any ContentContainer) async throws
    {
        let entry = try parameters.require("entry", as: IDValue.self)
        let data = try data.decode([String : String].self)
        let model = try await ModelType.instance(for: entry, on: database)
        
        try await model.updateFields(from: data, database: database)
    }
    
    func newModelInfo() async throws -> [ModelInstancePropertyRepresentation]
    {
        let model = ModelType.init()
        return try await model.adminFieldRepresentations(database: database)
    }
    
    func attemptCreate(data: any ContentContainer) async throws
    {
        // To work around a Swift crash when keypath sets access the getters, we need to try a raw decode to the type first, then update any "weird" properties that can't be represented by the JS form data
        let newModel = try data.decode(ModelType.self)
        let data = try data.decode([String : String].self)
        try await newModel.updateFields(from: data, database: database)
    }
    
    func attemptDelete(parameters: Parameters) async throws
    {
        let entry = try parameters.require("entry", as: IDValue.self)
        let model = try await ModelType.instance(for: entry, on: database)
        try await model.delete(on: database)
    }
}
