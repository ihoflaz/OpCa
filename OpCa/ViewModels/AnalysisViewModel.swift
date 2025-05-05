import Foundation
import SwiftUI
import SwiftData

@Observable
class AnalysisViewModel {
    private let apiService = APIService()
    
    var analysisState: AnalysisState = .ready
    var progress: Double = 0.0
    var imageData: Data?
    var results: [ParasiteResult] = []
    var selectedParasite: ParasiteType?
    var parasiteInfo: ParasiteInfo?
    var errorMessage: String?
    var showError = false
    var notes: String = ""
    var location: String = ""
    
    enum AnalysisState {
        case ready
        case processing
        case completed
        case failed
    }
    
    func analyzeImage(_ imageData: Data) async {
        guard analysisState != .processing else { return }
        
        self.imageData = imageData
        self.analysisState = .processing
        self.progress = 0.0
        
        // Simulate progress
        let progressTask = Task { @MainActor in
            for i in 1...10 {
                try await Task.sleep(for: .seconds(0.2))
                self.progress = Double(i) / 10.0
            }
        }
        
        do {
            self.results = try await apiService.analyzeImage(imageData)
            self.analysisState = .completed
            progressTask.cancel()
            self.progress = 1.0
            
            // Select the dominant parasite automatically
            if let dominant = results.max(by: { $0.confidence < $1.confidence }) {
                selectParasite(dominant.type)
            }
        } catch {
            self.analysisState = .failed
            self.errorMessage = error.localizedDescription
            self.showError = true
            progressTask.cancel()
            self.progress = 0.0
        }
    }
    
    func selectParasite(_ parasiteType: ParasiteType) {
        selectedParasite = parasiteType
        
        // Fetch parasite info
        Task {
            do {
                parasiteInfo = try await apiService.getParasiteInfo(for: parasiteType)
            } catch {
                errorMessage = "Failed to load parasite information: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    func saveAnalysis(context: ModelContext) -> Analysis? {
        guard let imageData = imageData, !results.isEmpty else {
            errorMessage = "No analysis data to save"
            showError = true
            return nil
        }
        
        let analysis = Analysis(
            imageData: imageData,
            location: location.isEmpty ? nil : location,
            timestamp: Date(),
            notes: notes,
            results: results,
            isUploaded: false
        )
        
        context.insert(analysis)
        
        // If auto-sync is enabled, upload the analysis
        if UserDefaults.standard.bool(forKey: "autoDataSync") {
            Task {
                await uploadAnalysis(analysis, context: context)
            }
        }
        
        return analysis
    }
    
    func uploadAnalysis(_ analysis: Analysis, context: ModelContext) async {
        do {
            let success = try await apiService.uploadAnalysis(analysis)
            
            if success {
                analysis.isUploaded = true
                analysis.uploadTimestamp = Date()
                try context.save()
            }
        } catch {
            print("Failed to upload analysis: \(error.localizedDescription)")
            // Will retry next time
        }
    }
    
    func reset() {
        imageData = nil
        results = []
        selectedParasite = nil
        parasiteInfo = nil
        analysisState = .ready
        progress = 0.0
        notes = ""
        location = ""
    }
} 