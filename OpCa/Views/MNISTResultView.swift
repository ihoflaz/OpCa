import SwiftUI

struct MNISTResultView: View {
    let results: [DigitResult]
    let selectedDigit: DigitType?
    var onDigitSelected: ((DigitType) -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Rakam Tanıma Sonuçları")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    // En yüksek olasılıklı rakam
                    if let topResult = results.max(by: { $0.confidence < $1.confidence }) {
                        HStack {
                            Text("Tanınan Rakam:")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            HStack(spacing: 5) {
                                Image(systemName: topResult.type.icon)
                                    .font(.title)
                                    .foregroundStyle(topResult.type.color)
                                Text("\(topResult.type.rawValue)")
                                    .font(.title2.bold())
                                    .foregroundStyle(topResult.type.color)
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(topResult.type.color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Sonuçları çubuk grafiği olarak göster
                    ForEach(results.sorted(by: { $0.confidence > $1.confidence })) { result in
                        DigitResultRow(
                            result: result,
                            isSelected: selectedDigit == result.type,
                            maxWidth: geometry.size.width - 76 // Padding ve diğer boşluklar için pay bıraktık
                        )
                        .onTapGesture {
                            onDigitSelected?(result.type)
                        }
                    }
                }
                .padding()
                .frame(width: geometry.size.width)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct DigitResultRow: View {
    let result: DigitResult
    let isSelected: Bool
    let maxWidth: CGFloat
    
    var body: some View {
        HStack(spacing: 10) {
            // Rakam ikonu
            ZStack {
                Circle()
                    .fill(result.type.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text("\(result.type.rawValue)")
                    .font(.headline)
                    .foregroundStyle(result.type.color)
            }
            
            // İlerleme çubuğu
            VStack(alignment: .leading, spacing: 4) {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: maxWidth, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Rectangle()
                        .fill(result.type.color)
                        .frame(width: max(12, maxWidth * result.confidence), height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Text(result.formattedConfidence)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Seçiliyse işaret
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DigitInfoView: View {
    let digit: DigitType
    let info: DigitInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: digit.icon)
                    .font(.title)
                    .foregroundStyle(digit.color)
                
                Text(digit.description)
                    .font(.headline)
            }
            .padding(.bottom, 5)
            
            if let info = info {
                Text(info.description)
                    .font(.subheadline)
            } else {
                Text("Rakam \(digit.rawValue) hakkında bilgi yüklenemedi.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let mockResults: [DigitResult] = [
        DigitResult(type: .zero, confidence: 0.05, detectionDate: Date()),
        DigitResult(type: .one, confidence: 0.10, detectionDate: Date()),
        DigitResult(type: .two, confidence: 0.15, detectionDate: Date()),
        DigitResult(type: .three, confidence: 0.05, detectionDate: Date()),
        DigitResult(type: .four, confidence: 0.05, detectionDate: Date()),
        DigitResult(type: .five, confidence: 0.70, detectionDate: Date()),
        DigitResult(type: .six, confidence: 0.05, detectionDate: Date()),
        DigitResult(type: .seven, confidence: 0.05, detectionDate: Date()),
        DigitResult(type: .eight, confidence: 0.05, detectionDate: Date()),
        DigitResult(type: .nine, confidence: 0.05, detectionDate: Date())
    ]
    
    return VStack {
        MNISTResultView(results: mockResults, selectedDigit: .five)
        
        Spacer().frame(height: 20)
        
        DigitInfoView(
            digit: .five,
            info: DigitInfo(
                id: "5",
                value: 5,
                description: "Beş (5) rakamı, sayı sistemimizde önemli bir rakamdır.",
                examples: []
            )
        )
    }
    .padding()
} 