//
//  ExpressionTests.swift
//  SwORMTests
//
//  Created by NobodyNada on 7/24/17.
//

import XCTest
@testable import SwORM

class ExpressionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTypedExpression() {
        let expr: TypedExpression<Bool, TestObject> = \.id == 5 as Int64? && !(\.string == "Hello, world!")
        XCTAssertEqual(
            expr.sql.sqlString(dialect: .sqlite).replacingOccurrences(of: " ", with: ""),
            "((`test_object`.`id` = ?) AND NOT (`test_object`.`string` = ?))".replacingOccurrences(of: " ", with: "")
            )
    }
    
    func testUntypedExpression() {
        func f<T: UntypedExpressionConvertible>(_ expr: T) -> UntypedExpression<Bool> where T.ExpressionResult == Bool {
            return expr.asUntypedExpression
        }
        let expr = f(\TestObject.id == 5 as Int64? && !(\TestObject2.string2 == "Hello, world!"))
        XCTAssertEqual(
            expr.sql.sqlString(dialect: .sqlite).replacingOccurrences(of: " ", with: ""),
            "((`test_object`.`id` = ?) AND NOT (`test_object_2`.`string2` = ?))".replacingOccurrences(of: " ", with: "")
        )
    }
    
    func testJoin() {
        let join = TestObject.join(TestObject2.self, on: \TestObject.string == \TestObject2.string2)
        XCTAssertEqual(
            join.sql.sqlString(dialect: .sqlite).replacingOccurrences(of: " ", with: ""),
            "(`test_object` INNER JOIN `test_object_2` ON (`test_object`.`string` = `test_object_2`.`string2`))"
                .replacingOccurrences(of: " ", with: "")
        )
    }
    
    static var allTests = [
        ("testTypedExpression", testTypedExpression),
        ("testUntypedExpression", testUntypedExpression),
        ("testJoin", testJoin)
    ]
}
