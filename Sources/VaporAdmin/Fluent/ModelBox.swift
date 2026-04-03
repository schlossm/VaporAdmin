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

private let jsonDecoder : JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.assumesTopLevelDictionary = true
    return decoder
}()

private let jsonEncoder : JSONEncoder = {
    let encoder = JSONEncoder()
    return encoder
}()

struct _ModelBox<ModelType : FluentAdminDisplay & Model> : ModelBox
{
    typealias IDValue = ModelType.IDValue
    
    private let database : Database
    private let fieldTypeCache = [AnyKeyPath : ModelInstancePropertyRepresentation.FieldType]()
    
    private var idField : KeyPath<ModelType, Fluent.IDProperty<ModelType, IDValue>>
    {
        ModelType.adminMetadata.filter { $0.metadata is IDProperty }.first!.fluentKeypath as! KeyPath<ModelType, Fluent.IDProperty<ModelType, IDValue>>
    }
    
    init(database: Database)
    {
        self.database = database
    }
    
    func instances() async throws -> [ModelInstanceRepresentation]
    {
        let entries = try await database.query(ModelType.self).all()
        return entries.map { .init(id: String(describing: $0.id!), description: getDisplayString(from: $0)) }
    }
    
    func instanceProperties(parameters: Parameters) async throws -> ModelInstancePropertiesRepresentation
    {
        let entry = try parameters.require("entry", as: IDValue.self)
        guard let model = try await database.query(ModelType.self).filter(idField == entry).first() else { throw AdminError.couldNotFindInstance }
        
        let fields = try await _fields(for: model)
        return .init(id: String(describing: model.id!), description: getDisplayString(from: model), properties: fields)
    }
    
    func attemptUpdate(for parameters: Parameters, data: any ContentContainer) async throws
    {
        let entry = try parameters.require("entry", as: IDValue.self)
        let data = try data.decode([String : String].self)
        guard let model = try await database.query(ModelType.self).filter(idField == entry).first() else { throw AdminError.couldNotFindInstance }
        
        try await updateFields(on: model, data: data, create: false)
    }
    
    func newModelInfo() async throws -> [ModelInstancePropertyRepresentation]
    {
        let model = ModelType.init()
        return try await _fields(for: model)
    }
    
    func attemptCreate(data: any ContentContainer) async throws
    {
        // To work around a Swift crash when keypath sets access the getters, we need to try a raw decode to the type first, then update any "weird" properties that can't be represented by the JS form data
        let newModel = try data.decode(ModelType.self)
        let data = try data.decode([String : String].self)
        try await updateFields(on: newModel, data: data, create: true)
    }
    
    func attemptDelete(parameters: Parameters) async throws
    {
        let entry = try parameters.require("entry", as: IDValue.self)
        guard let model = try await database.query(ModelType.self).filter(idField == entry).first() else { throw AdminError.couldNotFindInstance }
        try await model.delete(on: database)
    }
    
    private func _fields(for model: ModelType) async throws -> [ModelInstancePropertyRepresentation]
    {
        var output = [ModelInstancePropertyRepresentation]()
        for property in ModelType.adminMetadata.filter({ !($0.metadata is IDProperty) })
        {
            let key = property.name
            var value = (model[keyPath: property.fluentKeypath] as! any Property).value
            let propertyType = type(of: property.dataKeypath).valueType
            
            let fieldType : ModelInstancePropertyRepresentation.FieldType
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
                output.append(.init(key: key, value: String(describing: value), fieldType: fieldType))
            }
            else
            {
                output.append(.init(key: key, value: "", fieldType: fieldType))
            }
        }
        
        return output
    }
    
    private func updateFields(on model: ModelType, data: [String : String], create: Bool) async throws
    {
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
                    try relationship.setNewEntry(from: data, decoder: jsonDecoder, fluentKeypath: property.fluentKeypath, on: model, from: database)
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
