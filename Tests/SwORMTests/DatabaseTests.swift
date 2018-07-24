//
//  DatabaseTests.swift
//  SwORMTests
//
//  Created by NobodyNada on 2/20/18.
//

import XCTest
@testable import SwORM
import Async
import Core

///A simple mock connection that remembers all executed queries, and can compare them to an expected list of queries.
class LoggingConnection: Database, Connection, BasicWorker {
    var database: Database { return self }
    let worker: Worker
    
    var eventLoop: EventLoop { return worker.eventLoop }
    
    var executedQueries = [String]()
    
    func _newConnection(on worker: Worker) -> Future<Connection> {
        return worker.eventLoop.newSucceededFuture(result: self)
    }
    
    var beforeQuery: ((String) throws -> ())?
    
    func execute(_ query: String, parameters: [DatabaseType?]) -> Future<[Row]> {
        executedQueries.append(query)
        
        let promise = worker.eventLoop.newPromise([Row].self)
        
        do {
            try beforeQuery?(query)
        } catch {
            print("LoggingConnection: Failing \(query)")
            promise.fail(error: error)
            return promise.futureResult
        }
        
        print("LoggingConnection: Executed \"\(query)\"")
        
        promise.succeed(result: [])
        return promise.futureResult
    }
    
    init(worker: Worker) { self.worker = worker }
    
    var schemaVersion: Int = 0
    func loadSchemaVersion(on worker: Worker) -> Future<Int> { return worker.eventLoop.newSucceededFuture(result: schemaVersion) }
    func setSchemaVersion(to: Int, on worker: Worker) -> Future<Void> {
        schemaVersion = to
        return worker.eventLoop.newSucceededFuture(result: ())
    }
    
    func lastInsertedRow() -> Future<Int64> { return worker.eventLoop.newSucceededFuture(result: 0) }
    
    func assertExecuted(_ expected: [String]) {
        defer { executedQueries = [] }
        
        let pairs = zip(executedQueries, expected)
        XCTAssertEqual(expected.count, executedQueries.count, "Incorrect number of queries executed (have '\(executedQueries)'; expected '\(expected)')")
        for pair in pairs {
            XCTAssert(pair.0.starts(with: pair.1), "Incorrect query executed (have '\(pair.0)'; expected '\(pair.1)')")
        }
    }
}

class DatabaseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTransaction() throws {
        enum TestError: Error {
            case blockFailed
            
            case savepointFailed
            case releaseFailed
            case rollbackFailed
        }
        
        class QueryChecker {
            var failSavepoint = false
            var failRelease = false
            var failRollback = false
            
            init() {}
            
            func before(query: String) throws {
                if failSavepoint && query.starts(with: "BEGIN") { throw TestError.savepointFailed }
                if failRelease && query.starts(with: "COMMIT") { throw TestError.releaseFailed }
                if failRollback && query.starts(with: "ROLLBACK") { throw TestError.rollbackFailed }
            }
        }
        
        let worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let connection = LoggingConnection(worker: worker)
        let checker = QueryChecker()
        connection.beforeQuery = checker.before(query:)
        
        try connection.transaction(on: worker) { connection -> Future<Void> in
            connection.execute("in transaction").transform(to: Void())
            }.wait()
        connection.assertExecuted(["BEGIN", "in transaction", "COMMIT"])
        
        XCTAssertThrowsError(try connection.transaction(on: worker) { connection -> Future<Void> in
            connection.execute("in transaction").map(to: Void.self) { _ in
                throw TestError.blockFailed
            }
            }.wait()
        ) { error in
            if case TestError.blockFailed = error {}
            else { XCTFail("Incorrect error thrown: \(error)") }
        }
        connection.assertExecuted(["BEGIN", "in transaction", "ROLLBACK"])
        
        checker.failSavepoint = true
        XCTAssertThrowsError(try connection.transaction(on: worker) { connection -> Void in
            XCTFail("Block should not be executed if savepoint fails")
            }.wait()
        ) { error in
            if case TestError.savepointFailed = error {}
            else { XCTFail("Incorrect error thrown: \(error)") }
        }
        connection.assertExecuted(["BEGIN", "ROLLBACK"])
        
        checker.failSavepoint = true
        checker.failRollback = true
        XCTAssertThrowsError(try connection.transaction(on: worker) { connection -> Void in
            XCTFail("Block should not be executed if savepoint fails")
            }.wait()
        ) { error in
            if case TestError.savepointFailed = error {}
            else { XCTFail("Incorrect error thrown: \(error)") }
        }
        connection.assertExecuted(["BEGIN", "ROLLBACK"])
        
        checker.failSavepoint = false
        checker.failRelease = true
        checker.failRollback = false
        XCTAssertThrowsError(try connection.transaction(on: worker) { connection in
            connection.execute("in transaction").map(to: String.self) { _ in "Hello, world!" }
            }.wait()
        ) { error in
            if case TestError.releaseFailed = error {}
            else { XCTFail("Incorrect error thrown: \(error)") }
        }
        connection.assertExecuted(["BEGIN", "in transaction", "COMMIT", "ROLLBACK"])
        
        checker.failRelease = true
        checker.failRollback = true
        XCTAssertThrowsError(try connection.transaction(on: worker) { connection in
            connection.execute("in transaction").map(to: String.self) { _ in "Hello, world!" }
            }.wait()
        ) { error in
            if case TestError.releaseFailed = error {}
            else { XCTFail("Incorrect error thrown: \(error)") }
        }
        connection.assertExecuted(["BEGIN", "in transaction", "COMMIT", "ROLLBACK"])
    }
    
    static var allTests = [
        ("testTransaction", testTransaction)
    ]
}
