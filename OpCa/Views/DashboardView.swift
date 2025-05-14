import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var analyses: [Analysis]
    @State private var showDeveloperOptions = false
    private let localization = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats section
                    statsView
                    
                    // Visualization section
                    if let summary = viewModel.analysisSummary {
                        visualizationView(summary: summary)
                    }
                    
                    // Developer Options (For Testing All Views)
                    developerOptionsView
                        .opacity(showDeveloperOptions ? 1 : 0)
                        .frame(height: showDeveloperOptions ? nil : 0)
                    
                    // Recent analyses section
                    recentAnalysesView
                }
                .padding()
            }
            .navigationTitle(localization.localizedString(for: "dashboard"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.pendingUploads > 0 {
                        Button {
                            Task {
                                await viewModel.uploadPendingAnalyses(context: modelContext)
                            }
                        } label: {
                            Label("Upload", systemImage: "arrow.up.to.line")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            showDeveloperOptions.toggle()
                        }
                    } label: {
                        Image(systemName: "hammer.circle")
                            .foregroundColor(showDeveloperOptions ? .blue : .gray)
                    }
                }
            }
            .overlay {
                if analyses.isEmpty {
                    ContentUnavailableView {
                        Label(localization.localizedString(for: "no_analyses"), systemImage: "doc.text.magnifyingglass")
                    } description: {
                        Text(localization.localizedString(for: "start_new_analysis"))
                    } actions: {
                        // Demo veri yoksa, oluşturmak için buton ekle
                        Button("Create Demo Data") {
                            SampleDataGenerator.populateSampleData(context: modelContext)
                        }
                        .primaryButtonStyle()
                    }
                }
            }
            .refreshable {
                viewModel.loadPendingUploads(context: modelContext)
                viewModel.generateSummary(context: modelContext)
            }
            .task {
                viewModel.loadPendingUploads(context: modelContext)
                viewModel.generateSummary(context: modelContext)
            }
            .onChange(of: viewModel.selectedTimeFrame) {
                viewModel.generateSummary(context: modelContext)
            }
        }
    }
    
    private var statsView: some View {
        VStack(spacing: 20) {
            HStack {
                Text(localization.localizedString(for: "statistics"))
                    .font(.headline)
                
                Spacer()
                
                Picker(localization.localizedString(for: "filter"), selection: $viewModel.selectedTimeFrame) {
                    ForEach(DashboardViewModel.TimeFrame.allCases) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(.menu)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                StatCard(
                    title: localization.localizedString(for: "total_scans"),
                    value: "\(viewModel.analysisSummary?.totalCount ?? 0)",
                    icon: "chart.bar.doc.horizontal",
                    color: .blue
                )
                
                StatCard(
                    title: localization.localizedString(for: "pending_uploads"),
                    value: "\(viewModel.pendingUploads)",
                    icon: "arrow.up.circle",
                    color: viewModel.pendingUploads > 0 ? .orange : .green
                )
                
                if let summary = viewModel.analysisSummary {
                    let highestCountType = ParasiteType.allCases.max(by: {
                        summary.parasiteCounts[$0] ?? 0 < summary.parasiteCounts[$1] ?? 0
                    })
                    
                    if let highestType = highestCountType {
                        StatCard(
                            title: localization.localizedString(for: "most_common"),
                            value: highestType.rawValue,
                            icon: highestType.icon,
                            color: highestType.color
                        )
                    }
                    
                    let totalInfections = summary.parasiteCounts.values.reduce(0, +)
                    StatCard(
                        title: localization.localizedString(for: "infection_rate"),
                        value: "\(Int((Double(totalInfections) / Double(max(1, summary.totalCount))) * 100))%",
                        icon: "chart.pie.fill",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func visualizationView(summary: DashboardViewModel.AnalysisSummary) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(localization.localizedString(for: "parasite_distribution"))
                .font(.headline)
            
            Chart {
                ForEach(ParasiteType.allCases) { type in
                    SectorMark(
                        angle: .value("Count", summary.parasiteCounts[type] ?? 0),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(type.color)
                    .cornerRadius(5)
                    .opacity(0.8)
                    .annotation(position: .overlay) {
                        if (summary.parasiteCounts[type] ?? 0) > 0 {
                            Text("\(summary.parasiteCounts[type] ?? 0)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .frame(height: 200)
            
            // Legend
            HStack {
                ForEach(ParasiteType.allCases) { type in
                    HStack {
                        Circle()
                            .fill(type.color)
                            .frame(width: 10, height: 10)
                        
                        Text(type.rawValue)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var developerOptionsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Developer Test Navigation")
                .font(.headline)
            
            Text("Access all views directly for testing")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(spacing: 12) {
                // Mock data for testing
                let mockImageData = UIImage(systemName: "photo")?.pngData().map { IdentifiableData(data: $0) }
                let currentDate = Date()
                let mockParasiteResults = [
                    ParasiteResult(type: .neosporosis, confidence: 0.87, detectionDate: currentDate),
                    ParasiteResult(type: .echinococcosis, confidence: 0.10, detectionDate: currentDate),
                    ParasiteResult(type: .coenurosis, confidence: 0.03, detectionDate: currentDate)
                ]
                let mockAnalysis = Analysis(
                    imageData: UIImage(systemName: "microscope")?.pngData(),
                    location: "Test Location",
                    timestamp: Date(),
                    notes: "Test analysis",
                    analysisType: .parasite,
                    results: mockParasiteResults
                )
                
                // Navigation buttons
                NavigationLink(destination: CameraView { _ in }) {
                    navButton(title: "Camera View", icon: "camera.fill")
                }
                
                NavigationLink(destination: mockImageData.map { AnalysisProcessingView(imageData: $0.data) }) {
                    navButton(title: "Analysis Processing View", icon: "waveform")
                }
                
                NavigationLink(destination: AnalysisDetailView(analysis: mockAnalysis)) {
                    navButton(title: "Analysis Detail View", icon: "doc.text.magnifyingglass")
                }
                
                NavigationLink(destination: ParasiteInfoView(parasiteType: .neosporosis)) {
                    navButton(title: "Parasite Info View (Neosporosis)", icon: "info.circle")
                }
                
                NavigationLink(destination: ParasiteInfoView(parasiteType: .echinococcosis)) {
                    navButton(title: "Parasite Info View (Echinococcosis)", icon: "info.circle")
                }
                
                NavigationLink(destination: ParasiteInfoView(parasiteType: .coenurosis)) {
                    navButton(title: "Parasite Info View (Coenurosis)", icon: "info.circle")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func navButton(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
    
    private var recentAnalysesView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(localization.localizedString(for: "recent_scans"))
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: AnalysisHistoryView()) {
                    Text(localization.localizedString(for: "view_all"))
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            
            if analyses.isEmpty {
                Text(localization.localizedString(for: "no_recent_scans"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(analyses.sorted(by: { $0.timestamp > $1.timestamp }).prefix(5))) { analysis in
                            NavigationLink(destination: AnalysisDetailView(analysis: analysis)) {
                                AnalysisCardView(analysis: analysis)
                                    .frame(width: 180, height: 200)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 5) // A little padding for shadows
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// AnalysisCardView bileşenini ekle
struct AnalysisCardView: View {
    let analysis: Analysis
    
    var body: some View {
        if analysis.analysisType == nil {
            VStack(alignment: .leading, spacing: 8) {
                Text("Geçersiz Analiz")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Bu analiz düzgün yüklenemedi.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 180, height: 200)
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2, x: 0, y: 1)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail image
                ZStack(alignment: .topTrailing) {
                    if let imageData = analysis.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 120)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                                    .font(.largeTitle)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Upload status indicator
                    Image(systemName: analysis.isUploaded ? "checkmark.circle.fill" : "arrow.up.circle")
                        .foregroundStyle(analysis.isUploaded ? .green : .orange)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(6)
                }
                
                // Date
                Text(analysis.formattedDate)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                // Dominant parasite
                if let dominantType = analysis.dominantParasite {
                    HStack {
                        Image(systemName: dominantType.icon)
                            .foregroundStyle(dominantType.color)
                        
                        Text(dominantType.rawValue)
                            .font(.subheadline)
                    }
                } else {
                    Text(LocalizationManager.shared.localizedString(for: "no_parasites_detected"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Location if available
                if let location = analysis.location, !location.isEmpty {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2, x: 0, y: 1)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Analysis.self, inMemory: true)
} 