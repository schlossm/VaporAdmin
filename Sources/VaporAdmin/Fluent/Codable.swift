//
//  Codable.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/2/26.
//

struct EncodedData<T : Encodable> : Encodable
{
    let field : T
}

struct DecodedData<T : Decodable> : Decodable
{
    let field : T
    
    enum CodingKeys: CodingKey
    {
        case field
    }
    
    init(from decoder: any Decoder) throws
    {
        // Attempt to decode using the following algorithm:
        // 1. If the type conforms to Decodable (or Codable), decode using that
        // 2. If it can't decode the type (for example String -> Int), check if `T` conforms to either LosslessStringConvertible or RawRepresentable<String>
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do
        {
            self.field = try container.decode(T.self, forKey: .field)
        }
        catch DecodingError.typeMismatch
        {
            if let _type = T.self as? LosslessStringConvertible.Type
            {
                let string = try container.decode(String.self, forKey: .field)
                guard let result = _type.init(string) else
                {
                    throw DecodingError.typeMismatch(T.self, .init(codingPath: [CodingKeys.field], debugDescription: "Cannot convert string to type \(T.self)"))
                }
                field = result as! T
                return
            }
            else if let _type = T.self as? (any RawRepresentable<String>.Type)
            {
                let string = try container.decode(String.self, forKey: .field)
                guard let result = _type.init(rawValue: string) else
                {
                    throw DecodingError.typeMismatch(T.self, .init(codingPath: [CodingKeys.field], debugDescription: "Cannot convert string to type \(T.self)"))
                }
                field = result as! T
                return
            }
            throw DecodingError.typeMismatch(T.self, .init(codingPath: [CodingKeys.field], debugDescription: "Cannot convert string to type \(T.self)"))
        }
    }
}
