//
//  RowEncoderTests.swift
//  SwORMTests
//
//  Created by NobodyNada on 7/16/17.
//

import Foundation
import XCTest
@testable import SwORM

struct Test: Codable {
    var bool: Bool
    var double: Double
    var int: Int
    var string: String
    var data: Data
    var optionalString: String?
}

class RowEncoderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEncoding() throws {
        let test = Test(
            bool: true,
            double: 1.1,
            int: 2,
            string: "Hello, world!",
            data: Data(bytes: [1, 2, 3]),
            optionalString: nil
        )
        
        let row = try RowEncoder().encode(test)
        
        XCTAssertEqual(try row.column(named: "bool"), true)
        XCTAssertEqual(try row.column(named: "double"), 1.1)
        XCTAssertEqual(try row.column(named: "int"), 2)
        XCTAssertEqual(try row.column(named: "string"), "Hello, world!")
        XCTAssertEqual(try row.column(named: "data"), Data(bytes: [1, 2, 3]))
        XCTAssertThrowsError(try row.column(named: "optionalString") as String?, "optionalString should throw a nameNotFound error")
    }
    
    func testDecoding() throws {
        let row = Row(columns: [
            1.asNative,
            1.1.asNative,
            2.asNative,
            "Hello, world!".asNative,
            Data(bytes: [1, 2, 3]).asNative
            ], columnIndices:
            Dictionary(
                uniqueKeysWithValues: zip(["bool", "double", "int", "string", "data"], 0...)
            )
        )
        
        let test: Test
        do {
            test = try RowDecoder().decode(Test.self, from: row)
        } catch {
            XCTFail("Decoding failed: \(error)")
            return
        }
        
        XCTAssertEqual(test.bool, true)
        XCTAssertEqual(test.double, 1.1)
        XCTAssertEqual(test.int, 2)
        XCTAssertEqual(test.string, "Hello, world!")
        XCTAssertEqual(test.data, Data(bytes: [1, 2, 3]))
        XCTAssertEqual(test.optionalString, nil)
    }
    
    static var allTests = [
        ("testEncoding", testEncoding),
        ("testDecoding", testDecoding)
    ]
}
