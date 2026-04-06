//
//  ModelCoordinatorTests.swift
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

@Suite("ModelCoordinator.swift Tests")
struct ModelCoordinatorTests
{
    @Test("register")
    func register() throws
    {
        let database = CallbackTestDatabase { _ in
            Issue.record("Unexpected call to database")
            return []
        }
        class TestBox : ModelBox
        {
            func instances() async throws -> [VaporAdmin.ModelInstanceRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func instanceProperties(parameters: RoutingKit.Parameters) async throws -> VaporAdmin.ModelInstancePropertiesRepresentation
            {
                Issue.record("Unexpected call to \(#function)")
                return .init(id: "", description: "", properties: [])
            }
            
            func attemptUpdate(for parameters: RoutingKit.Parameters, data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func newModelInfo() async throws -> [VaporAdmin.ModelInstancePropertyRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func attemptCreate(data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func attemptDelete(parameters: RoutingKit.Parameters) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
        }
        
        let coordinator = ModelCoordinator(database: database.db, boxInitializer: { _ in TestBox() })
        coordinator.register(TestModel.self)
        #expect(coordinator.models["TestModel"] != nil)
    }
    
    @Test("register cannot register same model twice")
    func registerCannotRegisterSameModelTwice() async throws
    {
        await #expect(processExitsWith: .failure) {
            let database = CallbackTestDatabase { _ in
                Issue.record("Unexpected call to database")
                return []
            }
            class TestBox : ModelBox
            {
                func instances() async throws -> [VaporAdmin.ModelInstanceRepresentation]
                {
                    Issue.record("Unexpected call to \(#function)")
                    return []
                }
                
                func instanceProperties(parameters: RoutingKit.Parameters) async throws -> VaporAdmin.ModelInstancePropertiesRepresentation
                {
                    Issue.record("Unexpected call to \(#function)")
                    return .init(id: "", description: "", properties: [])
                }
                
                func attemptUpdate(for parameters: RoutingKit.Parameters, data: any Vapor.ContentContainer) async throws
                {
                    Issue.record("Unexpected call to \(#function)")
                }
                
                func newModelInfo() async throws -> [VaporAdmin.ModelInstancePropertyRepresentation]
                {
                    Issue.record("Unexpected call to \(#function)")
                    return []
                }
                
                func attemptCreate(data: any Vapor.ContentContainer) async throws
                {
                    Issue.record("Unexpected call to \(#function)")
                }
                
                func attemptDelete(parameters: RoutingKit.Parameters) async throws
                {
                    Issue.record("Unexpected call to \(#function)")
                }
            }
            
            let coordinator = ModelCoordinator(database: database.db, boxInitializer: { _ in TestBox() })
            coordinator.register(TestModel.self)
            coordinator.register(TestModel.self)
        }
    }
    
    @Test("listModels")
    func listModels()
    {
        let database = CallbackTestDatabase { _ in
            Issue.record("Unexpected call to database")
            return []
        }
        class TestBox : ModelBox
        {
            func instances() async throws -> [VaporAdmin.ModelInstanceRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func instanceProperties(parameters: RoutingKit.Parameters) async throws -> VaporAdmin.ModelInstancePropertiesRepresentation
            {
                Issue.record("Unexpected call to \(#function)")
                return .init(id: "", description: "", properties: [])
            }
            
            func attemptUpdate(for parameters: RoutingKit.Parameters, data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func newModelInfo() async throws -> [VaporAdmin.ModelInstancePropertyRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func attemptCreate(data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func attemptDelete(parameters: RoutingKit.Parameters) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
        }
        
        let coordinator = ModelCoordinator(database: database.db, boxInitializer: { _ in TestBox() })
        coordinator.register(TestModel.self)
        #expect(coordinator.listModels() == ["TestModel"])
    }
    
    @Test("listEntries")
    func listEntries() async throws
    {
        let database = CallbackTestDatabase { _ in
            Issue.record("Unexpected call to database")
            return []
        }
        class TestBox : ModelBox
        {
            func instances() async throws -> [VaporAdmin.ModelInstanceRepresentation]
            {
                [.init(id: "blah", description: "blah")]
            }
            
            func instanceProperties(parameters: RoutingKit.Parameters) async throws -> VaporAdmin.ModelInstancePropertiesRepresentation
            {
                Issue.record("Unexpected call to \(#function)")
                return .init(id: "", description: "", properties: [])
            }
            
            func attemptUpdate(for parameters: RoutingKit.Parameters, data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func newModelInfo() async throws -> [VaporAdmin.ModelInstancePropertyRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func attemptCreate(data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func attemptDelete(parameters: RoutingKit.Parameters) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
        }
        
        let coordinator = ModelCoordinator(database: database.db, boxInitializer: { _ in TestBox() })
        coordinator.register(TestModel.self)
        try await #expect(coordinator.listEntries(for: "TestModel") == [.init(id: "blah", description: "blah")])
    }
    
    @Test("details")
    func details() async throws
    {
        let database = CallbackTestDatabase { _ in
            Issue.record("Unexpected call to database")
            return []
        }
        class TestBox : ModelBox
        {
            func instances() async throws -> [VaporAdmin.ModelInstanceRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func instanceProperties(parameters: RoutingKit.Parameters) async throws -> VaporAdmin.ModelInstancePropertiesRepresentation
            {
                return .init(id: "", description: "", properties: [])
            }
            
            func attemptUpdate(for parameters: RoutingKit.Parameters, data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func newModelInfo() async throws -> [VaporAdmin.ModelInstancePropertyRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func attemptCreate(data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func attemptDelete(parameters: RoutingKit.Parameters) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
        }
        
        let coordinator = ModelCoordinator(database: database.db, boxInitializer: { _ in TestBox() })
        coordinator.register(TestModel.self)
        try await #expect(coordinator.details(for: .init(), model: "TestModel") == .init(id: "", description: "", properties: []))
    }
    
    @Test("attemptUpdate")
    func attemptUpdate() async throws
    {
        let database = CallbackTestDatabase { _ in
            Issue.record("Unexpected call to database")
            return []
        }
        class TestBox : ModelBox
        {
            func instances() async throws -> [VaporAdmin.ModelInstanceRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func instanceProperties(parameters: RoutingKit.Parameters) async throws -> VaporAdmin.ModelInstancePropertiesRepresentation
            {
                Issue.record("Unexpected call to \(#function)")
                return .init(id: "", description: "", properties: [])
            }
            
            func attemptUpdate(for parameters: RoutingKit.Parameters, data: any Vapor.ContentContainer) async throws
            {
                
            }
            
            func newModelInfo() async throws -> [VaporAdmin.ModelInstancePropertyRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func attemptCreate(data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func attemptDelete(parameters: RoutingKit.Parameters) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
        }
        
        let coordinator = ModelCoordinator(database: database.db, boxInitializer: { _ in TestBox() })
        coordinator.register(TestModel.self)
        try await coordinator.attemptUpdate(for: .init(), model: "TestModel", data: TestContentContainer(body: .init(), headers: .init()))
    }
    
    @Test("newModelInfo")
    func newModelInfo() async throws
    {
        let database = CallbackTestDatabase { _ in
            Issue.record("Unexpected call to database")
            return []
        }
        class TestBox : ModelBox
        {
            func instances() async throws -> [VaporAdmin.ModelInstanceRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func instanceProperties(parameters: RoutingKit.Parameters) async throws -> VaporAdmin.ModelInstancePropertiesRepresentation
            {
                Issue.record("Unexpected call to \(#function)")
                return .init(id: "", description: "", properties: [])
            }
            
            func attemptUpdate(for parameters: RoutingKit.Parameters, data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func newModelInfo() async throws -> [VaporAdmin.ModelInstancePropertyRepresentation]
            {
                return [.init(key: "test", value: "test2", fieldType: .text)]
            }
            
            func attemptCreate(data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func attemptDelete(parameters: RoutingKit.Parameters) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
        }
        
        let coordinator = ModelCoordinator(database: database.db, boxInitializer: { _ in TestBox() })
        coordinator.register(TestModel.self)
        try await #expect(coordinator.newModelInfo(for: "TestModel") == [.init(key: "test", value: "test2", fieldType: .text)])
    }
    
    @Test("attemptCreate")
    func attemptCreate() async throws
    {
        let database = CallbackTestDatabase { _ in
            Issue.record("Unexpected call to database")
            return []
        }
        class TestBox : ModelBox
        {
            func instances() async throws -> [VaporAdmin.ModelInstanceRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func instanceProperties(parameters: RoutingKit.Parameters) async throws -> VaporAdmin.ModelInstancePropertiesRepresentation
            {
                Issue.record("Unexpected call to \(#function)")
                return .init(id: "", description: "", properties: [])
            }
            
            func attemptUpdate(for parameters: RoutingKit.Parameters, data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func newModelInfo() async throws -> [VaporAdmin.ModelInstancePropertyRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func attemptCreate(data: any Vapor.ContentContainer) async throws
            {
                
            }
            
            func attemptDelete(parameters: RoutingKit.Parameters) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
        }
        
        let coordinator = ModelCoordinator(database: database.db, boxInitializer: { _ in TestBox() })
        coordinator.register(TestModel.self)
        try await coordinator.attemptCreate(for: "TestModel", data: TestContentContainer(body: .init(), headers: .init()))
    }
    
    @Test("attemptDelete")
    func attemptDelete() async throws
    {
        let database = CallbackTestDatabase { _ in
            Issue.record("Unexpected call to database")
            return []
        }
        class TestBox : ModelBox
        {
            func instances() async throws -> [VaporAdmin.ModelInstanceRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func instanceProperties(parameters: RoutingKit.Parameters) async throws -> VaporAdmin.ModelInstancePropertiesRepresentation
            {
                Issue.record("Unexpected call to \(#function)")
                return .init(id: "", description: "", properties: [])
            }
            
            func attemptUpdate(for parameters: RoutingKit.Parameters, data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func newModelInfo() async throws -> [VaporAdmin.ModelInstancePropertyRepresentation]
            {
                Issue.record("Unexpected call to \(#function)")
                return []
            }
            
            func attemptCreate(data: any Vapor.ContentContainer) async throws
            {
                Issue.record("Unexpected call to \(#function)")
            }
            
            func attemptDelete(parameters: RoutingKit.Parameters) async throws
            {
                
            }
        }
        
        let coordinator = ModelCoordinator(database: database.db, boxInitializer: { _ in TestBox() })
        coordinator.register(TestModel.self)
        try await coordinator.attemptDelete(for: "TestModel", parameters: .init())
    }
}
