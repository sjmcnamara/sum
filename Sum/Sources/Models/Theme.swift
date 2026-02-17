import SwiftUI
import UIKit

/// Shared color constants for the Numi theme
enum NumiTheme {
    // MARK: - SwiftUI Colors

    static let background = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let textGreen = Color(red: 0.0, green: 0.9, blue: 0.3)
    static let resultGreen = Color(red: 0.0, green: 1.0, blue: 0.4)
    static let dimGreen = Color(red: 0.0, green: 0.5, blue: 0.2)
    static let barBackground = Color(red: 0.08, green: 0.08, blue: 0.08)

    // MARK: - UIKit Colors

    static let uiBackground = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
    static let uiTextGreen = UIColor(red: 0.0, green: 0.9, blue: 0.3, alpha: 1)
    static let uiResultGreen = UIColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1)
    static let uiDimGreen = UIColor(red: 0.0, green: 0.5, blue: 0.2, alpha: 1)
    static let uiVariableBlue = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1)
    static let uiKeyword = UIColor(red: 0.0, green: 0.7, blue: 0.5, alpha: 1)
    static let uiFunction = UIColor(red: 0.3, green: 0.8, blue: 0.8, alpha: 1)
    static let uiComment = UIColor(white: 0.35, alpha: 0.8)
    static let uiError = UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 0.6)
    static let uiToolbar = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
    static let uiButton = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
    static let uiLineNumber = UIColor(red: 0.0, green: 0.4, blue: 0.2, alpha: 0.5)
}
