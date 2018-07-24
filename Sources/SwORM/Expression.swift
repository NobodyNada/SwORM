//
//  Query.swift
//  SwORMTests
//
//  Created by NobodyNada on 7/24/17.
//

import Foundation

///A `SQLFragment` represents a fragment of a SQL query.
public enum SQLFragment: CustomStringConvertible {
    ///A textual fragment of SQL.
    /// - leftDelimiter: Whether this text is a delimiter on the left side; i. e. it doesn't require space separators.
    /// - rightDelimiter: Whether this text is a delimiter on the right side; i. e. it doesn't require space separators.
    case text(String, leftDelimiter: Bool, rightDelimiter: Bool)
    
    ///A bound parameter.
    case parameter(DatabaseType?)
    
    case dialectSpecific([SQLDialect:[SQLFragment]])
    
    public var description: String {
        switch self {
        case .text(let s): return s.0
        case .parameter(let v): return "?<\(v ?? "nil")>"
        case .dialectSpecific(let dialects): return dialects.first?.value.description ?? ""
        }
    }
    
    public static func literal(_ text: String) -> SQLFragment { return .text(text, leftDelimiter: false, rightDelimiter: false) }
    public static func delimiter(_ text: String) -> SQLFragment { return .text(text, leftDelimiter: true, rightDelimiter: true) }
    public static func identifier(_ text: String) -> SQLFragment { return .literal(sanitize(identifier: text)) }
    
    public static var openingParen: SQLFragment = .text("(", leftDelimiter: false, rightDelimiter: true)
    public static var closingParen: SQLFragment = .text(")", leftDelimiter: true, rightDelimiter: false)
    
    public static func parenthesized(_ sql: [SQLFragment]) -> [SQLFragment] {
        return [openingParen] + sql + [closingParen]
    }
}

public extension Array where Element == SQLFragment {
    ///Converts an array of `SQLFragment`s to a string of SQL code.  Parameters are replaced with `?`.
    private func _sqlString(dialect: SQLDialect, delimited: Bool) -> (text: String, leftDelimiter: Bool, rightDelimiter: Bool) {
        var delimited = delimited
        var result = ""
        
        var first = true
        var resultIsLeftDelimiter = false
        
        for fragment in self {
            let text: String
            let leftDelimiter: Bool
            let rightDelimiter: Bool
            if case .text(let t, let l, let r) = fragment {
                text = t
                leftDelimiter = l
                rightDelimiter = r
            } else if case .parameter(_) = fragment {
                text = "?"
                leftDelimiter = false
                rightDelimiter = false
            } else if case .dialectSpecific(let dialects) = fragment {
                let sql = dialects[dialect] ?? dialects.first!.value
                let result = sql._sqlString(dialect: dialect, delimited: delimited)
                
                if result.text.isEmpty { continue }
                (text, leftDelimiter, rightDelimiter) = result
            } else { fatalError() }
            
            if !delimited && !leftDelimiter { result += " " }
            result += text
            delimited = rightDelimiter
            
            if first {
                resultIsLeftDelimiter = leftDelimiter
                first = false
            }
        }
        
        return (result, resultIsLeftDelimiter, delimited)
    }
    
    public func sqlString(dialect: SQLDialect) -> String {
        return _sqlString(dialect: dialect, delimited: true).text
    }
    
    ///Returns the bound parameters in this array of `SQLFragment`s.
    public func sqlParameters(dialect: SQLDialect) -> [DatabaseType?] {
        return self.flatMap { (fragment: SQLFragment) -> [DatabaseType?] in
            if case .parameter(let v) = fragment {
                return [v] as [DatabaseType?]
            } else if case .dialectSpecific(let dialects) = fragment, let sql = dialects[dialect] {
                return sql.sqlParameters(dialect: dialect)
            }
            return []
        }
    }
}

///An Expression represents a typed expression that can be converted to SQL.
public protocol Expression {
    ///The result type of this expression.
    associatedtype Result: DatabaseType
    
    ///The SQL representation of this expression.
    var sql: [SQLFragment] { get }
    
    ///Creates a new expression with the given SQL representation.
    init(_ sql: [SQLFragment])
}

public extension Expression {
    static func binaryOperator<L: Expression, R: Expression>(_ lhs: L, _ op: String, _ rhs: R) -> Self {
        let sql: [SQLFragment] = Array([
            [.openingParen],
            lhs.sql,
            [.literal(op)],
            rhs.sql,
            [.closingParen]
            ].joined()
        )
        return .init(sql)
    }
    static func prefixOperator<E: Expression>(_ op: String, _ e: E) -> Self {
        return .init([.literal(op)] + e.sql)
    }
    
    init(_ sql: SQLFragment...) { self.init(sql) }
}

///An `UntypedExpressionConvertible` is a type that can be converted to an `UntypedExpression`.
public protocol UntypedExpressionConvertible {
    ///The result type of the expression.
    associatedtype ExpressionResult: DatabaseType
    
    ///Converts `self` to an `UntypedExpression`.
    var asUntypedExpression: UntypedExpression<ExpressionResult> { get }
}

///A `TypedExpressionConvertible` is a type that can be converted to an `TypedExpression`.
public protocol TypedExpressionConvertible: UntypedExpressionConvertible {
    ///The `DatabaseObject` of the expression.
    associatedtype ExpressionObject: DatabaseObject
    
    ///Converts `self` to a `TypedExpression`.
    var asTypedExpression: TypedExpression<ExpressionResult, ExpressionObject> { get}
}

public extension TypedExpressionConvertible {
    var asUntypedExpression: UntypedExpression<ExpressionResult> {
        return UntypedExpression(asTypedExpression.sql)
    }
}

///A `TypedExpression` represents an expression which is bound to a `DatabaseObject`.
//`TypedExpression`s only accept key path columns with a matching `DatabaseObject`.
public struct TypedExpression<ResultType: DatabaseType, ObjectType: DatabaseObject>: Expression {
    public typealias Result = ResultType
    public typealias Object = ObjectType
    
    public var sql: [SQLFragment]
    
    public init(_ sql: [SQLFragment]) {
        self.sql = sql
    }
    
    public init(_ sql: SQLFragment...) { self.init(sql) }
    
    public var asUntypedExpression: UntypedExpression<ResultType> { return UntypedExpression(sql) }
}

extension TypedExpression: TypedExpressionConvertible  {
    public typealias ExpressionObject = Object
    public typealias ExpressionResult = Result
    
    public var asTypedExpression: TypedExpression<Result, Object> { return self }
}

///An `UntypedExpression` represents an expression which is *not* bound to a `DatabaseObject`.
///`UntypedExpression`s accept key path columns of any `DatabaseObject`.
public struct UntypedExpression<ResultType: DatabaseType>: Expression {
    public typealias Result = ResultType
    
    public var sql: [SQLFragment]
    
    public init(_ sql: [SQLFragment]) {
        self.sql = sql
    }
    
    public init(_ sql: SQLFragment...) { self.init(sql) }
}

extension UntypedExpression: UntypedExpressionConvertible {
    public typealias ExpressionResult = Result
    
    public var asUntypedExpression: UntypedExpression<Result> { return self }
}

///A `ParameterExpressionConvertible` is a type that can be converted to a SQL bound parameter expression.
public protocol ParameterExpressionConvertible: UntypedExpressionConvertible {}
extension ParameterExpressionConvertible where Self: DatabaseType, ExpressionResult == Self {
    public var asUntypedExpression: UntypedExpression<ExpressionResult> {
        return .init(.parameter(self))
    }
}

extension Optional: UntypedExpressionConvertible where Wrapped: DatabaseType & ParameterExpressionConvertible {
    public typealias ExpressionResult = Optional<Wrapped>
    public var asUntypedExpression: UntypedExpression<Optional<Wrapped>> {
        return .init(.parameter(self))
    }
}

extension Optional: ParameterExpressionConvertible where Wrapped: DatabaseType & ParameterExpressionConvertible { }

extension Int: ParameterExpressionConvertible {}
extension Int8: ParameterExpressionConvertible {}
extension Int16: ParameterExpressionConvertible {}
extension Int32: ParameterExpressionConvertible {}
extension Int64: ParameterExpressionConvertible {}
extension UInt: ParameterExpressionConvertible {}
extension UInt8: ParameterExpressionConvertible {}
extension UInt16: ParameterExpressionConvertible {}
extension UInt32: ParameterExpressionConvertible {}
extension Float: ParameterExpressionConvertible {}
extension Data: ParameterExpressionConvertible {}
extension Date: ParameterExpressionConvertible {}
extension String: ParameterExpressionConvertible {}

extension KeyPath: UntypedExpressionConvertible where Root: DatabaseObject, Value: DatabaseType {
    public typealias ExpressionResult = Value
    
    public var asUntypedExpression: UntypedExpression<ExpressionResult> {
        return UntypedExpression(asTypedExpression.sql)
    }
}

extension KeyPath: TypedExpressionConvertible where Root: DatabaseObject, Value: DatabaseType {
    public typealias ExpressionObject = Root
    
    public var asTypedExpression: TypedExpression<Value, Root> {
        guard let column = Root.name(of: self) else {
            fatalError("\(self) was not found in allColumns")
        }
        
        let table = Root.tableName
        return .init([.identifier(table), .delimiter("."), .identifier(column)])
    }
}
