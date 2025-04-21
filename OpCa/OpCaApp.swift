import SwiftUI

struct OpCaApp: App {
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorSchemeManager.isDarkMode ? .dark : .light)
        }
    }
} 
