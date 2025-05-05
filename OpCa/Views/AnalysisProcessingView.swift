import SwiftUI
import SwiftData

struct AnalysisProcessingView: View {
    @State private var viewModel = AnalysisViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: FocusField?
    
    enum FocusField {
        case location, notes
    }
    
    let imageData: Data
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch viewModel.analysisState {
                case .ready, .processing:
                    processingView
                case .completed:
                    resultsView
                case .failed:
                    errorView
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if viewModel.analysisState == .completed {
                    Button("New Scan") {
                        dismiss()
                    }
                }
            }
            
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    focusedField = nil
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .task {
            await viewModel.analyzeImage(imageData)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Processing Sample...")
                .font(.title2.bold())
            
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(spacing: 5) {
                ProgressView(value: viewModel.progress)
                    .tint(.blue)
                    .padding(.horizontal)
                
                Text("\(Int(viewModel.progress * 100))%")
            }
            
            Text("AI is analyzing the image for parasitic infections")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .frame(minHeight: 500)
    }
    
    private var resultsView: some View {
        VStack(spacing: 20) {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text("Diagnosis Results")
                .font(.title2.bold())
            
            VStack(spacing: 15) {
                ForEach(viewModel.results.sorted(by: { $0.confidence > $1.confidence })) { result in
                    ParasiteResultRow(result: result, isSelected: viewModel.selectedParasite == result.type)
                        .onTapGesture {
                            viewModel.selectParasite(result.type)
                        }
                }
            }
            .padding(.vertical)
            
            if let selectedParasite = viewModel.selectedParasite,
               let parasiteInfo = viewModel.parasiteInfo {
                VStack(alignment: .leading, spacing: 10) {
                    Text("About \(selectedParasite.rawValue)")
                        .font(.headline)
                    
                    Text(parasiteInfo.description)
                        .font(.subheadline)
                    
                    Text("Treatment")
                        .font(.headline)
                        .padding(.top, 5)
                    
                    Text(parasiteInfo.treatment)
                        .font(.subheadline)
                    
                    NavigationLink("Learn More") {
                        ParasiteInfoView(parasiteType: selectedParasite)
                    }
                    .padding(.top, 5)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer(minLength: 20)
            
            VStack(spacing: 15) {
                TextField("Location (optional)", text: $viewModel.location)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($focusedField, equals: .location)
                
                TextField("Notes (optional)", text: $viewModel.notes)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($focusedField, equals: .notes)
                
                Button("Save Analysis") {
                    focusedField = nil
                    if viewModel.saveAnalysis(context: modelContext) != nil {
                        dismiss()
                    }
                }
                .primaryButtonStyle()
                .padding(.vertical, 10)
            }
            .padding(.top)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.yellow)
            
            Text("Analysis Failed")
                .font(.title2.bold())
            
            Text(viewModel.errorMessage ?? "An unknown error occurred while analyzing the image.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button("Try Again") {
                Task {
                    await viewModel.analyzeImage(imageData)
                }
            }
            .primaryButtonStyle()
            
            Button("Go Back") {
                dismiss()
            }
            .secondaryButtonStyle()
            
            Spacer()
            Spacer()
        }
        .frame(minHeight: 500)
    }
}

struct ParasiteResultRow: View {
    let result: ParasiteResult
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: result.type.icon)
                .font(.title2)
                .foregroundStyle(result.type.color)
                .padding()
                .background(result.type.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(result.type.rawValue)
                    .font(.headline)
                
                Text("Detection confidence")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(result.formattedConfidence)
                .font(.title3.bold())
                .foregroundStyle(result.type.color)
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        AnalysisProcessingView(imageData: Data())
            .modelContainer(for: Analysis.self, inMemory: true)
    }
} 