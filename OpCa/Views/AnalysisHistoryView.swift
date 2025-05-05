import SwiftUI
import SwiftData

struct AnalysisHistoryView: View {
    @Query(sort: \Analysis.timestamp, order: .reverse) private var analyses: [Analysis]
    @State private var searchText = ""
    @State private var showingFilterOptions = false
    @State private var filterByParasite: ParasiteType?
    @State private var filterByUploadStatus: Bool?
    private let localization = LocalizationManager.shared
    
    var filteredAnalyses: [Analysis] {
        var result = analyses
        
        // Apply search if any
        if !searchText.isEmpty {
            result = result.filter { analysis in
                let locationMatch = analysis.location?.localizedCaseInsensitiveContains(searchText) ?? false
                let notesMatch = analysis.notes.localizedCaseInsensitiveContains(searchText)
                let parasiteMatch = analysis.results.contains { $0.type.rawValue.localizedCaseInsensitiveContains(searchText) }
                return locationMatch || notesMatch || parasiteMatch
            }
        }
        
        // Apply parasite filter if selected
        if let filterParasite = filterByParasite {
            result = result.filter { analysis in
                analysis.results.contains { $0.type == filterParasite }
            }
        }
        
        // Apply upload status filter if selected
        if let uploadStatus = filterByUploadStatus {
            result = result.filter { $0.isUploaded == uploadStatus }
        }
        
        return result
    }
    
    var body: some View {
        List {
            ForEach(filteredAnalyses) { analysis in
                NavigationLink {
                    AnalysisDetailView(analysis: analysis)
                } label: {
                    AnalysisHistoryRow(analysis: analysis)
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle(localization.localizedString(for: "history_title"))
        .searchable(text: $searchText, prompt: localization.localizedString(for: "search"))
        .overlay {
            if analyses.isEmpty {
                ContentUnavailableView(
                    localization.localizedString(for: "no_analyses"),
                    systemImage: "doc.text.magnifyingglass",
                    description: Text(localization.localizedString(for: "start_new_analysis"))
                )
            } else if filteredAnalyses.isEmpty {
                ContentUnavailableView(
                    localization.localizedString(for: "no_results"),
                    systemImage: "magnifyingglass",
                    description: Text(localization.localizedString(for: "try_changing_search"))
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingFilterOptions = true
                } label: {
                    Label(localization.localizedString(for: "filter"), systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingFilterOptions) {
            FilterView(
                filterByParasite: $filterByParasite,
                filterByUploadStatus: $filterByUploadStatus
            )
            .presentationDetents([.medium])
        }
    }
}

struct AnalysisHistoryRow: View {
    let analysis: Analysis
    
    var body: some View {
        HStack(spacing: 15) {
            // Thumbnail image
            if let imageData = analysis.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.formattedDate)
                    .font(.headline)
                    .foregroundStyle(.primary) // Explicitly set foreground
                
                if let dominantType = analysis.dominantParasite {
                    HStack {
                        Image(systemName: dominantType.icon)
                            .foregroundStyle(dominantType.color)
                        
                        Text(dominantType.rawValue)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
                
                if let location = analysis.location, !location.isEmpty {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Upload status indicator with chevron
            HStack(spacing: 10) {
                Image(systemName: analysis.isUploaded ? "checkmark.circle.fill" : "arrow.up.circle")
                    .foregroundStyle(analysis.isUploaded ? .green : .orange)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle()) // Make entire row tappable
        .padding(.vertical, 4) // Add vertical padding
    }
}

struct FilterView: View {
    @Binding var filterByParasite: ParasiteType?
    @Binding var filterByUploadStatus: Bool?
    @Environment(\.dismiss) private var dismiss
    private let localization = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section(localization.localizedString(for: "filter_by_parasite")) {
                    Button {
                        filterByParasite = nil
                    } label: {
                        HStack {
                            Text(localization.localizedString(for: "filter_all"))
                            Spacer()
                            if filterByParasite == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    ForEach(ParasiteType.allCases) { type in
                        Button {
                            filterByParasite = type
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundStyle(type.color)
                                Text(type.rawValue)
                                Spacer()
                                if filterByParasite == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(localization.localizedString(for: "filter_by_upload_status")) {
                    Button {
                        filterByUploadStatus = nil
                    } label: {
                        HStack {
                            Text(localization.localizedString(for: "filter_all"))
                            Spacer()
                            if filterByUploadStatus == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    Button {
                        filterByUploadStatus = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(localization.localizedString(for: "uploaded"))
                            Spacer()
                            if filterByUploadStatus == true {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    Button {
                        filterByUploadStatus = false
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.circle")
                                .foregroundStyle(.orange)
                            Text(localization.localizedString(for: "not_uploaded"))
                            Spacer()
                            if filterByUploadStatus == false {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                Section {
                    Button(localization.localizedString(for: "reset_filters")) {
                        filterByParasite = nil
                        filterByUploadStatus = nil
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle(localization.localizedString(for: "filter_options"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.localizedString(for: "done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnalysisHistoryView()
            .modelContainer(for: Analysis.self, inMemory: true)
    }
} 