import Foundation
import UIKit

enum ServiceError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case unknownError
    case invalidImage
    case modelPredictionFailed(String)
    case modelNotLoaded(String)
    
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
        case .invalidImage:
            return "Görüntü işlenemedi veya MNIST formatına dönüştürülemedi"
        case .modelPredictionFailed(let reason):
            return "CoreML tahmin hatası: \(reason)"
        case .modelNotLoaded(let reason):
            return "Model yüklenemedi: \(reason)"
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

struct DigitInfo: Identifiable, Codable {
    let id: String
    let value: Int
    let description: String
    let examples: [URL]
}

// API iletişimi için kullanılacak DTO (Data Transfer Object) modelleri
struct ParasiteResultDTO: Codable, Identifiable {
    var id: UUID
    var typeString: String
    var confidence: Double
    var detectionDate: Date
    
    // ParasiteResult modelinden dönüşüm için initializer
    init(from parasiteResult: ParasiteResult) {
        self.id = parasiteResult.id
        self.typeString = parasiteResult.typeString
        self.confidence = parasiteResult.confidence
        self.detectionDate = parasiteResult.detectionDate
    }
    
    // ParasiteResult modeline dönüşüm
    func toParasiteResult() -> ParasiteResult {
        let result = ParasiteResult()
        result.id = self.id
        result.typeString = self.typeString
        result.confidence = self.confidence
        result.detectionDate = self.detectionDate
        return result
    }
}

struct DigitResultDTO: Codable, Identifiable {
    var id: UUID
    var typeValue: Int
    var confidence: Double
    var detectionDate: Date
    
    // DigitResult modelinden dönüşüm için initializer
    init(from digitResult: DigitResult) {
        self.id = digitResult.id
        self.typeValue = digitResult.typeValue
        self.confidence = digitResult.confidence
        self.detectionDate = digitResult.detectionDate
    }
    
    // DigitResult modeline dönüşüm
    func toDigitResult() -> DigitResult {
        let result = DigitResult()
        result.id = self.id
        result.typeValue = self.typeValue
        result.confidence = self.confidence
        result.detectionDate = self.detectionDate
        return result
    }
}

struct AnalysisRequest: Codable {
    let imageData: Data
    let metadata: [String: String]
    let analysisType: String
}

struct AnalysisResponse: Codable {
    let results: [ParasiteResultDTO]
    let processingTimeMs: Int
    let timestamp: Date
}

@Observable
class APIService {
    private let baseURL = "https://api.example.com"
    private let mnistService = MNISTService.shared
    
    enum AnalysisMode {
        case parasite
        case mnist
    }
    
    var analysisMode: AnalysisMode = .parasite
    
    func analyzeImage(_ imageData: Data) async throws -> [ParasiteResult] {
        // Parazit modu aktifse standart analiz yap
        if analysisMode == .parasite {
            // Mock implementasyon - gerçek bir uygulamada sunucuya görüntü gönderilir
            try await Task.sleep(for: .seconds(2))
            
            let result1 = ParasiteResult()
            result1.typeString = ParasiteType.neosporosis.rawValue
            result1.confidence = 0.87
            result1.detectionDate = Date()
            
            let result2 = ParasiteResult()
            result2.typeString = ParasiteType.echinococcosis.rawValue
            result2.confidence = 0.10
            result2.detectionDate = Date()
            
            let result3 = ParasiteResult()
            result3.typeString = ParasiteType.coenurosis.rawValue
            result3.confidence = 0.03
            result3.detectionDate = Date()
            
            return [result1, result2, result3]
        } else {
            // MNIST modu - boş parazit sonucu döndür
            return []
        }
    }
    
    func analyzeImageWithMNIST(_ imageData: Data) async throws -> [DigitResult] {
        guard let image = UIImage(data: imageData) else {
            throw ServiceError.invalidResponse
        }
        
        return try await mnistService.recognizeDigit(from: image)
    }
    
    func analyzeImageBoth(_ imageData: Data) async throws -> (parasiteResults: [ParasiteResult], digitResults: [DigitResult]) {
        async let parasiteResults = analyzeImage(imageData)
        async let digitResults = analyzeImageWithMNIST(imageData)
        
        return try await (parasiteResults: parasiteResults, digitResults: digitResults)
    }
    
    func getParasiteInfo(for type: ParasiteType) async throws -> ParasiteInfo {
        // Mock implementasyon
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
    
    func getDigitInfo(for digit: DigitType) async throws -> DigitInfo {
        // Mock implementasyon
        try await Task.sleep(for: .seconds(0.5))
        
        return DigitInfo(
            id: String(digit.rawValue),
            value: digit.rawValue,
            description: "Rakam \(digit.rawValue) hakkında genel bilgi ve kullanım örnekleri.",
            examples: []
        )
    }
    
    func uploadAnalysis(_ analysis: Analysis) async throws -> Bool {
        // Mock implementasyon
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