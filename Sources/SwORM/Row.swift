//
//  Row.swift
//  SwORM
//
//  Created by NobodyNada on 7/14/17.
//

import Foundation

///A `Row` represents a result row from a database query.
public final class Row {
    enum RowError: Error {
        case indexOutOfRange(index: Int, columnCount: Int)
        case nameNotFound(String)
        case incompatibleType(expected: DatabaseType.Type, actual: DatabaseNativeType)
    }
    
    ///The columns of this row.
    open var columns: [DatabaseNativeType]
    
    ///A Dictionary mapping the names of this row's columns to their indices in `columns`.
    open var columnIndices: [String:Int]
    
    public init(columns: [DatabaseNativeType], columnIndices: [String:Int]) {
        self.columns = columns
        self.columnIndices = columnIndices
    }
    
    
    //MARK: - Convenience functions for accessing columns
    
    
    ///Returns the contents of the column at the specified index.
    ///
    ///- parameter index: The index of the column to return.
    ///- parameter type: The type of the column to return.  Will be inferred by the compiler
    ///                  if not specified.  Must conform to `DatabaseType`.
    ///
    ///- returns: The contents of the column, or `nil` if the contents are `NULL`.
    ///
    ///- warning: Will throw if the index is out of range or the column has an incompatible type.
    open func column<T: DatabaseType>(at index: Int, type: T.Type = T.self) throws -> T? {
        if case .null = columns[index] { return nil }
        guard let converted = T.from(native: columns[index]) else {
            throw RowError.incompatibleType(expected: type, actual: columns[index])
        }
        return converted
    }
    
    ///Returns the contents of the column with the specified name.
    ///
    ///- parameter name: The name of the column to return.
    ///- parameter type: The type of the column to return.  Will be inferred by the compiler
    ///                  if not specified.  Must conform to `DatabaseType`.
    ///
    ///- returns: The contents of the column.
    ///
    ///- warning: Will throw if the name does not exist or the column has an incompatible type.
    open func column<T: DatabaseType>(named name: String, type: T.Type = T.self) throws -> T? {
        guard let index = columnIndices[name] else {
            throw RowError.nameNotFound(name)
        }
        return try column(at: index)
    }
}

