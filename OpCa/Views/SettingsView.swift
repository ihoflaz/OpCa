import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $viewModel.colorSchemePreference) {
                        ForEach(ColorSchemePreference.allCases) { scheme in
                            Label(scheme.displayName, systemImage: scheme.icon)
                                .tag(scheme)
                        }
                    }
                    
                    Toggle("High Contrast Mode", isOn: $viewModel.highContrastMode)
                    
                    Toggle("Large Display Mode", isOn: $viewModel.largeDisplayMode)
                }
                
                // Camera
                Section("Camera") {
                    Toggle("Show Grid", isOn: $viewModel.cameraGridEnabled)
                }
                
                // Data
                Section("Data") {
                    Toggle("Auto-sync Data", isOn: $viewModel.autoDataSync)
                    
                    Toggle("Notifications", isOn: $viewModel.notificationsEnabled)
                }
                
                // Language
                Section("Language") {
                    Picker("App Language", selection: $viewModel.currentLanguage) {
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
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                    
                    NavigationLink {
                        AboutView()
                    } label: {
                        Text("About OpCa")
                    }
                    
                    Link(destination: URL(string: "https://example.com/help")!) {
                        HStack {
                            Text("Help & Support")
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
                        Text("Reset to Defaults")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Settings", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetToDefaults()
                }
            } message: {
                Text("Are you sure you want to reset all settings to default values?")
            }
        }
    }
}

struct AboutView: View {
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
                    
                    Text("Veterinary Diagnostic Tool")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("OpCa helps veterinarians diagnose parasitic infections using microscopic image analysis with AI technology.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            Section("Credits") {
                HStack {
                    Text("Designed and developed by")
                    Spacer()
                    Text("İbrahim Hulusi Oflaz")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("AI Model")
                    Spacer()
                    Text("OpCa Research Team")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Legal") {
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
                
                Link(destination: URL(string: "https://example.com/terms")!) {
                    HStack {
                        Text("Terms of Use")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
                
                Link(destination: URL(string: "https://example.com/licenses")!) {
                    HStack {
                        Text("Licenses")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
            }
            
            Section {
                Text("© 2025 OpCa. All rights reserved.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
} 