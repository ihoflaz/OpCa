import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var viewModel = CameraViewModel()
    @State private var showConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var onImageCaptured: (Data) -> Void
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView()
                .edgesIgnoringSafeArea(.all)
            
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
                        viewModel.capturePhoto()
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
    }
}

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
        
        // Use the shared AVCaptureSession
        if let session = (NSClassFromString("AVCaptureSession") as? AVCaptureSession.Type)?.init() {
            view.session = session
            
            Task {
                session.startRunning()
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

#Preview {
    CameraView { _ in }
} 