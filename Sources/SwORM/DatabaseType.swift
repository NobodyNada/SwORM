//
//  DatabaseType.swift
//  SwORM
//
//  Created by NobodyNada on 7/14/17.
//

import Foundation

///A type which can be represented in a database.
public protocol DatabaseType {
    ///Converts `self` to a native type.
    var asNative: DatabaseNativeType { get }
    
    ///Converts a `DatabaseNativeType` to this type.
    ///- parameter native: The value to convert.
    ///- returns: The converted value, or `nil` if a conversion is not possible.
    static func from(native: DatabaseNativeType) -> Self?
}

extension Optional: DatabaseType where Wrapped: DatabaseType {
    public var asNative: DatabaseNativeType { return self?.asNative ?? .null }
    
    public static func from(native: DatabaseNativeType) -> Optional<Wrapped>? {
        return Wrapped.from(native: native)
    }
}

///A type which can be directly represented in a databse.
public enum DatabaseNativeType: DatabaseType {
    ///An integer (SQL `INTEGER`).
    case int(Int64)
    
    ///A double (SQL `NUMERIC`).
    case double(Double)
    
    ///A string (SQL `TEXT`).
    case string(String)
    
    ///A collection of binary data (SQL `BLOB`)
    case data(Data)
    
    ///A date (SQL `DATETIME` if supported, otherwise `TEXT`)
    case date(Date)
    
    ///Null.
    case null
}

public extension DatabaseNativeType {
    var asNative: DatabaseNativeType { return self }
    
    static func from(native: DatabaseNativeType) -> DatabaseNativeType? {
        return native
    }
}

extension Float: DatabaseType {
    public var asNative: DatabaseNativeType { return .double(Double(self)) }
    
    public static func from(native: DatabaseNativeType) -> Float? {
        if case .double(let n) = native { return Float(n) }
        if case .int(let n) = native { return Float(n) }
        return nil
    }
}

extension Double: DatabaseType {
    public var asNative: DatabaseNativeType { return .double(self) }
    
    public static func from(native: DatabaseNativeType) -> Double? {
        if case .double(let n) = native { return n }
        if case .int(let n) = native { return Double(n) }
        return nil
    }
}


extension Bool: DatabaseType {
    public var asNative: DatabaseNativeType { return .int(self ? 1 : 0) }
    
    public static func from(native: DatabaseNativeType) -> Bool? {
        guard case .int(let n) = native else { return nil }
        switch n {
        case 0: return false
        case 1: return true
        default: return nil
        }
    }
}

extension Int8: DatabaseType {
    public var asNative: DatabaseNativeType { return .int(Int64(self)) }
    
    public static func from(native: DatabaseNativeType) -> Int8? {
        guard case .int(let n) = native else { return nil }
        return Int8(n)
    }
}
extension Int16: DatabaseType {
    public var asNative: DatabaseNativeType { return .int(Int64(self)) }
    
    public static func from(native: DatabaseNativeType) -> Int16? {
        guard case .int(let n) = native else { return nil }
        return Int16(n)
    }
}
extension Int32: DatabaseType {
    public var asNative: DatabaseNativeType { return .int(Int64(self)) }
    
    public static func from(native: DatabaseNativeType) -> Int32? {
        guard case .int(let n) = native else { return nil }
        return Int32(n)
    }
}
extension Int64: DatabaseType {
    public var asNative: DatabaseNativeType { return .int(self) }
    
    public static func from(native: DatabaseNativeType) -> Int64? {
        guard case .int(let n) = native else { return nil }
        return n
    }
}
extension Int: DatabaseType {
    public var asNative: DatabaseNativeType { return .int(Int64(self)) }
    
    public static func from(native: DatabaseNativeType) -> Int? {
        guard case .int(let n) = native else { return nil }
        return Int(n)
    }
}

extension UInt8: DatabaseType {
    public var asNative: DatabaseNativeType { return .int(Int64(self)) }
    
    public static func from(native: DatabaseNativeType) -> UInt8? {
        guard case .int(let n) = native else { return nil }
        return UInt8(exactly: n)
    }
}
extension UInt16: DatabaseType {
    public var asNative: DatabaseNativeType { return .int(Int64(self)) }
    
    public static func from(native: DatabaseNativeType) -> UInt16? {
        guard case .int(let n) = native else { return nil }
        return UInt16(exactly: n)
    }
}
extension UInt32: DatabaseType {
    public var asNative: DatabaseNativeType { return .int(Int64(self)) }
    
    public static func from(native: DatabaseNativeType) -> UInt32? {
        guard case .int(let n) = native else { return nil }
        return UInt32(exactly: n)
    }
}
extension UInt: DatabaseType {
    public var asNative: DatabaseNativeType { return .int(Int64(self)) }
    
    public static func from(native: DatabaseNativeType) -> UInt? {
        guard case .int(let n) = native else { return nil }
        return UInt(exactly: n)
    }
}

extension String: DatabaseType {
    public var asNative: DatabaseNativeType { return .string(self) }
    
    public static func from(native: DatabaseNativeType) -> String? {
        if case .string(let n) = native { return n }
        else if case .data(let n) = native { return String(data: n, encoding: .utf8) }
        else { return nil }
    }
}

extension Data: DatabaseType {
    public var asNative: DatabaseNativeType { return .data(self) }
    
    public static func from(native: DatabaseNativeType) -> Data? {
        guard case .data(let n) = native else { return nil }
        return n
    }
}

let dateFormatter: DateFormatter = {
    let result = DateFormatter()
    result.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return result
}()

extension Date: DatabaseType {
    public var asNative: DatabaseNativeType { return .date(self) }
    
    ///Converts this date into a string, for storage in a database that does not support `DATETIME`.
    public var asDatabaseString: DatabaseNativeType { return .string(dateFormatter.string(from: self)) }
    
    public static func from(native: DatabaseNativeType) -> Date? {
        switch native {
        case .date(let n): return n
        case .int(let i): return Date(timeIntervalSince1970: TimeInterval(i))
        case .double(let d): return Date(timeIntervalSince1970: d)
        case .string(let s): return dateFormatter.date(from: s)
        default: return nil
        }
    }
}
