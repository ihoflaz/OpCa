import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var analyses: [Analysis]
    @State private var showDeveloperOptions = false
    
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
            .navigationTitle("Dashboard")
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
                    ContentUnavailableView(
                        "No Analysis Data",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Start by capturing a sample image to analyze it for parasites")
                    )
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
                Text("Statistics")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Frame", selection: $viewModel.selectedTimeFrame) {
                    ForEach(DashboardViewModel.TimeFrame.allCases) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(.menu)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                StatCard(
                    title: "Total Analyses",
                    value: "\(viewModel.analysisSummary?.totalCount ?? 0)",
                    icon: "chart.bar.doc.horizontal",
                    color: .blue
                )
                
                StatCard(
                    title: "Pending Uploads",
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
                            title: "Most Common",
                            value: highestType.rawValue,
                            icon: highestType.icon,
                            color: highestType.color
                        )
                    }
                    
                    let totalInfections = summary.parasiteCounts.values.reduce(0, +)
                    StatCard(
                        title: "Infection Rate",
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
            Text("Parasite Distribution")
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
            Text("Recent Analyses")
                .font(.headline)
            
            ForEach(Array(analyses.prefix(5).enumerated()), id: \.element.id) { index, analysis in
                NavigationLink(destination: AnalysisDetailView(analysis: analysis)) {
                    HStack {
                        if let imageData = analysis.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 70, height: 70)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(analysis.formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            
                            if let dominantType = analysis.dominantParasite {
                                HStack {
                                    Image(systemName: dominantType.icon)
                                        .foregroundStyle(dominantType.color)
                                    
                                    Text(dominantType.rawValue)
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            } else {
                                Text("No parasites detected")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            
                            if let location = analysis.location, !location.isEmpty {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(.secondary)
                                    
                                    Text(location)
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if analyses.count > 5 {
                NavigationLink("View All Analyses") {
                    AnalysisHistoryView()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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

#Preview {
    DashboardView()
        .modelContainer(for: Analysis.self, inMemory: true)
} 