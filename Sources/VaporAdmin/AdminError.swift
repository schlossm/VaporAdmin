//
//  AdminError.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/2/26.
//

enum AdminError : Error, Equatable
{
    case couldNotFindModel
    case couldNotFindInstance
    case unexpected(message: String)
}
