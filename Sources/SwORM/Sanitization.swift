//
//  Sanitization.swift
//  SwORM
//
//  Created by NobodyNada on 7/24/17.
//

import Foundation

///Sanitizes an identifier for SQL with backticks.
public func sanitize(identifier: String) -> String {
    return "`" + identifier.replacingOccurrences(of: "`", with: "``") + "`"
}
