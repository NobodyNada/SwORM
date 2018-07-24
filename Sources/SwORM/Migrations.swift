import Foundation
import Async

///A `Migrator` handles the migration from one database schema version to another.
public struct Migrator {
    public let database: Database
    public let worker: Worker
    
    public init(database: Database, worker: Worker) {
        self.database = database
        self.worker = worker
    }
    
    ///If the current schema version is less than the specified version, runs the `migration` block and updates the database schema version.
    public func migrate(to version: Int, migration: @escaping (Connection) -> Future<Void>) throws {
        return try database.transaction(on: worker) { connection in
            return self.database.loadSchemaVersion(on: self.worker).flatMap(to: Void.self) { schemaVersion in
                if schemaVersion < version {
                    return migration(connection).flatMap(to: Void.self) {
                        self.database.setSchemaVersion(to: version, on: self.worker)
                    }
                }
                return connection.eventLoop.newSucceededFuture(result: ())
            }
            }.wait()
    }
}

//A "fake" DatabaseObject that lets us instantiate a TableDef without a DatabaseObject.
public struct _NullDatabaseObject: DatabaseObject {
    
    private static func used() -> Never { fatalError("_NullDataseObject should never be used") }
    
    public static var primaryKey: KeyPath<_NullDatabaseObject, Int64?> { used() }
    public static var tableName: String { used() }
    public static var allColumns: [(PartialKeyPath<_NullDatabaseObject>, CodingKey)] { used() }
}

///A `TableDef` is a builder object that describes the addition of columns and indexes to a table.
public struct TableDef<T: DatabaseObject> {
    ///The name of the table.
    public var name: String
    
    ///The columns to add.
    public var columns: [Column] = []
    
    ///Represents the creation or removal of an index.
    public enum IndexOperation {
        ///Adds an index with the specified columns and name.
        case add(columns: [String], name: String)
        
        ///Removes the index with the specified name.
        case drop(name: String)
    }
    ///The creations and removals of indexes to perform.
    public var indices: [IndexOperation] = []
    
    public init(name: String) {
        self.name = name
    }
    
    ///A `Column` represents the addition of a column to a table.
    public struct Column {
        ///The name of this column.
        public var name: String
        
        ///The SQL type of this column.
        public var type: ColumnType
        
        ///The SQL of this column's name, type, and constraints.
        public var sql: [SQLFragment] {
            return [SQLFragment.identifier(name)] + type.sql + Array(constraints.map { $0.sql }.joined())
        }
        
        public enum ColumnType: Equatable {
            case integer
            case numeric
            case text
            case varchar(Int)
            case blob
            case datetime
            
            public var sql: [SQLFragment] {
                let name: String
                switch self {
                case .integer: name = "INTEGER"
                case .numeric: name = "NUMERIC"
                case .text: name = "TEXT"
                case .varchar(let length): name = "VARCHAR(\(length))"
                case .blob: name = "BLOB"
                case .datetime: name = "DATETIME"
                }
                return [.literal(name)]
            }
        }
        public enum Constraint {
            case primaryKey
            case unique
            case notNull
            case _default([SQLFragment])
            case _foreignKey(table: String, column: String)
            case _check([SQLFragment])
            
            public var sql: [SQLFragment] {
                switch self {
                case .primaryKey: return [.literal("PRIMARY KEY"), .dialectSpecific([.sqlite:[], .mysql:[.literal("AUTO_INCREMENT")]])]
                case .unique: return [.literal("UNIQUE")]
                case .notNull: return [.literal("NOT NULL")]
                case ._default(let e): return [.literal("DEFAULT"), .openingParen] + e + [.closingParen]
                case ._foreignKey(let table, let column): return [.literal("REFERENCES"), .identifier(table), .openingParen, .identifier(column), .closingParen]
                case ._check(let e): return [.literal("CHECK"), .openingParen] + e + [.closingParen]
                }
            }
            
            public static func `default`<E: UntypedExpressionConvertible>(_ expr: E) -> Constraint {
                return ._default(expr.asUntypedExpression.sql)
            }
            public static func `default`<E: TypedExpressionConvertible>(_ expr: E) -> Constraint where E.ExpressionObject == T {
                return ._default(expr.asUntypedExpression.sql)
            }
            
            public static func foreignKey(table: String, column: String) -> Constraint {
                return ._foreignKey(table: table, column: column)
            }
            public static func foreignKey<O: DatabaseObject>(referencing: O.Type) -> Constraint {
                return ._foreignKey(table: O.tableName, column: O.name(of: O.primaryKey)!)
            }
            public static func foreignKey<O: DatabaseObject>(_ k: KeyPath<T, ForeignKey<O>>) -> Constraint {
                return ._foreignKey(table: O.tableName, column: O.name(of: O.primaryKey)!)
            }
            public static func foreignKey<O: DatabaseObject>(_ k: KeyPath<T, ForeignKey<O>?>) -> Constraint {
                return ._foreignKey(table: O.tableName, column: O.name(of: O.primaryKey)!)
            }
            
            public static func check<E: UntypedExpressionConvertible>(_ expr: E) -> Constraint where E.ExpressionResult == Bool {
                return ._check(expr.asUntypedExpression.sql)
            }
            public static func check<E: TypedExpressionConvertible>(_ expr: E) -> Constraint where E.ExpressionObject == T, E.ExpressionResult == Bool {
                return ._check(expr.asTypedExpression.sql)
            }
        }
        public var constraints: [Constraint]
        
        public init(name: String, type: ColumnType, constraints: [Constraint]) {
            self.name = name
            self.type = type
            self.constraints = constraints
        }
    }
    
    ///Adds a column to the table.
    public mutating func add(column: Column) {
        columns.append(column)
    }
    
    
    ///Adds an index to the table.
    ///- parameter column: The column to index.
    ///- parameter name: The name of the index.  If not specified, a default name will be generated.
    public mutating func index(_ column: String, name: String? = nil) {
        indices.append(.add(columns: [column], name: name ?? defaultName(index: [column])))
    }
    
    ///Adds an index to the table.
    ///- parameter column: The column to index.
    ///- parameter name: The name of the index.  If not specified, a default name will be generated.
    public mutating func index<V: DatabaseType>(_ column: KeyPath<T, V>, name: String? = nil) {
        index(T.name(of: column)!, name: name)
    }
    
    ///Adds an index to the table.
    ///- parameter column: The column to index.
    ///- parameter name: The name of the index.  If not specified, a default name will be generated.
    public mutating func index<V: DatabaseType>(_ column: KeyPath<T, V?>, name: String? = nil) {
        index(T.name(of: column)!, name: name)
    }
    
    
    ///Adds a composite index to the table.
    ///- parameter columns: The columns to index.
    ///- parameter name: The name of the index.  If not specified, a default name will be generated.
    public mutating func compositeIndex(_ columns: [String], name: String? = nil) {
        indices.append(.add(columns: columns, name: name ?? defaultName(index: columns)))
    }
    
    ///Adds a composite index to the table.
    ///- parameter columns: The columns to index.
    ///- parameter name: The name of the index.  If not specified, a default name will be generated.
    public mutating func compositeIndex(_ columns: String..., name: String? = nil) {
        compositeIndex(columns, name: name)
    }
    
    ///Adds a composite index to the table.
    ///- parameter columns: The columns to index.
    ///- parameter name: The name of the index.  If not specified, a default name will be generated.
    public mutating func compositeIndex(_ columns: PartialKeyPath<T>..., name: String? = nil) {
        compositeIndex(columns.map { T.name(of: $0)! }, name: name)
    }
    
    
    ///Removes an index from the table.
    ///- parameter name: The name of the index to remove.
    public mutating func dropIndex(named name: String) {
        indices.append(.drop(name: name))
    }
    
    ///Removes an index from the table.  The index must have been created using the default name.
    ///- parameter column: The column to remove the index from.
    public mutating func drop(index column: String) {
        dropIndex(named: defaultName(index: [column]))
    }
    
    ///Removes an index from the table.  The index must have been created using the default name.
    ///- parameter column: The column to remove the index from.
    public mutating func drop<V: DatabaseType>(index column: KeyPath<T, V>) {
        drop(index: T.name(of: column)!)
    }
    
    ///Removes an index from the table.  The index must have been created using the default name.
    ///- parameter column: The column to remove the index from.
    public mutating func drop<V: DatabaseType>(index column: KeyPath<T, V?>) {
        drop(index: T.name(of: column)!)
    }
    
    
    ///Removes a compisite index from the table.  The index must have been created using the default name.
    ///- parameter columns: The columns to remove the index from.
    public mutating func drop(compositeIndex columns: [String]) {
        dropIndex(named: defaultName(index: columns))
    }
    
    ///Removes a compisite index from the table.  The index must have been created using the default name.
    ///- parameter columns: The columns to remove the index from.
    public mutating func drop(compositeIndex columns: String..., name: String? = nil) {
        drop(compositeIndex: columns)
    }
    
    ///Removes a compisite index from the table.  The index must have been created using the default name.
    ///- parameter columns: The columns to remove the index from.
    public mutating func drop(compositeIndex columns: PartialKeyPath<T>..., name: String? = nil) {
        drop(compositeIndex: columns.map { T.name(of: $0)! })
    }
    
    
    
    private func defaultName(index: [String]) -> String {
        //Simple mangling scheme to prevent two indices from accidentally having the same name
        return (["SwORM_index", String(index.count), String(name.count), name] + index.flatMap { [String($0.count), $0] }).joined(separator: "_")
    }
    
    private func writeIndices(connection: Connection) -> Future<Void> {
        return indices.map { index in { () -> Future<Void> in
            let sql: [SQLFragment]
            
            switch index {
            case .add(let columns, let indexName):
                let columnsSQL = (columns.map { [SQLFragment.identifier($0)] }).joined(separator: [.delimiter(", ")])
                sql = [
                    .literal("CREATE INDEX"),
                    .identifier(indexName),
                    .literal("ON"),
                    .identifier(self.name),
                    .openingParen] +
                    [SQLFragment](columnsSQL) +
                    [.closingParen]
            case .drop(let name):
                sql = [
                    .literal("DROP INDEX"),
                    .identifier(name)
                ]
            }
            
            return connection.execute(sql.sqlString(dialect: connection.database.dialect)).map(to: Void.self) { _ in }
            }}.reduce(connection.eventLoop.future()) { $0.then($1 as () -> Future<Void>) }
    }
    
    internal func create(connection: Connection) -> Future<Void> {
        return connection.database.transaction(on: connection.eventLoop) { connection in
            let columns: [Column]
            //If this database does not support the `DATETIME` type, replace it with `TEXT`.
            if connection.database.supportsDatetime {
                columns = self.columns
            } else {
                columns = self.columns.map {
                    var c = $0
                    if c.type == .datetime { c.type = .text }
                    return c
                }
            }
            
            let columnsSQL =  Array(columns.map { $0.sql }.joined(separator: [SQLFragment.delimiter(", ")]))
            let sql: [SQLFragment] = Array([
                [
                    .literal("CREATE TABLE"),
                    .identifier(self.name),
                    .openingParen,
                    ],
                columnsSQL,
                [.closingParen]
                ].joined())
            
            return connection.execute(
                sql.sqlString(dialect: connection.database.dialect),
                parameters: sql.sqlParameters
                ).flatMap(to: Void.self) { _ in self.writeIndices(connection: connection) }
        }
    }
    
    internal func alter(connection: Connection) -> Future<Void> {
        return connection.database.transaction(on: connection.eventLoop) { connection in
            let results: [() -> Future<Void>] = self.columns.map { c in { () -> Future<Void> in
                var column = c
                if column.type == .datetime && !connection.database.supportsDatetime { column.type = .text }
                let sql: [SQLFragment] = [
                    .literal("ALTER TABLE"), .identifier(self.name), .literal("ADD COLUMN")
                    ] + column.sql
                
                return connection.execute(sql.sqlString(dialect: connection.database.dialect)).map(to: Void.self) { _ in }
                }}
            
            return results
                .reduce(connection.eventLoop.future()) { $0.then($1 as () -> Future<Void>)
                    .flatMap(to: Void.self) { _ in self.writeIndices(connection: connection) }
            }
        }
    }
}

public extension Connection {
    ///Creates a new table.
    ///- parameter name: The name of this table.
    ///- parameter builder: A closure which accepts a `TableDef` and adds columns and indices to it.
    public func create(table name: String, builder: (inout TableDef<_NullDatabaseObject>) throws -> ()) -> Future<Void> {
        var table = TableDef<_NullDatabaseObject>(name: name)
        do {
            try builder(&table)
        } catch {
            return eventLoop.newFailedFuture(error: error)
        }
        return table.create(connection: self)
    }
    
    ///Creates a new table.
    ///- parameter table: A `DatabaseObject` backed by the table.
    ///- parameter builder: A closure which accepts a `TableDef` and adds columns and indices to it.
    public func create<O: DatabaseObject>(table: O.Type, builder: (inout TableDef<O>) throws -> ()) -> Future<Void> {
        var table = TableDef<O>(name: O.tableName)
        do {
            try builder(&table)
        } catch {
            return eventLoop.newFailedFuture(error: error)
        }
        return table.create(connection: self)
    }
    
    
    ///Renames a table
    ///- parameter old: The old name of this table.
    ///- parameter new: The new name of this table.
    public func renameTable(old: String, new: String) -> Future<Void> {
        let sql: [SQLFragment] = [
            .literal("ALTER TABLE"), .identifier(old), .literal("RENAME TO"), .identifier(new)
        ]
        return execute(sql.sqlString(dialect: database.dialect)).map(to: Void.self) { _ in }
    }
    
    
    ///Adds columns and/or indices to a table.
    ///- parameter name: The name of this table.
    ///- parameter builder: A closure which accepts a `TableDef` and adds columns and indices to it.
    public func alter(table name: String, builder: (inout TableDef<_NullDatabaseObject>) throws -> ()) -> Future<Void> {
        var table = TableDef<_NullDatabaseObject>(name: name)
        do {
            try builder(&table)
        } catch {
            return eventLoop.newFailedFuture(error: error)
        }
        return table.alter(connection: self)
    }
    
    ///Adds columns and/or indices to a table.
    ///- parameter table: A `DatabaseObject` backed by the table.
    ///- parameter builder: A closure which accepts a `TableDef` and adds columns and indices to it.
    public func alter<O: DatabaseObject>(table: O.Type, builder: (inout TableDef<O>) throws -> ()) -> Future<Void> {
        var table = TableDef<O>(name: O.tableName)
        do {
            try builder(&table)
        } catch {
            return eventLoop.newFailedFuture(error: error)
        }
        return table.alter(connection: self)
    }
    
    ///Removes a table.
    ///- parameter table: The table to remove.
    public func drop(table: String) -> Future<Void> {
        let sql = [SQLFragment.literal("DROP TABLE"), .identifier(table)]
        return execute(sql.sqlString(dialect: database.dialect)).map(to: Void.self) { _ in }
    }
    
    ///Removes a table.
    ///- parameter table: The table to remove.
    public func drop<O: DatabaseObject>(table: O.Type) -> Future<Void> {
        return drop(table: table.tableName)
    }
}
