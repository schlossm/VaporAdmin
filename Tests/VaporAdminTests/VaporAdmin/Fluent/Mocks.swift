//
//  Mocks.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/3/26.
//

import Foundation
import VaporAdmin
import Fluent

// MARK: - Basic

enum TestModelEnum : String, Codable
{
    case one
    case two
}

@AdminDisplayable
final class TestModel : Model, @unchecked Sendable
{
    static let schema = "test_models"
    
    @ID(key: .id)
    var id : UUID?
    
    @Field(key: "name")
    var name : String
    
    @Field(key: "bar")
    var bar : Int
    
    @Field(key: "enum")
    var modelEnum : TestModelEnum
    
    required init() {}
    
    init(id: UUID? = nil, name: String, bar: Int, modelEnum: TestModelEnum = .one)
    {
        self.id = id
        self.name = name
        self.bar = bar
        self.modelEnum = modelEnum
    }
}

// MARK: - Case Iterable

enum TestModelEnumCaseIterable : String, Codable, CaseIterable
{
    case one
    case two
}

@AdminDisplayable
final class TestModelCaseIterable : Model, @unchecked Sendable
{
    static let schema = "test_models"
    
    @ID(key: .id)
    var id : UUID?
    
    @Field(key: "name")
    var name : String
    
    @Field(key: "bar")
    var bar : Int
    
    @Field(key: "enum")
    var modelEnum : TestModelEnumCaseIterable
    
    required init() {}
    
    init(id: UUID? = nil, name: String, bar: Int, modelEnum: TestModelEnumCaseIterable = .one)
    {
        self.id = id
        self.name = name
        self.bar = bar
        self.modelEnum = modelEnum
    }
}

// MARK: - CustomAdminDisplayable

@AdminDisplayable
final class TestModelCustomAdminDisplayable : Model, @unchecked Sendable, CustomAdminDisplayable
{
    static let schema = "test_models"
    
    @ID(key: .id)
    var id : UUID?
    
    @Field(key: "name")
    var name : String
    
    @Field(key: "bar")
    var bar : Int
    
    var displayString : String { name }
    
    required init() {}
    
    init(id: UUID? = nil, name: String, bar: Int)
    {
        self.id = id
        self.name = name
        self.bar = bar
    }
}

// MARK: - Relationsip

final class TestModelOptionalParentRelationshipChildParent : Model, @unchecked Sendable, CustomAdminDisplayable
{
    static let schema = "test_models_parent"
    
    var displayString : String { name }
    
    @ID(key: .id)
    var id : UUID?
    
    @Field(key: "name")
    var name : String
    
    @Children(for: \.$parent)
    var children : [TestModelOptionalParentRelationshipChild]
    
    required init() {}
    
    init(id: UUID? = nil, name: String)
    {
        self.id = id
        self.name = name
    }
}

@AdminDisplayable
final class TestModelOptionalParentRelationshipChild : Model, @unchecked Sendable
{
    static let schema = "test_models"
    
    @ID(key: .id)
    var id : UUID?
    
    @Field(key: "name")
    var name : String
    
    @Field(key: "bar")
    var bar : Int
    
    @Field(key: "enum")
    var modelEnum : TestModelEnum
    
    @OptionalParent(key: "parent_id")
    var parent : TestModelOptionalParentRelationshipChildParent?
    
    required init() {}
    
    init(id: UUID? = nil, name: String, bar: Int, modelEnum: TestModelEnum = .one)
    {
        self.id = id
        self.name = name
        self.bar = bar
        self.modelEnum = modelEnum
    }
}
