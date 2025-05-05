import Foundation
import SwiftData
import SwiftUI

// Singleton ModelContainer erişimcisi
class ModelContainerManager {
    static var shared: ModelContainer?
}

@Observable
class UserManager {
    static let shared = UserManager()
    
    var isLoggedIn: Bool = false
    var currentUser: User?
    
    var isInitialized: Bool = false
    
    private init() {
        // Check if user is already logged in
        loadUserSession()
    }
    
    func loadUserSession() {
        // Check for existing session in UserDefaults
        let defaults = UserDefaults.standard
        isLoggedIn = defaults.bool(forKey: "isLoggedIn")
        
        if isLoggedIn {
            // Load user from SwiftData
            Task {
                await loadUserFromDatabase()
            }
        }
        
        isInitialized = true
    }
    
    private func loadUserFromDatabase() async {
        guard let modelContainer = ModelContainerManager.shared else {
            print("ModelContainer not available yet")
            return
        }
        
        let context = await modelContainer.mainContext
        
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try context.fetch(descriptor)
            
            if let user = users.first {
                await MainActor.run {
                    self.currentUser = user
                }
            } else {
                // No user found in database despite being "logged in"
                await MainActor.run {
                    self.isLoggedIn = false
                    UserDefaults.standard.set(false, forKey: "isLoggedIn")
                }
            }
        } catch {
            print("Error loading user from database: \(error.localizedDescription)")
        }
    }
    
    func setLoggedIn(_ loggedIn: Bool, userInfo: UserInfo? = nil) {
        isLoggedIn = loggedIn
        UserDefaults.standard.set(loggedIn, forKey: "isLoggedIn")
        
        if loggedIn, let userInfo = userInfo {
            // Save token
            TokenManager.shared.saveToken(userInfo.token)
            
            // Save user to SwiftData
            Task {
                await saveUserToDatabase(from: userInfo)
            }
        } else if !loggedIn {
            // Clear token when logging out
            TokenManager.shared.clearToken()
            currentUser = nil
        }
        
        // Post notification for app state to refresh
        NotificationCenter.default.post(name: .authStatusChanged, object: nil)
    }
    
    private func saveUserToDatabase(from userInfo: UserInfo) async {
        guard let modelContainer = ModelContainerManager.shared else {
            print("ModelContainer not available yet")
            return
        }
        
        let context = await modelContainer.mainContext
        
        // Create or update user in database
        await MainActor.run {
            // Check if user already exists
            let descriptor = FetchDescriptor<User>(predicate: #Predicate<User> { $0.userId == userInfo.userId })
            
            do {
                let existingUsers = try context.fetch(descriptor)
                
                if let existingUser = existingUsers.first {
                    // Update existing user
                    existingUser.fullName = userInfo.fullName
                    existingUser.email = userInfo.email
                    existingUser.profileImageUrl = userInfo.profileImageUrl
                    existingUser.role = userInfo.role
                    existingUser.lastLoginDate = Date()
                    self.currentUser = existingUser
                } else {
                    // Create new user
                    let newUser = User(
                        userId: userInfo.userId,
                        fullName: userInfo.fullName,
                        email: userInfo.email,
                        profileImageUrl: userInfo.profileImageUrl,
                        role: userInfo.role
                    )
                    context.insert(newUser)
                    self.currentUser = newUser
                }
                
                try context.save()
                
            } catch {
                print("Error saving user from database: \(error.localizedDescription)")
            }
        }
    }
}

// Notification for auth state changes
extension Notification.Name {
    static let authStatusChanged = Notification.Name("com.opca.authStatusChanged")
} 