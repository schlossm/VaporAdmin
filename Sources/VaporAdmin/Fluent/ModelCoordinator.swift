//
//  ModelCoordinator.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 2/28/26.
//

import Fluent
import Vapor

class ModelCoordinator : @unchecked Sendable
{
    let database : Database
    private(set) var models = [String : any ModelBox]()
    let boxInitializer : (any AdminModel.Type) -> any ModelBox
    
    init(database: Database, boxInitializer: @escaping (any AdminModel.Type) -> any ModelBox)
    {
        self.database = database
        self.boxInitializer = boxInitializer
    }
    
    func register<ModelType: AdminModel>(_ model: ModelType.Type)
    {
        let description = String(describing: model)
        if models[description] != nil
        {
            assertionFailure("\(model) is already registered")
        }
        models[String(describing: model)] = boxInitializer(model)
    }
    
    func listModels() -> [String]
    {
        Array(models.keys)
    }
    
    func listEntries(for model: String) async throws -> [ModelInstanceRepresentation]
    {
        return try await box(for: model).instances()
    }
    
    func details(for parameters: Parameters, model: String) async throws -> ModelInstancePropertiesRepresentation
    {
        return try await box(for: model).instanceProperties(parameters: parameters)
    }
    
    func attemptUpdate(for parameters: Parameters, model: String, data: any ContentContainer) async throws
    {
        try await box(for: model).attemptUpdate(for: parameters, data: data)
    }
    
    func newModelInfo(for model: String) async throws -> [ModelInstancePropertyRepresentation]
    {
        return try await box(for: model).newModelInfo()
    }
    
    func attemptCreate(for model: String, data: any ContentContainer) async throws
    {
        try await box(for: model).attemptCreate(data: data)
    }
    
    func attemptDelete(for model: String, parameters: Parameters) async throws
    {
        try await box(for: model).attemptDelete(parameters: parameters)
    }
    
    private func box(for model: String) -> any ModelBox
    {
        return models[model] ?? { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }()
    }
}
