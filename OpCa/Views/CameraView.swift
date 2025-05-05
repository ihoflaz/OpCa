import SwiftUI
import AVFoundation
import Combine

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    var onImageCaptured: (Data) -> Void
    
    var body: some View {
        ZStack {
            // Camera preview
            #if targetEnvironment(simulator)
            // For simulator, show static preview
            MockCameraPreviewView()
                .edgesIgnoringSafeArea(.all)
            #else
            // For real device, show camera preview
            CameraPreviewView()
                .edgesIgnoringSafeArea(.all)
            #endif
            
            // Camera grid overlay
            if settingsViewModel.cameraGridEnabled {
                CameraGridView()
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                // Top controls
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.toggleTorch() }) {
                        Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Light intensity slider
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "sun.min.fill")
                                .foregroundStyle(.white)
                            
                            Slider(value: $viewModel.torchLevel, in: 0.1...1.0)
                                .tint(.white)
                            
                            Image(systemName: "sun.max.fill")
                                .foregroundStyle(.white)
                        }
                        
                        Text("Light Intensity")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Focus slider
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "camera.macro")
                                .foregroundStyle(.white)
                            
                            Slider(value: $viewModel.focusLevel, in: 0.0...1.0)
                                .tint(.white)
                            
                            Image(systemName: "camera.macro.circle")
                                .foregroundStyle(.white)
                        }
                        
                        Text("Focus")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Capture button
                    Button(action: {
                        #if targetEnvironment(simulator)
                        // Simulasyonda kısa bir gecikme ekleyerek 
                        // fotoğraf çekme animasyonu oluştur
                        withAnimation {
                            viewModel.capturePhoto()
                        }
                        #else
                        // Gerçek cihazda normal çekimi uygula
                        viewModel.capturePhoto()
                        #endif
                    }) {
                        ZStack {
                            Circle()
                                .strokeBorder(.white, lineWidth: 3)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                        }
                    }
                    .disabled(viewModel.isCapturing)
                    .scaleEffect(viewModel.isCapturing ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isCapturing)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            
            // Image preview overlay
            if let imageData = viewModel.capturedImageData,
               let uiImage = UIImage(data: imageData) {
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Review Capture")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                        .shadow(radius: 10)
                    
                    Text("Is the image clear enough?")
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 20) {
                        Button("Retake") {
                            viewModel.resetCapture()
                        }
                        .secondaryButtonStyle()
                        
                        Button("Use Photo") {
                            if let data = viewModel.capturedImageData {
                                onImageCaptured(data)
                                dismiss()
                            }
                        }
                        .primaryButtonStyle()
                    }
                    .padding(.top)
                }
                .padding()
                .transition(.opacity)
                .animation(.easeInOut, value: viewModel.capturedImageData != nil)
            }
        }
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(
                title: Text("Camera Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .dynamicTypeSize(settingsViewModel.largeDisplayMode ? .xxxLarge : .large)
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        var session: AVCaptureSession? {
            get { videoPreviewLayer.session }
            set { videoPreviewLayer.session = newValue }
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        // Connect to CameraService's session
        let cameraService = CameraService.shared
        view.session = cameraService.session
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

// MARK: - Mock Camera Preview
private struct MockCameraPreviewView: View {
    var body: some View {
        ZStack {
            Color.black
            
            VStack {
                Image(systemName: "camera.viewfinder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white.opacity(0.5))
                
                Text("Camera Preview")
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top)
                
                Text("Preview Mode")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.caption)
            }
        }
    }
}

// MARK: - Static Preview for Xcode Canvas
struct StaticCameraPreview: View {
    // Mock sample image for the review screen
    @State private var showReviewScreen = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if showReviewScreen {
                // Mock review screen
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Review Capture")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    // Use SF Symbol as placeholder for image
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                        
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    
                    Text("Is the image clear enough?")
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 20) {
                        Button("Retake") {
                            showReviewScreen = false
                        }
                        .secondaryButtonStyle()
                        
                        Button("Use Photo") {}
                        .primaryButtonStyle()
                    }
                    .padding(.top)
                }
                .padding()
            } else {
                VStack {
                    // Top controls
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "flashlight.off.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Mock camera view
                    MockCameraPreviewView()
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 20) {
                        // Light intensity slider
                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "sun.min.fill")
                                    .foregroundStyle(.white)
                                
                                Slider(value: .constant(0.5), in: 0.1...1.0)
                                    .tint(.white)
                                
                                Image(systemName: "sun.max.fill")
                                    .foregroundStyle(.white)
                            }
                            
                            Text("Light Intensity")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Focus slider
                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "camera.macro")
                                    .foregroundStyle(.white)
                                
                                Slider(value: .constant(0.5), in: 0.0...1.0)
                                    .tint(.white)
                                
                                Image(systemName: "camera.macro.circle")
                                    .foregroundStyle(.white)
                            }
                            
                            Text("Focus")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Capture button
                        Button(action: { showReviewScreen = true }) {
                            ZStack {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 3)
                                    .frame(width: 70, height: 70)
                                
                                Circle()
                                    .fill(.white)
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

// MARK: - Camera Grid View
struct CameraGridView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Vertical lines
                ForEach(1..<3) { i in
                    let position = geometry.size.width / 3 * CGFloat(i)
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 1)
                        .position(x: position, y: geometry.size.height / 2)
                }
                
                // Horizontal lines  
                ForEach(1..<3) { i in
                    let position = geometry.size.height / 3 * CGFloat(i)
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 1)
                        .position(x: geometry.size.width / 2, y: position)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    StaticCameraPreview()
} 