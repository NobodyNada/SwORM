//
//  Query.swift
//  SwORM
//
//  Created by NobodyNada on 7/24/17.
//

import Foundation
import Async
import Core

///An object on which `SELECT` queries can be run.
public protocol Selectable {
    ///The SQL representation of this object.
    var sql: [SQLFragment] { get }
    
    ///The columns to select.
    var selectColumns: [SelectColumn] { get }
}

///An object on which `INSERT` queries can be run.
public protocol Insertable {
    ///The SQL representation of this object.
    var sql: [SQLFragment] { get }
}

///An object on which `UPDATE` queries can be run.
public protocol Updatable {
    ///The SQL representation of this object.
    var sql: [SQLFragment] { get }
}

///An object on which `DELETE` queries can be run.
public protocol Deletable {
    ///The SQL representation of this object.
    var sql: [SQLFragment] { get }
}

///An type which can be instantiated from a `Row`.
public protocol RowInitializable {
    ///Creates an object from this row.
    static func from(row: Row) throws -> Self
}

extension Row: RowInitializable {
    public static func from(row: Row) throws -> Row { return row }
}

///A wrapper for a SQL expression that can be queried.
public struct Table: Selectable, Insertable, Updatable, Deletable {
    public var sql: [SQLFragment] {
        return [.identifier(name)]
    }
    
    public var selectColumns = [SelectColumn]()
    
    public var name: String
    public init(name: String, columns: [SelectColumn])  {
        self.name = name
        self.selectColumns = columns
    }
}

///A column or group of columns to be produced by a `SELECT` query
public enum SelectColumn {
    ///A single column, with the given alias and SQL representation.
    case column(name: String, sql: [SQLFragment])
    
    ///A group of columns, aliases prefixed with the given name.
    case group(name: String, columns: [SelectColumn])
    
    ///This column or column group as a flat array of column aliases and SQL values.
    ///
    ///  - `name`: The alias of this column, with all group prefixes added.
    ///  - `sql`: The SQL representation of this column.
    public var flattened: [(name: String, sql: [SQLFragment])] {
        switch self {
        case .column(let name, let sql): return [(name: name, sql: sql)]
        case .group(let name, let columns): return columns
            .flatMap { $0.flattened }
            .map {
                (
                    name: "\(name).\($0.name)",
                    sql: $0.sql
                )
            }
        }
    }
    
    ///The `name` value pf this `SelectColumn`.
    public var name: String {
        switch self {
        case .column(let name, _): return name
        case .group(let name, _): return name
        }
    }
    
    ///If this item is a column group, returns the subgroup with the given name.
    ///Returns `nil` if this item is not a column group or no subgroup with the given name was found.
    public func subgroup(named name: String) -> [SelectColumn]? {
        guard case let .group(_, columns) = self else { return nil }
        return columns.subgroup(named: name)
    }
}

extension Array where Element == SelectColumn {
    ///Returns the column group with the given name, or `nil` if none was found.
    public func subgroup(named name: String) -> [SelectColumn]? {
        for item in self {
            if case let .group(name, columns) = item, item.name == name { return columns }
        }
        return nil
    }
}

///A SQL query.
public protocol Query {
    var sql: [SQLFragment] { get }
}

///A SQL query that returns no rows, such as an `INSERT`, `UPDATE`, or `DELETE`.
public protocol VoidQuery: Query {}

///A SQL `SELECT` query.
public protocol SelectQuery: Query, Selectable {
    ///The SQL of a query that counts the result rows.
    var countSQL: [SQLFragment] { get }
    
    ///The result type of this query.
    associatedtype Result: RowInitializable
}

public extension VoidQuery {
    ///Runs this query on the given connection.
    func run(_ connection: Connection) -> Future<Void> {
        let sql = self.sql
        return connection.execute(sql.sqlString(dialect: connection.database.dialect), parameters: sql.sqlParameters).map(to: Void.self) { _ in }
    }
}

//MARK: - Select
public enum SelectError: Error {
    ///A `COUNT` query did not return any rows.
    case noRowsReturnedByCount
}

public extension SelectQuery {
    ///Runs this query on the given connection, returning all results.
    func all(_ connection: Connection) -> Future<[Result]> {
        let sql = self.sql
        return connection.execute(sql.sqlString(dialect: connection.database.dialect), parameters: sql.sqlParameters).map(to: [Result].self) {
            try $0.map { try Result.from(row: $0) }
        }
    }
    
    ///Runs this query on the given connection, returning the first result.
    func first(_ connection: Connection) -> Future<Result?> {
        let sql = self.sql
        return connection.execute(
            (sql + [SQLFragment.literal("LIMIT 1")]).sqlString(dialect: connection.database.dialect),
            parameters: sql.sqlParameters
            ).map(to: Result?.self) { try $0.first.map { try Result.from(row: $0) } }
    }
    
    ///Runs this query on the given connection, returning the number of results.
    func count(_ connection: Connection) -> Future<Int> {
        let sql = self.sql
        return connection.execute(countSQL.sqlString(dialect: connection.database.dialect), parameters: sql.sqlParameters)
            .map(to: Int?.self) { try $0.first?.column(at: 0, type: Int.self) }
            .unwrap(or: SelectError.noRowsReturnedByCount)
    }
}

///A `SELECT` query, with a typed where clause.
public struct TypedSelectQuery<Table: Selectable, WhereClause: TypedExpressionConvertible, Result>: SelectQuery, Selectable
where WhereClause.ExpressionObject == Result, WhereClause.ExpressionResult == Bool {
    public var selectColumns = [SelectColumn]()
    
    public var sql: [SQLFragment] {
        return makeSelectQuery(columns: selectColumns, from: from.sql, whereClause: whereClause?.asTypedExpression.sql)
    }
    public var countSQL: [SQLFragment] {
        return makeSelectQuery(
            columns: [
                .column(
                    name: "count",
                    sql: [SQLFragment.literal("COUNT(*)")]
                )
            ],
            from: from.sql,
            whereClause: whereClause?.asTypedExpression.sql
        )
    }
    public var from: Table
    public var whereClause: WhereClause?
    
    public init(columns: [SelectColumn], from: Table, where whereClause: WhereClause? = nil) {
        self.selectColumns = columns
        self.from = from
        self.whereClause = whereClause
    }
}

///A `SELECT` query, with an untyped where clause.
public struct UntypedSelectQuery<Table: Selectable, WhereClause: UntypedExpressionConvertible, Result: RowInitializable>: SelectQuery, Selectable
where WhereClause.ExpressionResult == Bool {
    public var selectColumns = [SelectColumn]()
    
    public var sql: [SQLFragment] {
        return makeSelectQuery(columns: selectColumns, from: from.sql, whereClause: whereClause?.asUntypedExpression.sql)
    }
    public var countSQL: [SQLFragment] {
        return makeSelectQuery(
            columns: [
                .column(
                    name: "count",
                    sql: [SQLFragment.literal("COUNT(*)")]
                )
            ],
            from: from.sql,
            whereClause: whereClause?.asUntypedExpression.sql
        )
    }
    
    public var from: Table
    public var whereClause: WhereClause?
    
    public init(columns: [SelectColumn], from: Table, where whereClause: WhereClause? = nil) {
        self.selectColumns = columns
        self.from = from
        self.whereClause = whereClause
    }
}


private func makeSelectQuery(columns: [SelectColumn], from: [SQLFragment], whereClause: [SQLFragment]?) -> [SQLFragment] {
    let columnFragment = columns.flatMap { $0.flattened }.map {
        $0.sql + [SQLFragment.literal("AS"), SQLFragment.identifier($0.name)]
        }.map { $0.sqlString() }.joined(separator: ", ")
    
    var result = [SQLFragment]()
    result.append(.literal("SELECT \(columnFragment) FROM"))
    result += from
    if let whereClause = whereClause {
        result.append(.literal("WHERE"))
        result += whereClause
    }
    
    return result
}

internal extension Selectable {
    func select<T: RowInitializable>(as: T.Type) -> TypedSelectQuery<Self, TypedExpression<Bool, T>, T> {
        let e = nil as TypedExpression<Bool, T>?
        return select(where: e, as: T.self)
    }
    
    func select<E: TypedExpressionConvertible, T>(where whereClause: E? = nil, as: T.Type) -> TypedSelectQuery<Self, E, T> where T == E.ExpressionObject {
        return .init(columns: selectColumns, from: self, where: whereClause)
    }
    
    func select<E: UntypedExpressionConvertible, T: RowInitializable>(where whereClause: E? = nil, as: T.Type) -> UntypedSelectQuery<Self, E, T> where E.ExpressionResult == Bool {
        return UntypedSelectQuery(columns: selectColumns, from: self, where: whereClause)
    }
    
    func join<E: UntypedExpressionConvertible, O: Selectable, T: RowInitializable>(_ other: O, type: JoinType = .inner, on expr: E, firstAs: T.Type)
        -> Join<T, O> where E.ExpressionResult == Bool {
            return Join<T, O>(type: type, self, other, on: expr)
    }
    
    func join<E: UntypedExpressionConvertible, O: Selectable, T: RowInitializable, U: RowInitializable>
        (_ other: O, type: JoinType = .inner, on expr: E, firstAs: T.Type, secondAs: U.Type)
        -> Join<T, U> where E.ExpressionResult == Bool {
            return Join<T, U>(type: type, self, other, on: expr)
    }
}

public extension Selectable where Self: RowInitializable {
    func select<E: TypedExpressionConvertible>(where whereClause: E? = nil) -> TypedSelectQuery<Self, E, Self> where Self == E.ExpressionObject {
        return .init(columns: selectColumns, from: self, where: whereClause)
    }
    
    func select<E: UntypedExpressionConvertible>(where whereClause: E? = nil) -> UntypedSelectQuery<Self, E, Self> where E.ExpressionResult == Bool {
        return UntypedSelectQuery(columns: selectColumns, from: self, where: whereClause)
    }
    
    func join<E: UntypedExpressionConvertible, O: Selectable>(_ other: O, type: JoinType = .inner, on expr: E)
        -> Join<Self, O> where E.ExpressionResult == Bool {
            return Join<Self, O>(type: type, self, other, on: expr)
    }
    
    internal func join<E: UntypedExpressionConvertible, O: Selectable, T: RowInitializable>(_ other: O, type: JoinType = .inner, on expr: E, secondAs: T.Type)
        -> Join<Self, T> where E.ExpressionResult == Bool {
            return Join<Self, T>(type: type, self, other, on: expr)
    }
}


//MARK: - Join

///The result of a join query.
public struct JoinResult<First: RowInitializable, Second: RowInitializable>: RowInitializable {
    ///The left-hand side of the query results.
    public let first: First
    
    ///The right-hand side of the query results.
    public let second: Second
    
    public init(first: First, second: Second) {
        self.first = first
        self.second = second
    }
    
    private enum JoinResultError: Error {
        case unnamedColumn(row: Row, index: Int)
        case multipleNames(row: Row, index: Int, names: [String])
    }
    
    private static func columns(of row: Row, withPrefix prefix: String) throws -> Row {
        var columns = [DatabaseNativeType]()
        var columnIndices = [String:Int]()
        
        for index in row.columns.indices {
            let names = row.columnIndices.filter { $0.value == index } as [(key: String, value: Int)]
            if names.count == 0 { throw JoinResultError.unnamedColumn(row: row, index: index) }
            if names.count > 1 { throw JoinResultError.multipleNames(row: row, index: index, names: names.map { $0.key })}
            
            let name = names.first!.key
            
            if name.hasPrefix(prefix) {
                columnIndices[String(name.dropFirst(prefix.count))] = columns.count
                columns.append(row.columns[index])
            }
        }
        
        return Row(columns: columns, columnIndices: columnIndices)
    }
    
    public static func from(row: Row) throws -> JoinResult {
        return JoinResult(
            first: try First.from(row: columns(of: row, withPrefix: "first.")),
            second: try Second.from(row: columns(of: row, withPrefix: "second."))
        )
    }
}

///The type of this join.
public enum JoinType {
    ///A SQL `INNER JOIN`.
    case inner
    
    ///A SQL `LEFT OUTER JOIN`.
    case leftOuter
    
    ///A SQL `RIGHT OUTER JOIN`.
    case rightOuter
    
    ///A SQL `FULL OUTER JOIN`.
    case fullOuter
    
    ///A SQL `CROSS JOIN`.
    case cross
    
    ///The SQL representation of this join.
    public var sql: [SQLFragment] {
        let name: String
        switch self {
        case .inner: name = "INNER JOIN"
        case .leftOuter: name = "LEFT OUTER JOIN"
        case .rightOuter: name = "RIGHT OUTER JOIN"
        case .fullOuter: name = "FULL OUTER JOIN"
        case .cross: name = "CROSS JOIN"
        }
        return [.literal(name)]
    }
}

///A `Selectable` representing the join of two `Selectable`s.
public struct Join<First: RowInitializable, Second: RowInitializable>: Selectable {
    public var selectColumns: [SelectColumn] { return [
        .group(name: "first", columns: first.selectColumns),
        .group(name: "second", columns: second.selectColumns),
        ]
    }
    
    public typealias Result = JoinResult<First, Second>
    
    public var sql: [SQLFragment] {
        return Array([
            [SQLFragment.openingParen],
            first.sql,
            type.sql,
            second.sql,
            [.literal("ON")],
            condition.sql,
            [.closingParen],
            ].joined())
    }
    
    var type: JoinType
    
    public var first: Selectable
    public var second: Selectable
    public var condition: UntypedExpression<Bool>
    
    public init<E: UntypedExpressionConvertible>(
        type: JoinType = .inner,
        _ first: Selectable,
        _ second: Selectable,
        on condition: E) where E.ExpressionResult == Bool {
        
        self.type = type
        self.first = first
        self.second = second
        self.condition = condition.asUntypedExpression
    }
    
    public func select() -> UntypedSelectQuery<Join, UntypedExpression<Bool>, Result> {
        let e = nil as UntypedExpression<Bool>?
        return select(where: e)
    }
    
    public func select<E: UntypedExpressionConvertible>(where whereClause: E? = nil) -> UntypedSelectQuery<Join, E, Result> where E.ExpressionResult == Bool {
        return UntypedSelectQuery(columns: selectColumns, from: self, where: whereClause)
    }
}



//MARK: - Insert

public extension Insertable {
    func insert(row: Row, or onConflict: ConflictResolution = .abort, connection: Connection) -> Future<Void> {
        let query = InsertQuery(row: row, table: self)
        return query.run(connection)
    }
}

public enum ConflictResolution {
    case abort
    case fail
    case replace
    case ignore
    
    public var sql: [SQLFragment] {
        switch self {
        case .abort: return []
        case .fail: return [.literal("OR FAIL")]
        case .replace: return [.literal("OR REPLACE")]
        case .ignore: return [.literal("OR IGNORE")]
        }
    }
}

///A SQL `INSERT` query.
public struct InsertQuery<Table: Insertable>: VoidQuery {
    public var sql: [SQLFragment] {
        return Array([
            [SQLFragment.literal("INSERT")],
            onConflict.sql,
            [SQLFragment.literal("INTO")],
            table.sql,
            columnNamesSQL,
            [SQLFragment.literal("VALUES"), .openingParen],
            Array(columns.flatMap { [SQLFragment.parameter($0), .delimiter(", ")] }.dropLast()),
            [.closingParen]
            ].joined())
    }
    
    public var columnNamesSQL: [SQLFragment] {
        if let names = columnNames {
            return [
                SQLFragment.literal(
                    "(\(names.map { sanitize(identifier: $0) }.joined(separator: ", ")))"
                )]
        } else {
            return []
        }
    }
    
    public var columnNames: [String]?
    public var columns: [DatabaseNativeType]
    public var table: Table
    public var onConflict: ConflictResolution
    public init(columnNames: [String]? = nil, columns: [DatabaseNativeType], table: Table, onConflict: ConflictResolution = .abort) {
        self.columnNames = columnNames
        self.columns = columns
        self.table = table
        self.onConflict = onConflict
    }
    
    public init(columns: [String:DatabaseNativeType], table: Table, onConflict: ConflictResolution = .abort) {
        self.init(columnNames: Array(columns.keys), columns: Array(columns.values), table: table, onConflict: onConflict)
    }
    
    public init(row: Row, table: Table, onConflict: ConflictResolution = .abort) {
        let columns = row.columnIndices.mapValues { row.columns[$0] }
        self.init(columns: columns, table: table, onConflict: onConflict)
    }
}


//MARK: - Update

///A SQL `UPDATE` query.
public extension Updatable {
    func update<
        L: TypedExpressionConvertible,
        R: TypedExpressionConvertible,
        W: TypedExpressionConvertible>(_ lhs: L, to rhs: R, where whereClause: W? = nil, connection: Connection) -> Future<Void>
        where W.ExpressionResult == Bool, Self == W.ExpressionObject,
        Self == L.ExpressionObject, Self == R.ExpressionObject,
        L.ExpressionResult == R.ExpressionResult {
            let query = TypedUpdateQuery<Self, L, R, W>(table: self, lhs: lhs, rhs: rhs, where: whereClause)
            return query.run(connection)
    }
    
    func update<
        L: UntypedExpressionConvertible,
        R: UntypedExpressionConvertible,
        W: UntypedExpressionConvertible>(_ lhs: L, to rhs: R, where whereClause: W? = nil, connection: Connection) -> Future<Void>
        where W.ExpressionResult == Bool, L.ExpressionResult == R.ExpressionResult {
            let query = UntypedUpdateQuery<Self, L, R, W>(table: self, lhs: lhs, rhs: rhs, where: whereClause)
            return query.run(connection)
    }
    
    func update<
        W: TypedExpressionConvertible>(
        columns: [(lhs: [SQLFragment], rhs: [SQLFragment])],
        where whereClause: W? = nil,
        connection: Connection
        ) -> Future<Void>
        where W.ExpressionResult == Bool, Self == W.ExpressionObject {
            let query = TypedMultiColumnUpdateQuery<Self, W>(table: self, columns: columns, where: whereClause)
            return query.run(connection)
    }
    
    func update<
        W: UntypedExpressionConvertible>(
        columns: [(lhs: [SQLFragment], rhs: [SQLFragment])],
        where whereClause: W? = nil,
        connection: Connection
        ) -> Future<Void>
        where W.ExpressionResult == Bool {
            let query = UntypedMultiColumnUpdateQuery<Self, W>(table: self, columns: columns, where: whereClause)
            return query.run(connection)
    }
    
    private func convert(row: Row) -> [(lhs: [SQLFragment], rhs: [SQLFragment])] {
        return row.columnIndices.map { (item: (key: String, value: Int)) -> (lhs: [SQLFragment], rhs: [SQLFragment]) in
            (lhs: [SQLFragment.identifier(item.key)], rhs: [SQLFragment.parameter(row.columns[item.value])])
        }
    }
    
    func update<
        W: TypedExpressionConvertible>(
        row: Row,
        where whereClause: W? = nil,
        connection: Connection
        ) -> Future<Void>
        where W.ExpressionResult == Bool, Self == W.ExpressionObject {
            
            return update(columns: convert(row: row), where: whereClause, connection: connection)
    }
    
    func update<
        W: UntypedExpressionConvertible>(
        row: Row,
        where whereClause: W? = nil,
        connection: Connection
        ) -> Future<Void>
        where W.ExpressionResult == Bool {
            return update(columns: convert(row: row), where: whereClause, connection: connection)
    }
}

///A SQL `UPDATE` query with a typed `WHERE` clause.
public struct TypedUpdateQuery<
    Table,
    L: TypedExpressionConvertible,
    R: TypedExpressionConvertible,
    WhereClause: TypedExpressionConvertible>: VoidQuery
    where WhereClause.ExpressionObject == Table,
    WhereClause.ExpressionResult == Bool,
    L.ExpressionObject == Table,
    R.ExpressionObject == Table,
L.ExpressionResult == R.ExpressionResult {
    
    public var sql: [SQLFragment] {
        return makeUpdateQuery(
            table: table.sql,
            columns: [(lhs: lhs.asUntypedExpression.sql,
                       rhs: rhs.asUntypedExpression.sql)],
            whereClause: whereClause?.asTypedExpression.sql,
            onConflict: onConflict
        )
    }
    
    public var table: Table
    public var lhs: L
    public var rhs: R
    public var whereClause: WhereClause?
    public var onConflict: ConflictResolution
    
    public init(table: Table, lhs: L, rhs: R, where whereClause: WhereClause? = nil, onConflict: ConflictResolution = .abort) {
        self.table = table
        self.lhs = lhs
        self.rhs = rhs
        self.whereClause = whereClause
        self.onConflict = onConflict
    }
}


///A SQL `UPDATE` query with an untyped `WHERE` clause.
public struct UntypedUpdateQuery<
    Table: Updatable,
    L: UntypedExpressionConvertible,
    R: UntypedExpressionConvertible,
    WhereClause: UntypedExpressionConvertible>: VoidQuery
    where WhereClause.ExpressionResult == Bool,
L.ExpressionResult == R.ExpressionResult {
    
    public var sql: [SQLFragment] {
        return makeUpdateQuery(
            table: table.sql,
            columns: [(lhs: lhs.asUntypedExpression.sql,
                       rhs: rhs.asUntypedExpression.sql)],
            whereClause: whereClause?.asUntypedExpression.sql,
            onConflict: onConflict
        )
    }
    
    public var table: Table
    public var lhs: L
    public var rhs: R
    public var whereClause: WhereClause?
    public var onConflict: ConflictResolution
    
    public init(table: Table, lhs: L, rhs: R, where whereClause: WhereClause? = nil, onConflict: ConflictResolution = .abort) {
        self.table = table
        self.lhs = lhs
        self.rhs = rhs
        self.whereClause = whereClause
        self.onConflict = onConflict
    }
}

///A SQL `UPDATE` query updating multiple columns, with an untyped `WHERE` clause.
public struct UntypedMultiColumnUpdateQuery<
    Table: Updatable,
    WhereClause: UntypedExpressionConvertible>: VoidQuery
where WhereClause.ExpressionResult == Bool {
    public var sql: [SQLFragment] {
        return makeUpdateQuery(
            table: table.sql,
            columns: columns,
            whereClause: whereClause?.asUntypedExpression.sql,
            onConflict: onConflict
        )
    }
    
    public var table: Table
    public var columns: [(lhs: [SQLFragment], rhs: [SQLFragment])]
    public var whereClause: WhereClause? = nil
    public var onConflict: ConflictResolution
    
    public init(table: Table,
                columns: [(lhs: [SQLFragment], rhs: [SQLFragment])],
                where whereClause: WhereClause? = nil,
                onConflict: ConflictResolution = .abort
        ) {
        self.table = table
        self.columns = columns
        self.whereClause = whereClause
        self.onConflict = onConflict
    }
}

///A SQL `UPDATE` query updating multiple columns, with a typed `WHERE` clause.
public struct TypedMultiColumnUpdateQuery<
    Table: Updatable,
    WhereClause: TypedExpressionConvertible>: VoidQuery
where WhereClause.ExpressionResult == Bool, WhereClause.ExpressionObject == Table {
    public var sql: [SQLFragment] {
        return makeUpdateQuery(
            table: table.sql,
            columns: columns,
            whereClause: whereClause?.asUntypedExpression.sql,
            onConflict: onConflict
        )
    }
    
    public var table: Table
    public var columns: [(lhs: [SQLFragment], rhs: [SQLFragment])]
    public var whereClause: WhereClause? = nil
    public var onConflict: ConflictResolution
    
    public init(table: Table,
                columns: [(lhs: [SQLFragment], rhs: [SQLFragment])],
                where whereClause: WhereClause? = nil,
                onConflict: ConflictResolution = .abort
        ) {
        self.table = table
        self.columns = columns
        self.whereClause = whereClause
        self.onConflict = onConflict
    }
}

private func makeUpdateQuery(
    table: [SQLFragment],
    columns: [(lhs: [SQLFragment], rhs: [SQLFragment])],
    whereClause: [SQLFragment]?,
    onConflict: ConflictResolution
    ) -> [SQLFragment] {
    
    return Array([
        [SQLFragment.literal("UPDATE")],
        onConflict.sql,
        table,
        [SQLFragment.literal("SET")],
        Array(columns.map { [$0.lhs, [.literal("=")], $0.rhs].joined() }.joined(separator: [SQLFragment.delimiter(", ")])),
        whereClause != nil ? [SQLFragment.literal("WHERE")] : [],
        whereClause ?? []
        ].joined()
    )
    
}




//MARK: - Delete

public extension Deletable {
    func delete<E: TypedExpressionConvertible>(where whereClause: E? = nil, connection: Connection) -> Future<Void>
        where E.ExpressionResult == Bool, Self == E.ExpressionObject {
            let query = TypedDeleteQuery<Self, E>(from: self, where: whereClause)
            return query.run(connection)
    }
    
    func delete<E: UntypedExpressionConvertible>(where whereClause: E? = nil, connection: Connection) -> Future<Void>
        where E.ExpressionResult == Bool {
            let query = UntypedDeleteQuery(from: self, where: whereClause)
            return query.run(connection)
    }
}

///A SQL `DELETE` query with a typed `WHERE` clause.
public struct TypedDeleteQuery<Table, WhereClause: TypedExpressionConvertible>: VoidQuery
where WhereClause.ExpressionObject == Table, WhereClause.ExpressionResult == Bool {
    public var sql: [SQLFragment] {
        return makeDeleteQuery(from: from.sql, whereClause: whereClause?.asTypedExpression.sql)
    }
    
    public var from: Table
    public var whereClause: WhereClause?
    
    public init(from: Table, where whereClause: WhereClause? = nil) {
        self.from = from
        self.whereClause = whereClause
    }
}

///A SQL `DELETE` query with an untyped `WHERE` clause.
public struct UntypedDeleteQuery<Table: Deletable, WhereClause: UntypedExpressionConvertible>: VoidQuery
where WhereClause.ExpressionResult == Bool {
    public var sql: [SQLFragment] {
        return makeDeleteQuery(from: from.sql, whereClause: whereClause?.asUntypedExpression.sql)
    }
    
    public var from: Table
    public var whereClause: WhereClause?
    
    public init(from: Table, where whereClause: WhereClause? = nil) {
        self.from = from
        self.whereClause = whereClause
    }
}


private func makeDeleteQuery(from: [SQLFragment], whereClause: [SQLFragment]?) -> [SQLFragment] {
    return Array([
        [.literal("DELETE FROM")],
        from,
        whereClause != nil ? [.literal("WHERE")] : [],
        whereClause ?? []
        ].joined()
    )
}
