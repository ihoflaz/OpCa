import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var showAlert = false
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
                    TextField("E-posta", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal)
                    
                    SecureField("Şifre", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: handleLogin) {
                        Text("Giriş Yap")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        // Şifremi unuttum işlemi
                    }) {
                        Text("Şifremi Unuttum")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 30)
                
                Spacer()
                
                // Kayıt Ol Butonu
                VStack {
                    Divider()
                    
                    Button(action: {
                        // Kayıt ol işlemi
                    }) {
                        Text("Hesabınız yok mu? Kayıt Olun")
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .alert("Hata", isPresented: $showAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Geçersiz e-posta veya şifre")
            }
            .fullScreenCover(isPresented: $isLoggedIn) {
                ContentView()
            }
        }
        .preferredColorScheme(colorSchemeManager.isDarkMode ? .dark : .light)
    }
    
    private func handleLogin() {
        // Örnek giriş kontrolü
        if email == "test@opca.com" && password == "123456" {
            isLoggedIn = true
        } else {
            showAlert = true
        }
    }
}

#Preview {
    LoginView()
} 
