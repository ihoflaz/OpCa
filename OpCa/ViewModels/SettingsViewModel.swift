import Foundation
import SwiftUI

@Observable
class SettingsViewModel {
    private let settingsManager = SettingsManager()
    private let localizationManager = LocalizationManager()
    
    var colorSchemePreference: ColorSchemePreference {
        get { settingsManager.colorSchemePreference }
        set { settingsManager.setColorScheme(newValue) }
    }
    
    var autoDataSync: Bool {
        get { settingsManager.autoDataSync }
        set { settingsManager.setAutoDataSync(newValue) }
    }
    
    var notificationsEnabled: Bool {
        get { settingsManager.notificationsEnabled }
        set { settingsManager.setNotificationsEnabled(newValue) }
    }
    
    var highContrastMode: Bool {
        get { settingsManager.highContrastMode }
        set { settingsManager.setHighContrastMode(newValue) }
    }
    
    var largeDisplayMode: Bool {
        get { settingsManager.largeDisplayMode }
        set { settingsManager.setLargeDisplayMode(newValue) }
    }
    
    var cameraGridEnabled: Bool {
        get { settingsManager.cameraGridEnabled }
        set { settingsManager.setCameraGridEnabled(newValue) }
    }
    
    var currentLanguage: AppLanguage {
        get { localizationManager.currentLanguage }
        set { localizationManager.setLanguage(newValue) }
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    func resetToDefaults() {
        settingsManager.resetToDefaults()
    }
    
    func getLocalizedString(for key: String) -> String {
        localizationManager.localizedString(for: key)
    }
    
    func getColorScheme() -> ColorScheme? {
        colorSchemePreference.colorScheme
    }
} 