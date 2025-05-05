import SwiftUI

struct RegistrationView: View {
    @Bindable var viewModel = RegistrationViewModel()
    @Environment(\.dismiss) private var dismiss
    private let localization = LocalizationManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text.localized("create_account")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                
                Text.localized("registration_subtitle")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 20)
                
                // Registration form
                VStack(spacing: 16) {
                    TextField(localization.localizedString(for: "full_name"), text: $viewModel.fullName)
                        .textContentType(.name)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    TextField(localization.localizedString(for: "email"), text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: viewModel.email) { _, _ in
                            viewModel.validateEmail()
                        }
                    
                    if viewModel.showEmailError {
                        Text(localization.localizedString(for: "invalid_email"))
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.top, -8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    SecureField(localization.localizedString(for: "password"), text: $viewModel.password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: viewModel.password) { _, _ in
                            viewModel.validatePassword()
                        }
                    
                    if viewModel.showPasswordError {
                        Text(localization.localizedString(for: "password_requirements"))
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.top, -8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    SecureField(localization.localizedString(for: "confirm_password"), text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: viewModel.confirmPassword) { _, _ in
                            viewModel.validatePasswordsMatch()
                        }
                    
                    if viewModel.showPasswordMatchError {
                        Text(localization.localizedString(for: "passwords_not_match"))
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.top, -8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Toggle(localization.localizedString(for: "terms_agreement"), isOn: $viewModel.agreeToTerms)
                        .padding(.vertical, 8)
                }
                
                // Register button
                Button {
                    Task {
                        await viewModel.register()
                    }
                } label: {
                    Text(viewModel.isLoading ? localization.localizedString(for: "registering") : localization.localizedString(for: "create_account"))
                        .frame(maxWidth: .infinity)
                }
                .primaryButtonStyle()
                .disabled(viewModel.isLoading || !viewModel.isValid)
                .padding(.top, 20)
                
                // Already have account
                Button {
                    dismiss()
                } label: {
                    Text.localized("already_have_account")
                        .foregroundStyle(.blue)
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
            .alert(isPresented: $viewModel.showErrorAlert) {
                Alert(
                    title: Text(localization.localizedString(for: "registration_error")),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text(localization.localizedString(for: "ok")))
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
        .navigationTitle(localization.localizedString(for: "registration"))
        .navigationBarTitleDisplayMode(.inline)
        .highContrastEnabled(SettingsViewModel.shared.highContrastMode)
    }
}

#Preview {
    NavigationStack {
        RegistrationView()
    }
} 