//
//  OpCaApp.swift
//  OpCa
//
//  Created by İbrahim Hulusi Oflaz on 5.05.2025.
//

import SwiftUI
import SwiftData
import Observation  // @Bindable için gerekli olabilir

// High contrast mode notification name
extension Notification.Name {
    static let highContrastModeChanged = Notification.Name("HighContrastModeChanged")
}

// Ana görünüm için wrapper
struct AppContentView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Bindable var userManager = UserManager.shared
    let modelContainer: ModelContainer
    @AppStorage("didPopulateSampleData") private var didPopulateSampleData = false
    @State private var hasSampledDataBeenChecked = false
    
    var body: some View {
        if userManager.isInitialized {
            if userManager.isLoggedIn {
                HomeView()
                    .modelContainer(modelContainer)
                    .preferredColorScheme(settings.getColorScheme())
                    .environment(\.locale, Locale(identifier: settings.currentLanguage.rawValue))
                    .dynamicTypeSize(settings.largeDisplayMode ? .xxxLarge : .large)
                    .highContrastEnabled(settings.highContrastMode)
                    .task {
                        if !didPopulateSampleData && !hasSampledDataBeenChecked {
                            hasSampledDataBeenChecked = true
                            await addSampleDataIfNeeded()
                        }
                    }
            } else {
                LoginView()
                    .modelContainer(modelContainer)
                    .preferredColorScheme(settings.getColorScheme())
                    .environment(\.locale, Locale(identifier: settings.currentLanguage.rawValue))
                    .dynamicTypeSize(settings.largeDisplayMode ? .xxxLarge : .large)
                    .highContrastEnabled(settings.highContrastMode)
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
                .preferredColorScheme(settings.getColorScheme())
        }
    }
    
    // Demo verileri ekleyen fonksiyon
    private func addSampleDataIfNeeded() async {
        // Swift 6.0'da mainContext async bir özellik olduğu için Task içinde kullanmalıyız
        let context = await modelContainer.mainContext
        
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

@main
struct OpCaApp: App {
    @State private var settingsViewModel = SettingsViewModel.shared
    
    // Authentication state
    @Bindable private var userManager = UserManager.shared
    
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
        // ModelContainerManager'a erişim sağla
        ModelContainerManager.shared = sharedModelContainer
    }
    
    var body: some Scene {
        WindowGroup {
            AppContentView(modelContainer: sharedModelContainer)
        }
    }
}
