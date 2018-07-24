import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(DatabaseObjectTests.allTests),
        testCase(DatabaseTests.allTests),
        testCase(ExpressionTests.allTests),
        testCase(MigrationTests.allTests),
        testCase(QueryTests.allTests),
        testCase(RowEncoderTests.allTests),
    ]
}
#endif
