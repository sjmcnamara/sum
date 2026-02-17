import Foundation
import Combine

/// User-configurable formatting and display settings, persisted to UserDefaults
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private let thousandsSeparatorKey = "org.sum.thousandsSeparator"
    private let decimalPrecisionKey = "org.sum.decimalPrecision"
    private let showLineNumbersKey = "org.sum.showLineNumbers"
    private let syntaxHighlightingKey = "org.sum.syntaxHighlighting"

    @Published var useThousandsSeparator: Bool {
        didSet { defaults.set(useThousandsSeparator, forKey: thousandsSeparatorKey) }
    }

    @Published var decimalPrecision: DecimalPrecision {
        didSet { defaults.set(decimalPrecision.rawValue, forKey: decimalPrecisionKey) }
    }

    @Published var showLineNumbers: Bool {
        didSet { defaults.set(showLineNumbers, forKey: showLineNumbersKey) }
    }

    @Published var syntaxHighlightingEnabled: Bool {
        didSet { defaults.set(syntaxHighlightingEnabled, forKey: syntaxHighlightingKey) }
    }

    init() {
        self.useThousandsSeparator = defaults.object(forKey: thousandsSeparatorKey) as? Bool ?? true
        let rawPrecision = defaults.object(forKey: decimalPrecisionKey) as? Int ?? -1
        self.decimalPrecision = DecimalPrecision(rawValue: rawPrecision) ?? .auto
        self.showLineNumbers = defaults.object(forKey: showLineNumbersKey) as? Bool ?? false
        self.syntaxHighlightingEnabled = defaults.object(forKey: syntaxHighlightingKey) as? Bool ?? true
    }

    /// Builds an immutable config snapshot for formatting
    var formattingConfig: FormattingConfig {
        FormattingConfig(
            useThousandsSeparator: useThousandsSeparator,
            decimalPrecision: decimalPrecision
        )
    }
}
