//
//  FluentPropertyMetadataDefinitions.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 3/29/26.
//

import SwiftSyntax

typealias PropertyMetadataMacroDefinition = @Sendable (String, String) -> String

package struct FluentPropertyMetadataDefinition : CaseIterable, Sendable
{
    let propertyWrapper : TokenKind
    let definition : PropertyMetadataMacroDefinition?
    
    // TODO: Add support for other Relationship-based PropertyWrappers
    package static let allCases : [FluentPropertyMetadataDefinition] = [
        .init(propertyWrapper: .identifier("Boolean"), definition: nil),
//        .init(propertyWrapper: "Children", definition: { "VaporAdmin.NonOptionalRelationshipProperty<\($0), \($1)>()" }),
//        .init(propertyWrapper: "CompositeChildren", definition: { "VaporAdmin.NonOptionalRelationshipProperty<\($0), \($1)>()" }),
        .init(propertyWrapper: .identifier("CompositeID"), definition: nil),
//        .init(propertyWrapper: "CompositeOptionalChild", definition: { "VaporAdmin.OptionalRelationshipProperty<\($0), \($1)>()" }),
//        .init(propertyWrapper: "CompositeOptionalParent", definition: { "VaporAdmin.OptionalRelationshipProperty<\($0), \($1)>()" }),
//        .init(propertyWrapper: "CompositeParent", definition: { "VaporAdmin.NonOptionalRelationshipProperty<\($0), \($1)>()" }),
        .init(propertyWrapper: .identifier("Enum"), definition: nil),
        .init(propertyWrapper: .identifier("Field"), definition: nil),
        .init(propertyWrapper: .identifier("Group"), definition: nil),
        .init(propertyWrapper: .identifier("ID"), definition: { _, _ in "VaporAdmin.IDProperty()" }),
        .init(propertyWrapper: .identifier("OptionalBoolean"), definition: { _, _ in "VaporAdmin.OptionalProperty()" }),
//        .init(propertyWrapper: "OptionalChild", definition: { "VaporAdmin.OptionalRelationshipProperty<\($0), \($1)>()" }),
        .init(propertyWrapper: .identifier("OptionalField"), definition: { _, _ in "VaporAdmin.OptionalProperty()" }),
        .init(propertyWrapper: .identifier("OptionalParent"), definition: { "VaporAdmin.OptionalRelationshipProperty<\($0), \($1)>()" }),
//        .init(propertyWrapper: "Parent", definition: { "VaporAdmin.NonOptionalRelationshipProperty<\($0), \($1)>()" }),
//        .init(propertyWrapper: "Siblings", definition: { "VaporAdmin.NonOptionalRelationshipProperty<\($0), \($1)>()" }),
        .init(propertyWrapper: .identifier("Timestamp"), definition: nil)
    ]
}

extension VariableDeclSyntax
{
    var fluentPropertyWrapperMetadata : FluentPropertyMetadataDefinition?
    {
        for attribute in attributes
        {
            guard case .attribute(let attributeSyntax) = attribute else { continue }
            return FluentPropertyMetadataDefinition.allCases.first { defintion in
                attributeSyntax.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }).contains(defintion.propertyWrapper)
            }
        }
        return nil
    }
}
