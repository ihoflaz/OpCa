import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        }
    }
    
    var icon: String {
        switch self {
        case .english: return "🇺🇸"
        case .turkish: return "🇹🇷"
        }
    }
}

@Observable
class LocalizationManager {
    var currentLanguage: AppLanguage
    
    init() {
        // Get preferred language from UserDefaults or use system language
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Check if the system language is supported, otherwise default to English
            let preferredLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = AppLanguage(rawValue: preferredLanguage) ?? .english
        }
    }
    
    func setLanguage(_ language: AppLanguage) {
        self.currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
    }
    
    func localizedString(for key: String) -> String {
        // Load the appropriate localized string based on current language
        let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj")
        let bundle: Bundle
        
        if let path = path {
            bundle = Bundle(path: path) ?? Bundle.main
        } else {
            bundle = Bundle.main
        }
        
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

struct LocalizedStringKey: RawRepresentable, ExpressibleByStringLiteral {
    var rawValue: String
    
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }
}

extension View {
    func localized(_ key: String, _ localizationManager: LocalizationManager) -> some View {
        let localizedText = localizationManager.localizedString(for: key)
        return self.accessibilityLabel(Text(localizedText))
    }
} 