import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel.shared
    @State private var showResetConfirmation = false
    private let localization = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // Appearance
                Section(header: Text.localized("appearance")) {
                    Picker(localization.localizedString(for: "theme"), selection: $viewModel.colorSchemePreference) {
                        ForEach(ColorSchemePreference.allCases) { scheme in
                            Label(localization.localizedString(for: scheme.rawValue), systemImage: scheme.icon)
                                .tag(scheme)
                        }
                    }
                    
                    Toggle(localization.localizedString(for: "high_contrast_mode"), isOn: $viewModel.highContrastMode)
                        .onChange(of: viewModel.highContrastMode) { _, _ in
                            // Notify the system about high contrast mode change
                            NotificationCenter.default.post(
                                name: .highContrastModeChanged,
                                object: nil, 
                                userInfo: ["enabled": viewModel.highContrastMode]
                            )
                        }
                    
                    Toggle(localization.localizedString(for: "large_display_mode"), isOn: $viewModel.largeDisplayMode)
                        .onChange(of: viewModel.largeDisplayMode) { _, _ in
                            // UI'ı güncellemek için dinamik font boyutu ayarlarını değiştir
                            if viewModel.largeDisplayMode {
                                UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .unspecified
                            }
                        }
                }
                
                // Camera
                Section(header: Text.localized("camera")) {
                    Toggle(localization.localizedString(for: "show_grid"), isOn: $viewModel.cameraGridEnabled)
                }
                
                // Data
                Section(header: Text.localized("data")) {
                    Toggle(localization.localizedString(for: "auto_sync_data"), isOn: $viewModel.autoDataSync)
                    
                    Toggle(localization.localizedString(for: "notifications"), isOn: $viewModel.notificationsEnabled)
                }
                
                // Language
                Section(header: Text.localized("language")) {
                    Picker(localization.localizedString(for: "app_language"), selection: $viewModel.currentLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            HStack {
                                Text(language.icon)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    }
                }
                
                // About
                Section(header: Text.localized("about")) {
                    HStack {
                        Text.localized("version")
                        Spacer()
                        Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                    
                    NavigationLink {
                        AboutView()
                    } label: {
                        Text.localized("about_opca")
                    }
                    
                    Link(destination: URL(string: "https://example.com/help")!) {
                        HStack {
                            Text.localized("help_support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                    }
                }
                
                // Reset
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text.localized("reset_to_defaults")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(localization.localizedString(for: "settings_title"))
            .alert(localization.localizedString(for: "reset_to_defaults"), isPresented: $showResetConfirmation) {
                Button(localization.localizedString(for: "cancel"), role: .cancel) { }
                Button(localization.localizedString(for: "reset_to_defaults"), role: .destructive) {
                    viewModel.resetToDefaults()
                }
            } message: {
                Text(localization.localizedString(for: "Are you sure you want to reset all settings to default values?"))
            }
        }
        .preferredColorScheme(viewModel.colorSchemePreference.colorScheme)
        .environment(\.locale, Locale(identifier: viewModel.currentLanguage.rawValue))
        .dynamicTypeSize(viewModel.largeDisplayMode ? .xxxLarge : .large)
        .highContrastEnabled(viewModel.highContrastMode) // Apply high contrast using a custom modifier
    }
}

struct AboutView: View {
    private let localization = LocalizationManager.shared
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.top)
                    
                    Text("OpCa")
                        .font(.title.bold())
                    
                    Text.localized("app_subtitle")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text.localized("app_description")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            Section(header: Text.localized("credits")) {
                HStack {
                    Text.localized("designed_by")
                    Spacer()
                    Text("İbrahim Hulusi Oflaz")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text.localized("ai_model")
                    Spacer()
                    Text("OpCa Research Team")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(header: Text.localized("legal")) {
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text.localized("privacy_policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
                
                Link(destination: URL(string: "https://example.com/terms")!) {
                    HStack {
                        Text.localized("terms_of_use")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
                
                Link(destination: URL(string: "https://example.com/licenses")!) {
                    HStack {
                        Text.localized("licenses")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
            }
            
            Section {
                Text.localized("copyright")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(localization.localizedString(for: "about_page_title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
} 