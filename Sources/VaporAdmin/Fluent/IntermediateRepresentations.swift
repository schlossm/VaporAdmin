//
//  IntermediateRepresentations.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/2/26.
//

struct ModelInstancePropertyRepresentation : Codable, Equatable
{
    struct Relationship : Codable, Equatable
    {
        let displayName : String
        let id : String
    }
    
    enum FieldType : Codable, Equatable
    {
        case bool
        case text
        case number
        case array(possibleValues: [String])
        case relationship(possibleValues: [Relationship])
    }
    
    let key : String
    let value : String
    let fieldType : FieldType
    
    let optional : Bool
    let isMultiSelect : Bool
}

struct ModelInstanceRepresentation : Equatable
{
    let id : String
    let description : String
}

struct ModelInstancePropertiesRepresentation : Equatable
{
    let id : String
    let description : String
    let properties : [ModelInstancePropertyRepresentation]
}
