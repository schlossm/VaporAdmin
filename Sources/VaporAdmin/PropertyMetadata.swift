import Fluent
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
    package let name : String
    package let fluentKeypath : AnyKeyPath
    package let dataKeypath : AnyKeyPath
    package let metadata : (any FluentPropertyMetadata)?
    
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

package protocol RelationshipProperty : FluentPropertyMetadata
{
    associatedtype RelationshipModel : Model where RelationshipModel.IDValue == UUID
    associatedtype BaseModel : Model
    
    func getRelationshipModels(from database: Database) async throws -> [AdminField.Relationship]
    
    func nilOut<T: Model>(on model: T, fluentKeypath: AnyKeyPath)
    func getID<T: Model>(on model: T, fluentKeypath: AnyKeyPath) -> UUID?
    func setNewEntry<T: Model>(id: UUID, fluentKeypath: AnyKeyPath, on model: T, from database: Database)
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
    package func getRelationshipModels(from database: Database) async throws -> [AdminField.Relationship]
    {
        let values = try await database.query(RelationshipModel.self).all()
        return values.compactMap
        { value in
            if let displayable = value as? any CustomAdminDisplayable
            {
                guard let id = value.id else { return nil }
                return AdminField.Relationship(displayName: displayable.displayString, id: String(describing: id))
            }
            else
            {
                assertionFailure("\(type(of: value)) doesn't conform to `AdminDisplayable`")
                guard let id = value.id else { return nil }
                return AdminField.Relationship(displayName: String(describing: id), id: String(describing: id))
            }
        }
    }
    
    package func nilOut<T: Model>(on model: T, fluentKeypath: AnyKeyPath)
    {
        let model = model as! BaseModel
        if let keypath = fluentKeypath as? KeyPath<BaseModel, OptionalParentProperty<BaseModel, RelationshipModel>>
        {
            model[keyPath: keypath].id = nil
        }
    }
    
    package func getID<T: Model>(on model: T, fluentKeypath: AnyKeyPath) -> UUID?
    {
        let model = model as! BaseModel
        if let keypath = fluentKeypath as? KeyPath<BaseModel, OptionalParentProperty<BaseModel, RelationshipModel>>
        {
            return model[keyPath: keypath].id
        }
        return nil
    }
    
    package func setNewEntry<T: Model>(id: UUID, fluentKeypath: AnyKeyPath, on model: T, from database: Database)
    {
        let model = model as! BaseModel
        if let keypath = fluentKeypath as? KeyPath<BaseModel, OptionalParentProperty<BaseModel, RelationshipModel>>
        {
            model[keyPath: keypath].id = id
        }
    }
}
