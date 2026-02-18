import SwiftUI
import UIKit

/// Available app color themes
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case classicGreen = "classicGreen"
    case amber = "amber"
    case ocean = "ocean"
    case light = "light"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classicGreen: return "Classic Green"
        case .amber: return "Amber"
        case .ocean: return "Ocean"
        case .light: return "Light"
        }
    }

    /// Whether this theme uses a dark color scheme
    var isDark: Bool {
        switch self {
        case .classicGreen, .amber, .ocean: return true
        case .light: return false
        }
    }
}

/// Shared color constants that adapt to the current AppTheme
enum NumiTheme {
    private static var theme: AppTheme { AppSettings.shared.theme }

    // MARK: - SwiftUI Colors

    static var background: Color {
        switch theme {
        case .classicGreen: return Color(red: 0.05, green: 0.05, blue: 0.05)
        case .amber:        return Color(red: 0.06, green: 0.04, blue: 0.02)
        case .ocean:        return Color(red: 0.03, green: 0.05, blue: 0.08)
        case .light:        return Color(red: 0.96, green: 0.96, blue: 0.94)
        }
    }

    static var textGreen: Color {
        switch theme {
        case .classicGreen: return Color(red: 0.0, green: 0.9, blue: 0.3)
        case .amber:        return Color(red: 1.0, green: 0.7, blue: 0.2)
        case .ocean:        return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .light:        return Color(red: 0.15, green: 0.15, blue: 0.2)
        }
    }

    static var resultGreen: Color {
        switch theme {
        case .classicGreen: return Color(red: 0.0, green: 1.0, blue: 0.4)
        case .amber:        return Color(red: 1.0, green: 0.8, blue: 0.3)
        case .ocean:        return Color(red: 0.5, green: 0.9, blue: 1.0)
        case .light:        return Color(red: 0.0, green: 0.5, blue: 0.2)
        }
    }

    static var dimGreen: Color {
        switch theme {
        case .classicGreen: return Color(red: 0.0, green: 0.5, blue: 0.2)
        case .amber:        return Color(red: 0.6, green: 0.4, blue: 0.1)
        case .ocean:        return Color(red: 0.2, green: 0.4, blue: 0.6)
        case .light:        return Color(red: 0.4, green: 0.4, blue: 0.45)
        }
    }

    static var barBackground: Color {
        switch theme {
        case .classicGreen: return Color(red: 0.08, green: 0.08, blue: 0.08)
        case .amber:        return Color(red: 0.08, green: 0.06, blue: 0.03)
        case .ocean:        return Color(red: 0.05, green: 0.07, blue: 0.10)
        case .light:        return Color(red: 0.92, green: 0.92, blue: 0.90)
        }
    }

    // MARK: - UIKit Colors

    static var uiBackground: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        case .amber:        return UIColor(red: 0.06, green: 0.04, blue: 0.02, alpha: 1)
        case .ocean:        return UIColor(red: 0.03, green: 0.05, blue: 0.08, alpha: 1)
        case .light:        return UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1)
        }
    }

    static var uiTextGreen: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.0, green: 0.9, blue: 0.3, alpha: 1)
        case .amber:        return UIColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1)
        case .ocean:        return UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1)
        case .light:        return UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
        }
    }

    static var uiResultGreen: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1)
        case .amber:        return UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1)
        case .ocean:        return UIColor(red: 0.5, green: 0.9, blue: 1.0, alpha: 1)
        case .light:        return UIColor(red: 0.0, green: 0.5, blue: 0.2, alpha: 1)
        }
    }

    static var uiDimGreen: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.0, green: 0.5, blue: 0.2, alpha: 1)
        case .amber:        return UIColor(red: 0.6, green: 0.4, blue: 0.1, alpha: 1)
        case .ocean:        return UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
        case .light:        return UIColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1)
        }
    }

    static var uiVariableBlue: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1)
        case .amber:        return UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1)
        case .ocean:        return UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1)
        case .light:        return UIColor(red: 0.2, green: 0.3, blue: 0.7, alpha: 1)
        }
    }

    static var uiKeyword: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.0, green: 0.7, blue: 0.5, alpha: 1)
        case .amber:        return UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1)
        case .ocean:        return UIColor(red: 0.3, green: 0.7, blue: 0.8, alpha: 1)
        case .light:        return UIColor(red: 0.0, green: 0.5, blue: 0.4, alpha: 1)
        }
    }

    static var uiFunction: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.3, green: 0.8, blue: 0.8, alpha: 1)
        case .amber:        return UIColor(red: 0.8, green: 0.7, blue: 0.4, alpha: 1)
        case .ocean:        return UIColor(red: 0.5, green: 0.8, blue: 0.9, alpha: 1)
        case .light:        return UIColor(red: 0.1, green: 0.5, blue: 0.6, alpha: 1)
        }
    }

    static var uiComment: UIColor {
        switch theme {
        case .classicGreen: return UIColor(white: 0.35, alpha: 0.8)
        case .amber:        return UIColor(white: 0.35, alpha: 0.8)
        case .ocean:        return UIColor(white: 0.35, alpha: 0.8)
        case .light:        return UIColor(white: 0.55, alpha: 0.6)
        }
    }

    static var uiError: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 0.75)
        case .amber:        return UIColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 0.75)
        case .ocean:        return UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 0.75)
        case .light:        return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 0.85)
        }
    }

    static var uiToolbar: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        case .amber:        return UIColor(red: 0.1, green: 0.08, blue: 0.04, alpha: 1)
        case .ocean:        return UIColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 1)
        case .light:        return UIColor(red: 0.9, green: 0.9, blue: 0.88, alpha: 1)
        }
    }

    static var uiButton: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        case .amber:        return UIColor(red: 0.15, green: 0.12, blue: 0.06, alpha: 1)
        case .ocean:        return UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1)
        case .light:        return UIColor(red: 0.85, green: 0.85, blue: 0.83, alpha: 1)
        }
    }

    static var uiLineNumber: UIColor {
        switch theme {
        case .classicGreen: return UIColor(red: 0.0, green: 0.4, blue: 0.2, alpha: 0.5)
        case .amber:        return UIColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 0.5)
        case .ocean:        return UIColor(red: 0.15, green: 0.3, blue: 0.5, alpha: 0.5)
        case .light:        return UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 0.5)
        }
    }
}
