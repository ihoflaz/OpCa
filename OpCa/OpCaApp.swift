//
//  OpCaApp.swift
//  OpCa
//
//  Created by İbrahim Hulusi Oflaz on 5.05.2025.
//

import SwiftUI
import SwiftData

@main
struct OpCaApp: App {
    @State private var settingsViewModel = SettingsViewModel()
    
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
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(settingsViewModel.getColorScheme())
                .environment(\.locale, Locale(identifier: settingsViewModel.currentLanguage.rawValue))
                .onAppear {
                    // Demo verileri ekle
                    addSampleDataIfNeeded()
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
                SampleDataGenerator.populateSampleData(context: context)
            }
        }
    }
}
