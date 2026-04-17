//
//  ModelBoxTests.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/5/26.
//

@testable import VaporAdmin
import Foundation
import XCTFluent
import Testing
import Fluent
import Vapor

@Suite("ModelBox.swift Tests")
struct ModelBoxTests
{
    @Test("instances")
    func instances() async throws
    {
        let database = CallbackTestDatabase { _ in
            return [
                TestOutput(TestModel(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test1", bar: 1, modelEnum: .one)),
                TestOutput(TestModel(id: UUID(uuid: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1)), name: "test2", bar: 1))
            ]
        }
        
        let modelBox = _ModelBox<TestModel>(database: database.db)
        let output = try await modelBox.instances()
        #expect(output.count == 2)
        #expect(output[0].id == "00010203-0405-0607-0809-0A0B0C0D0E0F")
        #expect(output[0].description == output[0].id)
    }
    
    @Test("instances CustomAdminDisplayable")
    func instancesCustomAdminDisplayable() async throws
    {
        let database = CallbackTestDatabase { _ in
            return [
                TestOutput(TestModelCustomAdminDisplayable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test1", bar: 1)),
                TestOutput(TestModelCustomAdminDisplayable(id: UUID(uuid: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1)), name: "test2", bar: 1))
            ]
        }
        
        let modelBox = _ModelBox<TestModelCustomAdminDisplayable>(database: database.db)
        let output = try await modelBox.instances()
        #expect(output.count == 2)
        #expect(output[0].id == "00010203-0405-0607-0809-0A0B0C0D0E0F")
        #expect(output[0].description == "test1")
    }
    
    @Test("instanceProperties(parameters:) with well-formed params and valid entry")
    func instancePropertiesParameters() async throws
    {
        let database = CallbackTestDatabase { _ in
            return [
                TestOutput(TestModelCustomAdminDisplayable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test1", bar: 1))
            ]
        }
        
        var parameters = Parameters()
        parameters.set("entry", to: "00010203-0405-0607-0809-0A0B0C0D0E0F")
        let modelBox = _ModelBox<TestModelCustomAdminDisplayable>(database: database.db)
        let output = try await modelBox.instanceProperties(parameters: parameters)
        
        #expect(output.id == "00010203-0405-0607-0809-0A0B0C0D0E0F")
        #expect(output.description == "test1")
        #expect(output.properties == [
            .init(key: "name", value: "test1", fieldType: .text, optional: false, isMultiSelect: false),
            .init(key: "bar_blah", value: "1", fieldType: .number, optional: false, isMultiSelect: false)
        ])
    }
    
    @Test("instanceProperties(parameters:) with missing entry param")
    func instancePropertiesParametersMissingEntry() async throws
    {
        let database = CallbackTestDatabase { _ in
            return [
                TestOutput(TestModelCustomAdminDisplayable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test1", bar: 1))
            ]
        }
        
        let parameters = Parameters()
        let modelBox = _ModelBox<TestModelCustomAdminDisplayable>(database: database.db)
        let error = try await #require(throws: Abort.self, performing: { try await modelBox.instanceProperties(parameters: parameters) })
        
        #expect(error.status == .internalServerError)
        #expect(error.reason == "The parameter provided does not exist")
    }
    
    @Test("instanceProperties(parameters:) with well-formed params and missing instance")
    func instancePropertiesParametersNoInstance() async throws
    {
        let database = CallbackTestDatabase { _ in
            return []
        }
        
        var parameters = Parameters()
        parameters.set("entry", to: "00010203-0405-0607-0809-0A0B0C0D0E0F")
        let modelBox = _ModelBox<TestModelCustomAdminDisplayable>(database: database.db)
        let error = try await #require(throws: AdminError.self, performing: { try await modelBox.instanceProperties(parameters: parameters) })
        
        #expect(error == .couldNotFindInstance)
    }
    
    @Test("attemptUpdate(for:data:) with well-formed params and valid instance")
    func attemptUpdate() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action {
            case .update:
                for input in query.input
                {
                    switch input {
                    case .dictionary(let dictionary):
                        guard let value = dictionary["name"] else { continue }
                        switch value
                        {
                        case .bind(let string):
                            #expect(string as? String == "test2")
                            return []
                            
                        default: continue
                        }
                    default: continue
                    }
                }
                Issue.record("Reached the end of updates without matching expected input: \(query.input)")
                break
            case .read:
                return [
                    TestOutput(TestModelCustomAdminDisplayable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test1", bar: 1))
                ]
            
            default: Issue.record("Expected .update, received query \(query)")
            }
            return []
        }
        
        var parameters = Parameters()
        parameters.set("entry", to: "00010203-0405-0607-0809-0A0B0C0D0E0F")
        let modelBox = _ModelBox<TestModelCustomAdminDisplayable>(database: database.db)
        
        let updates = ["name": "test2"]
        var container = TestContentContainer(body: .init(), headers: .init())
        try container.encode(updates, using: JSONEncoder())
        
        try await modelBox.attemptUpdate(for: parameters, data: container)
    }
    
    @Test("attemptUpdate(for:data:) with missing entry param")
    func attemptUpdateMissingEntryParam() async throws
    {
        let database = CallbackTestDatabase { query in
            Issue.record("Expected nothing, received query \(query)")
            return []
        }
        
        let parameters = Parameters()
        let modelBox = _ModelBox<TestModelCustomAdminDisplayable>(database: database.db)
        
        let updates = ["name": "test2"]
        var container = TestContentContainer(body: .init(), headers: .init())
        try container.encode(updates, using: JSONEncoder())
        
        let error = try await #require(throws: Abort.self) { try await modelBox.attemptUpdate(for: parameters, data: container) }
        
        #expect(error.status == .internalServerError)
        #expect(error.reason == "The parameter provided does not exist")
    }
    
    @Test("attemptUpdate(for:data:) with well-formed params and missing instance")
    func attemptUpdateMissingInstance() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action {
            case .update:
                Issue.record("Expected no update, received query \(query)")
                break
            case .read:
                return []
            
            default: Issue.record("Expected .read, received query \(query)")
            }
            return []
        }
        
        var parameters = Parameters()
        parameters.set("entry", to: "00010203-0405-0607-0809-0A0B0C0D0E0F")
        let modelBox = _ModelBox<TestModelCustomAdminDisplayable>(database: database.db)
        
        let updates = ["name": "test2"]
        var container = TestContentContainer(body: .init(), headers: .init())
        try container.encode(updates, using: JSONEncoder())
        
        let error = try await #require(throws: AdminError.self) { try await modelBox.attemptUpdate(for: parameters, data: container) }
        
        #expect(error == .couldNotFindInstance)
    }
    
    @Test("newModelInfo")
    func newModelInfo() async throws
    {
        let database = CallbackTestDatabase { _ in return [] }
        let modelBox = _ModelBox<TestModelCustomAdminDisplayable>(database: database.db)
        let output = try await modelBox.newModelInfo()
        
        #expect(output.count == 2)
    }
    
    @Test("attemptCreate with well-formed params and valid instance")
    func attemptCreate() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action {
            case .create:
                for input in query.input
                {
                    switch input
                    {
                    case .dictionary(let dictionary):
                        #expect(dictionary["name"]?.bind() == "test2")
                        #expect(dictionary["bar_blah"]?.bind() == 2)
                        return []
                        
                    default: continue
                    }
                }
                Issue.record("Expected .create with dictionary, received query \(query)")
                return []
                
            default: Issue.record("Expected .create, received query \(query)")
            }
            return []
        }
        
        let modelBox = _ModelBox<TestModelCustomAdminDisplayable>(database: database.db)
        
        var buffer = ByteBuffer()
        let encoder = FormDataEncoder()
        try encoder.encode(["name": "test2", "bar_blah": "2"], boundary: "---Test", into: &buffer)
        let container = TestContentContainer(body: buffer, headers: ["Content-Type": "multipart/form-data; boundary=---Test"])
        try await modelBox.attemptCreate(data: container)
    }
    
    @Test("attemptCreate with missing data")
    func attemptCreateMissingData() async throws
    {
        let database = CallbackTestDatabase { query in
            Issue.record("Expected nothing, received query \(query)")
            return []
        }
        
        let modelBox = _ModelBox<TestModelCustomAdminDisplayable>(database: database.db)
        
        let buffer = ByteBuffer()
        let container = TestContentContainer(body: buffer, headers: ["Content-Type": "multipart/form-data; boundary=---Test"])
        let error = try await #require(throws: AdminError.self) { try await modelBox.attemptCreate(data: container) }
        #expect(error == .invalidInput)
    }
    
    @Test("attemptDelete with well-formed params and valid instance")
    func attemptDelete() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action {
            case .delete:
                break
                
            case .read:
                return [TestOutput(TestModel(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test1", bar: 1, modelEnum: .one))]
            
            default: Issue.record("Expected .read and .delete, received query \(query)")
            }
            return []
        }
        
        let modelBox = _ModelBox<TestModel>(database: database.db)
        
        var parameters = Parameters()
        parameters.set("entry", to: "00010203-0405-0607-0809-0A0B0C0D0E0F")
        try await modelBox.attemptDelete(parameters: parameters)
    }
    
    @Test("attemptDelete with missing entry param")
    func attemptDeleteMissingEntryParam() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action {
            case .delete:
                break
                
            case .read:
                return [TestOutput(TestModel(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test1", bar: 1, modelEnum: .one))]
            
            default: Issue.record("Expected .read and .delete, received query \(query)")
            }
            return []
        }
        
        let modelBox = _ModelBox<TestModel>(database: database.db)
        
        let parameters = Parameters()
        let error = try await #require(throws: Abort.self) { try await modelBox.attemptDelete(parameters: parameters) }
        
        #expect(error.status == .internalServerError)
        #expect(error.reason == "The parameter provided does not exist")
    }
    
    @Test("attemptDelete with well-formed params and missing instance")
    func attemptDeleteMissingInstance() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action {
            case .read:
                return []
            
            default: Issue.record("Expected .read, received query \(query)")
            }
            return []
        }
        
        let modelBox = _ModelBox<TestModel>(database: database.db)
        
        var parameters = Parameters()
        parameters.set("entry", to: "00010203-0405-0607-0809-0A0B0C0D0E0F")
        let error = try await #require(throws: AdminError.self) { try await modelBox.attemptDelete(parameters: parameters) }
        #expect(error == .couldNotFindInstance)
    }
}
