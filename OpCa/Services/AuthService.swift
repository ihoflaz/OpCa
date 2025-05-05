import Foundation

class AuthService {
    static let shared = AuthService()
    
    private let apiClient = APIClient.shared
    private let baseURL = "https://api.example.com/auth"
    
    private init() {}
    
    func login(username: String, password: String) async throws -> AuthResponse {
        // In a real app, this would hit an actual API endpoint
        // For now, we'll simulate a network request with a delay
        
        #if DEBUG
        // In debug mode, simulate network delay and allow any credentials
        try await Task.sleep(for: .seconds(1.5))
        
        // For testing - accept any non-empty username/password
        if !username.isEmpty && password.count >= 6 {
            return AuthResponse.mock
        } else {
            return AuthResponse(success: false, message: "Invalid credentials", userInfo: nil)
        }
        #else
        // In production, make actual API call
        let loginData = ["username": username, "password": password]
        
        return try await apiClient.post(
            url: "\(baseURL)/login",
            body: loginData,
            responseType: AuthResponse.self
        )
        #endif
    }
    
    func register(fullName: String, email: String, password: String) async throws -> AuthResponse {
        // In a real app, this would hit an actual API endpoint
        
        #if DEBUG
        // In debug mode, simulate network delay
        try await Task.sleep(for: .seconds(1.5))
        
        // For testing - create a mock user
        var mockResponse = AuthResponse.mock
        mockResponse.userInfo?.fullName = fullName
        mockResponse.userInfo?.email = email
        return mockResponse
        #else
        // In production, make actual API call
        let registerData: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "password": password
        ]
        
        return try await apiClient.post(
            url: "\(baseURL)/register",
            body: registerData,
            responseType: AuthResponse.self
        )
        #endif
    }
    
    func resetPassword(email: String) async throws -> AuthResponse {
        #if DEBUG
        // In debug mode, simulate network delay
        try await Task.sleep(for: .seconds(1.5))
        
        return AuthResponse(
            success: true,
            message: "Password reset instructions sent to your email",
            userInfo: nil
        )
        #else
        // In production, make actual API call
        let resetData = ["email": email]
        
        return try await apiClient.post(
            url: "\(baseURL)/reset-password",
            body: resetData,
            responseType: AuthResponse.self
        )
        #endif
    }
    
    func validateToken(token: String) async throws -> Bool {
        #if DEBUG
        // In debug mode, simulate network delay
        try await Task.sleep(for: .seconds(0.5))
        
        // For testing, assume token is valid
        return true
        #else
        // In production, make actual API call
        let validateData = ["token": token]
        
        let response = try await apiClient.post(
            url: "\(baseURL)/validate-token",
            body: validateData,
            responseType: AuthResponse.self
        )
        
        return response.success
        #endif
    }
    
    func logout() async throws {
        // Clear local token data
        UserManager.shared.setLoggedIn(false)
        
        #if DEBUG
        // In debug mode, just simulate network delay
        try await Task.sleep(for: .seconds(0.5))
        #else
        // In production, hit the logout endpoint
        let token = TokenManager.shared.getToken() ?? ""
        
        _ = try await apiClient.post(
            url: "\(baseURL)/logout",
            body: ["token": token],
            responseType: EmptyResponse.self
        )
        #endif
    }
}

// Empty response type for endpoints that don't return data
struct EmptyResponse: Codable {} 