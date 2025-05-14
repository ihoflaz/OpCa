import SwiftUI
import AVFoundation

struct HomeView: View {
    enum AnalysisType {
        case parasite
        case mnist
    }
    
    @State private var showCameraView = false
    @State private var showDrawingView = false
    @State private var selectedImage: IdentifiableData?
    @State private var showSettings = false
    @State private var showPermissionsAlert = false
    @State private var permissionAlertMessage = ""
    @State private var selectedAnalysisType: AnalysisType = .parasite
    @State private var mnistViewModel: MNISTViewModel?
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
        .sheet(isPresented: $showDrawingView) {
            NavigationStack {
                DrawingCanvasView { viewModel in
                    self.mnistViewModel = viewModel
                }
            }
        }
        .fullScreenCover(item: $selectedImage) { identifiableData in
            NavigationStack {
                let processingAnalysisType: AnalysisProcessingView.AnalysisType = 
                    selectedAnalysisType == .parasite ? .parasite : .mnist
                
                AnalysisProcessingView(imageData: identifiableData.data, analysisType: processingAnalysisType)
            }
        }
        .fullScreenCover(item: Binding(
            get: { mnistViewModel },
            set: { mnistViewModel = $0 }
        )) { viewModel in
            NavigationStack {
                AnalysisProcessingView(mnistViewModel: viewModel)
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
                // Analiz seçme bölümü
                HStack {
                    Spacer()
                    
                    VStack(spacing: 10) {
                        Text("Analiz Tipi")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Picker("Analiz Tipi", selection: $selectedAnalysisType) {
                            Text("Parazit Analizi").tag(AnalysisType.parasite)
                            Text("Rakam Tanıma").tag(AnalysisType.mnist)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 400)
                    }
                    
                    Spacer()
                }
                .padding(.top)
                
                if selectedAnalysisType == .parasite {
                    parasiteScanView
                } else {
                    mnistScanView
                }
            }
            .navigationTitle(selectedAnalysisType == .parasite ? "Parazit Analizi" : "Rakam Tanıma")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var parasiteScanView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                Image(systemName: "allergens")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .foregroundStyle(.blue)
                    .padding(.top, 20)
                
                Text(localization.localizedString(for: "parasite_detection"))
                    .font(.largeTitle.bold())
                
                Text(localization.localizedString(for: "capture_description"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                Spacer(minLength: 30)
                
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
                
                Spacer(minLength: 50)
                
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
        }
        .scrollIndicators(.hidden)
    }
    
    private var mnistScanView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header - Parazit analiziyle aynı boyutlarda olması için düzenlendi
                Image(systemName: "hand.draw.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                Text("Rakam Tanıma")
                    .font(.largeTitle.bold())
                
                Text("El yazısı rakamları yapay zeka ile tanıyan bir uygulama. Çizim ekranında rakam çizin veya kamera ile rakam fotoğrafı çekin.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                Spacer(minLength: 30)
                
                // MNIST Kullanım bilgisi - MNIST seçeneklerinin önüne taşındı
                VStack(alignment: .leading, spacing: 15) {
                    Text("Nasıl Kullanılır?")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "1.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Rakam çizmek veya kamera ile çekmek için aşağıdaki butonları kullanın.")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "2.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Rakam tanıma sonuçları analiz ekranında gösterilecektir.")
                    }
                    
                    HStack(alignment: .top) {
                        Image(systemName: "3.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Analiz geçmişinizi görmek için aşağıdaki geçmiş sekmesini kullanabilirsiniz.")
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                Spacer(minLength: 30)
                
                // MNIST Seçenekleri - aşağıya alındı, diğer sekmede olduğu gibi button kısmı altta
                VStack(spacing: 20) {
                    Button {
                        showDrawingView = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.headline)
                            Text("Rakam Çiz")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        checkCameraPermission()
                    } label: {
                        HStack {
                            Image(systemName: "camera")
                                .font(.headline)
                            Text("Kamera ile Çek")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .scrollIndicators(.hidden)
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