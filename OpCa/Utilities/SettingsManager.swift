import Foundation
import SwiftUI

enum ColorSchemePreference: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Observable
class SettingsManager {
    var colorSchemePreference: ColorSchemePreference
    var autoDataSync: Bool
    var notificationsEnabled: Bool
    var highContrastMode: Bool
    var largeDisplayMode: Bool
    var cameraGridEnabled: Bool
    
    init() {
        let defaults = UserDefaults.standard
        
        // Load saved preferences or use defaults
        if let savedScheme = defaults.string(forKey: "colorScheme"),
           let scheme = ColorSchemePreference(rawValue: savedScheme) {
            self.colorSchemePreference = scheme
        } else {
            self.colorSchemePreference = .system
        }
        
        self.autoDataSync = defaults.bool(forKey: "autoDataSync")
        self.notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        self.highContrastMode = defaults.bool(forKey: "highContrastMode")
        self.largeDisplayMode = defaults.bool(forKey: "largeDisplayMode")
        self.cameraGridEnabled = defaults.bool(forKey: "cameraGridEnabled")
    }
    
    func setColorScheme(_ scheme: ColorSchemePreference) {
        self.colorSchemePreference = scheme
        UserDefaults.standard.set(scheme.rawValue, forKey: "colorScheme")
    }
    
    func setAutoDataSync(_ enabled: Bool) {
        self.autoDataSync = enabled
        UserDefaults.standard.set(enabled, forKey: "autoDataSync")
    }
    
    func setNotificationsEnabled(_ enabled: Bool) {
        self.notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
    }
    
    func setHighContrastMode(_ enabled: Bool) {
        self.highContrastMode = enabled
        UserDefaults.standard.set(enabled, forKey: "highContrastMode")
    }
    
    func setLargeDisplayMode(_ enabled: Bool) {
        self.largeDisplayMode = enabled
        UserDefaults.standard.set(enabled, forKey: "largeDisplayMode")
    }
    
    func setCameraGridEnabled(_ enabled: Bool) {
        self.cameraGridEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "cameraGridEnabled")
    }
    
    func resetToDefaults() {
        colorSchemePreference = .system
        autoDataSync = false
        notificationsEnabled = true
        highContrastMode = false
        largeDisplayMode = false
        cameraGridEnabled = true
        
        let defaults = UserDefaults.standard
        defaults.set(colorSchemePreference.rawValue, forKey: "colorScheme")
        defaults.set(autoDataSync, forKey: "autoDataSync")
        defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(highContrastMode, forKey: "highContrastMode")
        defaults.set(largeDisplayMode, forKey: "largeDisplayMode")
        defaults.set(cameraGridEnabled, forKey: "cameraGridEnabled")
    }
} 