import XCTest
@testable import Sum

// MARK: - Comment Tests

final class CommentTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testFullLineDoubleSlashComment() {
        let results = parser.evaluateAll("// this is a comment")
        XCTAssertNil(results[0].value)
        XCTAssertNil(results[0].error)
    }

    func testFullLineHashComment() {
        let results = parser.evaluateAll("# ignored line")
        XCTAssertNil(results[0].value)
        XCTAssertNil(results[0].error)
    }

    func testInlineDoubleSlashComment() {
        let results = parser.evaluateAll("5 + 3 // adds")
        XCTAssertEqual(results[0].value?.number, 8)
    }

    func testInlineHashComment() {
        let results = parser.evaluateAll("10 * 2 # multiply")
        XCTAssertEqual(results[0].value?.number, 20)
    }

    func testCommentDoesNotAffectNextLine() {
        let results = parser.evaluateAll("// comment\n42")
        XCTAssertNil(results[0].value)
        XCTAssertEqual(results[1].value?.number, 42)
    }

    func testCommentHighlightRange() {
        let tokenizer = Tokenizer()
        let ranges = tokenizer.tokenizeWithRanges("5 + 3 // comment")
        let comments = ranges.filter { $0.kind == .comment }
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(comments[0].range.location, 6) // "// comment" starts at index 6
    }
}

// MARK: - Bitwise NOT Tests

final class BitwiseNotTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testBitwiseNotTilde() {
        let results = parser.evaluateAll("~0")
        XCTAssertEqual(results[0].value?.number, -1)
    }

    func testBitwiseNotKeyword() {
        let results = parser.evaluateAll("not 0xFF")
        XCTAssertEqual(results[0].value?.number, Double(~0xFF))
    }

    func testBitwiseNotInExpression() {
        let results = parser.evaluateAll("~0xF0 & 0xFF")
        XCTAssertEqual(results[0].value?.number, 15) // 0x0F
    }
}

// MARK: - Keyword Highlighting Tests

final class KeywordHighlightTests: XCTestCase {
    func testModHighlightedAsKeyword() {
        let tokenizer = Tokenizer()
        let ranges = tokenizer.tokenizeWithRanges("17 mod 5")
        let keywords = ranges.filter { $0.kind == .keyword }
        XCTAssertEqual(keywords.count, 1)
        XCTAssertEqual(keywords[0].range.location, 3) // "mod" starts at index 3
    }
}

// MARK: - Constants Tests

final class ConstantsTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testSpeedOfLight() {
        let results = parser.evaluateAll("speedoflight")
        XCTAssertEqual(results[0].value?.number, 299_792_458)
    }

    func testAvogadro() {
        let results = parser.evaluateAll("avogadro")
        XCTAssertEqual(results[0].value?.number ?? 0, 6.02214076e23, accuracy: 1e17)
    }

    func testTauEquals2Pi() {
        let results = parser.evaluateAll("tau")
        XCTAssertEqual(results[0].value?.number ?? 0, .pi * 2, accuracy: 1e-10)
    }

    func testPhi() {
        let results = parser.evaluateAll("phi")
        XCTAssertEqual(results[0].value?.number ?? 0, 1.618, accuracy: 0.001)
    }

    func testConstantAlias() {
        let r1 = parser.evaluateAll("lightspeed")
        let r2 = parser.evaluateAll("speedoflight")
        XCTAssertEqual(r1[0].value?.number, r2[0].value?.number)
    }

    func testConstantInExpression() {
        let results = parser.evaluateAll("2 * pi")
        let tau = parser.evaluateAll("tau")
        XCTAssertEqual(results[0].value?.number ?? 0, tau[0].value?.number ?? 1, accuracy: 1e-10)
    }
}

// MARK: - Speed Unit Tests

final class SpeedUnitTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testMphToKph() {
        let results = parser.evaluateAll("60 mph in kph")
        XCTAssertEqual(results[0].value?.number ?? 0, 96.56, accuracy: 0.1)
        XCTAssertEqual(results[0].value?.unit, .kilometersPerHour)
    }

    func testKphToMps() {
        let results = parser.evaluateAll("3.6 kph in mps")
        XCTAssertEqual(results[0].value?.number ?? 0, 1.0, accuracy: 0.01)
        XCTAssertEqual(results[0].value?.unit, .metersPerSecond)
    }

    func testKnotsToMph() {
        let results = parser.evaluateAll("100 knots in mph")
        XCTAssertEqual(results[0].value?.number ?? 0, 115.08, accuracy: 0.1)
        XCTAssertEqual(results[0].value?.unit, .milesPerHour)
    }
}

// MARK: - Pressure Unit Tests

final class PressureUnitTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testAtmToPsi() {
        let results = parser.evaluateAll("1 atm in psi")
        XCTAssertEqual(results[0].value?.number ?? 0, 14.696, accuracy: 0.01)
        XCTAssertEqual(results[0].value?.unit, .psi)
    }

    func testBarToKpa() {
        let results = parser.evaluateAll("1 bar in kpa")
        XCTAssertEqual(results[0].value?.number ?? 0, 100, accuracy: 0.1)
        XCTAssertEqual(results[0].value?.unit, .kilopascal)
    }

    func testPsiToAtm() {
        let results = parser.evaluateAll("14.696 psi in atm")
        XCTAssertEqual(results[0].value?.number ?? 0, 1.0, accuracy: 0.01)
        XCTAssertEqual(results[0].value?.unit, .atmosphere)
    }
}

// MARK: - Energy Unit Tests

final class EnergyUnitTests: XCTestCase {
    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testCalToKcal() {
        let results = parser.evaluateAll("1000 cal in kcal")
        XCTAssertEqual(results[0].value?.number ?? 0, 1.0, accuracy: 0.01)
        XCTAssertEqual(results[0].value?.unit, .kilocalorie)
    }

    func testKwhToJoules() {
        let results = parser.evaluateAll("1 kwh in joules")
        XCTAssertEqual(results[0].value?.number ?? 0, 3_600_000, accuracy: 1)
        XCTAssertEqual(results[0].value?.unit, .joule)
    }

    func testBtuToKj() {
        let results = parser.evaluateAll("1 btu in kj")
        XCTAssertEqual(results[0].value?.number ?? 0, 1.055, accuracy: 0.01)
        XCTAssertEqual(results[0].value?.unit, .kilojoule)
    }
}
