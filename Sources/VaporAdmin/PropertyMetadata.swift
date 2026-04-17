import Fluent
import Foundation
import struct Foundation.UUID

/// Defines a single `adminMetadata` property.  Add the `@AdminDisplayable` Macro to properly conform to this protocol
public protocol FluentAdminDisplay
{
    static var adminMetadata : [PropertyMetadata<Self>] { get }
}

/// An interface for describing a property
public protocol FluentPropertyMetadata
{
    var isOptional : Bool { get }
    var isMultiRelationship : Bool { get }
}

/// Metadata that describes each Fluent property
public struct PropertyMetadata<T>
{
    let name : String
    let fluentKeypath : AnyKeyPath
    let dataKeypath : AnyKeyPath
    let metadata : (any FluentPropertyMetadata)?
    
    public init(name: String, fluentKeypath: AnyKeyPath, dataKeypath: AnyKeyPath, metadata: (any FluentPropertyMetadata)?)
    {
        self.name = name
        self.fluentKeypath = fluentKeypath
        self.dataKeypath = dataKeypath
        self.metadata = metadata
    }
}

/// Describes a Fluent `ID` property
public struct IDProperty : FluentPropertyMetadata
{
    public let isOptional = false
    public let isMultiRelationship = false
    
    public init() {}
}

/// Describes a Fluent `Optional<Value>` property
public struct OptionalProperty : FluentPropertyMetadata
{
    public let isOptional = true
    public let isMultiRelationship = false
    
    public init() {}
}

protocol RelationshipProperty : FluentPropertyMetadata
{
    associatedtype RelationshipModel : Model
    associatedtype BaseModel : Model
    
    func process<T : Model>(update: String, on model: T, keypath: AnyKeyPath) throws
    func getCurrentRelationships<T : Model>(on model: T, keypath: AnyKeyPath) -> [RelationshipModel.IDValue]
    func getPossibleRelationshipValues(from database: Database) async throws -> [ModelInstancePropertyRepresentation.Relationship]
}

/// Describes a Fluent `OptionalParent` property
public struct OptionalParentRelationshipProperty<BaseModel : Model, RelationshipModel : Model> : RelationshipProperty
{
    public let isOptional = true
    public let isMultiRelationship = false
    
    public init() {}
    
    private func ensureKeyPathIsCorrect(keypath: AnyKeyPath) -> KeyPath<BaseModel, OptionalParentProperty<BaseModel, RelationshipModel>>
    {
        guard let keyPath = keypath as? KeyPath<BaseModel, OptionalParentProperty<BaseModel, RelationshipModel>> else
        {
            preconditionFailure("Internal error -- invalid keypath")
        }
        return keyPath
    }
    
    func process<T : Model>(update: String, on model: T, keypath: AnyKeyPath) throws
    {
        let keyPath = ensureKeyPathIsCorrect(keypath: keypath)
        let model = model as! BaseModel
        if update.isEmpty
        {
            model[keyPath: keyPath].id = nil
        }
        else
        {
            let data = try JSONEncoder().encode(EncodedData(field: update))
            let id = try JSONDecoder().decode(DecodedData<RelationshipModel.IDValue>.self, from: data).field
            model[keyPath: keyPath].id = id
        }
    }
    
    func getCurrentRelationships<T : Model>(on model: T, keypath: AnyKeyPath) -> [RelationshipModel.IDValue]
    {
        let keyPath = ensureKeyPathIsCorrect(keypath: keypath)
        let model = model as! BaseModel
        return model[keyPath: keyPath].id.map { [$0] } ?? []
    }
    
    func getPossibleRelationshipValues(from database: Database) async throws -> [ModelInstancePropertyRepresentation.Relationship]
    {
        let values = try await database.query(RelationshipModel.self).all()
        return values.compactMap
        { value -> ModelInstancePropertyRepresentation.Relationship? in
            guard let id = value.id else { return nil }
            return ModelInstancePropertyRepresentation.Relationship(displayName: value.adminDescription, id: String(describing: id))
        }
    }
}

/// Describes a Fluent `Parent` property
public struct ParentRelationshipProperty<BaseModel : Model, RelationshipModel : Model> : RelationshipProperty
{
    public let isOptional = false
    public let isMultiRelationship = false
    
    public init() {}
    
    private func ensureKeyPathIsCorrect(keypath: AnyKeyPath) -> KeyPath<BaseModel, ParentProperty<BaseModel, RelationshipModel>>
    {
        guard let keyPath = keypath as? KeyPath<BaseModel, ParentProperty<BaseModel, RelationshipModel>> else
        {
            preconditionFailure("Internal error -- invalid keypath")
        }
        return keyPath
    }
    
    func process<T : Model>(update: String, on model: T, keypath: AnyKeyPath) throws
    {
        let keyPath = ensureKeyPathIsCorrect(keypath: keypath)
        let model = model as! BaseModel
        guard !update.isEmpty else { throw AdminError.invalidInput }
        let data = try JSONEncoder().encode(EncodedData(field: update))
        let id = try JSONDecoder().decode(DecodedData<RelationshipModel.IDValue>.self, from: data).field
        model[keyPath: keyPath].id = id
    }
    
    func getCurrentRelationships<T : Model>(on model: T, keypath: AnyKeyPath) -> [RelationshipModel.IDValue]
    {
        let keyPath = ensureKeyPathIsCorrect(keypath: keypath)
        let model = model as! BaseModel
        return [model[keyPath: keyPath].id]
    }
    
    func getPossibleRelationshipValues(from database: Database) async throws -> [ModelInstancePropertyRepresentation.Relationship]
    {
        let values = try await database.query(RelationshipModel.self).all()
        return values.compactMap
        { value -> ModelInstancePropertyRepresentation.Relationship? in
            guard let id = value.id else { return nil }
            return ModelInstancePropertyRepresentation.Relationship(displayName: value.adminDescription, id: String(describing: id))
        }
    }
}
