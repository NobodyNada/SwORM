//
//  Database.swift
//  SwORM
//
//  Created by NobodyNada on 2/16/18.
//

import Foundation
import Async

public enum SQLDialect {
    case sqlite
    case mysql
}

///A Database represents a single database, and can create `Connection`s to execute queries on.
public protocol Database: class {
    ///Opens a new connection to this database.  This method is guaranteed to be called once for each thread that accesses the database.
    ///You should never call this method directly; use `connection()` instead, which caches and resuses connections per-thread.
    func _newConnection(on worker: Worker) -> Future<Connection>
    
    ///Whether this Database supports the SQL DATETIME type.
    ///If `false`, `TEXT` will instead be used to store dates.  The default is `true`.
    var supportsDatetime: Bool { get }
    
    ///Returns the schema version of this database.  Used to track migrations.
    ///
    ///The implementation of this method depends on the database.  For example, on SQLite the `user_version` pragma can be used.
    func loadSchemaVersion(on worker: Worker) -> Future<Int>
    
    ///Updates the schema version of this database.
    /// - parameter version: The new schema version.
    func setSchemaVersion(to version: Int, on worker: Worker) -> Future<Void>
    
    var dialect: SQLDialect { get }
}

///A Connection represents a connection to a `Database`.
//Queries must be executed on a `Connection`, and a single `Database` can have multiple `Connection`s.
public protocol Connection: Worker {
    ///Executes a query on the database.
    /// - parameter query: The query to execute, as a SQL string.
    /// - parameter parameters: The parameters to bind to the query.
    func execute(_ query: String, parameters: [DatabaseType?]) -> Future<[Row]>
    
    ///The Database which created this Connection.
    var database: Database { get }
    
    ///Returns the primary key of the most recently inserted row.
    func lastInsertedRow() -> Future<Int64>
}
public extension Connection {
    ///Executes a query on the database.
    /// - parameter query: The query to execute, as a SQL string.
    /// - parameter parameters: The parameters to bind to the query.
    @discardableResult
    func execute(_ query: String, parameters: DatabaseType?...) -> Future<[Row]> {
        return execute(query, parameters: parameters)
    }
}

private var connections = [ObjectIdentifier:[pthread_t:Future<Connection>]]()
private var connectionsLock = NSLock()

public extension Database {
    var supportsDatetime: Bool { return true }
    
    var dialect: SQLDialect { return .sqlite }
    
    ///Returns a connection to this database.  The connection must not be used outside of the current thread.
    func connection(on worker: Worker) -> Future<Connection> {
        connectionsLock.lock()
        defer { connectionsLock.unlock() }
        
        let identifier = ObjectIdentifier(self)
        if connections[identifier] == nil { connections[identifier] = .init() }
        if let connection = connections[identifier]![pthread_self()] { return connection }
        else {
            let connection = _newConnection(on: worker)
            connections[identifier]![pthread_self()] = connection
            return connection
        }
    }
    
    //Creates a connection a with the `connection()` function and executes a query on it.
    @discardableResult
    func execute(_ query: String, parameters: [DatabaseType?], on worker: Worker) -> Future<[Row]> {
        return connection(on: worker).flatMap(to: [Row].self) { $0.execute(query, parameters: parameters) }
    }
    
    //Creates a connectionwith the `connection()` function and executes a query on it.
    @discardableResult
    func execute(_ query: String, parameters: DatabaseType?..., on worker: Worker) -> Future<[Row]> {
        return execute(query, parameters: parameters, on: worker)
    }
    
    ///Runs a closure inside of a database transaction.
    /// - parameter execute: The closure to execute.  The closure should use the provided `Connection` to run queries.
    /// - returns: The result of the closure, or an error if the transaction could not be performed or the closure threw in error.
    public func transaction<T>(on worker: Worker, execute: @escaping (Connection) -> Future<T>) -> Future<T> {
        let connection = self.connection(on: worker)
        return connection.flatMap(to: T.self) { connection in
            return connection.execute("BEGIN")
                .flatMap(to: T.self) { _ in execute(connection) }
                .flatMap(to: T.self) { result in
                    connection.execute("COMMIT").map(to: T.self) { _ in return result }
                }
                .catchFlatMap { error in
                    return connection.execute("ROLLBACK", parameters: [])
                        .map(to: T.self) { _ in throw error }
                        .catchMap { _ in throw error }
            }
            } as Future<T>
    }
    
    ///Runs a closure inside of a database transaction.
    /// - parameter execute: The closure to execute.  The closure should use the provided `Connection` to run queries.
    /// - returns: The result of the closure, or an error if the transaction could not be performed or the closure threw in error.
    public func transaction<T>(on worker: Worker, execute: @escaping (Connection) throws -> T) -> Future<T> {
        return transaction(on: worker) { connection in
            let promise = connection.eventLoop.newPromise(T.self)
            do {
                try promise.succeed(result: execute(connection))
            } catch {
                promise.fail(error: error)
            }
            return promise.futureResult
        }
    }
}

