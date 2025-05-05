import Foundation
import SwiftData
import PhotosUI

@Model
final class Analysis {
    var id: UUID
    var imageData: Data?
    var location: String?
    var timestamp: Date
    var notes: String
    var results: [ParasiteResult]
    var isUploaded: Bool
    var uploadTimestamp: Date?
    
    init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        location: String? = nil,
        timestamp: Date = Date(),
        notes: String = "",
        results: [ParasiteResult] = [],
        isUploaded: Bool = false,
        uploadTimestamp: Date? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.location = location
        self.timestamp = timestamp
        self.notes = notes
        self.results = results
        self.isUploaded = isUploaded
        self.uploadTimestamp = uploadTimestamp
    }
    
    var dominantParasite: ParasiteType? {
        guard let highestResult = results.max(by: { $0.confidence < $1.confidence }) else {
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
} 