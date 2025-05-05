import SwiftUI
import SwiftData

struct AnalysisDetailView: View {
    let analysis: Analysis
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var isUploading = false
    
    private let apiService = APIService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image and timestamp
                VStack(spacing: 10) {
                    if let imageData = analysis.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                        
                        Text(analysis.formattedDate)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if let location = analysis.location, !location.isEmpty {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundStyle(.secondary)
                                
                                Text(location)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Results
                VStack(alignment: .leading, spacing: 15) {
                    Text("Results")
                        .font(.headline)
                    
                    if analysis.results.isEmpty {
                        Text("No parasites detected in this sample")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(analysis.results.sorted(by: { $0.confidence > $1.confidence })) { result in
                            ParasiteResultRow(result: result, isSelected: false)
                                .contextMenu {
                                    NavigationLink(destination: ParasiteInfoView(parasiteType: result.type)) {
                                        Label("View Details", systemImage: "info.circle")
                                    }
                                }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Notes section
                if !analysis.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.headline)
                        
                        Text(analysis.notes)
                            .foregroundStyle(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Upload status
                VStack(alignment: .leading, spacing: 10) {
                    Text("Upload Status")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: analysis.isUploaded ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(analysis.isUploaded ? .green : .orange)
                        
                        VStack(alignment: .leading) {
                            Text(analysis.isUploaded ? "Uploaded to System" : "Not Uploaded")
                                .font(.subheadline)
                            
                            if let uploadTime = analysis.uploadTimestamp {
                                Text("Uploaded on \(formattedDate(uploadTime))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if !analysis.isUploaded {
                            Button {
                                uploadAnalysis()
                            } label: {
                                if isUploading {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Text("Upload")
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .disabled(isUploading)
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Action buttons
                HStack(spacing: 15) {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    NavigationLink(destination: ParasiteInfoView(parasiteType: analysis.dominantParasite ?? .neosporosis)) {
                        Label("Learn More", systemImage: "info.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Analysis Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Analysis", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { 
                deleteAnalysis()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this analysis? This action cannot be undone.")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func uploadAnalysis() {
        isUploading = true
        
        Task {
            do {
                let success = try await apiService.uploadAnalysis(analysis)
                
                await MainActor.run {
                    isUploading = false
                    
                    if success {
                        analysis.isUploaded = true
                        analysis.uploadTimestamp = Date()
                        try? modelContext.save()
                    }
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                }
                
                print("Failed to upload analysis: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteAnalysis() {
        modelContext.delete(analysis)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Analysis.self, configurations: config)
    
    // Create a sample analysis for preview
    let analysis = Analysis(
        imageData: nil,
        location: "Sample Location",
        timestamp: Date(),
        notes: "This is a sample note for the analysis.",
        results: [
            ParasiteResult(type: .neosporosis, confidence: 0.87, detectionDate: Date()),
            ParasiteResult(type: .echinococcosis, confidence: 0.10, detectionDate: Date())
        ],
        isUploaded: true,
        uploadTimestamp: Date().addingTimeInterval(-3600)
    )
    
    return NavigationStack {
        AnalysisDetailView(analysis: analysis)
            .modelContainer(container)
    }
} 