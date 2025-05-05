import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(\.locale) private var locale
    private let localization = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo and branding
                Image("AppIcon")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .padding(.vertical, 20)
                
                Text("OpCa")
                    .font(.largeTitle.bold())
                
                Text.localized("app_subtitle")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
                
                // Login form
                VStack(spacing: 16) {
                    TextField(localization.localizedString(for: "email_username"), text: $viewModel.username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    SecureField(localization.localizedString(for: "password"), text: $viewModel.password)
                        .textContentType(.password)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    if viewModel.showErrorMessage {
                        Text(localization.localizedString(for: "login_error"))
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.top, -8)
                    }
                }
                .padding(.horizontal)
                
                // Login button
                Button {
                    Task {
                        await viewModel.login()
                    }
                } label: {
                    Text(viewModel.isLoading ? localization.localizedString(for: "logging_in") : localization.localizedString(for: "login"))
                        .frame(maxWidth: .infinity)
                }
                .primaryButtonStyle()
                .disabled(viewModel.isLoading || !viewModel.isValid)
                
                // Forgot password option
                Button {
                    viewModel.showForgotPassword.toggle()
                } label: {
                    Text.localized("forgot_password")
                        .foregroundStyle(.blue)
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Register option
                HStack {
                    Text.localized("no_account")
                    
                    NavigationLink {
                        RegistrationView()
                    } label: {
                        Text.localized("register_now")
                            .bold()
                    }
                }
                .padding(.bottom, 20)
            }
            .padding()
            .alert(isPresented: $viewModel.showForgotPassword) {
                Alert(
                    title: Text(localization.localizedString(for: "forgot_password")),
                    message: Text(localization.localizedString(for: "enter_email_to_reset")),
                    primaryButton: .default(Text(localization.localizedString(for: "submit"))) {
                        Task {
                            await viewModel.resetPassword()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
        .preferredColorScheme(SettingsViewModel.shared.getColorScheme())
        .environment(\.locale, Locale(identifier: SettingsViewModel.shared.currentLanguage.rawValue))
        .highContrastEnabled(SettingsViewModel.shared.highContrastMode)
    }
}

#Preview {
    LoginView()
} 