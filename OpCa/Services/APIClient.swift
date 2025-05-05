import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidRequest
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidRequest:
            return "Invalid request"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
        
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func get<T: Decodable>(url: String, queryParams: [String: String]? = nil, responseType: T.Type) async throws -> T {
        guard var components = URLComponents(string: url) else {
            throw NetworkError.invalidURL
        }
        
        // Add query parameters if any
        if let queryParams = queryParams, !queryParams.isEmpty {
            components.queryItems = queryParams.map { 
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add auth headers if user is logged in
        if let token = TokenManager.shared.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return try await makeRequest(request: request, responseType: responseType)
    }
    
    func post<T: Decodable>(url: String, body: [String: Any], responseType: T.Type) async throws -> T {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add auth headers if user is logged in
        if let token = TokenManager.shared.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Serialize the body to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            throw NetworkError.invalidRequest
        }
        
        return try await makeRequest(request: request, responseType: responseType)
    }
    
    func put<T: Decodable>(url: String, body: [String: Any], responseType: T.Type) async throws -> T {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        // Add auth headers if user is logged in
        if let token = TokenManager.shared.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Serialize the body to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            throw NetworkError.invalidRequest
        }
        
        return try await makeRequest(request: request, responseType: responseType)
    }
    
    func delete<T: Decodable>(url: String, responseType: T.Type) async throws -> T {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add auth headers if user is logged in
        if let token = TokenManager.shared.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return try await makeRequest(request: request, responseType: responseType)
    }
    
    // Generic request method
    private func makeRequest<T: Decodable>(request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // Check for HTTP errors
            if !(200...299).contains(httpResponse.statusCode) {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            // For EmptyResponse type, we don't need to decode anything
            if responseType is EmptyResponse.Type {
                return EmptyResponse() as! T
            }
            
            do {
                let decodedResponse = try jsonDecoder.decode(responseType, from: data)
                return decodedResponse
            } catch {
                throw NetworkError.decodingError(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
} 