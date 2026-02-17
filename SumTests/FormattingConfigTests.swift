import XCTest
@testable import Sum

final class FormattingConfigTests: XCTestCase {

    // MARK: - Default matches existing behavior

    func testDefaultConfigMatchesExistingFormatting() {
        let value = NumiValue(1234.5678, unit: nil)
        XCTAssertEqual(value.formatted, value.formatted(with: .default))
    }

    // MARK: - Thousands separator

    func testThousandsSeparatorOn() {
        let config = FormattingConfig(useThousandsSeparator: true, decimalPrecision: .auto)
        let value = NumiValue(1234567, unit: nil)
        let result = value.formatted(with: config)
        XCTAssertTrue(result.contains(","), "Expected thousands separator in \(result)")
    }

    func testThousandsSeparatorOff() {
        let config = FormattingConfig(useThousandsSeparator: false, decimalPrecision: .auto)
        let value = NumiValue(1234567, unit: nil)
        let result = value.formatted(with: config)
        XCTAssertFalse(result.contains(","), "Expected no thousands separator in \(result)")
    }

    func testThousandsSeparatorOffSmallNumber() {
        let config = FormattingConfig(useThousandsSeparator: false, decimalPrecision: .auto)
        let value = NumiValue(42, unit: nil)
        XCTAssertEqual(value.formatted(with: config), "42")
    }

    // MARK: - Decimal precision

    func testPrecisionTwo() {
        let config = FormattingConfig(useThousandsSeparator: true, decimalPrecision: .two)
        let value = NumiValue(3.14159, unit: nil)
        XCTAssertEqual(value.formatted(with: config), "3.14")
    }

    func testPrecisionFour() {
        let config = FormattingConfig(useThousandsSeparator: true, decimalPrecision: .four)
        let value = NumiValue(3.14159, unit: nil)
        XCTAssertEqual(value.formatted(with: config), "3.1416")
    }

    func testPrecisionSix() {
        let config = FormattingConfig(useThousandsSeparator: true, decimalPrecision: .six)
        let value = NumiValue(3.14159, unit: nil)
        XCTAssertEqual(value.formatted(with: config), "3.141590")
    }

    func testPrecisionAutoNoTrailingZeros() {
        let config = FormattingConfig(useThousandsSeparator: true, decimalPrecision: .auto)
        let value = NumiValue(5.0, unit: nil)
        XCTAssertEqual(value.formatted(with: config), "5")
    }

    func testPrecisionTwoTrailingZeros() {
        let config = FormattingConfig(useThousandsSeparator: true, decimalPrecision: .two)
        let value = NumiValue(5.0, unit: nil)
        XCTAssertEqual(value.formatted(with: config), "5.00")
    }

    // MARK: - Currency + formatting config

    func testCurrencyNoSeparator() {
        let config = FormattingConfig(useThousandsSeparator: false, decimalPrecision: .auto)
        let value = NumiValue(1234.56, unit: .currency("USD"))
        let result = value.formatted(with: config)
        XCTAssertTrue(result.contains("$"), "Expected $ in \(result)")
        // Should not contain comma
        let numericPart = result.replacingOccurrences(of: "$", with: "")
        XCTAssertFalse(numericPart.contains(","), "Expected no separator in \(result)")
    }

    func testCurrencyWithPrecision() {
        let config = FormattingConfig(useThousandsSeparator: true, decimalPrecision: .four)
        let value = NumiValue(99.1, unit: .currency("EUR"))
        let result = value.formatted(with: config)
        XCTAssertTrue(result.contains(".1000"),
                      "Expected 4 decimal places in \(result)")
    }

    // MARK: - Combined: separator off + precision

    func testNoSeparatorWithPrecision() {
        let config = FormattingConfig(useThousandsSeparator: false, decimalPrecision: .two)
        let value = NumiValue(1234567.891, unit: nil)
        let result = value.formatted(with: config)
        XCTAssertEqual(result, "1234567.89")
    }
}
