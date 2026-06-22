import SwiftSyntax

typealias PropertyMetadataMacroDefinition = @Sendable (String, String) -> String

struct FluentPropertyMetadataDefinition : CaseIterable, Sendable
{
    let propertyWrapper : TokenKind
    let definition : PropertyMetadataMacroDefinition?
    
    // TODO: Add support for other Relationship-based PropertyWrappers
    static let allCases : [FluentPropertyMetadataDefinition] = [
        .init(propertyWrapper: .identifier("Boolean"), definition: nil),
//        .init(propertyWrapper: "Children", definition: { "VaporAdmin._<\($0), \($1)>()" }),
//        .init(propertyWrapper: "CompositeChildren", definition: { "VaporAdmin._<\($0), \($1)>()" }),
//        .init(propertyWrapper: .identifier("CompositeID"), definition: nil),
//        .init(propertyWrapper: "CompositeOptionalChild", definition: { "VaporAdmin._<\($0), \($1)>()" }),
//        .init(propertyWrapper: "CompositeOptionalParent", definition: { "VaporAdmin._<\($0), \($1)>()" }),
//        .init(propertyWrapper: "CompositeParent", definition: { "VaporAdmin._<\($0), \($1)>()" }),
        .init(propertyWrapper: .identifier("Enum"), definition: nil),
        .init(propertyWrapper: .identifier("Field"), definition: nil),
//        .init(propertyWrapper: .identifier("Group"), definition: nil),
        .init(propertyWrapper: .identifier("ID"), definition: { _, _ in "VaporAdmin.IDProperty()" }),
        .init(propertyWrapper: .identifier("OptionalBoolean"), definition: { _, _ in "VaporAdmin.OptionalProperty()" }),
//        .init(propertyWrapper: "OptionalChild", definition: { "VaporAdmin._<\($0), \($1)>()" }),
        .init(propertyWrapper: .identifier("OptionalField"), definition: { _, _ in "VaporAdmin.OptionalProperty()" }),
        .init(propertyWrapper: .identifier("OptionalParent"), definition: { "VaporAdmin.OptionalParentRelationshipProperty<\($0), \($1)>()" }),
        .init(propertyWrapper: .identifier("Parent"), definition: { "VaporAdmin.ParentRelationshipProperty<\($0), \($1)>()" }),
//        .init(propertyWrapper: "Siblings", definition: { "VaporAdmin._<\($0), \($1)>()" }),
//        .init(propertyWrapper: .identifier("Timestamp"), definition: nil)
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
