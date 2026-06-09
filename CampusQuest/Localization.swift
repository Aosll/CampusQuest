//
//  Localization.swift
//  CampusQuest
//
//  In-app language selection. The user can override the device language from
//  Settings and the whole UI updates immediately — no restart needed.
//
//  How it works:
//  • `AppLanguage` lists the supported languages (plus a "system" option).
//  • `LanguageManager` stores the choice (UserDefaults, the same store that
//    backs @AppStorage) and resolves "system" to the device language with an
//    English fallback.
//  • A `Bundle` override points the main bundle at the chosen `.lproj` so both
//    `Text("…")` and `String(localized:)` resolve to the selected language.
//  • The app root also sets `\.locale` and an `.id(...)` so SwiftUI rebuilds
//    the tree on change.
//
//  Only interface text is localized here. Dictionary words, course names, and
//  quiz content stay in their original language on purpose.
//
//  Adding a language later: add a case below, add its `.lproj` (handled
//  automatically by the .xcstrings catalog), and add the code to
//  `supportedCodes`. Nothing else needs to change.
//

import Foundation
import SwiftUI
import Observation

/// A language the player can choose in Settings.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case en
    case tr
    case de
    case fr
    case es

    var id: String { rawValue }

    /// The concrete language code, or nil for "follow the device".
    var code: String? { self == .system ? nil : rawValue }

    /// Flag emoji shown in the picker.
    var flag: String {
        switch self {
        case .system: return "🌐"
        case .en:     return "🇺🇸"
        case .tr:     return "🇹🇷"
        case .de:     return "🇩🇪"
        case .fr:     return "🇫🇷"
        case .es:     return "🇪🇸"
        }
    }

    /// The language's own name (each shown in its own language), except the
    /// "system" option which is localized.
    var displayName: String {
        switch self {
        case .system: return String(localized: "System Default")
        case .en:     return "English"
        case .tr:     return "Türkçe"
        case .de:     return "Deutsch"
        case .fr:     return "Français"
        case .es:     return "Español"
        }
    }
}

@MainActor
@Observable
final class LanguageManager {
    /// The languages the app ships translations for.
    static let supportedCodes = ["en", "tr", "de", "fr", "es"]

    private let storageKey = "app.language"

    /// The user's current choice. Persisted on change.
    private(set) var selection: AppLanguage

    init() {
        let saved = UserDefaults.standard.string(forKey: storageKey)
        selection = AppLanguage(rawValue: saved ?? "") ?? .system
        Bundle.setLanguage(resolvedCode)
    }

    /// The concrete code in effect. Resolves "system" to the device language,
    /// falling back to English when the device language isn't supported.
    var resolvedCode: String {
        if let code = selection.code { return code }
        let device = Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "en"
        return Self.supportedCodes.contains(device) ? device : "en"
    }

    /// Locale for the resolved language, applied to the SwiftUI environment.
    var locale: Locale { Locale(identifier: resolvedCode) }

    /// Changes the language and updates the UI immediately.
    func select(_ language: AppLanguage) {
        guard language != selection else { return }
        selection = language
        UserDefaults.standard.set(language.rawValue, forKey: storageKey)
        Bundle.setLanguage(resolvedCode)
    }
}

// MARK: - Bundle override

// Address used to attach the chosen language bundle to `Bundle.main`.
// `nonisolated(unsafe)` is safe here: it is only ever used as a stable pointer
// for objc associated objects, never read/written as a value.
private nonisolated(unsafe) var languageBundleKey: UInt8 = 0

/// A `Bundle` subclass that redirects localized-string lookups to the language
/// bundle chosen at runtime. Installed onto `Bundle.main` by `setLanguage`.
private final class LanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &languageBundleKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Points `Bundle.main` at the given language's `.lproj`, so all localized
    /// lookups (Text and String(localized:)) resolve to that language.
    static func setLanguage(_ code: String) {
        object_setClass(Bundle.main, LanguageBundle.self)
        let lproj = Bundle.main.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:))
        objc_setAssociatedObject(Bundle.main, &languageBundleKey, lproj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
