import XCTest
@testable import Sum

final class AppSettingsTests: XCTestCase {

    // MARK: - Defaults

    func testDefaultValues() {
        // Create a fresh instance to test defaults (uses UserDefaults)
        let settings = AppSettings.shared
        // We test the config snapshot to verify the pipeline works
        let config = settings.formattingConfig
        // Default should match FormattingConfig.default
        XCTAssertEqual(config.useThousandsSeparator, FormattingConfig.default.useThousandsSeparator)
        XCTAssertEqual(config.decimalPrecision, FormattingConfig.default.decimalPrecision)
    }

    func testFormattingConfigSnapshot() {
        let settings = AppSettings.shared
        let originalSep = settings.useThousandsSeparator
        let originalPrec = settings.decimalPrecision

        // Modify settings
        settings.useThousandsSeparator = false
        settings.decimalPrecision = .four

        let config = settings.formattingConfig
        XCTAssertFalse(config.useThousandsSeparator)
        XCTAssertEqual(config.decimalPrecision, .four)

        // Restore
        settings.useThousandsSeparator = originalSep
        settings.decimalPrecision = originalPrec
    }

    func testDecimalPrecisionRawValues() {
        XCTAssertEqual(DecimalPrecision.auto.rawValue, -1)
        XCTAssertEqual(DecimalPrecision.two.rawValue, 2)
        XCTAssertEqual(DecimalPrecision.four.rawValue, 4)
        XCTAssertEqual(DecimalPrecision.six.rawValue, 6)
    }

    func testDecimalPrecisionLabels() {
        XCTAssertEqual(DecimalPrecision.auto.label, "Auto")
        XCTAssertEqual(DecimalPrecision.two.label, "2")
        XCTAssertEqual(DecimalPrecision.four.label, "4")
        XCTAssertEqual(DecimalPrecision.six.label, "6")
    }
}
