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
            var value : Any? = (self[keyPath: property.fluentKeypath] as! any Property).value
            var propertyType = type(of: property.dataKeypath).valueType
            
            let isOptional : Bool
            let isMultiSelect : Bool
            
            if let metadata = property.metadata
            {
                isOptional = metadata.isOptional
                isMultiSelect = metadata.isMultiRelationship
            }
            else
            {
                isOptional = false
                isMultiSelect = false
            }
            
            // unwrap all optionals to base type
            while let optionalProperty = propertyType as? OptionalProtocol.Type
            {
                propertyType = optionalProperty.wrappedType()
            }
            
            func unwrapGeneric<T>(value: Any?, type: T.Type) -> T?
            {
                return (value as? OptionalProtocol)?.getValue()
            }
            value = unwrapGeneric(value: value, type: propertyType)
            
            let fieldType : ModelInstancePropertyRepresentation.FieldType
            if propertyType is any BinaryInteger.Type || propertyType is any FloatingPoint.Type
            {
                fieldType = .number
            }
            else if propertyType is Bool.Type
            {
                fieldType = .bool
            }
            else if propertyType is any (CaseIterable & RawRepresentable).Type
            {
                func getCases<T : CaseIterable & RawRepresentable>(from value: T.Type) -> [String] { return T.allCases.map { String(describing: $0.rawValue) } }
                let _propertyType = propertyType as? (any (CaseIterable & RawRepresentable).Type)
                fieldType = .array(possibleValues: getCases(from: _propertyType!))
            }
            else if let metadata = property.metadata as? any RelationshipProperty
            {
                let relationships = metadata.getCurrentRelationships(on: self, keypath: property.fluentKeypath)
                if relationships.count == 1
                {
                    value = relationships[0]
                }
                else
                {
                    value = relationships.map { String(describing: $0) }
                }
                fieldType = try await .relationship(possibleValues: metadata.getPossibleRelationshipValues(from: database))
            }
            else
            {
                fieldType = .text
            }
        
            if let value
            {
                output.append(.init(key: key, value: String(describing: value), fieldType: fieldType, optional: isOptional, isMultiSelect: isMultiSelect))
            }
            else
            {
                output.append(.init(key: key, value: "", fieldType: fieldType, optional: isOptional, isMultiSelect: isMultiSelect))
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
                try relationship.process(update: update, on: self, keypath: property.fluentKeypath)
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
