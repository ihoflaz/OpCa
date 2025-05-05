import SwiftUI

struct ParasiteInfoView: View {
    let parasiteType: ParasiteType
    @State private var parasiteInfo: ParasiteInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let apiService = APIService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let info = parasiteInfo {
                    infoView(info: info)
                }
            }
            .padding()
        }
        .navigationTitle(parasiteType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadParasiteInfo()
        }
    }
    
    private func loadParasiteInfo() async {
        isLoading = true
        
        do {
            parasiteInfo = try await apiService.getParasiteInfo(for: parasiteType)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Loading information...")
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)
            
            Text("Failed to load information")
                .font(.headline)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("Try Again") {
                Task {
                    await loadParasiteInfo()
                }
            }
            .primaryButtonStyle()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    private func infoView(info: ParasiteInfo) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon and name
            HStack {
                Image(systemName: parasiteType.icon)
                    .font(.largeTitle)
                    .foregroundStyle(parasiteType.color)
                    .padding()
                    .background(parasiteType.color.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(info.name)
                        .font(.title.bold())
                    
                    Text("Parasitic Infection")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom)
            
            // Description
            VStack(alignment: .leading, spacing: 10) {
                Text("About")
                    .font(.headline)
                
                Text(info.description)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .cardStyle()
            
            // Treatment
            VStack(alignment: .leading, spacing: 10) {
                Text("Treatment")
                    .font(.headline)
                
                Text(info.treatment)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .cardStyle()
            
            // Prevention
            VStack(alignment: .leading, spacing: 10) {
                Text("Prevention Measures")
                    .font(.headline)
                
                ForEach(info.preventionMeasures, id: \.self) { measure in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        
                        Text(measure)
                    }
                    .padding(.vertical, 5)
                }
            }
            .cardStyle()
            
            // Images
            VStack(alignment: .leading, spacing: 10) {
                Text("Reference Images")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(info.imageURLs, id: \.self) { url in
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 250, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay {
                                            ProgressView()
                                        }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 250, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 250, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay {
                                            Image(systemName: "photo.slash")
                                                .font(.largeTitle)
                                                .foregroundStyle(.secondary)
                                        }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical)
                }
            }
            .cardStyle()
        }
    }
}

#Preview {
    NavigationStack {
        ParasiteInfoView(parasiteType: .neosporosis)
    }
} 