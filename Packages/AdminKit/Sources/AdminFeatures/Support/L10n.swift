import Foundation

/// App languages. Azərbaycan is the default, as in the main app (P02).
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case az, ru, en

    public var id: String { rawValue }

    /// Each language names itself, so it is findable whatever language is active.
    public var nativeName: String {
        switch self {
        case .az: "Azərbaycan"
        case .ru: "Русский"
        case .en: "English"
        }
    }

    public var locale: Locale {
        switch self {
        case .az: Locale(identifier: "az_AZ")
        case .ru: Locale(identifier: "ru_RU")
        case .en: Locale(identifier: "en_US")
        }
    }
}

enum L10n {
    static let storageKey = "rb.admin.language"

    static var current: AppLanguage {
        UserDefaults.standard.string(forKey: storageKey).flatMap(AppLanguage.init(rawValue:)) ?? .az
    }

    static var locale: Locale { current.locale }

    /// The compiled string catalogue for the chosen language.
    static var bundle: Bundle {
        guard let path = Bundle.module.path(forResource: current.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .module }
        return bundle
    }
}

/// Translates an English key from the string catalogue. Unknown keys (names, plates,
/// values from the backend) come back unchanged.
func tr(_ key: String) -> String {
    guard !key.isEmpty else { return key }
    return L10n.bundle.localizedString(forKey: key, value: key, table: nil)
}

/// Translates a key with `%@` / `%lld` placeholders.
func tr(_ key: String, _ args: CVarArg...) -> String {
    String(format: tr(key), locale: L10n.locale, arguments: args)
}
