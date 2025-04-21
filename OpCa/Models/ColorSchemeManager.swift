import SwiftUI

class ColorSchemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    
    static let shared = ColorSchemeManager()
    
    private init() {}
} 