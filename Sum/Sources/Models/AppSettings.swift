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
    private let defaultCurrencyKey = "org.sum.defaultCurrency"
    private let languageKey = "org.sum.language"
    private let hasSeenOnboardingKey = "org.sum.hasSeenOnboarding"
    private let themeKey = "org.sum.theme"

    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: themeKey) }
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: hasSeenOnboardingKey) }
    }

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

    @Published var defaultCurrency: String {
        didSet { defaults.set(defaultCurrency, forKey: defaultCurrencyKey) }
    }

    @Published var language: Language {
        didSet { defaults.set(language.rawValue, forKey: languageKey) }
    }

    init() {
        self.theme = AppTheme(rawValue: defaults.string(forKey: themeKey) ?? "classicGreen") ?? .classicGreen
        self.hasSeenOnboarding = defaults.object(forKey: hasSeenOnboardingKey) as? Bool ?? false
        self.useThousandsSeparator = defaults.object(forKey: thousandsSeparatorKey) as? Bool ?? true
        let rawPrecision = defaults.object(forKey: decimalPrecisionKey) as? Int ?? -1
        self.decimalPrecision = DecimalPrecision(rawValue: rawPrecision) ?? .auto
        self.showLineNumbers = defaults.object(forKey: showLineNumbersKey) as? Bool ?? false
        self.syntaxHighlightingEnabled = defaults.object(forKey: syntaxHighlightingKey) as? Bool ?? true
        self.defaultCurrency = defaults.string(forKey: defaultCurrencyKey) ?? "USD"
        self.language = Language(rawValue: defaults.string(forKey: languageKey) ?? "en") ?? .english
    }

    /// Builds an immutable config snapshot for formatting
    var formattingConfig: FormattingConfig {
        let keywords = Language.parserKeywords(for: language)
        return FormattingConfig(
            useThousandsSeparator: useThousandsSeparator,
            decimalPrecision: decimalPrecision,
            durationWords: keywords.durationWords
        )
    }
}
