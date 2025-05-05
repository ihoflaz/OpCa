import Foundation

enum ServiceError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case unknownError
    
    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

struct ParasiteInfo: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let treatment: String
    let preventionMeasures: [String]
    let imageURLs: [URL]
}

struct AnalysisRequest: Codable {
    let imageData: Data
    let metadata: [String: String]
}

struct AnalysisResponse: Codable {
    let results: [ParasiteResult]
    let processingTimeMs: Int
    let timestamp: Date
}

@Observable
class APIService {
    private let baseURL = "https://api.example.com"
    
    func analyzeImage(_ imageData: Data) async throws -> [ParasiteResult] {
        // This is a mock implementation. In a real app, this would send the image to a server
        // For now, we'll simulate a network delay and return mock data
        try await Task.sleep(for: .seconds(2))
        
        return [
            ParasiteResult(type: .neosporosis, confidence: 0.87, detectionDate: Date()),
            ParasiteResult(type: .echinococcosis, confidence: 0.10, detectionDate: Date()),
            ParasiteResult(type: .coenurosis, confidence: 0.03, detectionDate: Date())
        ]
    }
    
    func getParasiteInfo(for type: ParasiteType) async throws -> ParasiteInfo {
        // Mock implementation
        try await Task.sleep(for: .seconds(1))
        
        return ParasiteInfo(
            id: type.rawValue,
            name: type.rawValue,
            description: type.description,
            treatment: "Standard treatment includes antiparasitic medications specific to \(type.rawValue).",
            preventionMeasures: [
                "Regular deworming",
                "Avoid contact with infected animals",
                "Proper hygiene practices"
            ],
            imageURLs: [URL(string: "https://example.com/images/\(type.rawValue.lowercased()).jpg")!]
        )
    }
    
    func uploadAnalysis(_ analysis: Analysis) async throws -> Bool {
        // Mock implementation
        try await Task.sleep(for: .seconds(1))
        return true
    }
    
    // MARK: - Generic Network Request
    
    func fetch<T: Decodable>(from endpoint: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw ServiceError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ServiceError.serverError(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw ServiceError.decodingError(error)
            }
        } catch let error as ServiceError {
            throw error
        } catch {
            throw ServiceError.networkError(error)
        }
    }
    
    func post<T: Decodable, U: Encodable>(to endpoint: String, body: U) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw ServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ServiceError.serverError(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw ServiceError.decodingError(error)
            }
        } catch let error as ServiceError {
            throw error
        } catch {
            throw ServiceError.networkError(error)
        }
    }
} 