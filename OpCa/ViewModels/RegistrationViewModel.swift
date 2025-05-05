import Foundation
import SwiftUI

@Observable
class RegistrationViewModel {
    // Form inputs
    var fullName: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var agreeToTerms: Bool = false
    
    // Validation state
    var showEmailError: Bool = false
    var showPasswordError: Bool = false
    var showPasswordMatchError: Bool = false
    
    // UI state
    var isLoading: Bool = false
    var showErrorAlert: Bool = false
    var errorMessage: String = ""
    
    // Dependencies
    private let authService = AuthService.shared
    private let userManager = UserManager.shared
    
    var isValid: Bool {
        !fullName.isEmpty && 
        isValidEmail(email) && 
        isValidPassword(password) && 
        password == confirmPassword && 
        agreeToTerms
    }
    
    func validateEmail() {
        showEmailError = !email.isEmpty && !isValidEmail(email)
    }
    
    func validatePassword() {
        showPasswordError = !password.isEmpty && !isValidPassword(password)
        
        // If password changes, also check if passwords still match
        if !confirmPassword.isEmpty {
            validatePasswordsMatch()
        }
    }
    
    func validatePasswordsMatch() {
        showPasswordMatchError = !confirmPassword.isEmpty && password != confirmPassword
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters with at least one uppercase, one lowercase, and one number
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }
    
    func register() async {
        guard isValid else {
            // Show appropriate validation errors
            showEmailError = !isValidEmail(email)
            showPasswordError = !isValidPassword(password)
            showPasswordMatchError = password != confirmPassword
            return
        }
        
        isLoading = true
        
        do {
            let registrationResult = try await authService.register(
                fullName: fullName,
                email: email,
                password: password
            )
            
            await MainActor.run {
                isLoading = false
                
                if registrationResult.success {
                    userManager.setLoggedIn(true, userInfo: registrationResult.userInfo)
                } else {
                    errorMessage = registrationResult.message ?? LocalizationManager.shared.localizedString(for: "registration_failed")
                    showErrorAlert = true
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
} 