//
//  LeafContextModels.swift
//  mascomputech
//
//  Created by Michael Schloss on 3/1/26.
//

struct AdminContext
{
    struct Header : Codable
    {
        struct Breadcrumb : Codable
        {
            let text : String
            let relativeHREF : String
            let isActive : Bool
        }
        
        let username : String
        let breadcrumbs : [Breadcrumb]
    }
    
    struct Root : Codable
    {
        let header : Header
        let modelNames : [String]
    }
    
    struct List : Codable
    {
        struct Entry : Codable
        {
            let id : String
            let text : String
        }
        
        let header : Header
        let modelName : String
        let entries : [Entry]
    }
    
    struct Detail : Codable
    {
        struct Field : Codable
        {
            struct Relationship : Codable
            {
                let displayName : String
                let id : String
                
                init(adminField: ModelInstancePropertyRepresentation.Relationship)
                {
                    self.displayName = adminField.displayName
                    self.id = adminField.id
                }
            }
            
            enum FieldType : Codable
            {
                case text
                case number
                case array(possibleValues: [String])
                case relationship(optional: Bool, possibleValues: [Relationship])
                
                init(fieldType: ModelInstancePropertyRepresentation.FieldType)
                {
                    switch fieldType
                    {
                    case .text:
                        self = .text
                        
                    case .number:
                        self = .number
                        
                    case .array(let possibleValues):
                        self = .array(possibleValues: possibleValues)
                        
                    case .relationship(let isOptional, let possibleValues):
                        self = .relationship(optional: isOptional, possibleValues: possibleValues.map(Relationship.init(adminField:)))
                    }
                }
            }
            
            let key : String
            let value : String
            let fieldType : FieldType
        }
        
        struct Create : Codable
        {
            let header : Header
            let modelName : String
            
            let fields : [Field]
        }
        
        let header : Header
        let modelName : String
        let displayName : String
        let entryID : String
        
        let fields : [Field]
    }
}
