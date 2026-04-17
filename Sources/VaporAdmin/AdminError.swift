//
//  AdminError.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/2/26.
//

public enum AdminError : Error, Equatable
{
    case couldNotFindModel
    case couldNotFindInstance
    case invalidInput
    case unexpected(message: String)
}
