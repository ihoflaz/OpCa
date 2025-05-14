import Foundation
import SwiftUI
import SwiftData

enum DigitType: Int, CaseIterable, Codable, Identifiable {
    case zero = 0
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    
    var id: Int { rawValue }
    
    var color: Color {
        switch self {
        case .zero: return .blue
        case .one: return .green
        case .two: return .orange
        case .three: return .red
        case .four: return .purple
        case .five: return .pink
        case .six: return .yellow
        case .seven: return .mint
        case .eight: return .teal
        case .nine: return .indigo
        }
    }
    
    var icon: String {
        switch self {
        case .zero: return "0.circle.fill"
        case .one: return "1.circle.fill"
        case .two: return "2.circle.fill"
        case .three: return "3.circle.fill"
        case .four: return "4.circle.fill"
        case .five: return "5.circle.fill"
        case .six: return "6.circle.fill"
        case .seven: return "7.circle.fill"
        case .eight: return "8.circle.fill"
        case .nine: return "9.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .zero: return "Rakam Sıfır (0)"
        case .one: return "Rakam Bir (1)"
        case .two: return "Rakam İki (2)"
        case .three: return "Rakam Üç (3)"
        case .four: return "Rakam Dört (4)"
        case .five: return "Rakam Beş (5)"
        case .six: return "Rakam Altı (6)"
        case .seven: return "Rakam Yedi (7)"
        case .eight: return "Rakam Sekiz (8)"
        case .nine: return "Rakam Dokuz (9)"
        }
    }
}

@Model
final class DigitResult: Identifiable {
    var id: UUID = UUID()
    var typeValue: Int
    var confidence: Double
    var detectionDate: Date
    
    init() {
        self.typeValue = 0
        self.confidence = 0
        self.detectionDate = Date()
    }
    
    init(id: UUID = UUID(), type: DigitType, confidence: Double, detectionDate: Date) {
        self.id = id
        self.typeValue = type.rawValue
        self.confidence = confidence
        self.detectionDate = detectionDate
    }
    
    var type: DigitType {
        get {
            return DigitType(rawValue: typeValue) ?? .zero
        }
        set {
            typeValue = newValue.rawValue
        }
    }
    
    var formattedConfidence: String {
        return "\(Int(confidence * 100))%"
    }
} 