//
//  PropertyMetadataTests.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/13/26.
//

@testable import VaporAdmin
import Foundation
import XCTFluent
import Testing
import Fluent

@Suite("PropertyMetadata.swift Tests")
struct PropertyMetadataTests
{
    // MARK: - OptionalParentRelationshipProperty
    
    // MARK: process(update:on:keypath:)
    
    @Test("OptionalParentRelationshipProperty.process() - Non-nil")
    func optionalParentPropertyProcessNonNil() async throws
    {
        let model = TestModelOptionalParentRelationshipChild()
        let optionalParentPropertyMetadata = try #require( TestModelOptionalParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? OptionalParentRelationshipProperty<TestModelOptionalParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        
        try metadata.process(update: "00010203-0405-0607-0809-0A0B0C0D0E0F", on: model, keypath: optionalParentPropertyMetadata.fluentKeypath)
        #expect(model.$parent.id == UUID("00010203-0405-0607-0809-0A0B0C0D0E0F"))
    }
    
    @Test("OptionalParentRelationshipProperty.process() - nil")
    func optionalParentPropertyProcessNil() async throws
    {
        let model = TestModelOptionalParentRelationshipChild()
        model.$parent.id = UUID("00010203-0405-0607-0809-0A0B0C0D0E0F")
        let optionalParentPropertyMetadata = try #require( TestModelOptionalParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? OptionalParentRelationshipProperty<TestModelOptionalParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        
        try metadata.process(update: "", on: model, keypath: optionalParentPropertyMetadata.fluentKeypath)
        #expect(model.$parent.id == nil)
    }
    
    @Test("OptionalParentRelationshipProperty.process() - Invalid value")
    func optionalParentPropertyProcessInvalidValue() async throws
    {
        let model = TestModelOptionalParentRelationshipChild()
        let optionalParentPropertyMetadata = try #require( TestModelOptionalParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? OptionalParentRelationshipProperty<TestModelOptionalParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        
        #expect(throws: DecodingError.self) { try metadata.process(update: "139423940", on: model, keypath: optionalParentPropertyMetadata.fluentKeypath) }
        #expect(model.$parent.id == nil)
    }
    
    @Test("OptionalParentRelationshipProperty.process() - Crashes on invalid keypath")
    func optionalParentPropertyProcessCrashInvalidKeypath() async throws
    {
        await #expect(processExitsWith: .failure)
        {
            let model = TestModelOptionalParentRelationshipChild()
            let optionalParentPropertyMetadata = try #require( TestModelOptionalParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
            let metadata = try #require(optionalParentPropertyMetadata.metadata as? OptionalParentRelationshipProperty<TestModelOptionalParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
            
            try metadata.process(update: "00010203-0405-0607-0809-0A0B0C0D0E0F", on: model, keypath: \String.self)
            #expect(model.$parent.id == UUID("00010203-0405-0607-0809-0A0B0C0D0E0F"))
        }
    }
    
    // MARK: getCurrentRelationships(on:keypath:)
    
    @Test("OptionalParentRelationshipProperty.getCurrentRelationships() - Non-empty")
    func optionalParentPropertyGetCurrentRelationshipsNonEmpty() async throws
    {
        let model = TestModelOptionalParentRelationshipChild()
        model.$parent.id = UUID("00010203-0405-0607-0809-0A0B0C0D0E0F")
        let optionalParentPropertyMetadata = try #require( TestModelOptionalParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? OptionalParentRelationshipProperty<TestModelOptionalParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        let values = metadata.getCurrentRelationships(on: model, keypath: optionalParentPropertyMetadata.fluentKeypath)
        #expect(values == [UUID("00010203-0405-0607-0809-0A0B0C0D0E0F")!])
    }
    
    @Test("OptionalParentRelationshipProperty.getCurrentRelationships() - Empty")
    func optionalParentPropertyGetCurrentRelationshipsEmpty() async throws
    {
        let model = TestModelOptionalParentRelationshipChild()
        let optionalParentPropertyMetadata = try #require( TestModelOptionalParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? OptionalParentRelationshipProperty<TestModelOptionalParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        let values = metadata.getCurrentRelationships(on: model, keypath: optionalParentPropertyMetadata.fluentKeypath)
        #expect(values == [])
    }
    
    @Test("OptionalParentRelationshipProperty.getCurrentRelationships() - Crashes on invalid keypath")
    func optionalParentPropertyGetCurrentRelationshipsCrashInvalidKeypath() async throws
    {
        await #expect(processExitsWith: .failure)
        {
            let model = TestModelOptionalParentRelationshipChild()
            model.$parent.id = UUID("00010203-0405-0607-0809-0A0B0C0D0E0F")
            let optionalParentPropertyMetadata = try #require( TestModelOptionalParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
            let metadata = try #require(optionalParentPropertyMetadata.metadata as? OptionalParentRelationshipProperty<TestModelOptionalParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
            _ = metadata.getCurrentRelationships(on: model, keypath: \String.self)
        }
    }
    
    // MARK: getPossibleRelationshipValues()
    
    @Test("OptionalParentRelationshipProperty.getPossibleRelationshipValues()")
    func optionalParentPropertyGetPossibleRelationshipValues() async throws
    {
        let database = CallbackTestDatabase { query in
            guard case .read = query.action else
            {
                Issue.record("Unexpected query: \(query)")
                return []
            }
            return [
                TestOutput(TestModelOptionalParentRelationshipChildParent(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "foo")),
                TestOutput(TestModelOptionalParentRelationshipChildParent(id: UUID(uuid: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0)), name: "bar")),
                TestOutput(TestModelOptionalParentRelationshipChildParent(id: UUID(uuid: (2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 1)), name: "test3"))
            ]
        }
        
        let model = TestModelOptionalParentRelationshipChild()
        model.$parent.id = UUID("00010203-0405-0607-0809-0A0B0C0D0E0F")
        let optionalParentPropertyMetadata = try #require( TestModelOptionalParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? OptionalParentRelationshipProperty<TestModelOptionalParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        let values = try await metadata.getPossibleRelationshipValues(from: database.db)
        #expect(values == [
            .init(displayName: "foo", id: "00010203-0405-0607-0809-0A0B0C0D0E0F"),
            .init(displayName: "bar", id: "01020304-0506-0708-090A-0B0C0D0E0F00"),
            .init(displayName: "test3", id: "02030405-0607-0809-0A0B-0C0D0E0F0001")
        ])
    }
    
    // MARK: - ParentRelationshipProperty
    
    // MARK: process(update:on:keypath:)
    
    @Test("ParentRelationshipProperty.process() - Non-nil")
    func parentRelationshipPropertyProcessNonNil() async throws
    {
        let model = TestModelParentRelationshipChild()
        let optionalParentPropertyMetadata = try #require( TestModelParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? ParentRelationshipProperty<TestModelParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        
        try metadata.process(update: "00010203-0405-0607-0809-0A0B0C0D0E0F", on: model, keypath: optionalParentPropertyMetadata.fluentKeypath)
        #expect(model.$parent.id == UUID("00010203-0405-0607-0809-0A0B0C0D0E0F"))
    }
    
    @Test("ParentRelationshipProperty.process() - nil")
    func parentRelationshipPropertyProcessNil() async throws
    {
        let model = TestModelParentRelationshipChild()
        model.$parent.id = UUID("00010203-0405-0607-0809-0A0B0C0D0E0F")!
        let optionalParentPropertyMetadata = try #require( TestModelParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? ParentRelationshipProperty<TestModelParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        
        let error = #expect(throws: AdminError.self) { try metadata.process(update: "", on: model, keypath: optionalParentPropertyMetadata.fluentKeypath) }
        #expect(error == .invalidInput)
    }
    
    @Test("ParentRelationshipProperty.process() - Invalid value")
    func parentRelationshipPropertyProcessInvalidValue() async throws
    {
        let model = TestModelParentRelationshipChild()
        let optionalParentPropertyMetadata = try #require( TestModelParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? ParentRelationshipProperty<TestModelParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        
        #expect(throws: DecodingError.self) { try metadata.process(update: "139423940", on: model, keypath: optionalParentPropertyMetadata.fluentKeypath) }
    }
    
    @Test("ParentRelationshipProperty.process() - Crashes on invalid keypath")
    func parentRelationshipPropertyProcessCrashInvalidKeypath() async throws
    {
        await #expect(processExitsWith: .failure)
        {
            let model = TestModelParentRelationshipChild()
            let optionalParentPropertyMetadata = try #require( TestModelParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
            let metadata = try #require(optionalParentPropertyMetadata.metadata as? ParentRelationshipProperty<TestModelParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
            
            try metadata.process(update: "00010203-0405-0607-0809-0A0B0C0D0E0F", on: model, keypath: \String.self)
            #expect(model.$parent.id == UUID("00010203-0405-0607-0809-0A0B0C0D0E0F"))
        }
    }
    
    // MARK: getCurrentRelationships(on:keypath:)
    
    @Test("ParentRelationshipProperty.getCurrentRelationships()")
    func parentRelationshipPropertyGetCurrentRelationships() async throws
    {
        let model = TestModelParentRelationshipChild()
        model.$parent.id = UUID("00010203-0405-0607-0809-0A0B0C0D0E0F")!
        let optionalParentPropertyMetadata = try #require( TestModelParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? ParentRelationshipProperty<TestModelParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        let values = metadata.getCurrentRelationships(on: model, keypath: optionalParentPropertyMetadata.fluentKeypath)
        #expect(values == [UUID("00010203-0405-0607-0809-0A0B0C0D0E0F")!])
    }
    
    @Test("ParentRelationshipProperty.getCurrentRelationships() - Crashes on invalid keypath")
    func parentRelationshipPropertyGetCurrentRelationshipsCrashInvalidKeypath() async throws
    {
        await #expect(processExitsWith: .failure)
        {
            let model = TestModelParentRelationshipChild()
            model.$parent.id = UUID("00010203-0405-0607-0809-0A0B0C0D0E0F")!
            let optionalParentPropertyMetadata = try #require( TestModelParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
            let metadata = try #require(optionalParentPropertyMetadata.metadata as? ParentRelationshipProperty<TestModelParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
            _ = metadata.getCurrentRelationships(on: model, keypath: \String.self)
        }
    }
    
    // MARK: getPossibleRelationshipValues()
    
    @Test("ParentRelationshipProperty.getPossibleRelationshipValues()")
    func parentRelationshipPropertyGetPossibleRelationshipValues() async throws
    {
        let database = CallbackTestDatabase { query in
            guard case .read = query.action else
            {
                Issue.record("Unexpected query: \(query)")
                return []
            }
            return [
                TestOutput(TestModelOptionalParentRelationshipChildParent(id: UUID(uuid: (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)), name: "foo")),
                TestOutput(TestModelOptionalParentRelationshipChildParent(id: UUID(uuid: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0)), name: "bar")),
                TestOutput(TestModelOptionalParentRelationshipChildParent(id: UUID(uuid: (2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 1)), name: "test3"))
            ]
        }
        
        let model = TestModelParentRelationshipChild()
        model.$parent.id = UUID("00010203-0405-0607-0809-0A0B0C0D0E0F")!
        let optionalParentPropertyMetadata = try #require( TestModelParentRelationshipChild.adminMetadata.first(where: { $0.name == "parent_id" }))
        let metadata = try #require(optionalParentPropertyMetadata.metadata as? ParentRelationshipProperty<TestModelParentRelationshipChild, TestModelOptionalParentRelationshipChildParent>)
        let values = try await metadata.getPossibleRelationshipValues(from: database.db)
        #expect(values == [
            .init(displayName: "foo", id: "00010203-0405-0607-0809-0A0B0C0D0E0F"),
            .init(displayName: "bar", id: "01020304-0506-0708-090A-0B0C0D0E0F00"),
            .init(displayName: "test3", id: "02030405-0607-0809-0A0B-0C0D0E0F0001")
        ])
    }
}
