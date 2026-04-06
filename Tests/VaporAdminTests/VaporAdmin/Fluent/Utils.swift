//
//  Utils.swift
//  VaporAdmin
//
//  Created by Michael Schloss on 4/5/26.
//

import Fluent

extension DatabaseQuery.Value
{
    func bind<T>() -> T?
    {
        switch self {
        case .bind(let bind):
            return bind as? T
        default: return nil
        }
    }
}
