import XCTest
@testable import Sum

final class ParserTests: XCTestCase {

    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
        // Set up some currency rates for conversion tests
        parser.currencyRates = [
            "USD": 1.0,
            "EUR": 0.92,
            "GBP": 0.79,
            "JPY": 149.5,
            "BTC": 0.0000154,   // 1/64935 ≈ $64,935
            "ETH": 0.000285,    // 1/3508 ≈ $3,508
            "SATS": 0.00000000154, // not used directly, SATS converts through BTC
        ]
    }

    // MARK: - Basic Arithmetic

    func testAddition() {
        let results = parser.evaluateAll("2 + 3")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].value?.number, 5)
    }

    func testSubtraction() {
        let results = parser.evaluateAll("10 - 4")
        XCTAssertEqual(results[0].value?.number, 6)
    }

    func testMultiplication() {
        let results = parser.evaluateAll("6 * 7")
        XCTAssertEqual(results[0].value?.number, 42)
    }

    func testDivision() {
        let results = parser.evaluateAll("100 / 4")
        XCTAssertEqual(results[0].value?.number, 25)
    }

    func testDivisionByZero() {
        let results = parser.evaluateAll("10 / 0")
        XCTAssertNil(results[0].value)
    }

    func testModulo() {
        // "%" is parsed as percent unit, use "mod" for modulo
        let results = parser.evaluateAll("17 mod 5")
        XCTAssertEqual(results[0].value?.number, 2)
    }

    func testPower() {
        let results = parser.evaluateAll("2 ^ 10")
        XCTAssertEqual(results[0].value?.number, 1024)
    }

    func testOperatorPrecedence() {
        let results = parser.evaluateAll("2 + 3 * 4")
        XCTAssertEqual(results[0].value?.number, 14)
    }

    func testParentheses() {
        let results = parser.evaluateAll("(2 + 3) * 4")
        XCTAssertEqual(results[0].value?.number, 20)
    }

    func testNestedParentheses() {
        let results = parser.evaluateAll("((2 + 3) * (4 - 1))")
        XCTAssertEqual(results[0].value?.number, 15)
    }

    func testUnaryMinus() {
        let results = parser.evaluateAll("-5 + 3")
        XCTAssertEqual(results[0].value?.number, -2)
    }

    // MARK: - Number Formats

    func testHexNumber() {
        let results = parser.evaluateAll("0xFF")
        XCTAssertEqual(results[0].value?.number, 255)
    }

    func testBinaryNumber() {
        let results = parser.evaluateAll("0b1010")
        XCTAssertEqual(results[0].value?.number, 10)
    }

    func testOctalNumber() {
        let results = parser.evaluateAll("0o77")
        XCTAssertEqual(results[0].value?.number, 63)
    }

    func testLargeNumber() {
        let results = parser.evaluateAll("1000000")
        XCTAssertEqual(results[0].value?.number, 1_000_000)
    }

    // MARK: - Constants & Keywords

    func testPi() {
        let results = parser.evaluateAll("pi")
        XCTAssertEqual(results[0].value?.number ?? 0, Double.pi, accuracy: 0.0001)
    }

    func testEuler() {
        let results = parser.evaluateAll("e")
        XCTAssertEqual(results[0].value?.number ?? 0, M_E, accuracy: 0.0001)
    }

    // MARK: - Functions

    func testSqrt() {
        let results = parser.evaluateAll("sqrt(144)")
        XCTAssertEqual(results[0].value?.number, 12)
    }

    func testAbs() {
        let results = parser.evaluateAll("abs(-42)")
        XCTAssertEqual(results[0].value?.number, 42)
    }

    func testLog10() {
        let results = parser.evaluateAll("log(1000)")
        XCTAssertEqual(results[0].value?.number ?? 0, 3, accuracy: 0.0001)
    }

    func testLn() {
        let results = parser.evaluateAll("ln(e)")
        XCTAssertEqual(results[0].value?.number ?? 0, 1.0, accuracy: 0.0001)
    }

    func testSin() {
        let results = parser.evaluateAll("sin(0)")
        XCTAssertEqual(results[0].value?.number ?? 0, 0, accuracy: 0.0001)
    }

    func testCos() {
        let results = parser.evaluateAll("cos(0)")
        XCTAssertEqual(results[0].value?.number ?? 0, 1, accuracy: 0.0001)
    }

    func testRound() {
        let results = parser.evaluateAll("round(3.7)")
        XCTAssertEqual(results[0].value?.number, 4)
    }

    func testFloor() {
        let results = parser.evaluateAll("floor(3.9)")
        XCTAssertEqual(results[0].value?.number, 3)
    }

    func testCeil() {
        let results = parser.evaluateAll("ceil(3.1)")
        XCTAssertEqual(results[0].value?.number, 4)
    }

    func testFactorial() {
        let results = parser.evaluateAll("fact(5)")
        XCTAssertEqual(results[0].value?.number, 120)
    }

    // MARK: - Variables

    func testVariableAssignment() {
        let results = parser.evaluateAll("x = 10\nx * 5")
        XCTAssertEqual(results[0].value?.number, 10)
        XCTAssertEqual(results[1].value?.number, 50)
    }

    func testVariableAssignmentTracking() {
        let results = parser.evaluateAll("price = 42")
        XCTAssertEqual(results[0].assignmentVariable, "price")
    }

    func testMultipleVariables() {
        let results = parser.evaluateAll("a = 3\nb = 4\na + b")
        XCTAssertEqual(results[2].value?.number, 7)
    }

    func testVariableOverwrite() {
        let results = parser.evaluateAll("x = 5\nx = 10\nx")
        XCTAssertEqual(results[2].value?.number, 10)
    }

    // MARK: - Multi-line & Aggregates

    func testMultipleLines() {
        let results = parser.evaluateAll("10\n20\n30")
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].value?.number, 10)
        XCTAssertEqual(results[1].value?.number, 20)
        XCTAssertEqual(results[2].value?.number, 30)
    }

    func testEmptyLine() {
        let results = parser.evaluateAll("10\n\n20")
        XCTAssertEqual(results.count, 3)
        XCTAssertNil(results[1].value)
    }

    func testSum() {
        let results = parser.evaluateAll("10\n20\n30\nsum")
        XCTAssertEqual(results[3].value?.number, 60)
    }

    func testAverage() {
        let results = parser.evaluateAll("10\n20\n30\navg")
        XCTAssertEqual(results[3].value?.number, 20)
    }

    func testSumStopsAtEmptyLine() {
        let results = parser.evaluateAll("100\n\n10\n20\nsum")
        // sum should only include 10 and 20 (stops at empty line)
        XCTAssertEqual(results[4].value?.number, 30)
    }

    func testPrev() {
        let results = parser.evaluateAll("42\nprev * 2")
        XCTAssertEqual(results[1].value?.number, 84)
    }

    // MARK: - Unit Conversions (Length)

    func testKmToMiles() {
        let results = parser.evaluateAll("10 km in miles")
        XCTAssertNotNil(results[0].value)
        XCTAssertEqual(results[0].value?.number ?? 0, 6.2137, accuracy: 0.001)
    }

    func testFeetToMeters() {
        let results = parser.evaluateAll("100 feet in meters")
        XCTAssertEqual(results[0].value?.number ?? 0, 30.48, accuracy: 0.01)
    }

    func testCmToInches() {
        let results = parser.evaluateAll("2.54 cm in inches")
        XCTAssertEqual(results[0].value?.number ?? 0, 1.0, accuracy: 0.001)
    }

    // MARK: - Unit Conversions (Weight)

    func testKgToLbs() {
        let results = parser.evaluateAll("1 kg in lbs")
        XCTAssertEqual(results[0].value?.number ?? 0, 2.20462, accuracy: 0.001)
    }

    func testOzToGrams() {
        let results = parser.evaluateAll("1 oz in grams")
        XCTAssertEqual(results[0].value?.number ?? 0, 28.3495, accuracy: 0.01)
    }

    // MARK: - Temperature

    func testCelsiusToFahrenheit() {
        let results = parser.evaluateAll("100 °C in °F")
        XCTAssertEqual(results[0].value?.number ?? 0, 212, accuracy: 0.01)
    }

    func testFahrenheitToCelsius() {
        let results = parser.evaluateAll("32 °F in °C")
        XCTAssertEqual(results[0].value?.number ?? 0, 0, accuracy: 0.01)
    }

    func testCelsiusToKelvin() {
        let results = parser.evaluateAll("0 °C in kelvin")
        XCTAssertEqual(results[0].value?.number ?? 0, 273.15, accuracy: 0.01)
    }

    // MARK: - Data Units

    func testGBToMB() {
        let results = parser.evaluateAll("1 GB in MB")
        XCTAssertEqual(results[0].value?.number ?? 0, 1000, accuracy: 0.01)
    }

    func testTBToGB() {
        let results = parser.evaluateAll("1 TB in GB")
        XCTAssertEqual(results[0].value?.number ?? 0, 1000, accuracy: 0.01)
    }

    // MARK: - Time

    func testHoursToMinutes() {
        let results = parser.evaluateAll("2 hours in minutes")
        XCTAssertEqual(results[0].value?.number ?? 0, 120, accuracy: 0.01)
    }

    func testDaysToHours() {
        let results = parser.evaluateAll("7 days in hours")
        XCTAssertEqual(results[0].value?.number ?? 0, 168, accuracy: 0.01)
    }

    // MARK: - Currency Conversion

    func testUSDToEUR() {
        let results = parser.evaluateAll("100 USD in EUR")
        XCTAssertNotNil(results[0].value)
        XCTAssertEqual(results[0].value?.number ?? 0, 92, accuracy: 0.01)
    }

    func testEURToUSD() {
        let results = parser.evaluateAll("92 EUR in USD")
        XCTAssertEqual(results[0].value?.number ?? 0, 100, accuracy: 0.5)
    }

    func testDollarPrefix() {
        let results = parser.evaluateAll("$100 in EUR")
        XCTAssertNotNil(results[0].value)
        XCTAssertEqual(results[0].value?.number ?? 0, 92, accuracy: 0.01)
    }

    func testPoundPrefix() {
        let results = parser.evaluateAll("£100 in USD")
        XCTAssertNotNil(results[0].value)
        XCTAssertEqual(results[0].value?.number ?? 0, 100 / 0.79, accuracy: 0.5)
    }

    // MARK: - Crypto

    func testBTCToUSD() {
        let results = parser.evaluateAll("1 BTC in USD")
        XCTAssertNotNil(results[0].value)
        // 1 BTC / 0.0000154 rate = ~$64,935
        let expected = 1.0 / 0.0000154
        XCTAssertEqual(results[0].value?.number ?? 0, expected, accuracy: 1)
    }

    func testSATSToBTC() {
        let results = parser.evaluateAll("100000000 SATS in BTC")
        XCTAssertEqual(results[0].value?.number ?? 0, 1.0, accuracy: 0.0001)
    }

    func testBTCToSATS() {
        let results = parser.evaluateAll("1 BTC in SATS")
        XCTAssertEqual(results[0].value?.number ?? 0, 100_000_000, accuracy: 1)
    }

    func testCurrencyCodeCaseInsensitive() {
        // "usd" should work the same as "USD"
        let lower = parser.evaluateAll("100 eur in usd")
        let upper = parser.evaluateAll("100 EUR in USD")
        XCTAssertNotNil(lower[0].value)
        XCTAssertNotNil(upper[0].value)
        XCTAssertEqual(lower[0].value?.number ?? 0, upper[0].value?.number ?? -1, accuracy: 0.01)
    }

    func testCryptoCaseInsensitive() {
        // "btc" should work the same as "BTC"
        let lower = parser.evaluateAll("4 btc as usd")
        let upper = parser.evaluateAll("4 BTC as USD")
        XCTAssertNotNil(lower[0].value)
        XCTAssertNotNil(upper[0].value)
        XCTAssertEqual(lower[0].value?.number ?? 0, upper[0].value?.number ?? -1, accuracy: 0.01)
    }

    // MARK: - Percentages

    func testPercentageOf() {
        let results = parser.evaluateAll("20% of 200")
        XCTAssertEqual(results[0].value?.number, 40)
    }

    func testPercentageOn() {
        let results = parser.evaluateAll("10% on 100")
        XCTAssertEqual(results[0].value?.number, 110)
    }

    func testPercentageOff() {
        let results = parser.evaluateAll("25% off 200")
        XCTAssertEqual(results[0].value?.number, 150)
    }

    func testPercentageAdd() {
        // "$100 + 10%" should be $110
        let results = parser.evaluateAll("100 + 10%")
        XCTAssertEqual(results[0].value?.number, 110)
    }

    func testPercentageSubtract() {
        // "$100 - 20%" should be $80
        let results = parser.evaluateAll("100 - 20%")
        XCTAssertEqual(results[0].value?.number, 80)
    }

    // MARK: - Display Format Conversions

    func testToHex() {
        let results = parser.evaluateAll("255 in hex")
        XCTAssertNotNil(results[0].value)
        XCTAssertEqual(results[0].value?.unit, .hex)
    }

    func testToBinary() {
        let results = parser.evaluateAll("10 in bin")
        XCTAssertNotNil(results[0].value)
        XCTAssertEqual(results[0].value?.unit, .binary)
    }

    func testToOctal() {
        let results = parser.evaluateAll("8 in oct")
        XCTAssertNotNil(results[0].value)
        XCTAssertEqual(results[0].value?.unit, .octal)
    }

    // MARK: - Unit Arithmetic

    func testAddSameUnits() {
        let results = parser.evaluateAll("5 km + 3 km")
        XCTAssertEqual(results[0].value?.number, 8)
        XCTAssertEqual(results[0].value?.unit, .kilometer)
    }

    func testAddDifferentUnitsInCategory() {
        // 1 km + 500 m should be 1.5 km
        let results = parser.evaluateAll("1 km + 500 m")
        XCTAssertEqual(results[0].value?.number ?? 0, 1.5, accuracy: 0.001)
        XCTAssertEqual(results[0].value?.unit, .kilometer)
    }

    func testCurrencyArithmetic() {
        // $100 + €92 should be $200 (since €92 = $100 with our test rates)
        let results = parser.evaluateAll("$100 + 92 EUR")
        XCTAssertEqual(results[0].value?.number ?? 0, 200, accuracy: 0.5)
    }

    // MARK: - Edge Cases

    func testEmptyInput() {
        let results = parser.evaluateAll("")
        XCTAssertEqual(results.count, 1)
        XCTAssertNil(results[0].value)
    }

    func testJustANumber() {
        let results = parser.evaluateAll("42")
        XCTAssertEqual(results[0].value?.number, 42)
    }

    func testLargeExpression() {
        let results = parser.evaluateAll("(2 + 3) * (4 - 1) / 3 + 10 ^ 2")
        // (5 * 3) / 3 + 100 = 5 + 100 = 105
        XCTAssertEqual(results[0].value?.number ?? 0, 105, accuracy: 0.001)
    }
}

// MARK: - Persistence Tests

final class PersistenceTests: XCTestCase {

    private let testNotesKey = "com.sum.test.notes"
    private let testIndexKey = "com.sum.test.index"

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testNotesKey)
        UserDefaults.standard.removeObject(forKey: testIndexKey)
        super.tearDown()
    }

    func testNoteSerialization() {
        let note = Note(title: "Test", content: "2 + 2")
        let encoded = try! JSONEncoder().encode([note])
        let decoded = try! JSONDecoder().decode([Note].self, from: encoded)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].title, "Test")
        XCTAssertEqual(decoded[0].content, "2 + 2")
        XCTAssertEqual(decoded[0].id, note.id)
    }

    func testNoteStorageRoundTrip() {
        let storage = NoteStorage.shared
        let notes = [
            Note(title: "Note A", content: "10 + 20"),
            Note(title: "Note B", content: "price = 42"),
        ]
        storage.saveNotes(notes)
        let loaded = storage.loadNotes()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].title, "Note A")
        XCTAssertEqual(loaded[1].content, "price = 42")
    }

    func testCurrentNoteIndexPersistence() {
        let storage = NoteStorage.shared
        storage.saveCurrentNoteIndex(3)
        XCTAssertEqual(storage.loadCurrentNoteIndex(), 3)
        storage.saveCurrentNoteIndex(0)
        XCTAssertEqual(storage.loadCurrentNoteIndex(), 0)
    }
}

// MARK: - v1.1 Feature Tests

final class ErrorIndicatorTests: XCTestCase {

    private var parser: NumiParser!

    override func setUp() {
        super.setUp()
        parser = NumiParser()
    }

    func testDivisionByZeroError() {
        let results = parser.evaluateAll("10 / 0")
        XCTAssertEqual(results.count, 1)
        XCTAssertNil(results[0].value)
        XCTAssertEqual(results[0].error, "÷ by 0")
    }

    func testValidExpressionNoError() {
        let results = parser.evaluateAll("2 + 3")
        XCTAssertEqual(results.count, 1)
        XCTAssertNotNil(results[0].value)
        XCTAssertNil(results[0].error)
    }

    func testEmptyLineNoError() {
        let results = parser.evaluateAll("")
        XCTAssertEqual(results.count, 1)
        XCTAssertNil(results[0].value)
        XCTAssertNil(results[0].error)
    }

    func testMixedValidAndErrorLines() {
        let results = parser.evaluateAll("10 + 5\n100 / 0\n3 * 4")
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].value?.number, 15)
        XCTAssertNil(results[0].error)
        XCTAssertNil(results[1].value)
        XCTAssertEqual(results[1].error, "÷ by 0")
        XCTAssertEqual(results[2].value?.number, 12)
        XCTAssertNil(results[2].error)
    }

    func testUnrecognizedExpressionSilent() {
        // Gibberish that the parser can't evaluate — should produce nil value
        // with either an error or nil error (depends on whether it throws or returns nil)
        let results = parser.evaluateAll("hello world")
        XCTAssertEqual(results.count, 1)
        // Should not crash — result is either nil value or has a value
    }
}

final class ResultFormattingTests: XCTestCase {

    func testFormattedInteger() {
        let value = NumiValue(1234567)
        XCTAssertEqual(value.formatted, "1,234,567")
    }

    func testFormattedDecimal() {
        let value = NumiValue(3.14159)
        let formatted = value.formatted
        XCTAssertTrue(formatted.contains("3.14"), "Expected formatted to contain '3.14', got: \(formatted)")
    }

    func testFormattedCurrencyUSD() {
        let value = NumiValue(99.99, unit: .currency("USD"))
        XCTAssertEqual(value.formatted, "$99.99")
    }

    func testFormattedPercent() {
        let value = NumiValue(25, unit: .percent)
        XCTAssertEqual(value.formatted, "25%")
    }

    func testFormattedHex() {
        let value = NumiValue(255, unit: .hex)
        XCTAssertEqual(value.formatted, "0xFF")
    }

    func testFormattedBinary() {
        let value = NumiValue(10, unit: .binary)
        XCTAssertEqual(value.formatted, "0b1010")
    }

    func testFormattedBTC() {
        let value = NumiValue(1.5, unit: .currency("BTC"))
        let formatted = value.formatted
        XCTAssertTrue(formatted.hasPrefix("₿"), "Expected BTC prefix ₿, got: \(formatted)")
    }

    func testFormattedNegative() {
        let value = NumiValue(-42)
        XCTAssertEqual(value.formatted, "-42")
    }

    func testFormattedLargeNumber() {
        let value = NumiValue(1000000)
        XCTAssertEqual(value.formatted, "1,000,000")
    }

    func testFormattedZero() {
        let value = NumiValue(0)
        XCTAssertEqual(value.formatted, "0")
    }
}

final class NoteSearchTests: XCTestCase {

    func testSearchByTitle() {
        let notes = [
            Note(title: "Shopping List", content: "milk\neggs"),
            Note(title: "Budget", content: "rent = 2000"),
            Note(title: "Workout", content: "sets = 3"),
        ]
        let query = "budget"
        let filtered = notes.enumerated().filter { _, note in
            note.title.lowercased().contains(query) ||
            note.content.lowercased().contains(query)
        }
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].element.title, "Budget")
    }

    func testSearchByContent() {
        let notes = [
            Note(title: "Shopping", content: "milk\neggs\nbutter"),
            Note(title: "Budget", content: "rent = 2000\nfood = 500"),
        ]
        let query = "eggs"
        let filtered = notes.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].title, "Shopping")
    }

    func testSearchEmptyQuery() {
        let notes = [
            Note(title: "A", content: "1"),
            Note(title: "B", content: "2"),
        ]
        let query = ""
        // Empty query returns all
        let filtered = query.isEmpty ? notes : notes.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
        XCTAssertEqual(filtered.count, 2)
    }

    func testSearchNoMatch() {
        let notes = [
            Note(title: "Math", content: "2 + 2"),
            Note(title: "Physics", content: "F = ma"),
        ]
        let query = "chemistry"
        let filtered = notes.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
        XCTAssertEqual(filtered.count, 0)
    }

    func testSearchCaseInsensitive() {
        let notes = [
            Note(title: "My Budget", content: ""),
        ]
        let query = "my budget"
        let filtered = notes.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
        XCTAssertEqual(filtered.count, 1)
    }
}
