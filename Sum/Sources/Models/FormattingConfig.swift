import Foundation

/// Decimal precision options for result formatting
enum DecimalPrecision: Int, CaseIterable {
    case auto = -1
    case two = 2
    case four = 4
    case six = 6

    var label: String {
        switch self {
        case .auto: return "Auto"
        case .two: return "2"
        case .four: return "4"
        case .six: return "6"
        }
    }
}

/// Immutable snapshot of formatting settings, passed into NumiValue formatting
struct FormattingConfig {
    let useThousandsSeparator: Bool
    let decimalPrecision: DecimalPrecision

    static let `default` = FormattingConfig(
        useThousandsSeparator: true,
        decimalPrecision: .auto
    )
}
