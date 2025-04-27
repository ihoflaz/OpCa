import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @ObservedObject private var colorSchemeManager = ColorSchemeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo ve Başlık
                VStack(spacing: 15) {
                    Image(systemName: "microscope.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("OpCa")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("Parazit Tespit Sistemi")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // Giriş Formu
                VStack(spacing: 20) {
                    TextField("E-posta", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal)
                    
                    SecureField("Şifre", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button(action: viewModel.login) {
                            Text("Giriş Yap")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(colorSchemeManager.isDarkMode ? .dark : .light)
        .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
            ContentView()
        }
    }
}

class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isLoggedIn = false
    
    private var cancellables = Set<AnyCancellable>()
    private let userManager = UserManager.shared
    
    func login() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Lütfen e-posta ve şifrenizi girin"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        AuthService.shared.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                switch completion {
                case .failure(let error):
                    if let apiError = error as? APIError {
                        self?.errorMessage = apiError.errorDescription ?? "Bilinmeyen bir hata oluştu"
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                    self?.isLoggedIn = false
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                // Sadece başarılı yanıt durumunda isLoggedIn'i true yap
                self?.isLoggedIn = true
                self?.errorMessage = ""
                
                // UserDefaults'a token'ı kaydet
                UserDefaults.standard.set(response.token, forKey: "userToken")
            }
            .store(in: &cancellables)
    }
}

#Preview {
    LoginView()
} 
