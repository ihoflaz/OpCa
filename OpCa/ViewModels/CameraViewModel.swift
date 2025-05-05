import SwiftUI
import AVFoundation
import Combine

class CameraViewModel: ObservableObject {
    private let cameraService = CameraService.shared
    // Capture processor'ı sınıf düzeyinde sakla
    private var photoCaptureProcessor: PhotoCaptureProcessor?
    
    @Published var isCapturing = false
    @Published var capturedImageData: Data?
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    
    var isTorchOn: Bool {
        cameraService.isTorchOn
    }
    
    var torchLevel: Float {
        get { cameraService.torchLevel }
        set { cameraService.setTorchLevel(newValue) }
    }
    
    var focusLevel: Float {
        get { cameraService.focusLevel }
        set { cameraService.setFocus(newValue) }
    }
    
    func startCamera() {
        cameraService.startSession()
    }
    
    func stopCamera() {
        cameraService.stopSession()
    }
    
    func toggleTorch() {
        cameraService.toggleTorch()
        objectWillChange.send()
    }
    
    func capturePhoto() {
        guard !isCapturing else { return }
        
        isCapturing = true
        print("Fotoğraf çekme başlatıldı")
        
        #if targetEnvironment(simulator)
        // Simulatörde gerçek kamera olmadığı için demo görüntü yükle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadDemoImage()
            self.isCapturing = false
        }
        #else
        // Gerçek cihazda kamera kullan
        // PhotoCaptureProcessor'ı sakla
        let photoCaptureProcessor = PhotoCaptureProcessor { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isCapturing = false
                
                switch result {
                case .success(let imageData):
                    print("Fotoğraf başarıyla çekildi: \(imageData.count) byte")
                    self.capturedImageData = imageData
                    
                case .failure(let error):
                    print("Fotoğraf çekme hatası: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
        
        // Referansı kaydet
        self.photoCaptureProcessor = photoCaptureProcessor
        
        // Fotoğraf çek
        cameraService.capturePhoto(with: photoCaptureProcessor)
        #endif
    }
    
    func resetCapture() {
        capturedImageData = nil
        // Fotoğraf işlemcisini temizle
        photoCaptureProcessor = nil
    }
    
    /// Demo amaçlı: Demo görüntü yükleme
    func loadDemoImage() {
        // Simulatör için daha gerçekçi bir demo görüntü oluştur
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
        let demoImage = renderer.image { context in
            // Arka plan
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
            
            // Mikroskobik görüntü simülasyonu
            UIColor.darkGray.setStroke()
            context.stroke(CGRect(x: 10, y: 10, width: 280, height: 280))
            
            // Ortada örnek parazit
            UIColor.red.setFill()
            context.fill(CGRect(x: 100, y: 100, width: 100, height: 100).insetBy(dx: 10, dy: 10))
            
            // Rastgele noktalar ekleme
            for _ in 0..<20 {
                let x = CGFloat.random(in: 20...280)
                let y = CGFloat.random(in: 20...280)
                let size = CGFloat.random(in: 5...15)
                
                UIColor.orange.setFill()
                context.fill(CGRect(x: x, y: y, width: size, height: size))
            }
        }
        
        if let data = demoImage.jpegData(compressionQuality: 0.8) {
            DispatchQueue.main.async {
                self.capturedImageData = data
            }
        }
    }
} 