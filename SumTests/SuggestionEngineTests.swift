import XCTest
@testable import Sum

final class SuggestionEngineTests: XCTestCase {
    private var engine: SuggestionEngine!

    override func setUp() {
        super.setUp()
        engine = SuggestionEngine()
    }

    func testPrefixMatchFunction() {
        let results = engine.suggest(prefix: "sq")
        let names = results.map { $0.text }
        XCTAssertTrue(names.contains("sqrt"), "Expected 'sqrt' in results: \(names)")
    }

    func testPrefixMatchUnit() {
        let results = engine.suggest(prefix: "kil")
        let names = results.map { $0.text }
        XCTAssertTrue(names.contains("kilogram"), "Expected 'kilogram' in results: \(names)")
    }

    func testEmptyPrefixReturnsEmpty() {
        let results = engine.suggest(prefix: "")
        XCTAssertTrue(results.isEmpty)
    }

    func testNoMatchReturnsEmpty() {
        let results = engine.suggest(prefix: "zzzzz")
        XCTAssertTrue(results.isEmpty)
    }

    func testCaseInsensitive() {
        let results = engine.suggest(prefix: "Sqrt")
        let names = results.map { $0.text }
        XCTAssertTrue(names.contains("sqrt"), "Expected case-insensitive match for 'Sqrt'")
    }

    func testVariableCompletion() {
        engine.updateVariables(["price", "quantity"])
        let results = engine.suggest(prefix: "pri")
        let names = results.map { $0.text }
        XCTAssertTrue(names.contains("price"), "Expected 'price' in results: \(names)")
    }

    func testLimitRespected() {
        let results = engine.suggest(prefix: "k", limit: 3)
        XCTAssertLessThanOrEqual(results.count, 3)
    }

    func testExactMatchExcluded() {
        // Typing the exact word should not show it as a suggestion
        let results = engine.suggest(prefix: "sqrt")
        let names = results.map { $0.text }
        XCTAssertFalse(names.contains("sqrt"), "Exact match 'sqrt' should be excluded")
    }
}
