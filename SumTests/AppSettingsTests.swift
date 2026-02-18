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

    // MARK: - Theme

    func testAppThemeDisplayNames() {
        XCTAssertEqual(AppTheme.classicGreen.displayName, "Classic Green")
        XCTAssertEqual(AppTheme.amber.displayName, "Amber")
        XCTAssertEqual(AppTheme.ocean.displayName, "Ocean")
        XCTAssertEqual(AppTheme.light.displayName, "Light")
    }

    func testAppThemeRawValues() {
        XCTAssertEqual(AppTheme.classicGreen.rawValue, "classicGreen")
        XCTAssertEqual(AppTheme.amber.rawValue, "amber")
        XCTAssertEqual(AppTheme.ocean.rawValue, "ocean")
        XCTAssertEqual(AppTheme.light.rawValue, "light")
    }

    func testAppThemeIsDark() {
        XCTAssertTrue(AppTheme.classicGreen.isDark)
        XCTAssertTrue(AppTheme.amber.isDark)
        XCTAssertTrue(AppTheme.ocean.isDark)
        XCTAssertFalse(AppTheme.light.isDark)
    }

    func testAppThemeCaseCount() {
        XCTAssertEqual(AppTheme.allCases.count, 4)
    }

    func testThemePersistence() {
        let settings = AppSettings.shared
        let original = settings.theme

        settings.theme = .amber
        XCTAssertEqual(settings.theme, .amber)
        settings.theme = .ocean
        XCTAssertEqual(settings.theme, .ocean)
        settings.theme = .light
        XCTAssertEqual(settings.theme, .light)

        settings.theme = original
    }

    func testNumiThemeColorsChangeWithTheme() {
        let settings = AppSettings.shared
        let original = settings.theme

        settings.theme = .classicGreen
        let greenBg = NumiTheme.uiBackground

        settings.theme = .light
        let lightBg = NumiTheme.uiBackground

        XCTAssertNotEqual(greenBg, lightBg)

        settings.theme = original
    }
}
