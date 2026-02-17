import XCTest
@testable import Sum

final class TokenRangeTests: XCTestCase {

    private let tokenizer = Tokenizer()

    // MARK: - Keywords

    func testKeywordRanges() {
        let ranges = tokenizer.tokenizeWithRanges("5 kg in pounds")
        let keywords = ranges.filter { $0.kind == .keyword }
        XCTAssertEqual(keywords.count, 1, "Expected 1 keyword ('in')")
        // "in" starts at index 5
        XCTAssertEqual(keywords[0].range.location, 5)
        XCTAssertEqual(keywords[0].range.length, 2)
    }

    // MARK: - Functions

    func testFunctionRanges() {
        let ranges = tokenizer.tokenizeWithRanges("sqrt(144)")
        let functions = ranges.filter { $0.kind == .function }
        XCTAssertEqual(functions.count, 1)
        XCTAssertEqual(functions[0].range.location, 0)
        XCTAssertEqual(functions[0].range.length, 4) // "sqrt"
    }

    // MARK: - Mixed tokens

    func testMixedTokenTypes() {
        let ranges = tokenizer.tokenizeWithRanges("sqrt(144) in hex")
        let kinds = ranges.map { $0.kind }
        // sqrt → function, 144 → number, in → keyword, hex → unit
        XCTAssertTrue(kinds.contains(.function))
        XCTAssertTrue(kinds.contains(.number))
        XCTAssertTrue(kinds.contains(.keyword))
    }

    // MARK: - No overlaps

    func testNoOverlappingRanges() {
        let ranges = tokenizer.tokenizeWithRanges("width = 1920 * 2 + 100 km")
        for i in 0..<ranges.count {
            for j in (i + 1)..<ranges.count {
                let r1 = ranges[i].range
                let r2 = ranges[j].range
                let r1End = r1.location + r1.length
                let r2End = r2.location + r2.length
                XCTAssertTrue(r1End <= r2.location || r2End <= r1.location,
                              "Ranges overlap: \(r1) and \(r2)")
            }
        }
    }

    // MARK: - Empty input

    func testEmptyInput() {
        let ranges = tokenizer.tokenizeWithRanges("")
        XCTAssertTrue(ranges.isEmpty)
    }

    // MARK: - Variable ranges

    func testVariableRange() {
        let ranges = tokenizer.tokenizeWithRanges("myVar = 42")
        let variables = ranges.filter { $0.kind == .variable }
        XCTAssertEqual(variables.count, 1)
        XCTAssertEqual(variables[0].range.location, 0)
        XCTAssertEqual(variables[0].range.length, 5) // "myVar"
    }

    // MARK: - Operator ranges

    func testOperatorRanges() {
        let ranges = tokenizer.tokenizeWithRanges("3 + 4")
        let ops = ranges.filter { $0.kind == .op }
        XCTAssertEqual(ops.count, 1)
        XCTAssertEqual(ops[0].range.location, 2)
        XCTAssertEqual(ops[0].range.length, 1)
    }

    // MARK: - Unit ranges

    func testUnitRange() {
        let ranges = tokenizer.tokenizeWithRanges("100 km")
        let units = ranges.filter { $0.kind == .unit }
        XCTAssertEqual(units.count, 1)
        XCTAssertEqual(units[0].range.location, 4)
        XCTAssertEqual(units[0].range.length, 2)
    }
}
