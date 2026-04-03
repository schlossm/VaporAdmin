//
//  IntermediateRepresentations.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/2/26.
//

struct ModelInstancePropertyRepresentation : Codable
{
    struct Relationship : Codable
    {
        let displayName : String
        let id : String
    }
    
    enum FieldType : Codable
    {
        case text
        case number
        case array(possibleValues: [String])
        case relationship(optional: Bool, possibleValues: [Relationship])
    }
    
    let key : String
    let value : String
    let fieldType : FieldType
}

struct ModelInstanceRepresentation
{
    let id : String
    let description : String
}

struct ModelInstancePropertiesRepresentation
{
    let id : String
    let description : String
    let properties : [ModelInstancePropertyRepresentation]
}
