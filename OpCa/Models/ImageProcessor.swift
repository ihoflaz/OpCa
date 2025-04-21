import Foundation
import CoreML
import Vision
import UIKit

class ImageProcessor: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResult: AnalysisResult?
    
    // Görüntü ön işleme parametreleri
    private let targetImageSize = CGSize(width: 224, height: 224)
    
    func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        
        // Görüntüyü ön işleme
        guard let processedImage = preprocessImage(image) else {
            handleError("Görüntü işlenemedi")
            return
        }
        
        // Görüntü analizi yap
        analyzeWithVision(processedImage)
    }
    
    private func preprocessImage(_ image: UIImage) -> CVPixelBuffer? {
        // Görüntüyü yeniden boyutlandır
        guard let resizedImage = image.resize(to: targetImageSize) else { return nil }
        
        // CVPixelBuffer'a dönüştür
        return resizedImage.toCVPixelBuffer()
    }
    
    private func analyzeWithVision(_ pixelBuffer: CVPixelBuffer) {
        // TODO: ML Model entegrasyonu burada yapılacak
        // Şimdilik örnek sonuç döndürüyoruz
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.analysisResult = AnalysisResult(
                parasiteType: "Neosporosis",
                confidence: 0.95,
                timestamp: Date(),
                details: "Görüntüde parazit tespit edildi. Detaylı inceleme önerilir."
            )
            self.isAnalyzing = false
        }
    }
    
    private func handleError(_ message: String) {
        DispatchQueue.main.async {
            self.isAnalyzing = false
            // TODO: Hata yönetimi eklenecek
        }
    }
}

// Yardımcı uzantılar
extension UIImage {
    func resize(to targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return resized
    }
    
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       Int(self.size.width),
                                       Int(self.size.height),
                                       kCVPixelFormatType_32ARGB,
                                       attrs,
                                       &pixelBuffer)
        
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                    width: Int(self.size.width),
                                    height: Int(self.size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                    space: rgbColorSpace,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        else {
            return nil
        }
        
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

struct AnalysisResult: Identifiable {
    let id = UUID()
    let parasiteType: String
    let confidence: Double
    let timestamp: Date
    let details: String
} 