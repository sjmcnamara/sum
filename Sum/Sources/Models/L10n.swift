import Foundation

/// Localization helper that reads strings from the user's chosen language bundle
/// (independent from iOS system locale, allowing in-app language switching).
enum L10n {
    static func string(_ key: String) -> String {
        let lang = AppSettings.shared.language
        guard let path = Bundle.main.path(forResource: lang.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
