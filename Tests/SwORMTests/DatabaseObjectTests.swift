//
//  DatabaseObjectTests.swift
//  SwORMTests
//
//  Created by NobodyNada on 7/16/17.
//

import XCTest
import Foundation
@testable import SwORM
import NIO

struct TestObject: DatabaseObject, Equatable {
    static let tableName: String = "test_object"
    
    var id: Int64?
    var bool: Bool
    var double: Double
    var int: Int
    var string: String
    var data: Data
    var optionalString: String?
    
    static let primaryKey: KeyPath<TestObject, Int64?> = \.id
    static let allColumns: [(PartialKeyPath<TestObject>, CodingKey)] = [
        (\TestObject.id, CodingKeys.id),
        (\TestObject.bool, CodingKeys.bool),
        (\TestObject.double, CodingKeys.double),
        (\TestObject.int, CodingKeys.int),
        (\TestObject.string, CodingKeys.string),
        (\TestObject.data, CodingKeys.data),
        (\TestObject.optionalString, CodingKeys.optionalString)
    ]
}

struct TestObject2: DatabaseObject, Equatable {
    
    static var tableName: String = "test_object_2"
    
    var id: Int64?
    var string2: String
    
    static var primaryKey: KeyPath<TestObject2, Int64?> = \.id
    static var allColumns: [(PartialKeyPath<TestObject2>, CodingKey)] = [
        (\TestObject2.id, CodingKeys.id),
        (\TestObject2.string2, CodingKeys.string2)
    ]
}

class DatabaseObjectTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testKeyPathLookup() {
        XCTAssert(TestObject.name(of: (\TestObject.id)) == "id")
        XCTAssert(TestObject.name(of: (\TestObject.bool)) == "bool")
        XCTAssert(TestObject.name(of: (\TestObject.double)) == "double")
        XCTAssert(TestObject.name(of: (\TestObject.int)) == "int")
        XCTAssert(TestObject.name(of: (\TestObject.string)) == "string")
        XCTAssert(TestObject.name(of: (\TestObject.data)) == "data")
        XCTAssert(TestObject.name(of: (\TestObject.optionalString)) == "optionalString")
    }
    
    func testSave() throws {
        let connection = LoggingConnection(worker: MultiThreadedEventLoopGroup(numThreads: 1))
        var object = TestObject2(id: nil, string2: "Hello, world!")
        _ = try object.save(connection).wait()
        connection.assertExecuted(["INSERT INTO `test_object_2` (`string2`, `id`) VALUES (?, ?)"])
        
        object.id = 0
        _ = try object.save(connection).wait()
        connection.assertExecuted(["UPDATE `test_object_2` SET `id` = ?, `string2` = ? WHERE (`test_object_2`.`id` = ?)"])
    }
    
    func testFind() throws {
        let connection = LoggingConnection(worker: MultiThreadedEventLoopGroup(numThreads: 1))
        let result = try TestObject2.find(0, connection: connection).wait()
        XCTAssertEqual(result, nil, "LoggingConnection always returns empty")
        connection.assertExecuted(
            [
                "SELECT `test_object_2`.`id` AS `test_object_2.id`, `test_object_2`.`string2` AS `test_object_2.string2` " +
                "FROM `test_object_2` WHERE (`test_object_2`.`id` = ?)"
            ]
        )
    }
    
    func testDestroy() throws {
        let connection = LoggingConnection(worker: MultiThreadedEventLoopGroup(numThreads: 1))
        let object = TestObject2(id: 0, string2: "Hello, world!")
        try object.destroy(connection).wait()
        connection.assertExecuted(["DELETE FROM `test_object_2` WHERE (`test_object_2`.`id` = ?)"])
    }
    
    static var allTests = [
        ("testKeyPathLookup", testKeyPathLookup),
        ("testSave", testSave),
        ("testFind", testFind),
        ("testDestroy", testDestroy)
    ]
}
