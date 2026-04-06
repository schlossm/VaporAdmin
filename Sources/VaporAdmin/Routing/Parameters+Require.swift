//
//  Parameters+Require.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/2/26.
//

import Vapor

extension Parameters
{
    /// Grabs the named parameter from the parameter bag, casting it to a `LosslessStringConvertible` type or a `RawRepresentable<String>` type.
    /// If the parameter does not exist, `Abort(.internalServerError)` is thrown.
    /// If the parameter value cannot be converted to the required type, `Abort(.unprocessableEntity)` is thrown.
    ///
    /// - parameters:
    ///     - name: The name of the parameter.
    ///     - type: The required parameter value type.
    func require<T>(_ name: String, as type: T.Type = T.self) throws -> T
    {
        guard let stringValue : String = get(name) else
        {
            self.logger.debug("The parameter \(name) does not exist")
            throw Abort(.internalServerError, reason: "The parameter provided does not exist")
        }

        if let type = T.self as? LosslessStringConvertible.Type
        {
            guard let value = type.init(stringValue) else
            {
                self.logger.debug("The parameter \(stringValue) could not be converted to \(T.Type.self)")
                throw Abort(.unprocessableEntity, reason: "The parameter value could not be converted to the required type")
            }
            return value as! T
        }
        else if let type = T.self as? any RawRepresentable<String>.Type
        {
            guard let value = type.init(rawValue: stringValue) else
            {
                self.logger.debug("The parameter \(stringValue) could not be represented by \(T.Type.self)")
                throw Abort(.unprocessableEntity, reason: "The parameter value could not be converted to the required type")
            }
            return value as! T
        }
        
        throw Abort(.unprocessableEntity, reason: "The parameter value could not be converted from a string.  Ensure your type conforms to `LosslessStringConvertible` or `RawRepresentable<String>`")
    }
}
