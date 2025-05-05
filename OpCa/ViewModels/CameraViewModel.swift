import SwiftUI
import AVFoundation

@Observable
class CameraViewModel {
    private let cameraService = CameraService.shared
    
    var isCapturing = false
    var capturedImageData: Data?
    var errorMessage: String?
    var showErrorAlert = false
    
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
    }
    
    func capturePhoto() {
        guard !isCapturing else { return }
        
        isCapturing = true
        
        cameraService.capturePhoto { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isCapturing = false
                
                switch result {
                case .success(let imageData):
                    self.capturedImageData = imageData
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    func resetCapture() {
        capturedImageData = nil
    }
} 