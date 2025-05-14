import Foundation
import SwiftData

@Observable
class DashboardViewModel {
    private let apiService = APIService()
    var pendingUploads: Int = 0
    var selectedTimeFrame: TimeFrame = .week
    var analysisSummary: AnalysisSummary?
    var errorMessage: String?
    var showError = false
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var id: String { rawValue }
    }
    
    struct AnalysisSummary {
        var totalCount: Int
        var parasiteCounts: [ParasiteType: Int]
        var dateRange: ClosedRange<Date>
    }
    
    func loadPendingUploads(context: ModelContext) {
        let descriptor = FetchDescriptor<Analysis>(predicate: #Predicate { !$0.isUploaded })
        
        do {
            pendingUploads = try context.fetchCount(descriptor)
        } catch {
            errorMessage = "Failed to count pending uploads: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func uploadPendingAnalyses(context: ModelContext) async {
        let descriptor = FetchDescriptor<Analysis>(predicate: #Predicate { !$0.isUploaded })
        
        do {
            let pendingAnalyses = try context.fetch(descriptor)
            
            for analysis in pendingAnalyses {
                do {
                    let success = try await apiService.uploadAnalysis(analysis)
                    
                    if success {
                        analysis.isUploaded = true
                        analysis.uploadTimestamp = Date()
                        try context.save()
                    }
                } catch {
                    print("Failed to upload analysis: \(error.localizedDescription)")
                    // Continue with next analysis
                }
            }
            
            // Update pending count after uploads
            loadPendingUploads(context: context)
        } catch {
            errorMessage = "Failed to fetch pending uploads: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func generateSummary(context: ModelContext) {
        let startDate: Date
        let now = Date()
        
        switch selectedTimeFrame {
        case .day:
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        let descriptor = FetchDescriptor<Analysis>(
            predicate: #Predicate { $0.timestamp >= startDate && $0.timestamp <= now }
        )
        
        do {
            let analyses = try context.fetch(descriptor)
            var parasiteCounts: [ParasiteType: Int] = [:]
            
            // Initialize counts for all parasite types
            for type in ParasiteType.allCases {
                parasiteCounts[type] = 0
            }
            
            // Count occurrences of each parasite type as the dominant one
            for analysis in analyses {
                if analysis.analysisType == .parasite, let dominant = analysis.dominantParasite {
                    parasiteCounts[dominant, default: 0] += 1
                }
            }
            
            analysisSummary = AnalysisSummary(
                totalCount: analyses.count,
                parasiteCounts: parasiteCounts,
                dateRange: startDate...now
            )
        } catch {
            errorMessage = "Failed to generate summary: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func deleteAnalysis(_ analysis: Analysis, context: ModelContext) {
        context.delete(analysis)
        
        // Refresh data
        loadPendingUploads(context: context)
        generateSummary(context: context)
    }
} 