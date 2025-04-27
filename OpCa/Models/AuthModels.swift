import Foundation

// Request Model
struct LoginRequest: Codable {
    let email: String
    let password: String
}

// Response Models
struct LoginResponse: Codable {
    let message: String
    let token: String
    let user: UserResponse
}

struct UserResponse: Codable {
    let id: String
    let pharmacistId: String
    let name: String
    let email: String
    let role: String
}

// API Error Models
struct APIError: LocalizedError, Codable {
    let message: String?
    let errors: [ValidationError]?
    
    var errorDescription: String? {
        if let validationErrors = errors {
            return validationErrors.map { $0.msg }.joined(separator: "\n")
        }
        return message ?? "Bilinmeyen bir hata oluştu"
    }
}

struct ValidationError: Codable {
    let type: String
    let msg: String
    let path: String
    let location: String
} 