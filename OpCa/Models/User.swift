import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var userId: String
    var fullName: String
    var email: String
    var profileImageUrl: String?
    var role: String
    var isActive: Bool
    var lastLoginDate: Date
    var createdDate: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        fullName: String,
        email: String,
        profileImageUrl: String? = nil,
        role: String = "user",
        isActive: Bool = true,
        lastLoginDate: Date = Date(),
        createdDate: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.email = email
        self.profileImageUrl = profileImageUrl
        self.role = role
        self.isActive = isActive
        self.lastLoginDate = lastLoginDate
        self.createdDate = createdDate
    }
    
    // MARK: - Computed Properties
    
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        if components.count > 1,
           let firstInitial = components.first?.first,
           let lastInitial = components.last?.first {
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let firstInitial = components.first?.first {
            return String(firstInitial).uppercased()
        }
        return "U"
    }
    
    var formattedLastLogin: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastLoginDate)
    }
    
    var isVeterinarian: Bool {
        role.lowercased() == "veterinarian"
    }
}

// MARK: - Response Models

struct UserInfo: Codable {
    var userId: String
    var fullName: String
    var email: String
    var profileImageUrl: String?
    var role: String
    var token: String
}

struct AuthResponse: Codable {
    var success: Bool
    var message: String?
    var userInfo: UserInfo?
}

extension AuthResponse {
    static var mock: AuthResponse {
        AuthResponse(
            success: true,
            message: "Login successful",
            userInfo: UserInfo(
                userId: "123456",
                fullName: "John Doe",
                email: "john.doe@example.com",
                profileImageUrl: nil,
                role: "veterinarian",
                token: "mock-token-12345"
            )
        )
    }
} 