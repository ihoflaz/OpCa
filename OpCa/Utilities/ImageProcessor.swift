import UIKit
import Vision
import CoreImage
import CoreML

class ImageProcessor {
    
    // UIImage'ı grayscale ve 28x28 formatına dönüştürür (MNIST için gerekli)
    static func prepareImageForMNIST(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Grayscale dönüşümü
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let grayImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        // 28x28 boyutlandırma - MNIST modeli için standart boyut
        let size = CGSize(width: 28, height: 28)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        
        // Arka plan beyaz olsun (MNIST için standart)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // Görüntüyü çiz - MNIST beyaz arkaplan, siyah rakam kullanır
        let rect = CGRect(origin: .zero, size: size)
        UIImage(cgImage: grayImage).draw(in: rect)
        
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    // UIImage'ı CVPixelBuffer'a dönüştürür (CoreML input için)
    static func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        // Görüntünün 28x28 grayscale olduğundan emin ol
        guard let grayscaleImage = prepareImageForMNIST(image),
              let cgImage = grayscaleImage.cgImage else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // OneComponent8 formatı (tek kanallı grayscale)
        let bitsPerComponent = 8
        let bytesPerRow = width
        
        // Grayscale renk uzayı kullan
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue
        
        // CVPixelBuffer oluştur
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_OneComponent8,  // MNIST girişi için gerekli
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        // Buffer'a erişim için kilitle
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        // Buffer'ın veri alanını al
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        // Context oluştur ve grayscale görüntüyü çiz
        guard let context = CGContext(
            data: baseAddress,
            width: width, height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        // Görüntüyü context'e çiz
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        
        // İşlem tamamlandı, buffer'ı serbest bırak
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
    
    // Çizimden grayscale görüntü oluşturur
    static func createImageFromDrawing(paths: [UIBezierPath], size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        
        // MNIST için beyaz arkaplan, siyah yazı standardı
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        UIColor.black.setStroke()
        for path in paths {
            path.lineWidth = 15
            path.stroke()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Oluşturulan görüntüyü MNIST formatına dönüştür
        if let image = image {
            return prepareImageForMNIST(image)
        }
        
        return nil
    }
    
    // Vision framework ile görüntü işleme ve tahmin
    static func processWithVision(image: UIImage, model: MLModel, completion: @escaping ([String: Double]?) -> Void) {
        // Vision framework için Vision-CoreML modeli oluştur
        guard let visionModel = try? VNCoreMLModel(for: model) else {
            print("VNCoreMLModel oluşturulamadı")
            completion(nil)
            return
        }
        
        // Vision request oluştur
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let error = error {
                print("Vision request hatası: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let results = request.results else {
                print("Vision sonuçları boş")
                completion(nil)
                return
            }
            
            // MNIST modeli için sonuçları işle
            if let classifications = results as? [VNClassificationObservation] {
                // Sonuçları sözlük olarak dönüştür
                var resultDict = [String: Double]()
                for result in classifications {
                    // Sınıf adı (identifier) rakamı temsil eder
                    resultDict[result.identifier] = Double(result.confidence)
                    print("Sınıf: \(result.identifier), Güven: \(result.confidence)")
                }
                
                completion(resultDict)
            } else {
                print("VNClassificationObservation'a dönüştürülemedi: \(results)")
                completion(nil)
            }
        }
        
        // Görüntü oryantasyonunu ve ölçeklendirmeyi ayarla - MNIST için önemli
        request.imageCropAndScaleOption = .centerCrop
        
        guard let cgImage = image.cgImage else {
            print("CGImage oluşturulamadı")
            completion(nil)
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Vision framework hatası: \(error.localizedDescription)")
            completion(nil)
        }
    }
} 