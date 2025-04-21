import SwiftUI

struct ResultView: View {
    let result: AnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analiz Sonuçları")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tespit Edilen Parazit:")
                        .foregroundColor(.secondary)
                    Text(result.parasiteType)
                        .bold()
                }
                
                HStack {
                    Text("Doğruluk Oranı:")
                        .foregroundColor(.secondary)
                    Text("%\(Int(result.confidence * 100))")
                        .bold()
                        .foregroundColor(result.confidence > 0.9 ? .green : .orange)
                }
                
                Text(result.details)
                    .font(.callout)
                    .padding(.top, 4)
                
                Text("Analiz Tarihi: \(result.timestamp.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
        .padding()
    }
} 