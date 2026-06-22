struct AdminContext
{
    struct Header : Codable
    {
        struct Breadcrumb : Codable, Equatable
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
        struct Entry : Codable, Equatable
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
        struct Create : Codable
        {
            let header : Header
            let modelName : String
            
            let fields : [ModelInstancePropertyRepresentation]
        }
        
        let header : Header
        let modelName : String
        let displayName : String
        let entryID : String
        
        let fields : [ModelInstancePropertyRepresentation]
    }
}
