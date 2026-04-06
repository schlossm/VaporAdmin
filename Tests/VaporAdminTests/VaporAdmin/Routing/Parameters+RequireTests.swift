//
//  Parameters+RequireTests.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/5/26.
//

@testable import VaporAdmin
import Testing
import Vapor

@Suite("Parameters+Require.swift")
struct ParametersRequireTests
{
    @Test("require(_:as:) fails on missing param")
    func requireFailsOnMissingParam() throws
    {
        func testDecode<IDValue : Codable & Sendable>(_ type: IDValue.Type, from parameters: Parameters) throws
        {
            let error = try #require(throws: Abort.self) {
                try parameters.require("test", as: IDValue.self)
            }
            #expect(error.status == .internalServerError)
            #expect(error.reason == "The parameter provided does not exist")
        }
        
        try testDecode(String.self, from: .init())
    }
    
    @Test("require(_:as:) LosslessStringConvertible")
    func requireLosslessStringConvertible() throws
    {
        func testDecode<IDValue : Codable & Sendable>(_ type: IDValue.Type, from parameters: Parameters) throws
        {
            try #expect(parameters.require("test", as: IDValue.self) as? String == "test_param")
        }
        
        var parameters = Parameters()
        parameters.set("test", to: "test_param")
        try testDecode(String.self, from: parameters)
    }
    
    @Test("require(_:as:) LosslessStringConvertible cannot represent input")
    func requireLosslessStringConvertibleCannotRepresentInput() throws
    {
        func testDecode<IDValue : Codable & Sendable>(_ type: IDValue.Type, from parameters: Parameters) throws
        {
            let error = try #require(throws: Abort.self) {
                try parameters.require("test", as: IDValue.self)
            }
            #expect(error.status == .unprocessableEntity)
            #expect(error.reason == "The parameter value could not be converted to the required type")
        }
        
        var parameters = Parameters()
        parameters.set("test", to: "test_param")
        try testDecode(UUID.self, from: parameters)
    }
    
    @Test("require(_:as:) RawRepresentable")
    func requireAsRawRepresentable() throws
    {
        enum TestEnum : String
        {
            case foo = "test_param"
            case bar
        }
        var parameters = Parameters()
        parameters.set("test", to: "test_param")
        
        try #expect(parameters.require("test", as: TestEnum.self) == .foo)
    }
    
    @Test("require(_:as:) RawRepresentable cannot represent input")
    func requireAsRawRepresentableCannotRepresentInput() throws
    {
        enum TestEnum : String
        {
            case foo = "test_param"
            case bar
        }
        var parameters = Parameters()
        parameters.set("test", to: "test")
        
        let error = try #require(throws: Abort.self) {
            try parameters.require("test", as: TestEnum.self)
        }
        #expect(error.status == .unprocessableEntity)
        #expect(error.reason == "The parameter value could not be converted to the required type")
    }
    
    @Test("require(_:as:) unrepresentable type")
    func requireUnrepresentableType() throws
    {
        enum TestEnum
        {
            case foo
            case bar
        }
        var parameters = Parameters()
        parameters.set("test", to: "test_param")
        
        let error = try #require(throws: Abort.self) {
            try parameters.require("test", as: TestEnum.self)
        }
        #expect(error.status == .unprocessableEntity)
        #expect(error.reason == "The parameter value could not be converted from a string.  Ensure your type conforms to `LosslessStringConvertible` or `RawRepresentable<String>`")
    }
}
