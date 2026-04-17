//
//  Mocks.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/3/26.
//

import Foundation
import VaporAdmin
import Fluent
import Vapor

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
    
    @Enum(key: "enum")
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
    
    @OptionalField(key: "bar")
    var bar : Int?
    
    @Boolean(key: "nonOptionalBool")
    var nonOptionalBool : Bool
    
    @OptionalBoolean(key: "optionalBool")
    var optionalBool : Bool?
    
    @Field(key: "enum")
    var modelEnum : TestModelEnumCaseIterable
    
    required init() {}
    
    init(id: UUID? = nil, name: String, bar: Int?, nonOptionalBool: Bool, optionalBool: Bool?, modelEnum: TestModelEnumCaseIterable = .one)
    {
        self.id = id
        self.name = name
        self.bar = bar
        self.modelEnum = modelEnum
        self.nonOptionalBool = nonOptionalBool
        self.optionalBool = optionalBool
    }
}

// MARK: - CustomAdminDisplayable

@AdminDisplayable
final class TestModelCustomAdminDisplayable : Model, @unchecked Sendable, CustomAdminDisplayable
{
    static let schema = "test_models"
    
    @ID(custom: "id")
    var id : UUID?
    
    @Field(key: "name")
    var name : String
    
    @Field(key: "bar_blah")
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

@AdminDisplayable
final class TestModelParentRelationshipChild : Model, @unchecked Sendable
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
    
    @Parent(key: "parent_id")
    var parent : TestModelOptionalParentRelationshipChildParent
    
    required init() {}
    
    init(id: UUID? = nil, name: String, bar: Int, modelEnum: TestModelEnum = .one)
    {
        self.id = id
        self.name = name
        self.bar = bar
        self.modelEnum = modelEnum
    }
}

// MARK: - ContentContainer

struct TestContentContainer : ContentContainer
{
    var body : ByteBuffer
    var headers : HTTPHeaders

    var contentType : HTTPMediaType? { self.headers.contentType }

    mutating func encode<E>(_ encodable: E, using encoder: ContentEncoder) throws where E : Encodable
    {
        try encoder.encode(encodable, to: &self.body, headers: &self.headers)
    }

    func decode<D>(_ decodable: D.Type, using decoder: ContentDecoder) throws -> D where D : Decodable
    {
        try decoder.decode(D.self, from: body, headers: headers)
    }

    mutating func encode<C>(_ content: C, using encoder: ContentEncoder) throws where C : Content
    {
        var content = content
        try content.beforeEncode()
        try encoder.encode(content, to: &self.body, headers: &self.headers)
    }
}
