//
//  Model+Admin.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/3/26.
//

import Foundation
import Fluent

private let jsonDecoder : JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.assumesTopLevelDictionary = true
    return decoder
}()

private let jsonEncoder : JSONEncoder = {
    let encoder = JSONEncoder()
    return encoder
}()

// Helper to get the `innerType` from a variable
private func decode<T : Decodable>(data: Data, innerType: T.Type) throws -> T
{
    try jsonDecoder.decode(DecodedData<T>.self, from: data).field
}

extension Model
{
    var idDescription : String { String(describing: id!) }
    var adminDescription : String { (self as? any CustomAdminDisplayable)?.displayString ?? idDescription }
}

extension Model where Self : FluentAdminDisplay
{
    typealias IDKeyPath = KeyPath<Self, Fluent.IDProperty<Self, IDValue>>
    
    static var idField : IDKeyPath { Self.adminMetadata.filter { $0.metadata is IDProperty }.first!.fluentKeypath as! IDKeyPath }
    
    static func instance(for id: IDValue, on database: Database) async throws -> Self
    {
        guard let instance = try await database.query(Self.self).filter(idField == id).first() else { throw AdminError.couldNotFindInstance }
        return instance
    }
    
    func adminFieldRepresentations(database: Database) async throws -> [ModelInstancePropertyRepresentation]
    {
        var output = [ModelInstancePropertyRepresentation]()
        for property in Self.adminMetadata.filter({ !($0.metadata is IDProperty) })
        {
            let key = property.name
            var value = (self[keyPath: property.fluentKeypath] as! any Property).value
            var propertyType = type(of: property.dataKeypath).valueType
            
            if let optionalProperty = propertyType as? OptionalProtocol.Type
            {
                propertyType = optionalProperty.wrappedType()
            }
            
            let fieldType : ModelInstancePropertyRepresentation.FieldType
            if propertyType is any BinaryInteger.Type || propertyType is any FloatingPoint.Type
            {
                fieldType = .number
            }
            else if propertyType is any (CaseIterable & RawRepresentable).Type
            {
                func getCases<T : CaseIterable & RawRepresentable>(from value: T.Type) -> [String] { return T.allCases.map { String(describing: $0.rawValue) } }
                let _propertyType = propertyType as? (any (CaseIterable & RawRepresentable).Type)
                fieldType = .array(possibleValues: getCases(from: _propertyType!))
            }
            else if let metadata = property.metadata as? any RelationshipProperty
            {
                value = metadata.getID(on: self, fluentKeypath: property.fluentKeypath)
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
    
    func updateFields(from data: [String : String], database: Database) async throws
    {
        for property in Self.adminMetadata.filter({ !($0.metadata is IDProperty) })
        {
            guard let update = data[property.name] else { continue }
            var rawPropertyType = type(of: property.dataKeypath).valueType
            
            if let optionalProperty = rawPropertyType as? OptionalProtocol.Type
            {
                rawPropertyType = optionalProperty.wrappedType()
            }
            
            let propertyType = rawPropertyType as! any Decodable.Type
            
            if let relationship = property.metadata as? any RelationshipProperty // We have a relationship, do something
            {
                if update.isEmpty
                {
                    relationship.nilOut(on: self, fluentKeypath: property.fluentKeypath)
                }
                else
                {
                    let data = try jsonEncoder.encode(EncodedData(field: update))
                    try relationship.setNewEntry(from: data, decoder: jsonDecoder, fluentKeypath: property.fluentKeypath, on: self, from: database)
                }
            }
            else // Simple set
            {
                let data = try jsonEncoder.encode(EncodedData(field: update))
                let value = try decode(data: data, innerType: propertyType)
                
                func write<T : Decodable>(value: T)
                {
                    self[keyPath: property.dataKeypath as! ReferenceWritableKeyPath] = value as T?
                }
                write(value: value)
                
            }
        }
        
        if _$idExists
        {
            try await save(on: database)
        }
        else
        {
            try await create(on: database)
        }
    }
}
