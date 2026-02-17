import XCTest
@testable import Sum

// MARK: - Split Tests

final class SplitTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testSplitWithWays() {
        let results = parser.evaluateAll("$200 split 4 ways")
        XCTAssertEqual(results[0].value?.number ?? 0, 50, accuracy: 0.01)
        XCTAssertEqual(results[0].value?.unit, .currency("USD"))
    }

    func testSplitBetweenPeople() {
        let results = parser.evaluateAll("$120 split between 4 people")
        XCTAssertEqual(results[0].value?.number ?? 0, 30, accuracy: 0.01)
        XCTAssertEqual(results[0].value?.unit, .currency("USD"))
    }

    func testSplitLeading() {
        let results = parser.evaluateAll("split $120 between 4")
        XCTAssertEqual(results[0].value?.number ?? 0, 30, accuracy: 0.01)
    }

    func testSplitExpressionValue() {
        let results = parser.evaluateAll("$100 + $50 split 3 ways")
        XCTAssertEqual(results[0].value?.number ?? 0, 50, accuracy: 0.01)
    }

    func testSplitAmong() {
        let results = parser.evaluateAll("$90 split among 3 people")
        XCTAssertEqual(results[0].value?.number ?? 0, 30, accuracy: 0.01)
    }

    func testSplitByZero() {
        let results = parser.evaluateAll("$100 split 0 ways")
        XCTAssertNotNil(results[0].error)
    }
}

// MARK: - Tip/Tax Tests

final class TipTaxTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testTipOnValue() {
        // "20% tip on $85" → $85 + 20% of $85 = $102
        let results = parser.evaluateAll("20% tip on $85")
        XCTAssertEqual(results[0].value?.number ?? 0, 102, accuracy: 0.01)
        XCTAssertEqual(results[0].value?.unit, .currency("USD"))
    }

    func testTaxOnValue() {
        // "8% tax on $50" → $50 + 8% of $50 = $54
        let results = parser.evaluateAll("8% tax on $50")
        XCTAssertEqual(results[0].value?.number ?? 0, 54, accuracy: 0.01)
        XCTAssertEqual(results[0].value?.unit, .currency("USD"))
    }

    func testTipPreservesCurrencyUnit() {
        let results = parser.evaluateAll("15% tip on $100")
        XCTAssertEqual(results[0].value?.unit, .currency("USD"))
    }

    func testTipWithoutTipKeyword() {
        // "20% on $85" should still work (existing behavior)
        let results = parser.evaluateAll("20% on $85")
        XCTAssertEqual(results[0].value?.number ?? 0, 102, accuracy: 0.01)
    }
}

// MARK: - Compound Tip + Split Tests

final class CompoundTipSplitTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testTipOnValueSplitWays() {
        // "20% tip on $85 split 3 ways" → ($85 + 20% of $85) / 3 = $102/3 = $34
        let results = parser.evaluateAll("20% tip on $85 split 3 ways")
        XCTAssertEqual(results[0].value?.number ?? 0, 34, accuracy: 0.01)
    }

    func testTaxOnValueSplitWays() {
        // "10% tax on $100 split 4 ways" → ($100 + $10) / 4 = $27.50
        let results = parser.evaluateAll("10% tax on $100 split 4 ways")
        XCTAssertEqual(results[0].value?.number ?? 0, 27.50, accuracy: 0.01)
    }
}

// MARK: - Noise Word Stripping Tests

final class NoiseWordTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testWhatsTipOnValue() {
        // "what's 20% tip on $85" → stripped to "20% tip on $85" → $102
        let results = parser.evaluateAll("whats 20% tip on $85")
        XCTAssertEqual(results[0].value?.number ?? 0, 102, accuracy: 0.01)
    }

    func testWhatIsSplit() {
        let results = parser.evaluateAll("what is $200 split 4 ways")
        XCTAssertEqual(results[0].value?.number ?? 0, 50, accuracy: 0.01)
    }
}
