//
//  QueryTests.swift
//  SwORMTests
//
//  Created by NobodyNada on 2/20/18.
//

import XCTest
@testable import SwORM
import Async

class TestConnection: Database, Connection, BasicWorker {
    var database: Database { return self }
    let worker: Worker
    
    var eventLoop: EventLoop { return worker.eventLoop }
    
    func _newConnection(on worker: Worker) -> Future<Connection> {
        return worker.eventLoop.newSucceededFuture(result: self)
    }
    
    func execute(_ query: String, parameters: [DatabaseType?]) -> Future<[Row]> {
        print(query)
        return worker.eventLoop.newSucceededFuture(result: resultRows)
    }
    
    var resultRows: [Row]
    init(_ resultRows: [Row] = [], worker: Worker) {
        self.resultRows = resultRows
        self.worker = worker
    }
    
    convenience init(_ resultRows: [[(String, DatabaseNativeType)]], worker: Worker) {
        let rows = resultRows.map { row in
            Row(
                columns: row.map { $0.1 },
                columnIndices: Dictionary(uniqueKeysWithValues: row.indices.map { index in (row[index].0, index) })
            )
        }
        
        self.init(rows, worker: worker)
    }

    func loadSchemaVersion(on worker: Worker) -> Future<Int> { return worker.eventLoop.newSucceededFuture(result: 0) }
    func setSchemaVersion(to: Int, on worker: Worker) -> Future<Void> { return worker.eventLoop.newSucceededFuture(result: ()) }
    
    func lastInsertedRow() -> Future<Int64> { return worker.eventLoop.newSucceededFuture(result: 0) }
}

class QueryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    let table = Table(name: TestObject.tableName, columns: [.column(name: "id", sql: [.identifier("id")])])
    
    func testSelect() {
        let q = TestObject.select(where: \.int < 5)
        XCTAssertEqual(q.sql.sqlString(dialect: .sqlite), [
            "SELECT `test_object`.`id` AS `test_object.id`, `test_object`.`bool` AS `test_object.bool`, ",
            "`test_object`.`double` AS `test_object.double`, `test_object`.`int` AS `test_object.int`, ",
            "`test_object`.`string` AS `test_object.string`, `test_object`.`data` AS `test_object.data`, ",
            "`test_object`.`optionalString` AS `test_object.optionalString` FROM `test_object` WHERE (`test_object`.`int` < ?)"
            ].joined()
        )
    }
    
    func testInsert() {
        let columnNames = ["a", "b", "c", "d", "e", "f"]
        let columns = ["a", "b", "c", "d", "e", "f"].map { SelectColumn.column(name: $0, sql: [.identifier($0)])}
        let table = Table(name: "test", columns: columns)
        let q = InsertQuery(columnNames: columnNames, columns: [
            1.asNative,
            true.asNative,
            "Hello, world!".asNative,
            Date().asNative,
            Data().asNative,
            .null], table: table
        )
        XCTAssertEqual(
            q.sql.sqlString(dialect: .sqlite),
            "INSERT INTO `test` (`a`, `b`, `c`, `d`, `e`, `f`) VALUES (?, ?, ?, ?, ?, ?)"
        )
    }
    
    func testUpdate() throws {
        let conn = LoggingConnection(worker: MultiThreadedEventLoopGroup(numberOfThreads: 1))
        let _ = try TestObject.update(\TestObject.int, to: \.int + 1, where: \.bool, connection: conn).wait()
        conn.assertExecuted(["UPDATE `test_object` SET `test_object`.`int` = (`test_object`.`int` + ?) WHERE `test_object`.`bool`"])
    }
    
    func testDelete() throws {
        let conn = LoggingConnection(worker: MultiThreadedEventLoopGroup(numberOfThreads: 1))
        let _ = try TestObject.delete(where: \TestObject.optionalString == (nil as String?), connection: conn).wait()
        conn.assertExecuted(["DELETE FROM `test_object` WHERE (`test_object`.`optionalString` = ?)"])
    }
    
    struct JoinTest: DatabaseObject, Equatable {
        var id: Int64?
        var testObject: ForeignKey<TestObject>
        
        static var tableName: String = "join_test"
        static var primaryKey: KeyPath<QueryTests.JoinTest, Int64?> = \.id
        static var allColumns: [(PartialKeyPath<QueryTests.JoinTest>, CodingKey)] {
            return [
                (\JoinTest.id, CodingKeys.id),
                (\JoinTest.testObject, CodingKeys.testObject),
            ]
        }
        
        
    }
    
    func testJoin() throws {
        //let j: Join = (JoinTest.join(\JoinTest.testObject) as Join)
        //let s: UntypedSelectQuery<Join, UntypedExpression<Bool>, Join<JoinTest, TestObject>.Result> = j.select(where: 1 == 1)
        let conn = TestConnection(
            [[
                ("first.join_test.id", 1.asNative),
                ("first.join_test.testObject", 1.asNative),
                ("second.test_object.id", 1.asNative),
                ("second.test_object.bool", 0.asNative),
                ("second.test_object.double", 0.asNative),
                ("second.test_object.int", 0.asNative),
                ("second.test_object.string", "Hello!".asNative),
                ("second.test_object.data", Data().asNative),
                ("second.test_object.optionalString", .null)
            ]],
            worker: MultiThreadedEventLoopGroup(numberOfThreads: 1)
        )
        do {
            guard let result = try JoinTest.join(\.testObject).select().first(conn).wait() else {
                XCTFail("result is nil")
                return
            }
            XCTAssertEqual(
                result.first, JoinTest(id: 1, testObject: .init(id: 1))
            )
            XCTAssertEqual(
                result.second, TestObject(
                    id: 1,
                    bool: false,
                    double: 0,
                    int: 0,
                    string: "Hello!",
                    data: Data(),
                    optionalString: nil
                )
            )
        } catch {
            XCTFail("An error (\(type(of: error))) occured: \(error)")
        }
        //let results = j.select(where: true) as Future<JoinResult<JoinTest, TestObject>>
    }
    
    static var allTests = [
        ("testSelect", testSelect),
        ("testInsert", testInsert),
        ("testUpdate", testUpdate),
        ("testDelete", testDelete),
        ("testJoin", testJoin)
    ]
}
