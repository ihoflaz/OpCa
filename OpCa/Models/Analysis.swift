import Foundation
import SwiftData
import PhotosUI

enum AnalysisType: String, Codable {
    case parasite = "Parasite"
    case mnist = "MNIST"
}

@Model
final class Analysis {
    var id: UUID
    var imageData: Data?
    var location: String?
    var timestamp: Date
    var notes: String
    var analysisTypeString: String? = AnalysisType.parasite.rawValue
    var results: [ParasiteResult]
    var digitResults: [DigitResult]
    var isUploaded: Bool
    var uploadTimestamp: Date?
    
    init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        location: String? = nil,
        timestamp: Date = Date(),
        notes: String = "",
        analysisType: AnalysisType = .parasite,
        results: [ParasiteResult] = [],
        digitResults: [DigitResult] = [],
        isUploaded: Bool = false,
        uploadTimestamp: Date? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.location = location
        self.timestamp = timestamp
        self.notes = notes
        self.analysisTypeString = analysisType.rawValue
        self.results = results
        self.digitResults = digitResults
        self.isUploaded = isUploaded
        self.uploadTimestamp = uploadTimestamp
    }
    
    var analysisType: AnalysisType? {
        get {
            guard let typeString = analysisTypeString else { return nil }
            return AnalysisType(rawValue: typeString)
        }
        set {
            analysisTypeString = newValue?.rawValue
        }
    }
    
    var dominantParasite: ParasiteType? {
        guard analysisType == .parasite, let highestResult = results.max(by: { $0.confidence < $1.confidence }) else {
            return nil
        }
        return highestResult.type
    }
    
    var dominantDigit: DigitType? {
        guard analysisType == .mnist, let highestResult = digitResults.max(by: { $0.confidence < $1.confidence }) else {
            return nil
        }
        return highestResult.type
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var analysisTitle: String {
        switch analysisType {
        case .parasite:
            return "Parazit Analizi"
        case .mnist:
            return "MNIST Rakam Tanıma"
        case .none:
            return "Bilinmeyen Analiz"
        }
    }
} 