import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AdminDisplayableMacro : MemberMacro, ExtensionMacro
{
    private struct Error : DiagnosticMessage, Swift.Error
    {
        var message: String
        
        var diagnosticID: SwiftDiagnostics.MessageID
        
        var severity: SwiftDiagnostics.DiagnosticSeverity
        
        static let notAClass = Error(message: "@AdminDisplayable can only be applied to a class", diagnosticID: .init(domain: "com.michaelschloss.vaporadminmacro", id: "NotAClass"), severity: .error)
        
        init(message: String, diagnosticID: SwiftDiagnostics.MessageID, severity: SwiftDiagnostics.DiagnosticSeverity)
        {
            self.message = message
            self.diagnosticID = diagnosticID
            self.severity = severity
        }
        
        init(message: String)
        {
            self.message = message
            self.diagnosticID = .init(domain: "com.michaelschloss.vaporadminmacro", id: "Generic")
            self.severity = .error
        }
    }
    
    private static let modifierSyntax = DeclModifierListSyntax
    {
        DeclModifierSyntax(name: .keyword(.static))
    }
    
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax]
    {
        // Fluent property wrappers only work on `class` types
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else
        {
            let diagnostic = Error.notAClass.asDiagnostics(at: node)
            throw DiagnosticsError(diagnostics: diagnostic)
        }
        
        let className = classDecl.name.trimmed
        var metadataExprSyntax = [ExprSyntax]()
        
        // For each member (variable definition) in the model:
        //     1. Check if the member is wrapped in a Fluent-based property wrapper we support (defined in FluentPropertyMetadataDefinitions.swift)
        //     2. Some Fluent property wrappers use a String Literal for the db row key, while others (like @ID) don't have one
        //         a. If we have a db row key, use it.  If not, use the member's name
        //     3. Check to see if we have an internal mapper that goes Fluent Property Wrapper -> FluentPropertyMetadata impl
        //         b. If we have a mapper, execute it to return an impl syntax
        // Finally, build the static `adminMetadata` member
        
        for member in declaration.memberBlock.members
        {
            // 1.
            guard let variableSyntax = member.decl.as(VariableDeclSyntax.self),
                  let fluentMetadata = variableSyntax.fluentPropertyWrapperMetadata,
                  let identifier = variableSyntax.identifier?.trimmed,
                  let typeSyntax = variableSyntax.unwrappedType?.trimmed.description else {
                continue
            }
            
            var identifierName = identifier.description
            
            // 2.
            let fluentPropertyWrapper = variableSyntax.attributes.first!.as(AttributeSyntax.self)!.arguments!.as(LabeledExprListSyntax.self)!
            if let stringSyntax = fluentPropertyWrapper.first?.expression.as(StringLiteralExprSyntax.self),
               let literal = stringSyntax.representedLiteralValue
            {
                identifierName = literal // Use the db row value if it exists
            }
            
            // 3.
            let metadataDefinition = fluentMetadata.definition?(className.description, typeSyntax)
            metadataExprSyntax.append("""
            VaporAdmin.PropertyMetadata(name: "\(raw: identifierName)", fluentKeypath: \\\(className).$\(identifier), dataKeypath: \\\(className).\(identifier), metadata: \(raw: metadataDefinition ?? "nil"))
            """)
        }
        // Add a newline to the end of the last expression syntax
        metadataExprSyntax[metadataExprSyntax.count - 1] = metadataExprSyntax[metadataExprSyntax.count - 1].with(\.trailingTrivia, .newline)
        
        let syntax = VariableDeclSyntax(modifiers: modifierSyntax,
                                        bindingSpecifier: .keyword(.var),
                                        bindings: [
                                            PatternBindingSyntax(pattern: IdentifierPatternSyntax(identifier: .identifier("adminMetadata")),
                                                                 typeAnnotation: typeAnnotation(for: className),
                                                                 accessorBlock: accessorBlock(metadataExprSyntax: metadataExprSyntax))
                                        ])
        return [.init(syntax)]
    }
    
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax]
    {
        let decl: DeclSyntax = """
        extension \(raw: type.trimmedDescription) : FluentAdminDisplay {}
        """
        let ext = decl.cast(ExtensionDeclSyntax.self)
        
        return [ext]
    }
    
    private static func memberSyntax(for className: TokenSyntax) -> MemberTypeSyntax
    {
        let genericArgumentClause = GenericArgumentClauseSyntax(leftAngle: .leftAngleToken(),
                                                                arguments: [.init(argument: .type("\(raw: className)"))],
                                                                rightAngle: .rightAngleToken())
        return .init(baseType: IdentifierTypeSyntax(name: .identifier("VaporAdmin")),
                     period: .periodToken(),
                     name: .identifier("PropertyMetadata"),
                     genericArgumentClause: genericArgumentClause)
    }
    
    private static func accessorBlock(metadataExprSyntax: [ExprSyntax]) -> AccessorBlockSyntax
    {
        let formattedMetadata = metadataExprSyntax.map { $0.with(\.leadingTrivia, .newline) }
        let codeBlockSyntax = CodeBlockItemSyntax(item: .init(ArrayExprSyntax(elements: .init(expressions: formattedMetadata))))
        
        return .init(leftBrace: .leftBraceToken(),
                     accessors: .getter([codeBlockSyntax]),
                     rightBrace: .rightBraceToken())
    }
    
    private static func typeAnnotation(for className: TokenSyntax) -> TypeAnnotationSyntax
    {
        let typeSyntax = ArrayTypeSyntax(leftSquare: .leftSquareToken(),
                                         element: memberSyntax(for: className),
                                         rightSquare: .rightSquareToken())
        return .init(colon: .colonToken(),
                     type: typeSyntax)
    }
}

private extension VariableDeclSyntax
{
    var identifierPattern: IdentifierPatternSyntax? { bindings.first?.pattern.as(IdentifierPatternSyntax.self) }
    
    var identifier: TokenSyntax? { identifierPattern?.identifier }
    
    var unwrappedType : TypeSyntax?
    {
        let typeSyntax = bindings.first?.typeAnnotation?.type
        if let optionalType = typeSyntax?.as(OptionalTypeSyntax.self)
        {
            return optionalType.wrappedType
        }
        else
        {
            return typeSyntax
        }
    }
}

@main
struct VaporAdminMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AdminDisplayableMacro.self
    ]
}
