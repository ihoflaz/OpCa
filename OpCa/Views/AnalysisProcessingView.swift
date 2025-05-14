import SwiftUI
import SwiftData

struct AnalysisProcessingView: View {
    enum AnalysisType {
        case parasite
        case mnist
    }
    
    let analysisType: AnalysisType
    let imageData: Data
    
    @State private var parasiteViewModel = AnalysisViewModel()
    @State private var mnistViewModel = MNISTViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: FocusField?
    
    enum FocusField {
        case location, notes
    }
    
    init(imageData: Data, analysisType: AnalysisType = .parasite) {
        self.imageData = imageData
        self.analysisType = analysisType
    }
    
    // MNIST modelinden gelen ViewModel'i kullanarak bir view oluştur
    init(mnistViewModel: MNISTViewModel) {
        self.imageData = mnistViewModel.imageData ?? Data()
        self.analysisType = .mnist
        self._mnistViewModel = State(initialValue: mnistViewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch analysisType {
                case .parasite:
                    parasiteAnalysisView
                case .mnist:
                    mnistAnalysisView
                }
            }
            .padding()
            .safeAreaInset(edge: .top) {
                Color.clear
                    .frame(height: 1)
                    .background(.clear)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(analysisType == .parasite ? "Parazit Analizi" : "Rakam Tanıma")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if (analysisType == .parasite && parasiteViewModel.analysisState == .completed) ||
                   (analysisType == .mnist && mnistViewModel.analysisState == .completed) {
                    Button("Yeni Tarama") {
                        dismiss()
                    }
                }
            }
            
            ToolbarItem(placement: .keyboard) {
                Button("Tamam") {
                    focusedField = nil
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .alert(isPresented: analysisType == .parasite ? $parasiteViewModel.showError : $mnistViewModel.showError) {
            Alert(
                title: Text("Hata"),
                message: Text(analysisType == .parasite ? 
                              parasiteViewModel.errorMessage ?? "Bilinmeyen bir hata oluştu" :
                              mnistViewModel.errorMessage ?? "Bilinmeyen bir hata oluştu"),
                dismissButton: .default(Text("Tamam"))
            )
        }
        .task {
            if analysisType == .parasite {
                await parasiteViewModel.analyzeImage(imageData)
            } else if !mnistViewModel.isDrawingMode { // Çizim modunda değilse görüntüyü analiz et
                await mnistViewModel.analyzeImage(imageData)
            } else { // Çizim modundaysa çizimi analiz et
                await mnistViewModel.analyzeDrawing()
            }
        }
    }
    
    // MARK: - Parasite Analysis Views
    
    private var parasiteAnalysisView: some View {
        Group {
            switch parasiteViewModel.analysisState {
            case .ready, .processing:
                parasiteProcessingView
            case .completed:
                parasiteResultsView
            case .failed:
                errorView(viewModel: parasiteViewModel)
            }
        }
    }
    
    private var parasiteProcessingView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Numune İşleniyor...")
                .font(.title2.bold())
            
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(spacing: 5) {
                ProgressView(value: parasiteViewModel.progress)
                    .tint(.blue)
                    .padding(.horizontal)
                
                Text("\(Int(parasiteViewModel.progress * 100))%")
            }
            
            Text("Yapay zeka görüntüdeki parazitik enfeksiyonları analiz ediyor")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .frame(minHeight: 500)
    }
    
    private var parasiteResultsView: some View {
        VStack(spacing: 20) {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text("Teşhis Sonuçları")
                .font(.title2.bold())
            
            VStack(spacing: 15) {
                ForEach(parasiteViewModel.results.sorted(by: { $0.confidence > $1.confidence })) { result in
                    ParasiteResultRow(result: result, isSelected: parasiteViewModel.selectedParasite == result.type)
                        .onTapGesture {
                            parasiteViewModel.selectParasite(result.type)
                        }
                }
            }
            .padding(.vertical)
            
            if let selectedParasite = parasiteViewModel.selectedParasite,
               let parasiteInfo = parasiteViewModel.parasiteInfo {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(selectedParasite.rawValue) Hakkında")
                        .font(.headline)
                    
                    Text(parasiteInfo.description)
                        .font(.subheadline)
                    
                    Text("Tedavi")
                        .font(.headline)
                        .padding(.top, 5)
                    
                    Text(parasiteInfo.treatment)
                        .font(.subheadline)
                    
                    NavigationLink("Daha Fazla Bilgi") {
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
                TextField("Konum (isteğe bağlı)", text: $parasiteViewModel.location)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($focusedField, equals: .location)
                
                TextField("Notlar (isteğe bağlı)", text: $parasiteViewModel.notes)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($focusedField, equals: .notes)
                
                Button("Analizi Kaydet") {
                    focusedField = nil
                    if parasiteViewModel.saveAnalysis(context: modelContext) != nil {
                        dismiss()
                    }
                }
                .primaryButtonStyle()
                .padding(.vertical, 10)
            }
            .padding(.top)
        }
    }
    
    // MARK: - MNIST Analysis Views
    
    private var mnistAnalysisView: some View {
        Group {
            switch mnistViewModel.analysisState {
            case .ready, .processing:
                mnistProcessingView
            case .completed:
                mnistResultsView
            case .failed:
                errorView(viewModel: mnistViewModel)
            }
        }
    }
    
    private var mnistProcessingView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Rakam Tanınıyor...")
                .font(.title2.bold())
            
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(spacing: 5) {
                ProgressView(value: mnistViewModel.progress)
                    .tint(.blue)
                    .padding(.horizontal)
                
                Text("\(Int(mnistViewModel.progress * 100))%")
            }
            
            Text("Yapay zeka çizilen rakamı tanımaya çalışıyor")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            Spacer()
        }
        .frame(minHeight: 500)
    }
    
    private var mnistResultsView: some View {
        VStack(spacing: 20) {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text("Rakam Tanıma Sonucu")
                .font(.title2.bold())
            
            // MNIST sonuç bileşeni
            MNISTResultView(
                results: mnistViewModel.digitResults,
                selectedDigit: mnistViewModel.selectedDigit,
                onDigitSelected: { digit in
                    mnistViewModel.selectDigit(digit)
                }
            )
            
            // Seçili rakam hakkında bilgi
            if let selectedDigit = mnistViewModel.selectedDigit {
                DigitInfoView(
                    digit: selectedDigit,
                    info: mnistViewModel.digitInfo
                )
            }
            
            Spacer(minLength: 20)
            
            VStack(spacing: 15) {
                TextField("Konum (isteğe bağlı)", text: $mnistViewModel.location)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($focusedField, equals: .location)
                
                TextField("Notlar (isteğe bağlı)", text: $mnistViewModel.notes)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($focusedField, equals: .notes)
                
                Button("Analizi Kaydet") {
                    focusedField = nil
                    if mnistViewModel.saveAnalysis(context: modelContext) != nil {
                        dismiss()
                    }
                }
                .primaryButtonStyle()
                .padding(.vertical, 10)
            }
            .padding(.top)
        }
    }
    
    // MARK: - Common Error View
    
    private func errorView<T: AnyObject>(viewModel: T) -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.yellow)
            
            Text("Analiz Başarısız")
                .font(.title2.bold())
            
            Text(errorMessage(for: viewModel))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button("Tekrar Dene") {
                Task {
                    if let vm = viewModel as? AnalysisViewModel {
                        await vm.analyzeImage(imageData)
                    } else if let vm = viewModel as? MNISTViewModel {
                        if vm.isDrawingMode {
                            await vm.analyzeDrawing()
                        } else {
                            await vm.analyzeImage(imageData)
                        }
                    }
                }
            }
            .primaryButtonStyle()
            
            Button("Geri Dön") {
                dismiss()
            }
            .secondaryButtonStyle()
            
            Spacer()
            Spacer()
        }
        .frame(minHeight: 500)
    }
    
    private func errorMessage(for viewModel: Any) -> String {
        if let vm = viewModel as? AnalysisViewModel {
            return vm.errorMessage ?? "Görüntü analiz edilirken bilinmeyen bir hata oluştu."
        } else if let vm = viewModel as? MNISTViewModel {
            return vm.errorMessage ?? "Rakam tanıma sırasında bilinmeyen bir hata oluştu."
        }
        return "Bilinmeyen bir hata oluştu."
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

#Preview("Parazit Analizi") {
    NavigationStack {
        AnalysisProcessingView(imageData: Data(), analysisType: .parasite)
            .modelContainer(for: Analysis.self, inMemory: true)
    }
}

#Preview("MNIST Analizi") {
    NavigationStack {
        AnalysisProcessingView(imageData: Data(), analysisType: .mnist)
            .modelContainer(for: Analysis.self, inMemory: true)
    }
} 