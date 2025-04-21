import Foundation

class UserManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    
    static let shared = UserManager()
    
    private init() {}
    
    struct User {
        let id: String
        let email: String
        let name: String
    }
    
    func login(email: String, password: String) -> Bool {
        // Burada gerçek bir API çağrısı yapılacak
        // Şimdilik test amaçlı basit bir kontrol
        if email == "test@opca.com" && password == "123456" {
            currentUser = User(id: "1", email: email, name: "Test Kullanıcı")
            isLoggedIn = true
            return true
        }
        return false
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
    }
} 