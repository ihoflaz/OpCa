import SwiftUI
import AVFoundation

struct HomeView: View {
    @State private var showCameraView = false
    @State private var selectedImage: IdentifiableData?
    @State private var showSettings = false
    @State private var showPermissionsAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        TabView {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.doc.horizontal")
                }
            
            // New Scan Tab
            newScanView
                .tabItem {
                    Label("New Scan", systemImage: "camera.viewfinder")
                }
            
            // History Tab
            AnalysisHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .sheet(isPresented: $showCameraView) {
            CameraView { imageData in
                selectedImage = IdentifiableData(data: imageData)
            }
        }
        .fullScreenCover(item: $selectedImage) { identifiableData in
            NavigationStack {
                AnalysisProcessingView(imageData: identifiableData.data)
            }
        }
        .alert(isPresented: $showPermissionsAlert) {
            Alert(
                title: Text("Permission Required"),
                message: Text(permissionAlertMessage),
                primaryButton: .default(Text("Settings"), action: openSettings),
                secondaryButton: .cancel()
            )
        }
    }
    
    private var newScanView: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                Image("microscope")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .padding(.top, 20)
                
                Text("Parasite Detection")
                    .font(.largeTitle.bold())
                
                Text("Capture microscopic images of dog feces samples to detect parasitic infections.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                // Steps
                VStack(alignment: .leading, spacing: 15) {
                    stepView(number: 1, title: "Prepare Sample", description: "Place the sample under the DIPLE lens attached to your phone")
                    
                    stepView(number: 2, title: "Capture Image", description: "Adjust light and focus for a clear image")
                    
                    stepView(number: 3, title: "Analyze", description: "AI will analyze the image to detect parasites")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                Spacer()
                
                // Capture button
                Button {
                    checkCameraPermission()
                } label: {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.headline)
                        Text("Begin Scan")
                            .font(.headline)
                    }
                    .primaryButtonStyle()
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("New Scan")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func stepView(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number)")
                .font(.title3.bold())
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCameraView = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCameraView = true
                    } else {
                        permissionAlertMessage = "Camera access is required to capture microscopic images."
                        showPermissionsAlert = true
                    }
                }
            }
        case .denied, .restricted:
            permissionAlertMessage = "Camera access is required to capture microscopic images. Please enable it in Settings."
            showPermissionsAlert = true
        @unknown default:
            permissionAlertMessage = "Unknown camera authorization status. Please check your privacy settings."
            showPermissionsAlert = true
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// Swift 6 için çakışma olmayan bir yaklaşım
struct IdentifiableData: Identifiable {
    let data: Data
    
    var id: String {
        data.base64EncodedString()
    }
}

extension Data {
    var asIdentifiable: IdentifiableData {
        IdentifiableData(data: self)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Analysis.self, inMemory: true)
} 