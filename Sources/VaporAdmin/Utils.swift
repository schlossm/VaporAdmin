//
//  Utils.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/5/26.
//

protocol OptionalProtocol
{
    static func wrappedType() -> Any.Type
}

extension Optional : OptionalProtocol
{
    static func wrappedType() -> Any.Type
    {
        return Wrapped.self
    }
}
