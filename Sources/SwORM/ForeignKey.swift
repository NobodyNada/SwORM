//
//  ForeignKey.swift
//  SwORM
//
//  Created by NobodyNada on 3/11/18.
//

import Foundation
import Async

///A `ForeignKey` represents a reference to a row of another table in the database.
public struct ForeignKey<T: DatabaseObject>: Codable, DatabaseType, Hashable {
    public var asNative: DatabaseNativeType { return id.asNative }
    
    public static func from(native: DatabaseNativeType) -> ForeignKey<T>? {
        return Int64.from(native: native).map { ForeignKey(id: $0) }
    }
    
    ///The primary key of the target row.
    public let id: Int64
    
    ///Creates a new `ForeignKey` instance with the given `id`.
    public init(id: Int64) { self.id = id }
    
    public func encode(to encoder: Encoder) throws {
        try id.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        self.init(id: try Int64(from: decoder))
    }
    
    ///An error that can occur while looking up a foreign key.
    public enum LookupError: Error {
        ///The target row did not exist.
        case notFound
    }
    
    ///Returns the target `DatabaseObject` of this foreign key.
    public func find(_ connection: Connection) -> Future<T> {
        return T.find(id, connection: connection).map(to: T.self) {
            guard let result = $0 else { throw LookupError.notFound }
            return result
        }
    }
}

