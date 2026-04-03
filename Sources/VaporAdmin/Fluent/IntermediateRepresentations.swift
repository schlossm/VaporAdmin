//
//  IntermediateRepresentations.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/2/26.
//

struct ModelInstancePropertyRepresentation
{
    struct Relationship
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
