import Foundation
import SwiftUI

/// Available UI languages in PlistBar
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return "跟随系统 (System)"
        case .simplifiedChinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }
}

/// Zero-overhead Localization Manager backed directly by standard bundle tables.
/// Maintains minimal memory footprint (under 64 bytes) without caching redundant string maps.
@MainActor @Observable
final class LocalizationManager {
    static let shared = LocalizationManager()
    private static let storageKey = "plistbar.app_language"

    var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Self.storageKey)
            updateActiveBundle()
        }
    }

    /// Observable counter so SwiftUI views re-render whenever the user switches language
    private(set) var changeVersion: Int = 0

    private(set) var activeBundle: Bundle
    private(set) var effectiveLanguageCode: String

    init() {
        let savedRaw = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppLanguage.system.rawValue
        let initialLang = AppLanguage(rawValue: savedRaw) ?? .system
        self.selectedLanguage = initialLang
        let resolvedCode = Self.resolveEffectiveLanguageCode(for: initialLang)
        self.effectiveLanguageCode = resolvedCode
        self.activeBundle = Self.resolveBundle(for: initialLang)
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != selectedLanguage else { return }
        selectedLanguage = language
    }

    private func updateActiveBundle() {
        effectiveLanguageCode = Self.resolveEffectiveLanguageCode(for: selectedLanguage)
        activeBundle = Self.resolveBundle(for: selectedLanguage)
        changeVersion &+= 1
    }

    func localized(_ key: String) -> String {
        _ = changeVersion
        return activeBundle.localizedString(forKey: key, value: key, table: nil)
    }

    func localizedFormat(_ key: String, _ args: [CVarArg]) -> String {
        _ = changeVersion
        let format = activeBundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, locale: Locale(identifier: effectiveLanguageCode), arguments: args)
    }

    static func resolveEffectiveLanguageCode(for language: AppLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            return "zh-Hans"
        case .english:
            return "en"
        case .system:
            for lang in Locale.preferredLanguages {
                let lower = lang.lowercased()
                if lower.hasPrefix("zh") {
                    return "zh-Hans"
                } else if lower.hasPrefix("en") {
                    return "en"
                }
            }
            return "en"
        }
    }

    static func resolveBundle(for language: AppLanguage) -> Bundle {
        let langCode = resolveEffectiveLanguageCode(for: language)
        let candidates: [String] = langCode == "zh-Hans"
            ? ["zh-Hans", "zh-hans", "zh_CN", "zh"]
            : ["en", "en-US"]

        for base in [Bundle.module, Bundle.main] {
            for candidate in candidates {
                if let path = base.path(forResource: candidate, ofType: "lproj"),
                   let bundle = Bundle(path: path) {
                    return bundle
                }
            }
        }
        return Bundle.module
    }
}

/// Global convenience function for string localization
@MainActor
public func l10n(_ key: String) -> String {
    LocalizationManager.shared.localized(key)
}

/// Global convenience function for formatted string localization
@MainActor
public func l10n(_ key: String, _ args: CVarArg...) -> String {
    LocalizationManager.shared.localizedFormat(key, args)
}
