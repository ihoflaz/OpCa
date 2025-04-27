import Foundation
import Combine

class UserManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: UserResponse?
    @Published var authToken: String?
    
    static let shared = UserManager()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Kayıtlı token ve kullanıcı bilgilerini yükle
        loadSavedUser()
    }
    
    func login(email: String, password: String) -> AnyPublisher<Void, Error> {
        AuthService.shared.login(email: email, password: password)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("Login error: \(error)")
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                self?.handleSuccessfulLogin(response)
            }
            .store(in: &cancellables)
            
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func handleSuccessfulLogin(_ response: LoginResponse) {
        self.currentUser = response.user
        self.authToken = response.token
        self.isLoggedIn = true
        
        // Token ve kullanıcı bilgilerini kaydet
        saveUserData(token: response.token, user: response.user)
    }
    
    private func saveUserData(token: String, user: UserResponse) {
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "authToken")
        if let userData = try? JSONEncoder().encode(user) {
            defaults.set(userData, forKey: "userData")
        }
    }
    
    private func loadSavedUser() {
        let defaults = UserDefaults.standard
        if let token = defaults.string(forKey: "authToken"),
           let userData = defaults.data(forKey: "userData"),
           let user = try? JSONDecoder().decode(UserResponse.self, from: userData) {
            self.authToken = token
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
    
    func logout() {
        self.currentUser = nil
        self.authToken = nil
        self.isLoggedIn = false
        
        // Kayıtlı verileri temizle
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "authToken")
        defaults.removeObject(forKey: "userData")
    }
} 