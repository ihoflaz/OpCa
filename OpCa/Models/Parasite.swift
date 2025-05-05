import Foundation
import SwiftUI

enum ParasiteType: String, CaseIterable, Codable, Identifiable {
    case neosporosis = "Neosporosis"
    case echinococcosis = "Echinococcosis"
    case coenurosis = "Coenurosis"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .neosporosis: return .red
        case .echinococcosis: return .orange
        case .coenurosis: return .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .neosporosis: return "microbe.fill"
        case .echinococcosis: return "allergens.fill"
        case .coenurosis: return "ladybug.fill"
        }
    }
    
    var description: String {
        switch self {
        case .neosporosis: 
            return "Neosporosis is a parasitic disease caused by Neospora caninum, primarily affecting dogs and cattle."
        case .echinococcosis:
            return "Echinococcosis is a parasitic disease caused by infection with tiny tapeworms of the genus Echinococcus."
        case .coenurosis:
            return "Coenurosis is a parasitic disease caused by the larval stage (coenurus) of the tapeworm Taenia multiceps."
        }
    }
}

struct ParasiteResult: Identifiable, Codable {
    var id: UUID = UUID()
    var type: ParasiteType
    var confidence: Double
    var detectionDate: Date
    
    var formattedConfidence: String {
        return "\(Int(confidence * 100))%"
    }
} 