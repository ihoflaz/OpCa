import Foundation
import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    // Environment değişkeni olarak paylaşılabilmesi için static bir instance oluşturuyorum
    static let shared = SettingsViewModel()
    
    private let settingsManager = SettingsManager()
    // Shared örneği kullan
    private let localizationManager = LocalizationManager.shared
    
    @Published var colorSchemePreference: ColorSchemePreference {
        didSet {
            settingsManager.setColorScheme(colorSchemePreference)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    @Published var autoDataSync: Bool {
        didSet {
            settingsManager.setAutoDataSync(autoDataSync)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            settingsManager.setNotificationsEnabled(notificationsEnabled)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    @Published var highContrastMode: Bool {
        didSet {
            settingsManager.setHighContrastMode(highContrastMode)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    @Published var largeDisplayMode: Bool {
        didSet {
            settingsManager.setLargeDisplayMode(largeDisplayMode)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    @Published var cameraGridEnabled: Bool {
        didSet {
            settingsManager.setCameraGridEnabled(cameraGridEnabled)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            localizationManager.setLanguage(currentLanguage)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
            
            // Dil değişikliği bildirimini artık setLanguage fonksiyonu içinde gönderiyoruz
            // Bu sayede hem ViewModel'den hem de LocalizationManager'dan doğrudan çağrıldığında çalışacak
        }
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    private init() {
        // Başlangıç değerlerini settingsManager'dan al
        self.colorSchemePreference = settingsManager.colorSchemePreference
        self.autoDataSync = settingsManager.autoDataSync
        self.notificationsEnabled = settingsManager.notificationsEnabled 
        self.highContrastMode = settingsManager.highContrastMode
        self.largeDisplayMode = settingsManager.largeDisplayMode
        self.cameraGridEnabled = settingsManager.cameraGridEnabled
        self.currentLanguage = localizationManager.currentLanguage
    }
    
    func resetToDefaults() {
        settingsManager.resetToDefaults()
        
        // ViewModel'i de güncelle
        self.colorSchemePreference = .system
        self.autoDataSync = false
        self.notificationsEnabled = true
        self.highContrastMode = false
        self.largeDisplayMode = false
        self.cameraGridEnabled = true
        self.currentLanguage = .english
        
        // Değişiklikleri bildir
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
    
    func getLocalizedString(for key: String) -> String {
        localizationManager.localizedString(for: key)
    }
    
    func getColorScheme() -> ColorScheme? {
        colorSchemePreference.colorScheme
    }
}

// Ayarlar değiştiğinde bildirim göndermek için kullanacağımız notification
extension Notification.Name {
    static let settingsChanged = Notification.Name("com.opca.settingsChanged")
    static let languageChanged = Notification.Name("com.opca.languageChanged")
} 