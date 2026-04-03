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
    var isRelationship : Bool { get }
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
    public let isRelationship = false
    
    public init() {}
}

/// Describes a Fluent `Optional<Value>` property
public struct OptionalProperty : FluentPropertyMetadata
{
    public let isOptional = true
    public let isRelationship = false
    
    public init() {}
}

protocol RelationshipProperty : FluentPropertyMetadata
{
    associatedtype RelationshipModel : Model
    associatedtype BaseModel : Model
    
    func getRelationshipModels(from database: Database) async throws -> [ModelInstancePropertyRepresentation.Relationship]
    
    func nilOut<T: Model>(on model: T, fluentKeypath: AnyKeyPath)
    func getID<T: Model>(on model: T, fluentKeypath: AnyKeyPath) -> RelationshipModel.IDValue?
    func setNewEntry<T: Model>(from data: Data, decoder: JSONDecoder, fluentKeypath: AnyKeyPath, on model: T, from database: Database) throws
}

/// Describes a Fluent Relationship property
public struct NonOptionalRelationshipProperty<BaseModel : Model, RelationshipModel : Model> : RelationshipProperty where RelationshipModel.IDValue == UUID
{
    public let isOptional = false
    public let isRelationship = true
    
    public init() {}
}

/// Describes a Fluent `Optional<Relationship>` property
public struct OptionalRelationshipProperty<BaseModel : Model, RelationshipModel : Model> : RelationshipProperty where RelationshipModel.IDValue == UUID
{
    public let isOptional = true
    public let isRelationship = true
    
    public init() {}
}

extension RelationshipProperty
{
    func getRelationshipModels(from database: Database) async throws -> [ModelInstancePropertyRepresentation.Relationship]
    {
        let values = try await database.query(RelationshipModel.self).all()
        return values.compactMap
        { value in
            if let displayable = value as? any CustomAdminDisplayable
            {
                guard let id = value.id else { return nil }
                return ModelInstancePropertyRepresentation.Relationship(displayName: displayable.displayString, id: String(describing: id))
            }
            else
            {
                assertionFailure("\(type(of: value)) doesn't conform to `AdminDisplayable`")
                guard let id = value.id else { return nil }
                return ModelInstancePropertyRepresentation.Relationship(displayName: String(describing: id), id: String(describing: id))
            }
        }
    }
    
    func nilOut<T: Model>(on model: T, fluentKeypath: AnyKeyPath)
    {
        let model = model as! BaseModel
        if let keypath = fluentKeypath as? KeyPath<BaseModel, OptionalParentProperty<BaseModel, RelationshipModel>>
        {
            model[keyPath: keypath].id = nil
        }
    }
    
    func getID<T: Model>(on model: T, fluentKeypath: AnyKeyPath) -> RelationshipModel.IDValue?
    {
        let model = model as! BaseModel
        if let keypath = fluentKeypath as? KeyPath<BaseModel, OptionalParentProperty<BaseModel, RelationshipModel>>
        {
            return model[keyPath: keypath].id
        }
        return nil
    }
    
    func setNewEntry<T: Model>(from data: Data, decoder: JSONDecoder, fluentKeypath: AnyKeyPath, on model: T, from database: Database) throws
    {
        let id = try decoder.decode(DecodedData<RelationshipModel.IDValue>.self, from: data).field
        let model = model as! BaseModel
        if let keypath = fluentKeypath as? KeyPath<BaseModel, OptionalParentProperty<BaseModel, RelationshipModel>>
        {
            model[keyPath: keypath].id = id
        }
    }
}
