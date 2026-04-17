//
//  MacroTests.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 3/29/26.
//

import SwiftSyntaxMacrosTestSupport
import VaporAdminMacros
import VaporAdmin
import Fluent
import XCTest

class VaporAdminMacroTests : XCTestCase
{
    func testMacroSupport()
    {
        assertMacroExpansion("""
            @AdminDisplayable
            class Foo : Model, @unchecked Sendable
            {
                static let schema = "foo"
                
                @ID(key: .id)
                var id : UUID?
                
                @Field(key: "name")
                var name : String
            
                @OptionalParent(key: "bar")
                var bar : Bar?
            
                @Parent(key: "required_bar")
                var bar2 : Bar
            
                var foo : Int
                
                required init() { }
            }
            """, expandedSource: """
            class Foo : Model, @unchecked Sendable
            {
                static let schema = "foo"
                
                @ID(key: .id)
                var id : UUID?
                
                @Field(key: "name")
                var name : String
            
                @OptionalParent(key: "bar")
                var bar : Bar?
            
                @Parent(key: "required_bar")
                var bar2 : Bar
            
                var foo : Int
                
                required init() { }
            
                static var adminMetadata : [VaporAdmin.PropertyMetadata<Foo>]
                {
                    [
                        VaporAdmin.PropertyMetadata(name: "id", fluentKeypath: \\Foo.$id, dataKeypath: \\Foo.$id.value, metadata: VaporAdmin.IDProperty()),
                        VaporAdmin.PropertyMetadata(name: "name", fluentKeypath: \\Foo.$name, dataKeypath: \\Foo.$name.value, metadata: nil),
                        VaporAdmin.PropertyMetadata(name: "bar", fluentKeypath: \\Foo.$bar, dataKeypath: \\Foo.$bar.value, metadata: VaporAdmin.OptionalParentRelationshipProperty<Foo, Bar>()),
                        VaporAdmin.PropertyMetadata(name: "required_bar", fluentKeypath: \\Foo.$bar2, dataKeypath: \\Foo.$bar2.value, metadata: VaporAdmin.ParentRelationshipProperty<Foo, Bar>())
                    ]
                }
            }
            
            extension Foo : FluentAdminDisplay {
            }
            
            """, macros: ["AdminDisplayable": AdminDisplayableMacro.self])
    }
}
