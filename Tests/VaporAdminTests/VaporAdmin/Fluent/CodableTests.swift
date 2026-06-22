@testable import VaporAdmin
import Foundation
import Testing

@Suite("Codable.swift Tests")
struct CodableTests
{
    private let jsonDecoder : JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.assumesTopLevelDictionary = true
        return decoder
    }()

    private let jsonEncoder : JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()
    
    @Test("String -> String")
    func stringToString() throws
    {
        let testData = "hello"
        let encodedData = try jsonEncoder.encode(EncodedData(field: testData))
        let decoded = try jsonDecoder.decode(DecodedData<String>.self, from: encodedData).field
        
        #expect(decoded == testData)
    }
    
    @Test("String -> Int")
    func stringToInt() throws
    {
        let testData = "1"
        let encodedData = try jsonEncoder.encode(EncodedData(field: testData))
        let decoded = try jsonDecoder.decode(DecodedData<Int>.self, from: encodedData).field
        
        #expect(decoded == 1)
    }
    
    @Test("String -> enum")
    func stringToEnum() throws
    {
        enum Foo : String, Decodable
        {
            case bar = "1"
        }
        
        let testData = "1"
        let encodedData = try jsonEncoder.encode(EncodedData(field: testData))
        let decoded = try jsonDecoder.decode(DecodedData<Foo>.self, from: encodedData).field
        
        #expect(decoded == .bar)
    }
    
    @Test("String -> RawRepresentable<String> with custom coding")
    func stringToRawRepresentable() throws
    {
        struct Foo : RawRepresentable, Codable
        {
            typealias RawValue = String
            var bar : Int
            
            var rawValue : String { String(bar) }
            
            enum CodingKeys : String, CodingKey
            {
                case bar
            }
            
            init(from decoder: any Decoder) throws
            {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                bar = try container.decode(Int.self, forKey: .bar)
            }
            
            func encode(to encoder: any Encoder) throws
            {
                var container = encoder.container(keyedBy: CodingKeys.self)
                let barAsString = String(bar)
                try container.encode(barAsString, forKey: .bar)
            }
            
            init?(rawValue: String)
            {
                guard let int = Int(rawValue), int == 1 else { return nil }
                bar = int
            }
        }
        
        let testData = "1"
        let encodedData = try jsonEncoder.encode(EncodedData(field: testData))
        let decoded = try jsonDecoder.decode(DecodedData<Foo>.self, from: encodedData).field
        
        #expect(decoded.bar == 1)
    }
    
    @Test("Failed: String -> LosslessStringConvertible")
    func failedStringToLosslessStringConvertible() throws
    {
        enum Foo : Int, LosslessStringConvertible, Decodable
        {
            var description: String { String(self.rawValue) }
            
            case bar = 1
            
            init?(_ description: String) {
                guard let int = Int(description), int == 1 else { return nil }
                self = .bar
            }
        }
        
        let testData = "2"
        let encodedData = try jsonEncoder.encode(EncodedData(field: testData))
        
        let error = try #require(throws: DecodingError.self) {
            _ = try jsonDecoder.decode(DecodedData<Foo>.self, from: encodedData).field
        }
        guard case .typeMismatch(let type, let context) = error else
        {
            
            Issue.record("Expected `.typeMismatch` error, received \(error) instead")
            return
        }
        #expect(type is Foo.Type)
        let codingPath = try #require(context.codingPath as? [DecodedData<Foo>.CodingKeys])
        #expect(codingPath == [DecodedData<Foo>.CodingKeys.field])
        #expect(context.debugDescription == "Cannot convert string to type Foo")
    }
    
    @Test("Failed: String -> RawRepresentable<String>")
    func failedStringToRawRepresentable() throws
    {
        struct Foo : RawRepresentable, Codable
        {
            typealias RawValue = String
            var bar : Int
            
            var rawValue : String { String(bar) }
            
            enum CodingKeys : String, CodingKey
            {
                case bar
            }
            
            init(from decoder: any Decoder) throws
            {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                bar = try container.decode(Int.self, forKey: .bar)
            }
            
            func encode(to encoder: any Encoder) throws
            {
                var container = encoder.container(keyedBy: CodingKeys.self)
                let barAsString = String(bar)
                try container.encode(barAsString, forKey: .bar)
            }
            
            init?(rawValue: String)
            {
                guard let int = Int(rawValue), int == 1 else { return nil }
                bar = int
            }
        }
        
        let testData = "2"
        let encodedData = try jsonEncoder.encode(EncodedData(field: testData))
        
        let error = try #require(throws: DecodingError.self) {
            _ = try jsonDecoder.decode(DecodedData<Foo>.self, from: encodedData).field
        }
        guard case .typeMismatch(let type, let context) = error else
        {
            
            Issue.record("Expected `.typeMismatch` error, received \(error) instead")
            return
        }
        #expect(type is Foo.Type)
        let codingPath = try #require(context.codingPath as? [DecodedData<Foo>.CodingKeys])
        #expect(codingPath == [DecodedData<Foo>.CodingKeys.field])
        #expect(context.debugDescription == "Cannot convert string to type Foo")
    }
    
    @Test("Failed: String -> Some unknown type")
    func failedStringToUnknownType() throws
    {
        struct Foo : Codable
        {
            typealias RawValue = String
            var bar : Int
            
            enum CodingKeys : String, CodingKey
            {
                case bar
            }
            
            init(from decoder: any Decoder) throws
            {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                bar = try container.decode(Int.self, forKey: .bar)
            }
            
            func encode(to encoder: any Encoder) throws
            {
                var container = encoder.container(keyedBy: CodingKeys.self)
                let barAsString = String(bar)
                try container.encode(barAsString, forKey: .bar)
            }
        }
        
        let testData = "foo"
        let encodedData = try jsonEncoder.encode(EncodedData(field: testData))
        
        let error = try #require(throws: DecodingError.self) {
            _ = try jsonDecoder.decode(DecodedData<Foo>.self, from: encodedData).field
        }
        guard case .typeMismatch(let type, let context) = error else
        {
            
            Issue.record("Expected `.typeMismatch` error, received \(error) instead")
            return
        }
        #expect(type is Foo.Type)
        let codingPath = try #require(context.codingPath as? [DecodedData<Foo>.CodingKeys])
        #expect(codingPath == [DecodedData<Foo>.CodingKeys.field])
        #expect(context.debugDescription == "Cannot convert string to type Foo")
    }
}
