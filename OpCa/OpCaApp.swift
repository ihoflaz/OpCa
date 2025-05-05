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
    @StateObject private var settingsViewModel = SettingsViewModel.shared
    @AppStorage("didPopulateSampleData") private var didPopulateSampleData = false
    
    // Ayarların değiştiğini takip etmek için
    @State private var settingsChanged = false
    @State private var highContrastModeEnabled = false
    @State private var currentLocale = Locale(identifier: "en")
    @State private var refreshView = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Analysis.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .id(refreshView) // Force view refresh when language changes
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(settingsViewModel.getColorScheme())
                .environment(\.locale, currentLocale)
                .dynamicTypeSize(settingsViewModel.largeDisplayMode ? .xxxLarge : .large)
                .highContrastEnabled(highContrastModeEnabled) // Apply high contrast using custom modifier
                .onAppear {
                    // Set initial values
                    highContrastModeEnabled = settingsViewModel.highContrastMode
                    currentLocale = Locale(identifier: settingsViewModel.currentLanguage.rawValue)
                    
                    // Demo verileri sadece ilk çalıştırmada ekle
                    if !didPopulateSampleData {
                        addSampleDataIfNeeded()
                    }
                    
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
                }
                .onChange(of: settingsChanged) { _, _ in
                    // Bu değişkeni değiştirmek view'ın yeniden çizilmesini sağlar
                    // Ayarlar değiştiğinde UI güncellemesi için gerekli
                }
        }
    }
    
    // Demo verileri ekleyen fonksiyon
    private func addSampleDataIfNeeded() {
        let context = sharedModelContainer.mainContext
        
        // SwiftData üzerinden demo verileri ekle
        Task {
            // Demo verileri ana thread'de ekle
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
}
