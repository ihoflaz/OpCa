//
//  OpCaApp.swift
//  OpCa
//
//  Created by İbrahim Hulusi Oflaz on 5.05.2025.
//

import SwiftUI
import SwiftData

// High contrast mode notification name
extension Notification.Name {
    static let highContrastModeChanged = Notification.Name("HighContrastModeChanged")
}

@main
struct OpCaApp: App {
    @State private var settingsViewModel = SettingsViewModel.shared
    @AppStorage("didPopulateSampleData") private var didPopulateSampleData = false
    
    // Ayarların değiştiğini takip etmek için
    @State private var settingsChanged = false
    @State private var highContrastModeEnabled = false
    @State private var currentLocale = Locale(identifier: "en")
    @State private var refreshView = false
    @State private var hasSampledDataBeenChecked = false
    
    // Authentication state
    @State private var userManager = UserManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Analysis.self,
            User.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Set initial values
        highContrastModeEnabled = settingsViewModel.highContrastMode
        currentLocale = Locale(identifier: settingsViewModel.currentLanguage.rawValue)
        
        // ModelContainerManager'a erişim sağla
        ModelContainerManager.shared = sharedModelContainer
        
        // Listen for settings changes
        setupNotificationObservers()
    }
    
    var body: some Scene {
        WindowGroup {
            if userManager.isInitialized {
                if userManager.isLoggedIn {
                    HomeView()
                        .id(refreshView) // Force view refresh when language changes
                        .modelContainer(sharedModelContainer)
                        .preferredColorScheme(settingsViewModel.getColorScheme())
                        .environment(\.locale, currentLocale)
                        .dynamicTypeSize(settingsViewModel.largeDisplayMode ? .xxxLarge : .large)
                        .highContrastEnabled(highContrastModeEnabled) // Apply high contrast using custom modifier
                        .task {
                            if !didPopulateSampleData && !hasSampledDataBeenChecked {
                                hasSampledDataBeenChecked = true
                                await addSampleDataIfNeeded()
                            }
                        }
                } else {
                    LoginView()
                        .modelContainer(sharedModelContainer)
                        .preferredColorScheme(settingsViewModel.getColorScheme())
                        .environment(\.locale, currentLocale)
                        .dynamicTypeSize(settingsViewModel.largeDisplayMode ? .xxxLarge : .large)
                        .highContrastEnabled(highContrastModeEnabled)
                        .task {
                            if !didPopulateSampleData && !hasSampledDataBeenChecked {
                                hasSampledDataBeenChecked = true
                                await addSampleDataIfNeeded()
                            }
                        }
                }
            } else {
                // Show splash screen while initializing
                SplashView()
                    .preferredColorScheme(settingsViewModel.getColorScheme())
            }
        }
    }
    
    private func setupNotificationObservers() {
        // Ayar değişikliklerini dinle
        NotificationCenter.default.addObserver(
            forName: .settingsChanged,
            object: nil,
            queue: .main
        ) { _ in
            // state değişikliği yaparak UI'ın güncellenmesini sağla
            settingsChanged.toggle()
        }
        
        // Listen for high contrast mode changes
        NotificationCenter.default.addObserver(
            forName: .highContrastModeChanged,
            object: nil,
            queue: .main
        ) { notification in
            if let enabled = notification.userInfo?["enabled"] as? Bool {
                highContrastModeEnabled = enabled
            }
        }
        
        // Listen for language changes
        NotificationCenter.default.addObserver(
            forName: .languageChanged,
            object: nil,
            queue: .main
        ) { notification in
            if let languageCode = notification.userInfo?["language"] as? String {
                currentLocale = Locale(identifier: languageCode)
                // Görünümü tamamen yenilemek için ID'yi değiştir
                refreshView.toggle()
            }
        }
        
        // Listen for authentication status changes
        NotificationCenter.default.addObserver(
            forName: .authStatusChanged,
            object: nil,
            queue: .main
        ) { _ in
            // Manually trigger view refresh on auth change
            refreshView.toggle()
        }
    }
    
    // Demo verileri ekleyen fonksiyon
    private func addSampleDataIfNeeded() async {
        // Swift 6.0'da mainContext async bir özellik olduğu için Task içinde kullanmalıyız
        let context = await sharedModelContainer.mainContext
        
        // SwiftData üzerinden demo verileri ekle
        await MainActor.run {
            // Önce mevcut veri var mı kontrol et
            let descriptor = FetchDescriptor<Analysis>()
            do {
                let count = try context.fetchCount(descriptor)
                if count == 0 {
                    // Veri yoksa ekle
                    SampleDataGenerator.populateSampleData(context: context)
                    // Bir daha eklememek için flag'i güncelle
                    didPopulateSampleData = true
                } else {
                    // Veri zaten var
                    print("Veriler zaten mevcut, demo veri ekleme atlanıyor")
                    didPopulateSampleData = true
                }
            } catch {
                print("Veri kontrolü sırasında hata: \(error.localizedDescription)")
            }
        }
    }
}
