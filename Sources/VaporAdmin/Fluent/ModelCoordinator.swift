//
//  ModelCoordinator.swift
//  mascomputech
//
//  Created by Michael Schloss on 2/28/26.
//

import Fluent
import Vapor

class ModelCoordinator : @unchecked Sendable
{
    let database : Database
    private var models = [String : any ModelBox]()
    
    init(database: Database)
    {
        self.database = database
    }
    
    func register<ModelType: FluentAdminDisplay & Model>(_ model: ModelType.Type) where ModelType.IDValue : LosslessStringConvertible
    {
        let description = String(describing: model)
        if models[description] != nil
        {
            assertionFailure("\(model) is already registered")
        }
        models[String(describing: model)] = _ModelBox<ModelType>(database: database)
    }
    
    func listModels() -> [String]
    {
        Array(models.keys)
    }
    
    func listEntries(for model: String) async throws -> [ModelInstanceRepresentation]
    {
        guard let box = models[model] else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        return try await box.instances()
    }
    
    func details(for parameters: Parameters, model: String) async throws -> ModelInstancePropertiesRepresentation
    {
        guard let box = models[model] else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        return try await box.instanceProperties(parameters: parameters)
    }
    
    func attemptUpdate(for parameters: Parameters, model: String, data: any ContentContainer) async throws
    {
        guard let box = models[model] else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        try await box.attemptUpdate(for: parameters, data: data)
    }
    
    func newModelInfo(for model: String) async throws -> [ModelInstancePropertyRepresentation]
    {
        guard let box = models[model] else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        return try await box.newModelInfo()
    }
    
    func attemptCreate(for model: String, data: any ContentContainer) async throws
    {
        guard let box = models[model] else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        try await box.attemptCreate(data: data)
    }
    
    func attemptDelete(for model: String, parameters: Parameters) async throws
    {
        guard let box = models[model] else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        try await box.attemptDelete(parameters: parameters)
    }
}
