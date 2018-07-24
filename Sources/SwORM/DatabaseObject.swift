import Foundation
import Async

///A DatabaseObject represents a model object that may be saved in a database table.
///An instance of a DatabaseObject corresponds to a row in the backing table,
///and the properties of the object correspond to the columns of that row.
///
///To implement a DatabaseObject, you must provide the following static properties:
/// - `primaryKey`: The key path of this object's primary key.
/// - `tableName`: The name of the database table backing this `DatabaseObject`.
/// - `allColumns`: The key path and `CodingKey` of each column of this object.
///
///Here's an example implementation of a `DatabaseObject`:
///
///    struct TestObject: DatabaseObject, Equatable {
///        static let tableName: String = "test_object"
///
///        var id: Int64?
///        var bool: Bool
///        var double: Double
///        var int: Int
///        var string: String
///        var data: Data
///        var optionalString: String?
///
///        static let primaryKey: KeyPath<TestObject, Int64?> = \.id
///        static let allColumns: [(PartialKeyPath<TestObject>, CodingKey)] = [
///            (\TestObject.id, CodingKeys.id),
///            (\TestObject.bool, CodingKeys.bool),
///            (\TestObject.double, CodingKeys.double),
///            (\TestObject.int, CodingKeys.int),
///            (\TestObject.string, CodingKeys.string),
///            (\TestObject.data, CodingKeys.data),
///            (\TestObject.optionalString, CodingKeys.optionalString)
///        ]
///    }
public protocol DatabaseObject: Codable, RowInitializable {
    ///A key path to this object's primary key.
    ///
    ///An instance of a `DatabaseObject` will have the value of the primary key in this property,
    ///or `nil` if this object has not yet been inserted into the database.
    static var primaryKey: KeyPath<Self, Int64?> { get }
    
    ///The name of the table backing this `DatabaseObject`.
    static var tableName: String { get }
    
    ///The key path and `CodingKey` of each column of this object.
    static var allColumns: [(PartialKeyPath<Self>, CodingKey)] { get }
}

///An error raised by `DatabaseObject.find(_:connection:)`.
public enum FindError<O: DatabaseObject>: Error {
    ///Multiple rows were found with this primary key.
    case tooManyRows([O])
}

public extension DatabaseObject {
    ///Converts this `DatabaseObject` to a `Row`.
    public func toRow() throws -> Row {
        let row = try RowEncoder().encode(self)
        
        //Add null values
        for (keyPath, codingKey) in Self.allColumns {
            if row.columnIndices[codingKey.stringValue] == nil {
                if keyPath == Self.primaryKey { continue }
                row.columnIndices[codingKey.stringValue] = row.columns.endIndex
                row.columns.append(.null)
            }
        }
        
        return row
    }
    
    ///Converts a `Row` to a `DatabaseObject`.
    public static func from(row: Row) throws -> Self {
        //Remove table name prefixes
        let r = Row(columns: row.columns, columnIndices: Dictionary(uniqueKeysWithValues: row.columnIndices.compactMap {
            let prefix = tableName + "."
            if $0.key.hasPrefix(prefix) { return (key: String($0.key.dropFirst(prefix.count)), value: $0.value) }
            else if $0.key.contains(".") { return nil }
            else { return $0 }
        }))
        
        return try RowDecoder().decode(Self.self, from: r)
    }
    
    ///Returns the column name for a key path, by looking it up in `allColumns`.
    public static func name<T: DatabaseType>(of keyPath: KeyPath<Self, T>) -> String? {
        return allColumns.index { $0.0 as PartialKeyPath<Self> == keyPath }.map { allColumns[$0].1.stringValue }
    }
    
    ///Returns the column name for a key path, by looking it up in `allColumns`.
    public static func name<T: DatabaseType>(of keyPath: KeyPath<Self, T?>) -> String? {
        return allColumns.index { $0.0 as PartialKeyPath<Self> == keyPath }.map { allColumns[$0].1.stringValue }
    }
    
    ///Returns the column name for a key path, by looking it up in `allColumns`.
    public static func name(of keyPath: PartialKeyPath<Self>) -> String? {
        return allColumns.index { $0.0 == keyPath }.map { allColumns[$0].1.stringValue }
    }
    
    ///Returns the SQL for this database object's table.
    public var sql: [SQLFragment] {
        return [.identifier(Self.tableName)]
    }
    
    ///Returns the `DatabaseObject` with the given primary key, or `nil` if none was found.
    public static func find(_ id: Int64, connection: Connection) -> Future<Self?> {
        return select(where: primaryKey == (id as Int64?)).all(connection).map(to: Self?.self) {
            guard !($0.count > 1) else { throw FindError.tooManyRows($0) }
            return $0.first
        }
    }
    
    ///Inserts or updates this item in the database.
    ///
    ///If the primary key of this object is `nil`, inserts a new row in the database.  Otherwise, updates an existing row.
    /// - returns: The primary key of the database row.
    /// - warning: This function does NOT modify the primary key property of the DatabaseObject, even if it was `nil` before calling this function.
    ///If you need the inserted row ID, use the return value of this function.  If you need to call `save` multiple times
    ///after inserting a new row, manually update the primary key property to the return value of this function.
    public func save(_ connection: Connection) -> Future<Int64> {
        do {
            let row = try toRow()
            if let id = self[keyPath: Self.primaryKey] {
                return Self.asSelectable.update(row: row, where: Self.primaryKey == (id as Int64?), connection: connection).map(to: Int64.self) { _ in
                    return id
                }
            } else {
                return Self.asSelectable.insert(row: row, connection: connection).flatMap(to: Int64.self) { connection.lastInsertedRow() }
            }
        } catch {
            return connection.eventLoop.newFailedFuture(error: error)
        }
    }
    
    ///Deletes this instance from the database.
    public func destroy(_ connection: Connection) -> Future<Void> {
        if let id = self[keyPath: Self.primaryKey] {
            return Self.asSelectable.delete(where: Self.primaryKey == (id as Int64?), connection: connection)
        } else {
            return connection.eventLoop.newSucceededFuture(result: ())
        }
    }
    
    ///Returns a `Selectable` object representing this database.  You shouldn't usually need to call this directly;
    ///use `select`, `update`, or `delete` on this `DatabaseObject` metatype instead.
    public static var asSelectable: Table {
        return Table(name: tableName, columns: [SelectColumn.group(
            name: tableName,
            columns: allColumns
                .map { $0.1.stringValue }
                .map { .column(name: $0, sql: [.identifier(tableName), .delimiter("."), .identifier($0)]) })
            ])
    }
    
    ///Returns a `SELECT` query which queries this `DatabaseObject`.
    static func select() -> UntypedSelectQuery<Table, UntypedExpression<Bool>, Self> {
        return asSelectable.select(as: Self.self)
    }
    
    ///Returns a `SELECT` query which queries this `DatabaseObject`.
    /// - parameter where: The `WHERE` clause to filter the results of this query.
    static func select<E: TypedExpressionConvertible>(where whereClause: E? = nil) -> TypedSelectQuery<Table, E, Self> where E.ExpressionObject == Self {
        return asSelectable.select(where: whereClause, as: Self.self)
    }
    
    ///Returns a `Join` combining this `DatabaseObject` with another `Selectable`.
    ///- parameter other: The `Selectable` to join with.
    ///- parameter type: The type of join to use.  Defaults to `.inner`.
    ///- parameter expr: A boolean expression to join on.
    static func join<E: UntypedExpressionConvertible, O: Selectable>(_ other: O, type: JoinType = .inner, on expr: E) -> Join<Self, O>
        where E.ExpressionResult == Bool {
            return asSelectable.join(other, type: type, on: expr, firstAs: Self.self, secondAs: O.self)
    }
    
    ///Returns a `Join` combining this `DatabaseObject` with another `Selectable`.
    ///- parameter other: The `Selectable` to join with.
    ///- parameter type: The type of join to use.  Defaults to `.inner`.
    ///- parameter expr: A boolean expression to join on.
    ///- parameter as: A type to map the result columns of `other` to.
    static func join<E: UntypedExpressionConvertible, O: Selectable, T: RowInitializable>(_ other: O, type: JoinType = .inner, on expr: E, as: T.Type)
        -> Join<Self, T> where E.ExpressionResult == Bool {
            return asSelectable.join(other, type: type, on: expr, firstAs: Self.self, secondAs: T.self)
    }
    
    ///Returns a `Join` combining this `DatabaseObject` with another `DatabaseObject`.
    ///- parameter other: The `DatabaseObject` to join with.
    ///- parameter type: The type of join to use.  Defaults to `.inner`.
    ///- parameter expr: A boolean expression to join on.
    static func join<O: DatabaseObject, E: UntypedExpressionConvertible>(_ other: O.Type, type: JoinType = .inner, on expr: E) -> Join<Self, O>
        where E.ExpressionResult == Bool {
            return asSelectable.join(other.asSelectable, type: type, on: expr, firstAs: Self.self, secondAs: O.self)
    }
    
    ///Returns a `Join` combining this `DatabaseObject` with a foreign key column.
    ///- parameter key: The `ForeignKey` to join.
    ///- parameter type: The type of join to use.  Defaults to `.inner`.
    static func join<O: DatabaseObject>(_ key: KeyPath<Self, ForeignKey<O>>, type: JoinType = .inner) -> Join<Self, O> {
        let expr = UntypedExpression<Bool>.binaryOperator(key.asTypedExpression, "=", O.primaryKey.asTypedExpression)
        return join(O.self, type: type, on: expr)
    }
    
    ///Executes an `UPDATE` query, which updates one epxression on this `DatabaseObject` to another.
    ///- parameter lhs: The left-hand side of the update expression.
    ///- parameter rhs: The right-hand side of the update expression.
    ///- parameter whereClause: The `WHERE` clause to apply to the query.
    ///- parameter connection: The database connection to use.
    static func update<
        L: TypedExpressionConvertible,
        R: TypedExpressionConvertible,
        W: TypedExpressionConvertible>(_ lhs: L, to rhs: R, where whereClause: W? = nil, connection: Connection) -> Future<Void>
        where W.ExpressionResult == Bool, Self == W.ExpressionObject,
        Self == L.ExpressionObject, Self == R.ExpressionObject,
        L.ExpressionResult == R.ExpressionResult {
            return asSelectable.update(
                lhs, to: rhs,
                where: ((whereClause?.asTypedExpression.sql) as [SQLFragment]?).map(UntypedExpression.init),
                connection: connection
            )
    }
    
    ///Executes an `UPDATE` query, which updates one epxression on this `DatabaseObject` to another.
    ///- parameter lhs: The left-hand side of the update expression.
    ///- parameter rhs: The right-hand side of the update expression.
    ///- parameter whereClause: The `WHERE` clause to apply to the query.
    ///- parameter connection: The database connection to use.
    static func update<
        L,
        R: TypedExpressionConvertible,
        W: TypedExpressionConvertible>(_ lhs: KeyPath<Self, L>, to rhs: R, where whereClause: W? = nil, connection: Connection) -> Future<Void>
        where W.ExpressionResult == Bool, Self == W.ExpressionObject,
        Self == R.ExpressionObject,
        L == R.ExpressionResult {
            return asSelectable.update(
                lhs, to: rhs,
                where: ((whereClause?.asTypedExpression.sql) as [SQLFragment]?).map(UntypedExpression.init),
                connection: connection
            )
    }
    
    ///Executes an `UPDATE` query, which updates one column on this `DatabaseObject` to another.
    ///- parameter lhs: The left-hand side of the update expression.
    ///- parameter rhs: The right-hand side of the update expression.
    ///- parameter whereClause: The `WHERE` clause to apply to the query.
    ///- parameter connection: The database connection to use.
    static func update<
        V: DatabaseType,
        W: TypedExpressionConvertible>(_ lhs: KeyPath<Self, V>, to rhs: KeyPath<Self, V>, where whereClause: W? = nil, connection: Connection) -> Future<Void>
        where W.ExpressionResult == Bool, Self == W.ExpressionObject {
            return asSelectable.update(
                lhs, to: rhs,
                where: ((whereClause?.asTypedExpression.sql
                    ) as [SQLFragment]?).map(UntypedExpression.init),
                connection: connection
            )
    }
    
    ///Executes an `UPDATE` query, which updates one epxression on this `DatabaseObject` to another.
    ///- parameter lhs: The left-hand side of the update expression.
    ///- parameter rhs: The right-hand side of the update expression.
    ///- parameter whereClause: The `WHERE` clause to apply to the query.
    ///- parameter connection: The database connection to use.
    static func update<
        L: TypedExpressionConvertible,
        R,
        W: TypedExpressionConvertible>(_ lhs: L, to rhs: KeyPath<Self, R>, where whereClause: W? = nil, connection: Connection) -> Future<Void>
        where W.ExpressionResult == Bool, Self == W.ExpressionObject,
        L.ExpressionResult == R {
            return asSelectable.update(
                lhs, to: rhs,
                where: ((whereClause?.asTypedExpression.sql) as [SQLFragment]?).map(UntypedExpression.init),
                connection: connection
            )
    }
    
    
    ///Executes an `UPDATE` query, which updates one epxression on this `DatabaseObject` to another.
    ///- parameter lhs: The left-hand side of the update expression.
    ///- parameter rhs: The right-hand side of the update expression.
    ///- parameter whereClause: The `WHERE` clause to apply to the query.
    static func update<
        L: TypedExpressionConvertible,
        R: TypedExpressionConvertible
        >(_ lhs: L, to rhs: R, where whereClause: KeyPath<Self, Bool>? = nil, connection: Connection) -> Future<Void>
        where Self == L.ExpressionObject, Self == R.ExpressionObject,
        L.ExpressionResult == R.ExpressionResult {
            return asSelectable.update(
                lhs, to: rhs,
                where: ((whereClause?.asTypedExpression.sql) as [SQLFragment]?).map(UntypedExpression.init),
                connection: connection
            )
    }
    
    ///Executes an `UPDATE` query, which updates one epxression on this `DatabaseObject` to another.
    ///- parameter lhs: The left-hand side of the update expression.
    ///- parameter rhs: The right-hand side of the update expression.
    ///- parameter whereClause: The `WHERE` clause to apply to the query.
    static func update<
        L,
        R: TypedExpressionConvertible
        >(_ lhs: KeyPath<Self, L>, to rhs: R, where whereClause: KeyPath<Self, Bool>? = nil, connection: Connection) -> Future<Void>
        where Self == R.ExpressionObject, L == R.ExpressionResult {
            return asSelectable.update(
                lhs, to: rhs,
                where: ((whereClause?.asTypedExpression.sql) as [SQLFragment]?).map(UntypedExpression.init),
                connection: connection
            )
    }
    
    ///Executes an `UPDATE` query, which updates one column on this `DatabaseObject` to another.
    ///- parameter lhs: The left-hand side of the update expression.
    ///- parameter rhs: The right-hand side of the update expression.
    ///- parameter whereClause: The `WHERE` clause to apply to the query.
    static func update<
        V: DatabaseType
        >(_ lhs: KeyPath<Self, V>, to rhs: KeyPath<Self, V>, where whereClause: KeyPath<Self, Bool>? = nil, connection: Connection) -> Future<Void>
    {
        return asSelectable.update(
            lhs, to: rhs,
            where: ((whereClause?.asTypedExpression.sql) as [SQLFragment]?).map(UntypedExpression.init),
            connection: connection
        )
    }
    
    ///Executes an `UPDATE` query, which updates one epxression on this `DatabaseObject` to another.
    ///- parameter lhs: The left-hand side of the update expression.
    ///- parameter rhs: The right-hand side of the update expression.
    ///- parameter whereClause: The `WHERE` clause to apply to the query.
    static func update<
        L: TypedExpressionConvertible,
        R>(_ lhs: L, to rhs: KeyPath<Self, R>, where whereClause: KeyPath<Self, Bool>? = nil, connection: Connection) -> Future<Void>
        where L.ExpressionResult == R {
            return asSelectable.update(
                lhs, to: rhs,
                where: ((whereClause?.asTypedExpression.sql) as [SQLFragment]?).map(UntypedExpression.init),
                connection: connection
            )
    }
    
    ///Executes a `DELETE` query, which removes matching rows from the table.
    ///- parameter whereClause: The `WHERE` clause to filter the rows to remove.
    static func delete<E: TypedExpressionConvertible>(where whereClause: E? = nil, connection: Connection) -> Future<Void>
        where E.ExpressionResult == Bool, E.ExpressionObject == Self {
            return asSelectable.delete(where: ((whereClause?.asTypedExpression.sql) as [SQLFragment]?).map(UntypedExpression.init), connection: connection)
    }
}
