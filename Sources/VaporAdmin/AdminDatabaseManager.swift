//
//  AdminDatabaseManager.swift
//  mascomputech
//
//  Created by Michael Schloss on 2/28/26.
//

import Fluent
import Vapor

// MARK: - Package

package enum AdminError : Error
{
    case couldNotFindModel
    case couldNotFindInstance
    case unexpected(message: String)
}

package struct AdminField
{
    package struct Relationship
    {
        let displayName : String
        let id : String
    }
    
    enum FieldType
    {
        case text
        case number
        case array(possibleValues: [String])
        case relationship(optional: Bool, possibleValues: [Relationship])
    }
    
    let type : FieldType
    let key : String
    let value : String
}

// MARK: - Private

private protocol _ModelBox
{
    associatedtype IDValue
    
    func entries() async throws -> [(id: String, key: String)]
    func values(parameters: Parameters) async throws -> (id: String, displayName: String, fields: [AdminField])
    func attemptUpdate(for parameters: Parameters, data: any ContentContainer) async throws
    func newModelInfo() async throws -> [AdminField]
    func attemptCreate(data: any ContentContainer) async throws
    func attemptDelete(parameters: Parameters) async throws
}

private struct EncodedData<T : Encodable> : Encodable
{
    let field : T
}

private struct DecodedData<T : Decodable> : Decodable
{
    let field : T
    
    enum CodingKeys: CodingKey
    {
        case field
    }
    
    init(from decoder: any Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do
        {
            self.field = try container.decode(T.self, forKey: .field)
        }
        catch DecodingError.typeMismatch
        {
            // Check if T conforms to LosslessStringConvertible, it's the only way to move forward
            if let _type = T.self as? LosslessStringConvertible.Type
            {
                let string = try container.decode(String.self, forKey: .field)
                guard let result = _type.init(string) else
                {
                    throw DecodingError.typeMismatch(T.self, .init(codingPath: [CodingKeys.field], debugDescription: "Cannot convert string to type \(T.self)"))
                }
                field = result as! T
                return
            }
            throw DecodingError.typeMismatch(T.self, .init(codingPath: [CodingKeys.field], debugDescription: "Cannot convert string to type \(T.self)"))
        }
        catch
        {
            throw error
        }
    }
}

private struct ModelBox<ModelType : FluentAdminDisplay & Model, IDValue : LosslessStringConvertible> : _ModelBox where IDValue == ModelType.IDValue
{
    let modelType : ModelType.Type
    let database : Database
    
    var idField : KeyPath<ModelType, Fluent.IDProperty<ModelType, IDValue>>
    {
        modelType.adminMetadata.filter { $0.metadata is IDProperty }.first!.fluentKeypath as! KeyPath<ModelType, Fluent.IDProperty<ModelType, IDValue>>
    }
    
    init(modelType: ModelType.Type, database: Database)
    {
        self.modelType = modelType
        self.database = database
    }
    
    func entries() async throws -> [(id: String, key: String)]
    {
        let entries = try await database.query(modelType).all()
        return entries.map { (String(describing: $0.id!), getDisplayString(from: $0)) }
    }
    
    func values(parameters: Parameters) async throws -> (id: String, displayName: String, fields: [AdminField])
    {
        let entry = try parameters.require("entry", as: IDValue.self)
        guard let model = try await database.query(modelType).filter(idField == entry).first() else { throw AdminError.couldNotFindInstance }
        
        let fields = try await _fields(for: model)
        return (String(describing: model.id!), getDisplayString(from: model), fields)
    }
    
    func attemptUpdate(for parameters: Parameters, data: any ContentContainer) async throws
    {
        let entry = try parameters.require("entry", as: IDValue.self)
        let data = try data.decode([String : String].self)
        guard let model = try await database.query(modelType).filter(idField == entry).first() else { throw AdminError.couldNotFindInstance }
        
        try await updateFields(on: model, data: data, create: false)
    }
    
    func newModelInfo() async throws -> [AdminField]
    {
        let model = ModelType.init()
        return try await _fields(for: model)
    }
    
    func attemptCreate(data: any ContentContainer) async throws
    {
        let newModel = try data.decode(ModelType.self)
        let data = try data.decode([String : String].self)
        try await updateFields(on: newModel, data: data, create: true)
    }
    
    func attemptDelete(parameters: Parameters) async throws
    {
        let entry = try parameters.require("entry", as: IDValue.self)
        guard let model = try await database.query(modelType).filter(idField == entry).first() else { throw AdminError.couldNotFindInstance }
        try await model.delete(on: database)
    }
    
    private func _fields(for model: ModelType) async throws -> [AdminField]
    {
        var output = [AdminField]()
        for property in ModelType.adminMetadata.filter({ !($0.metadata is IDProperty) })
        {
            let key = property.name
            var value = (model[keyPath: property.fluentKeypath] as! any Property).value
            let propertyType = type(of: property.dataKeypath).valueType
            
            let fieldType : AdminField.FieldType
            if propertyType is any BinaryInteger.Type || propertyType is any FloatingPoint.Type
            {
                fieldType = .number
            }
            else if propertyType is any (CaseIterable & RawRepresentable).Type
            {
                func getCases<T : CaseIterable & RawRepresentable>(from value: T.Type) -> [String] { return T.allCases.map { String(describing: $0.rawValue) } }
                let _propertyType = propertyType as? (any (CaseIterable & RawRepresentable).Type)
                fieldType = .array(possibleValues: _openExistential(_propertyType!, do: getCases(from:)))
            }
            else if let metadata = property.metadata as? any RelationshipProperty
            {
                value = metadata.getID(on: model, fluentKeypath: property.fluentKeypath)
                fieldType = try await .relationship(optional: metadata.isOptional, possibleValues: metadata.getRelationshipModels(from: database))
            }
            else
            {
                fieldType = .text
            }
        
            if let value
            {
                output.append(.init(type: fieldType, key: key, value: String(describing: value)))
            }
            else
            {
                output.append(.init(type: fieldType, key: key, value: ""))
            }
        }
        
        return output
    }
    
    private func updateFields(on model: ModelType, data: [String : String], create: Bool) async throws
    {
        let jsonDecoder : JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.assumesTopLevelDictionary = true
            return decoder
        }()
        
        let jsonEncoder : JSONEncoder = {
            let encoder = JSONEncoder()
            return encoder
        }()
        
        func decode<T : Decodable>(data: Data, innerType: T.Type) throws -> T
        {
            try jsonDecoder.decode(DecodedData<T>.self, from: data).field
        }
        
        for property in ModelType.adminMetadata.filter({ !($0.metadata is IDProperty) })
        {
            guard let update = data[property.name] else { continue }
            let rawPropertyType = type(of: property.dataKeypath).valueType
            let propertyType = rawPropertyType as! any Decodable.Type
            
            if let relationship = property.metadata as? any RelationshipProperty // We have a relationship, do something
            {
                if update.isEmpty
                {
                    relationship.nilOut(on: model, fluentKeypath: property.fluentKeypath)
                }
                else
                {
                    let data = try jsonEncoder.encode(EncodedData(field: update))
                    let value = try decode(data: data, innerType: UUID.self)
                    relationship.setNewEntry(id: value, fluentKeypath: property.fluentKeypath, on: model, from: database)
                }
            }
            else // Simple set
            {
                let data = try jsonEncoder.encode(EncodedData(field: update))
                let value = try decode(data: data, innerType: propertyType)
                
                func write<T : Decodable>(value: T)
                {
                    model[keyPath: property.dataKeypath as! ReferenceWritableKeyPath] = value
                }
                _openExistential(value, do: write(value:))
            }
        }
        
        if !create
        {
            try await model.save(on: database)
        }
        else
        {
            try await model.create(on: database)
        }
    }
    
    private func getDisplayString(from model: ModelType) -> String
    {
        if let adminDisplayable = model as? any CustomAdminDisplayable
        {
            return adminDisplayable.displayString
        }
        return model.description
    }
}

public class AdminDatabaseManager : @unchecked Sendable
{
    let database : Database
    private var models = [(displayName: String, box: any _ModelBox)]()
    
    init(database: Database)
    {
        self.database = database
    }
    
    func register<T: FluentAdminDisplay & Model>(_ model: T.Type) where T.IDValue : LosslessStringConvertible
    {
        models.append((String(describing: model), ModelBox(modelType: model, database: database)))
    }
    
    func listModels() -> [String]
    {
        models.map { $0.displayName }
    }
    
    func listEntries(for model: String) async throws -> [(id: String, key: String)]
    {
        guard let box = models.first(where: { $0.displayName == model })?.box else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        return try await box.entries()
    }
    
    func details(for parameters: Parameters, model: String) async throws -> (id: String, displayName: String, fields: [AdminField])
    {
        guard let box = models.first(where: { $0.displayName == model })?.box else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        return try await box.values(parameters: parameters)
    }
    
    func attemptUpdate(for parameters: Parameters, model: String, data: any ContentContainer) async throws
    {
        guard let box = models.first(where: { $0.displayName == model })?.box else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        try await box.attemptUpdate(for: parameters, data: data)
    }
    
    func newModelInfo(for model: String) async throws -> [AdminField]
    {
        guard let box = models.first(where: { $0.displayName == model })?.box else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        return try await box.newModelInfo()
    }
    
    func attemptCreate(for model: String, data: any ContentContainer) async throws
    {
        guard let box = models.first(where: { $0.displayName == model })?.box else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        try await box.attemptCreate(data: data)
    }
    
    func attemptDelete(for model: String, parameters: Parameters) async throws
    {
        guard let box = models.first(where: { $0.displayName == model })?.box else { fatalError("Invalid `model`: \(model).  `model` must be a value returned from `listModels()") }
        try await box.attemptDelete(parameters: parameters)
    }
}
