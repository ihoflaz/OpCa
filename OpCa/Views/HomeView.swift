import SwiftUI
import AVFoundation

struct HomeView: View {
    @State private var showCameraView = false
    @State private var selectedImage: IdentifiableData?
    @State private var showSettings = false
    @State private var showPermissionsAlert = false
    @State private var permissionAlertMessage = ""
    private let localization = LocalizationManager.shared
    
    var body: some View {
        TabView {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label(localization.localizedString(for: "dashboard"), systemImage: "chart.bar.doc.horizontal")
                }
            
            // New Scan Tab
            newScanView
                .tabItem {
                    Label(localization.localizedString(for: "new_scan"), systemImage: "camera.viewfinder")
                }
            
            // History Tab
            NavigationStack {
                AnalysisHistoryView()
            }
            .tabItem {
                Label(localization.localizedString(for: "history"), systemImage: "clock.arrow.circlepath")
            }
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label(localization.localizedString(for: "settings"), systemImage: "gear")
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
                title: Text(localization.localizedString(for: "permission_required")),
                message: Text(permissionAlertMessage),
                primaryButton: .default(Text(localization.localizedString(for: "settings")), action: openSettings),
                secondaryButton: .cancel(Text(localization.localizedString(for: "cancel")))
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
                
                Text(localization.localizedString(for: "parasite_detection"))
                    .font(.largeTitle.bold())
                
                Text(localization.localizedString(for: "capture_description"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                // Steps
                VStack(alignment: .leading, spacing: 15) {
                    stepView(number: 1, 
                             title: localization.localizedString(for: "step_1_title"), 
                             description: localization.localizedString(for: "step_1_description"))
                    
                    stepView(number: 2, 
                             title: localization.localizedString(for: "step_2_title"), 
                             description: localization.localizedString(for: "step_2_description"))
                    
                    stepView(number: 3, 
                             title: localization.localizedString(for: "step_3_title"), 
                             description: localization.localizedString(for: "step_3_description"))
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
                        Text(localization.localizedString(for: "begin_scan"))
                            .font(.headline)
                    }
                    .primaryButtonStyle()
                }
                .padding(.bottom, 30)
            }
            .navigationTitle(localization.localizedString(for: "new_scan"))
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
                        permissionAlertMessage = localization.localizedString(for: "camera_permission_message")
                        showPermissionsAlert = true
                    }
                }
            }
        case .denied, .restricted:
            permissionAlertMessage = localization.localizedString(for: "camera_permission_denied")
            showPermissionsAlert = true
        @unknown default:
            permissionAlertMessage = localization.localizedString(for: "unknown_permission_status")
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