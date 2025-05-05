import SwiftUI
import AVFoundation

enum CameraError: Error {
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    case createCaptureInput(Error)
    case deniedAuthorization
    case restrictedAuthorization
    case unknownAuthorization
}

extension CameraError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is unavailable"
        case .cannotAddInput:
            return "Cannot add camera input"
        case .cannotAddOutput:
            return "Cannot add camera output"
        case .createCaptureInput(let error):
            return "Error creating capture input: \(error.localizedDescription)"
        case .deniedAuthorization:
            return "Camera access was denied"
        case .restrictedAuthorization:
            return "Camera access is restricted"
        case .unknownAuthorization:
            return "Unknown camera authorization status"
        }
    }
}

@Observable
class CameraService {
    static let shared = CameraService()
    
    let session = AVCaptureSession()
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var output: AVCapturePhotoOutput?
    private var photoData: Data?
    
    var error: CameraError?
    var isRunning = false
    var isTorchOn = false
    var torchLevel: Float = 0.5
    var focusLevel: Float = 0.5
    
    private init() {
        checkPermissions()
    }
    
    deinit {
        stopSession()
    }
    
    func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            Task {
                if await AVCaptureDevice.requestAccess(for: .video) {
                    await MainActor.run {
                        setupCamera()
                    }
                } else {
                    await MainActor.run {
                        self.error = .deniedAuthorization
                    }
                }
            }
        case .denied:
            self.error = .deniedAuthorization
        case .restricted:
            self.error = .restrictedAuthorization
        @unknown default:
            self.error = .unknownAuthorization
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // Set the quality level
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        
        // Add device input
        self.device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        guard let device = device else {
            self.error = .cameraUnavailable
            return
        }
        
        do {
            self.input = try AVCaptureDeviceInput(device: device)
            
            if let input = self.input, session.canAddInput(input) {
                session.addInput(input)
            } else {
                self.error = .cannotAddInput
                return
            }
            
            // Add photo output
            self.output = AVCapturePhotoOutput()
            guard let output = self.output else { return }
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            } else {
                self.error = .cannotAddOutput
                return
            }
            
            session.commitConfiguration()
        } catch {
            self.error = .createCaptureInput(error)
        }
    }
    
    func startSession() {
        guard !session.isRunning else { return }
        
        Task.detached { @MainActor in
            self.session.startRunning()
            self.isRunning = self.session.isRunning
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        
        Task.detached { @MainActor in
            self.session.stopRunning()
            self.isRunning = self.session.isRunning
        }
    }
    
    func toggleTorch() {
        guard let device = device, device.hasTorch, device.isTorchAvailable else { return }
        
        do {
            try device.lockForConfiguration()
            if device.torchMode == .off {
                try device.setTorchModeOn(level: torchLevel)
                isTorchOn = true
            } else {
                device.torchMode = .off
                isTorchOn = false
            }
            device.unlockForConfiguration()
        } catch {
            print("Error toggling torch: \(error.localizedDescription)")
        }
    }
    
    func setTorchLevel(_ level: Float) {
        guard let device = device, device.hasTorch, device.isTorchAvailable else { return }
        
        self.torchLevel = max(0.1, min(1.0, level))
        
        if isTorchOn {
            do {
                try device.lockForConfiguration()
                try device.setTorchModeOn(level: torchLevel)
                device.unlockForConfiguration()
            } catch {
                print("Error setting torch level: \(error.localizedDescription)")
            }
        }
    }
    
    func setFocus(_ level: Float) {
        guard let device = device, device.isFocusModeSupported(.continuousAutoFocus) else { return }
        
        self.focusLevel = max(0.0, min(1.0, level))
        
        do {
            try device.lockForConfiguration()
            
            // Set focus point
            let point = CGPoint(x: CGFloat(focusLevel), y: 0.5)
            device.focusPointOfInterest = point
            device.focusMode = .continuousAutoFocus
            
            // Set exposure point
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposurePointOfInterest = point
                device.exposureMode = .continuousAutoExposure
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting focus: \(error.localizedDescription)")
        }
    }
    
    // Doğrudan delegate kullanarak fotoğraf çekin
    func capturePhoto(with processor: PhotoCaptureProcessor) {
        guard let output = output else {
            processor.completion(.failure(CameraError.cannotAddOutput))
            return
        }
        
        // Create standard photo settings without specifying codec 
        let settings = AVCapturePhotoSettings()
        
        // Explicitly disable HEVC format for iOS 18.4 compatibility
        settings.photoQualityPrioritization = .balanced
        
        // Fotoğraf çekin ve processor'a delegate edin
        output.capturePhoto(with: settings, delegate: processor)
    }
    
    // Eski metod, geriye dönük uyumluluk için tuttuk
    func capturePhoto(completion: @escaping (Result<Data, Error>) -> Void) {
        // Yeni bir processor oluşturun
        let processor = PhotoCaptureProcessor(completion: completion)
        // Yeni metodu çağırın
        capturePhoto(with: processor)
    }
}

class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (Result<Data, Error>) -> Void
    
    init(completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            completion(.failure(CameraError.cannotAddOutput))
            return
        }
        
        completion(.success(imageData))
    }
} 