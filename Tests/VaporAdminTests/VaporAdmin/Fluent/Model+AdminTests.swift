//
//  Model+AdminTests.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/3/26.
//

@testable import VaporAdmin
import Foundation
import XCTFluent
import Testing
import Fluent

@Suite("Model+Admin.swift Tests")
struct ModelAdminTests
{
    @Test("idField")
    func idField() throws
    {
        #expect(TestModel.idField == \.$id)
    }
    
    @Test("idDescription")
    func idDescription() throws
    {
        let model = TestModel(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test", bar: 1)
        #expect(model.idDescription == "00010203-0405-0607-0809-0A0B0C0D0E0F")
    }
    
    @Test("adminDescription")
    func adminDescription() throws
    {
        let model = TestModel(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test", bar: 1)
        #expect(model.adminDescription == "00010203-0405-0607-0809-0A0B0C0D0E0F")
    }
    
    @Test("adminDescriptionCustomAdminDisplayable")
    func adminDescriptionCustomAdminDisplayable() throws
    {
        let model = TestModelCustomAdminDisplayable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test", bar: 1)
        #expect(model.adminDescription == "test")
    }
    
    @Test("instance(for:on:)")
    func instanceForOn() async throws
    {
        let uuid = UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15))
        let testDatabase = CallbackTestDatabase { query in
            return [TestOutput(TestModel(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test", bar: 1))]
        }
        
        _ = try await TestModel.instance(for: uuid, on: testDatabase.db)
    }
    
    @Test("Failed: instance(for:on:)")
    func instanceForOnFailsToFindInstance() async throws
    {
        let uuid = UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15))
        let testDatabase = CallbackTestDatabase { query in
            return []
        }
        
        await #expect(throws: AdminError.couldNotFindInstance, performing: { try await TestModel.instance(for: uuid, on: testDatabase.db) })
    }
    
    @Test("adminFieldRepresentations(database:) no relationships and enum is not case iterable")
    func adminFieldRepresentationsNoRelationshipsEnumNotCaseIterable() async throws
    {
        let expected = [
            ModelInstancePropertyRepresentation(key: "name", value: "test", fieldType: .text),
            ModelInstancePropertyRepresentation(key: "bar", value: "1", fieldType: .number),
            ModelInstancePropertyRepresentation(key: "enum", value: "one", fieldType: .text)
        ]
        let model = TestModel(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test", bar: 1)
        let actual = try await model.adminFieldRepresentations(database: ArrayTestDatabase().db)
        #expect(actual == expected)
    }
    
    @Test("adminFieldRepresentations(database:) no relationships and enum is case iterable")
    func adminFieldRepresentationsNoRelationshipsEnumIsCaseIterable() async throws
    {
        let expected = [
            ModelInstancePropertyRepresentation(key: "name", value: "test", fieldType: .text),
            ModelInstancePropertyRepresentation(key: "bar", value: "1", fieldType: .number),
            ModelInstancePropertyRepresentation(key: "enum", value: "one", fieldType: .array(possibleValues: ["one", "two"]))
        ]
        let model = TestModelCaseIterable(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test", bar: 1)
        let actual = try await model.adminFieldRepresentations(database: ArrayTestDatabase().db)
        #expect(actual == expected)
    }
    
    @Test("adminFieldRepresentations(database:) with optional parent relationship")
    func adminFieldRepresentationsWithOptionalParentRelationship() async throws
    {
        let expected = [
            ModelInstancePropertyRepresentation(key: "name", value: "test", fieldType: .text),
            ModelInstancePropertyRepresentation(key: "bar", value: "1", fieldType: .number),
            ModelInstancePropertyRepresentation(key: "enum", value: "one", fieldType: .text),
            ModelInstancePropertyRepresentation(key: "parent_id", value: "", fieldType: .relationship(optional: true, possibleValues: [.init(displayName: "test parent", id: "01020304-0506-0708-090A-0B0C0D0E0F04")]))
        ]
        let model = TestModelOptionalParentRelationshipChild(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test", bar: 1)
        
        let testDatabase = CallbackTestDatabase { _ in
            return [TestOutput(TestModelOptionalParentRelationshipChildParent(id: UUID(uuid: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 4)), name: "test parent"))]
        }
        let actual = try await model.adminFieldRepresentations(database: testDatabase.db)
        #expect(actual == expected)
    }
    
    @Test("updateFields(from:database:) simple set")
    func updateFieldsChangeSimpleField() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action
            {
            case .update:
                break
                
            case .read:
                return [TestOutput(TestModelOptionalParentRelationshipChild(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test", bar: 1))]
                        
            default: Issue.record("Expected .update, received query \(query)")
            }
            return []
        }
        
        let model = try await database.db.query(TestModelOptionalParentRelationshipChild.self).first()!
        try await model.updateFields(from: ["name": "test2", "bar": "2"], database: database.db)
        
        #expect(model.name == "test2")
        #expect(model.bar == 2)
    }
    
    @Test("updateFields(from:database:) relationship set")
    func updateFieldsChangeRelationshipSet() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action
            {
            case .update:
                break
                
            case .read:
                return [TestOutput(TestModelOptionalParentRelationshipChild(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test", bar: 1))]
                        
            default: Issue.record("Expected .update, received query \(query)")
            }
            return []
        }
        
        let model = try await database.db.query(TestModelOptionalParentRelationshipChild.self).first()!
        try await model.updateFields(from: ["parent_id": "01020304-0506-0708-090A-0B0C0D0E0F04"], database: database.db)
        
        #expect(model.$parent.id?.description == "01020304-0506-0708-090A-0B0C0D0E0F04")
    }
    
    @Test("updateFields(from:database:) relationship nil out")
    func updateFieldsChangeRelationshipNilOut() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action
            {
            case .update:
                break
                
            case .read:
                return [TestOutput(TestModelOptionalParentRelationshipChild(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "test", bar: 1))]
                        
            default: Issue.record("Expected .update, received query \(query)")
            }
            return []
        }
        
        let model = try await database.db.query(TestModelOptionalParentRelationshipChild.self).first()!
        
        // Set a relationship first, we'll immediately nil it out after
        try await model.updateFields(from: ["parent_id": "01020304-0506-0708-090A-0B0C0D0E0F04"], database: database.db)
        
        #expect(model.$parent.id?.description == "01020304-0506-0708-090A-0B0C0D0E0F04")
        
        try await model.updateFields(from: ["parent_id": ""], database: database.db)
        #expect(model.$parent.id == nil)
        #expect(model.parent == nil)
    }
    
    @Test("updateFields(from:database:) create if new")
    func updateFieldsCreateIfNew() async throws
    {
        let database = CallbackTestDatabase { query in
            switch query.action
            {
            case .create:
                break
                        
            default: Issue.record("Expected .update, received query \(query)")
            }
            return []
        }
        
        let model = TestModelOptionalParentRelationshipChild(id: nil, name: "test", bar: 1)
        
        // Set a relationship first, we'll immediately nil it out after
        try await model.updateFields(from: ["parent_id": "01020304-0506-0708-090A-0B0C0D0E0F04"], database: database.db)
        
        #expect(model.id != nil)
    }
}
