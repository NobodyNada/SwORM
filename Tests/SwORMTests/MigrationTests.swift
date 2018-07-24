//
//  MigrationTests.swift
//  SwORMTests
//
//  Created by NobodyNada on 3/22/18.
//

import XCTest
@testable import SwORM
import Async

class MigrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    enum TestError: Error {
        case testError
    }
    
    func testMigrations() throws {
        let worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let db = LoggingConnection(worker: worker)
        let m = Migrator(database: db, worker: worker)
        
        try m.migrate(to: 1) { connection in
            connection.create(table: "test") { t in
                t.int("i", .unique, .check(\TestObject.id == (0 as Int64?)))
                }.flatMap(to: Void.self) { _ in
                    connection.create(table: TestObject.self) { t in
                        t.int(\.int, .check(\.int == 0 || \.bool), .default(0))
                        t.text(\.optionalString)
                        t.int(\.id)
                        t.index(\TestObject.int)
                    }
            }
        }
        
        db.assertExecuted([
            "BEGIN",
            "BEGIN",
            "CREATE TABLE `test` (`i` INTEGER UNIQUE CHECK ((`test_object`.`id` = ?))",
            "COMMIT",
            "BEGIN",
            "CREATE TABLE `test_object` (`int` INTEGER CHECK (((`test_object`.`int` = ?) OR `test_object`.`bool`)) DEFAULT (?) NOT NULL" +
                ", `optionalString` TEXT, `id` INTEGER PRIMARY KEY NOT NULL)",
            "CREATE INDEX `sworm_index_1_11_test_object_3_int` ON `test_object` (`int`)",
            "COMMIT",
            "COMMIT"
            ]
        )
        
        try m.migrate(to: 1) { _ in XCTFail("Migration should only be run once"); return worker.eventLoop.newSucceededFuture(result: ()) }
        db.assertExecuted(["BEGIN", "COMMIT"])
        
        do {
            try m.migrate(to: 2) { _ in return worker.eventLoop.newFailedFuture(error: TestError.testError) }
            XCTFail("Migration did not throw")
        } catch {
            
        }
        db.assertExecuted(["BEGIN", "ROLLBACK"])
        
        try m.migrate(to: 2) { connection in
            connection.renameTable(old: "test", new: "renamed")
        }
        db.assertExecuted([
            "BEGIN",
            "ALTER TABLE `test` RENAME TO `renamed`",
            "COMMIT"
            ]
        )
        
        try m.migrate(to: 3) { connection in
            connection.alter(table: TestObject.self) { t in
                t.bool(\.bool)
                
                t.index(\.int)
                t.compositeIndex(\TestObject.int, \TestObject.bool)
                
                t.drop(index: \.int)
                t.drop(compositeIndex: \TestObject.int, \TestObject.bool)
            }
        }
        db.assertExecuted([
            "BEGIN",
            "BEGIN",
            
            "ALTER TABLE `test_object` ADD COLUMN `bool` INTEGER NOT NULL",
            
            "CREATE INDEX `sworm_index_1_11_test_object_3_int` ON `test_object` (`int`)",
            "CREATE INDEX `sworm_index_2_11_test_object_3_int_4_bool` ON `test_object` (`int`, `bool`)",
            
            "DROP INDEX `sworm_index_1_11_test_object_3_int`",
            "DROP INDEX `sworm_index_2_11_test_object_3_int_4_bool",
            
            "COMMIT",
            "COMMIT"
            ]
        )
        
        try m.migrate(to: 4) { connection in
            connection.drop(table: TestObject.self)
        }
        
        db.assertExecuted([
            "BEGIN",
            "DROP TABLE `test_object`",
            "COMMIT"
            ]
        )
        
        struct ForeignKeyTest: DatabaseObject {
            static let primaryKey: KeyPath<ForeignKeyTest, Int64?> = \.id
            
            static let tableName: String = "foreign_key_test"
            
            static let allColumns: [(PartialKeyPath<ForeignKeyTest>, CodingKey)] = [
                (\ForeignKeyTest.id, CodingKeys.id),
                (\ForeignKeyTest.testObject, CodingKeys.testObject),
            ]
            
            var id: Int64?
            var testObject: ForeignKey<TestObject>
        }
        
        try m.migrate(to: 5) { connection in
            connection.create(table: ForeignKeyTest.self) { t in
                t.int(\.id)
                t.foreignKey(\.testObject)
            }
        }
        
        db.assertExecuted([
            "BEGIN",
            "BEGIN",
            "CREATE TABLE `foreign_key_test` (`id` INTEGER PRIMARY KEY NOT NULL, `testObject` INTEGER REFERENCES `test_object` (`id`) NOT NULL)",
            "COMMIT",
            "COMMIT"
            ]
        )
    }
    
    static var allTests = [
        ("testMigrations", testMigrations)
    ]
}
