import Foundation
import Combine

class AuthService {
    static let shared = AuthService()
    private let baseURL = "https://testbackend-production-6e6f.up.railway.app/api"
    
    private init() {}
    
    func login(email: String, password: String) -> AnyPublisher<LoginResponse, Error> {
        // URL oluştur
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        // Request body oluştur
        let loginRequest = LoginRequest(email: email, password: password)
        
        // URLRequest oluştur
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Request body'yi encode et
        do {
            request.httpBody = try JSONEncoder().encode(loginRequest)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // API isteğini gerçekleştir
        return URLSession.shared
            .dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                // Debug için response body'yi yazdır
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
                
                // Hata durumlarını kontrol et
                if httpResponse.statusCode != 200 {
                    let decoder = JSONDecoder()
                    let apiError = try decoder.decode(APIError.self, from: data)
                    
                    switch httpResponse.statusCode {
                    case 400:
                        throw apiError // Validation hatası
                    case 401:
                        throw apiError // Kimlik doğrulama hatası
                    case 403:
                        throw apiError // Hesap aktif değil
                    case 500:
                        throw apiError // Sunucu hatası
                    default:
                        throw apiError
                    }
                }
                
                return data
            }
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
} 