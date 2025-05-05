import Foundation
import SwiftUI

@Observable
class LoginViewModel {
    // Inputs
    var username: String = ""
    var password: String = ""
    var resetEmail: String = ""
    
    // UI state
    var isLoading: Bool = false
    var showErrorMessage: Bool = false
    var showForgotPassword: Bool = false
    
    // Dependencies
    private let authService = AuthService.shared
    private let userManager = UserManager.shared
    
    var isValid: Bool {
        !username.isEmpty && password.count >= 6
    }
    
    func login() async {
        guard isValid else {
            showErrorMessage = true
            return
        }
        
        isLoading = true
        showErrorMessage = false
        
        do {
            let loginResult = try await authService.login(username: username, password: password)
            
            await MainActor.run {
                if loginResult.success {
                    userManager.setLoggedIn(true, userInfo: loginResult.userInfo)
                } else {
                    showErrorMessage = true
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                showErrorMessage = true
                isLoading = false
            }
        }
    }
    
    func resetPassword() async {
        guard !resetEmail.isEmpty else { return }
        
        isLoading = true
        
        do {
            let result = try await authService.resetPassword(email: resetEmail)
            
            await MainActor.run {
                isLoading = false
                // Could show a success message here
            }
        } catch {
            await MainActor.run {
                isLoading = false
                // Could show an error message here
            }
        }
    }
} 