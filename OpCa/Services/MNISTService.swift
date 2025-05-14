import Foundation
import UIKit
import CoreML
import Vision
import Observation

@Observable
class MNISTService {
    // MARK: - Özellikler
    static let shared = MNISTService()
    
    private var mnistModel: MLModel?
    private let modelName = "MNISTClassifier" // Apple'dan indirilen modelin doğru adı
    
    var errorMessage: String?
    var isModelLoaded = false
    
    init() {
        loadModel()
    }
    
    // MARK: - Model Yükleme
    private func loadModel() {
        // CoreML için yapılandırma oluştur
        let config = MLModelConfiguration()
        config.computeUnits = .all // CPU, GPU ve Neural Engine'i kullan
        
        // Olası model adları - bazı MNIST modelleri farklı adlandırma konvansiyonları kullanabilir
        let possibleModelNames = ["MNISTClassifier", "MNIST", "MNISTModel"]
        
        var foundModel = false
        
        for name in possibleModelNames {
            // Önce derlenmiş model (.mlmodelc) kontrol et
            if let compiledURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
                do {
                    print("Derlenmiş MNIST modeli bulundu: \(compiledURL.path)")
                    mnistModel = try MLModel(contentsOf: compiledURL, configuration: config)
                    isModelLoaded = true
                    print("MNIST derlenmiş modeli başarıyla yüklendi: \(name)")
                    foundModel = true
                    break
                } catch {
                    print("Derlenmiş \(name) modelini yükleme hatası: \(error.localizedDescription)")
                }
            }
            
            // Sonra normal model (.mlmodel) kontrol et
            if !foundModel, let modelURL = Bundle.main.url(forResource: name, withExtension: "mlmodel") {
                do {
                    print("MNIST model dosyası bulundu: \(modelURL.path)")
                    mnistModel = try MLModel(contentsOf: modelURL, configuration: config)
                    isModelLoaded = true
                    print("MNIST modeli başarıyla yüklendi: \(name)")
                    foundModel = true
                    break
                } catch {
                    print("\(name) modelini yükleme hatası: \(error.localizedDescription)")
                }
            }
        }
        
        // Model bulunamadıysa durumu kaydet
        if !foundModel {
            isModelLoaded = false
            print("MNIST modeli bulunamadı veya yüklenemedi, uygulama mock veri kullanacak")
            
            // Mevcut model dosyalarını kontrol et
            if let modelURLs = Bundle.main.urls(forResourcesWithExtension: "mlmodel", subdirectory: nil) {
                print("Mevcut mlmodel dosyaları: \(modelURLs)")
            } else {
                print("Bundle içinde hiç mlmodel dosyası bulunamadı")
            }
            
            if let compiledURLs = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil) {
                print("Mevcut derlenmiş mlmodelc dosyaları: \(compiledURLs)")
            } else {
                print("Bundle içinde hiç derlenmiş mlmodelc dosyası bulunamadı")
            }
        }
    }
    
    // MARK: - Tahmin İşlemleri
    /// Vision framework üzerinden MNIST tahmini yapar
    func recognizeDigit(from image: UIImage) async throws -> [DigitResult] {
        // Modelin yüklü olup olmadığını kontrol et
        guard isModelLoaded, let model = mnistModel else {
            print("MNIST modeli yüklü değil, hata fırlatılıyor")
            throw ServiceError.modelNotLoaded("MNIST modeli bulunamadı veya yüklenemedi")
        }
        
        // Görüntüyü MNIST için hazırla
        guard let processedImage = ImageProcessor.prepareImageForMNIST(image) else {
            print("Görüntü işlenemedi")
            throw ServiceError.invalidImage
        }
        
        print("Görüntü MNIST için işlendi, Vision ile tahmin yapılıyor")
        
        return try await withCheckedThrowingContinuation { continuation in
            // Vision framework'ü ile işleme
            ImageProcessor.processWithVision(image: processedImage, model: model) { results in
                guard let results = results else {
                    print("Vision framework sonuç döndürmedi")
                    continuation.resume(throwing: ServiceError.invalidResponse)
                    return
                }
                
                print("MNIST tahmin sonuçları (Vision): \(results)")
                
                var digitResults = [DigitResult]()
                
                // Sözlük sonuçlarını DigitResult'a dönüştür
                for (key, confidence) in results {
                    if let digitValue = Int(key),
                       let digitType = DigitType(rawValue: digitValue) {
                        let result = DigitResult()
                        result.typeValue = digitValue
                        result.confidence = confidence
                        result.detectionDate = Date()
                        digitResults.append(result)
                    }
                }
                
                // Sonuçları kontrol et
                if digitResults.isEmpty {
                    print("Vision framework kullanılarak anlamlı sonuç bulunamadı")
                    
                    // Doğrudan CoreML yöntemini dene
                    Task {
                        do {
                            print("Doğrudan CoreML yöntemi deneniyor...")
                            let directResults = try await self.recognizeDigitDirectly(from: image)
                            continuation.resume(returning: directResults)
                        } catch {
                            print("Her iki yöntem de başarısız oldu, hata fırlatılıyor: \(error.localizedDescription)")
                            continuation.resume(throwing: ServiceError.modelPredictionFailed("Hem Vision hem de doğrudan CoreML yöntemi başarısız oldu"))
                        }
                    }
                    return
                }
                
                // Sonuçları güven değerine göre sırala
                let sortedResults = digitResults.sorted { $0.confidence > $1.confidence }
                
                // Sonuçları görüntüle
                if let topResult = sortedResults.first {
                    print("Vision framework ile en yüksek tahmin: \(topResult.type.rawValue) (\(topResult.confidence * 100)%)")
                }
                
                continuation.resume(returning: sortedResults)
            }
        }
    }
    
    /// CoreML doğrudan tahmin için alternatif metod
    func recognizeDigitDirectly(from image: UIImage) async throws -> [DigitResult] {
        // Model yüklü mü kontrol et
        guard isModelLoaded, let model = mnistModel else {
            print("Model yüklü değil, hata fırlatılıyor")
            throw ServiceError.modelNotLoaded("MNIST modeli bulunamadı veya yüklenemedi")
        }
        
        // Görüntüyü MNIST için hazırla
        guard let processedImage = ImageProcessor.prepareImageForMNIST(image) else {
            print("Görüntü MNIST formatına dönüştürülemedi")
            throw ServiceError.invalidImage
        }
        
        print("Görüntü MNIST için hazırlandı: \(processedImage.size.width)x\(processedImage.size.height)")
        
        // Doğrudan görüntüyü de yazdır
        print("MNIST için hazırlanan görüntü boyutları: genişlik=\(processedImage.size.width), yükseklik=\(processedImage.size.height)")
        
        // iOS 16+ için MLFeatureValue ve MLModelConfiguration kullanımı
        do {
            // Görüntüyü CVPixelBuffer'a dönüştür
            guard let pixelBuffer = ImageProcessor.pixelBuffer(from: processedImage) else {
                print("Görüntü CVPixelBuffer'a dönüştürülemedi")
                throw ServiceError.invalidImage
            }
            
            // MNIST modelinin girdi adını kontrol et
            var inputFeatureName = "image"
            
            // modelDescription her zaman var, opsiyonel değil
            let description = model.modelDescription
            if description.inputDescriptionsByName.keys.contains("input_1") {
                inputFeatureName = "input_1"
            }
            print("Model girdi özellik(ler)i: \(description.inputDescriptionsByName.keys.joined(separator: ", "))")
            
            // Model girdisini oluştur
            // Bazı MNIST modelleri "image", bazıları "input_1" girdi adı kullanır
            let input = try MLDictionaryFeatureProvider(dictionary: [inputFeatureName: MLFeatureValue(pixelBuffer: pixelBuffer)])
            
            print("Tahmin başlatılıyor...")
            let prediction = try await model.prediction(from: input)
            print("Tahmin tamamlandı. Çıktı özellikleri: \(prediction.featureNames)")
            
            // Apple'ın MNIST modeli için özel işlem
            if prediction.featureNames.contains("labelProbabilities") && prediction.featureNames.contains("classLabel") {
                print("Apple'ın MNIST formatı tespit edildi")
                
                // Sonuç dizisi
                var results = [DigitResult]()
                
                // Sınıf etiketini al
                let classLabelFeature = prediction.featureValue(for: "classLabel")
                print("classLabel tipi: \(type(of: classLabelFeature))")
                
                // Önceden sınıf etiketini almaya çalışalım
                var bestDigit: Int? = nil
                if let clFeature = classLabelFeature {
                    if !clFeature.stringValue.isEmpty, let digit = Int(clFeature.stringValue) {
                        bestDigit = digit
                        print("classLabel string değeri: \(digit)")
                    } else {
                        let intValue = clFeature.int64Value
                        bestDigit = Int(intValue)
                        print("classLabel int değeri: \(bestDigit ?? -1)")
                    }
                }
                
                // labelProbabilities özelliğini al
                let probsFeature = prediction.featureValue(for: "labelProbabilities")
                print("labelProbabilities tipi: \(type(of: probsFeature))")
                
                // Özel Apple formatı - MLMultiArray veya Dictionary probabilityleri içerir
                if let pFeature = probsFeature {
                    if let multiArray = pFeature.multiArrayValue {
                        print("MLMultiArray formatında olasılıklar bulundu")
                        print("MLMultiArray şekli: \(multiArray.shape)")
                        print("MLMultiArray veri tipi: \(multiArray.dataType)")
                        
                        // Her rakam için bir DigitResult oluştur
                        for i in 0..<10 {
                            if i < multiArray.count {
                                let digitType = DigitType(rawValue: i)!
                                let confidence = Double(truncating: multiArray[i])
                                
                                let result = DigitResult()
                                result.typeValue = i
                                result.confidence = confidence
                                result.detectionDate = Date()
                                results.append(result)
                                
                                print("Rakam \(i) için olasılık: \(confidence)")
                            }
                        }
                    } else {
                        // Dictionary formatında olabilir
                        let dictValue = pFeature.dictionaryValue
                        print("Dictionary formatında olasılıklar: \(dictValue)")
                        
                        var probabilities: [Int: Double] = [:]
                        
                        // dictValue içinden değerleri çıkaralım
                        for (key, value) in dictValue {
                            // Anahtar işleme
                            var digitKey: Int? = nil
                            
                            if let intKey = key as? Int {
                                digitKey = intKey
                            } else if let numKey = key as? NSNumber {
                                digitKey = numKey.intValue
                            } else if let strKey = key as? String, let intFromStr = Int(strKey) {
                                digitKey = intFromStr
                            }
                            
                            // Değer işleme
                            if let digit = digitKey, 
                               let numValue = value as? NSNumber {
                                probabilities[digit] = numValue.doubleValue
                                print("Rakam \(digit) için olasılık: \(numValue.doubleValue)")
                            }
                        }
                        
                        // DigitResult'ları oluştur
                        for i in 0...9 {
                            if let confidence = probabilities[i] {
                                let result = DigitResult()
                                result.typeValue = i
                                result.confidence = confidence
                                result.detectionDate = Date()
                                results.append(result)
                            } else if bestDigit != nil && i == bestDigit {
                                // classLabel'dan bulduğumuz en iyi tahmin için makul bir değer ekleme
                                let result = DigitResult()
                                result.typeValue = i
                                result.confidence = 0.9
                                result.detectionDate = Date()
                                results.append(result)
                                print("classLabel'dan alınan \(i) rakamı için manuel olasılık (0.9) eklendi")
                            } else {
                                // Diğer rakamlar için düşük güven değerleri
                                let result = DigitResult()
                                result.typeValue = i
                                result.confidence = 0.01
                                result.detectionDate = Date()
                                results.append(result)
                            }
                        }
                    }
                    
                    // Sonuçları güven değerine göre sırala
                    let sortedResults = results.sorted { $0.confidence > $1.confidence }
                    
                    if !sortedResults.isEmpty {
                        print("Apple MNIST formatından \(sortedResults.count) sonuç bulundu.")
                        if let top = sortedResults.first {
                            print("En yüksek tahmin: \(top.type.rawValue) (\(top.confidence * 100)%)")
                        }
                        return sortedResults
                    }
                }
            }
            
            // Sonuç dizisi
            var results = [DigitResult]()
            
            // Modelin çıktı formatını analiz et
            if prediction.featureNames.contains("classLabelProbs") {
                // Standart MNIST model formatı - sınıf olasılıkları
                if let output = prediction.featureValue(for: "classLabelProbs")?.dictionaryValue as? [String: Double] {
                    print("classLabelProbs formatında sonuçlar: \(output)")
                    
                    for (key, confidence) in output {
                        if let digitValue = Int(key),
                           let digitType = DigitType(rawValue: digitValue) {
                            let result = DigitResult()
                            result.typeValue = digitValue
                            result.confidence = confidence
                            result.detectionDate = Date()
                            results.append(result)
                        }
                    }
                }
            } else if prediction.featureNames.contains("labelProbabilities") {
                // Apple'ın MNIST modeli formatı - label probabilities
                if let probsFeature = prediction.featureValue(for: "labelProbabilities") {
                    print("labelProbabilities özellik türü: \(type(of: probsFeature))")
                    print("labelProbabilities değeri: \(probsFeature)")
                    
                    var localProbabilities: [String: Double] = [:]
                    
                    // Değerleri özellik türüne göre işle
                    if let probs = probsFeature.dictionaryValue as? [String: Double] {
                        print("labelProbabilities sözlük değerleri: \(probs)")
                        localProbabilities = probs
                        
                        // Sözlük değerlerinden DigitResult'lar oluştur
                        for (key, confidence) in localProbabilities {
                            if let digitValue = Int(key),
                               let digitType = DigitType(rawValue: digitValue) {
                                let result = DigitResult()
                                result.typeValue = digitValue
                                result.confidence = confidence
                                result.detectionDate = Date()
                                results.append(result)
                            }
                        }
                    } else if let multiArray = probsFeature.multiArrayValue {
                        print("labelProbabilities multi-array şeklinde")
                        print("MultiArray boyutları: \(multiArray.shape)")
                        print("MultiArray dataType: \(multiArray.dataType)")
                        
                        // MultiArray'i döngüye al ve değerleri yazdır
                        print("MultiArray ilk 10 değeri (veya daha az):")
                        let arrayCount = min(multiArray.count, 10)
                        for i in 0..<arrayCount {
                            let value = multiArray[i]
                            print("  Index \(i): \(value)")
                        }
                        
                        // MultiArray'den olasılık değerlerini al
                        let arrayCount2 = min(multiArray.count, 10) // En fazla 10 rakam (0-9)
                        for i in 0..<arrayCount2 {
                            let prob = Double(truncating: multiArray[i])
                            localProbabilities[String(i)] = prob
                        }
                        print("MultiArray'den çıkarılan olasılıklar: \(localProbabilities)")
                        
                        // Olasılıklardan DigitResult'lar oluştur
                        for (key, confidence) in localProbabilities {
                            if let digitValue = Int(key),
                               let digitType = DigitType(rawValue: digitValue) {
                                let result = DigitResult()
                                result.typeValue = digitValue
                                result.confidence = confidence
                                result.detectionDate = Date()
                                results.append(result)
                            }
                        }
                    } else {
                        // dictionaryValue her zaman var, ama farklı tipte olabilir
                        let dictValue = probsFeature.dictionaryValue
                        print("Genel sözlük formatında, manuel dönüşüm yapılacak: \(dictValue)")
                        
                        // Dönüşüm için manual döngü
                        for (key, value) in dictValue {
                            // Anahtar String olabilir veya Int/NSNumber olabilir
                            var keyStr = ""
                            
                            if let intKey = key as? Int {
                                keyStr = String(intKey)
                            } else if let numKey = key as? NSNumber {
                                keyStr = String(numKey.intValue)
                            } else if let strKey = key as? String {
                                keyStr = strKey
                            } else {
                                // Diğer tipleri String'e dönüştürmeyi dene
                                keyStr = "\(key)"
                            }
                            
                            // Değer NSNumber olabilir
                            if let numValue = value as? NSNumber {
                                localProbabilities[keyStr] = numValue.doubleValue
                                print("Anahtar: \(key) (tip: \(type(of: key))), Değer: \(numValue.doubleValue)")
                            } else if let doubleValue = value as? Double {
                                localProbabilities[keyStr] = doubleValue
                                print("Anahtar: \(key) (tip: \(type(of: key))), Değer: \(doubleValue)")
                            } else {
                                print("Değer dönüştürülemedi: \(value) (tip: \(type(of: value)))")
                            }
                        }
                        
                        if !localProbabilities.isEmpty {
                            print("Manuel dönüşüm başarılı, sonuçlar: \(localProbabilities)")
                        } else {
                            print("Manuel dönüşüm başarısız, değerler çıkarılamadı")
                        }
                    }
                } else {
                    print("labelProbabilities featürü yok veya nil döndü")
                }
            } else if prediction.featureNames.contains("classLabel") {
                // Eğer sadece en yüksek olasılıklı sınıf döndürülüyorsa
                if let classLabelFeature = prediction.featureValue(for: "classLabel") {
                    print("classLabel özellik türü: \(type(of: classLabelFeature))")
                    print("classLabel değeri: \(classLabelFeature)")
                    print("classLabel.stringValue: \(classLabelFeature.stringValue)")
                    print("classLabel.int64Value: \(classLabelFeature.int64Value)")
                    
                    // Değeri string olarak almaya çalış
                    let stringValue = classLabelFeature.stringValue
                    if !stringValue.isEmpty {
                        print("classLabel string değeri: \(stringValue)")
                        
                        // Integer'a dönüştür
                        if let digitValue = Int(stringValue),
                           let digitType = DigitType(rawValue: digitValue) {
                            
                            print("classLabel formatında sonuç: \(stringValue)")
                            
                            // Diğer çıktı değerlerini kontrol et
                            var localProbabilities: [String: Double] = [:]
                            
                            // labelProbabilities varsa, buradan olasılıkları al
                            if prediction.featureNames.contains("labelProbabilities") {
                                if let probsFeature = prediction.featureValue(for: "labelProbabilities") {
                                    print("labelProbabilities özellik türü: \(type(of: probsFeature))")
                                    
                                    // Değerleri özellik türüne göre işle
                                    if let probs = probsFeature.dictionaryValue as? [String: Double] {
                                        print("labelProbabilities sözlük değerleri: \(probs)")
                                        localProbabilities = probs
                                    } else if let multiArray = probsFeature.multiArrayValue {
                                        print("labelProbabilities multi-array şeklinde")
                                        
                                        // MultiArray'den olasılık değerlerini al
                                        let numDigits = min(multiArray.count, 10) // En fazla 10 rakam (0-9)
                                        for i in 0..<numDigits {
                                            let prob = Double(truncating: multiArray[i])
                                            localProbabilities[String(i)] = prob
                                        }
                                        print("MultiArray'den çıkarılan olasılıklar: \(localProbabilities)")
                                    }
                                }
                            }
                            
                            // Eğer olasılık değerleri bulunamadıysa, makul değerler oluştur
                            if localProbabilities.isEmpty {
                                print("Olasılık değerleri bulunamadı, makul değerler oluşturuluyor")
                                
                                // Tahmin edilen sınıfa yüksek olasılık ver
                                for i in 0...9 {
                                    if i == digitValue {
                                        localProbabilities[String(i)] = 0.9 // Yüksek olasılık
                                    } else {
                                        localProbabilities[String(i)] = 0.01 // Düşük olasılık
                                    }
                                }
                            }
                            
                            // Tüm olasılıkları DigitResult'a dönüştür
                            for (key, confidence) in localProbabilities {
                                if let val = Int(key),
                                   let type = DigitType(rawValue: val) {
                                    let result = DigitResult()
                                    result.typeValue = val
                                    result.confidence = confidence
                                    result.detectionDate = Date()
                                    results.append(result)
                                }
                            }
                        } else {
                            print("classLabel string değeri rakama dönüştürülemedi: \(stringValue)")
                        }
                    } else {
                        // String değer yoksa int64 değer kontrolü yap
                        let intValue = classLabelFeature.int64Value
                        print("classLabel integer değeri: \(intValue)")
                        
                        let digitValue = Int(intValue)
                        if let digitType = DigitType(rawValue: digitValue) {
                            // Benzer şekilde olasılık değerleri oluştur
                            var localProbabilities: [String: Double] = [:]
                            
                            for i in 0...9 {
                                if i == digitValue {
                                    localProbabilities[String(i)] = 0.9
                                } else {
                                    localProbabilities[String(i)] = 0.01
                                }
                            }
                            
                            // Olasılıkları DigitResult'a dönüştür
                            for (key, confidence) in localProbabilities {
                                if let val = Int(key),
                                   let type = DigitType(rawValue: val) {
                                    let result = DigitResult()
                                    result.typeValue = val
                                    result.confidence = confidence
                                    result.detectionDate = Date()
                                    results.append(result)
                                }
                            }
                        } else {
                            print("Geçersiz rakam değeri: \(digitValue)")
                        }
                    }
                } else {
                    print("classLabel özelliği bulunamadı")
                }
            } else if let firstFeature = prediction.featureNames.first {
                // Diğer olası formatları deneme
                print("Bilinmeyen çıktı formatı, ilk özelliği deniyorum: \(firstFeature)")
                
                if let featureValue = prediction.featureValue(for: firstFeature) {
                    // Özellik türünü kontrol et
                    if let dictionaryValue = featureValue.dictionaryValue as? [String: Double] {
                        print("Sözlük formatında sonuçlar: \(dictionaryValue)")
                        
                        for (key, confidence) in dictionaryValue {
                            if let digitValue = Int(key),
                               let digitType = DigitType(rawValue: digitValue) {
                                let result = DigitResult()
                                result.typeValue = digitValue
                                result.confidence = confidence
                                result.detectionDate = Date()
                                results.append(result)
                            }
                        }
                    } else {
                        // dictionaryValue nil olmayabilir ama içeriği farklı tipte olabilir
                        // [AnyHashable: Any] tipinde olduğunu varsayalım ve güvenli dönüşüm yapalım
                        let dictValue = featureValue.dictionaryValue
                        print("Genel sözlük formatında sonuçlar: \(dictValue)")
                        
                        // Dönüşüm için kullanılacak sözlük
                        var mappedDict: [String: Double] = [:]
                        
                        // dictValue içinden değerleri çıkaralım
                        for (key, value) in dictValue {
                            // Anahtar String olabilir veya Int/NSNumber olabilir
                            var keyStr = ""
                            
                            if let intKey = key as? Int {
                                keyStr = String(intKey)
                            } else if let numKey = key as? NSNumber {
                                keyStr = String(numKey.intValue)
                            } else if let strKey = key as? String {
                                keyStr = strKey
                            } else {
                                // Diğer tipleri String'e dönüştürmeyi dene
                                keyStr = "\(key)"
                            }
                            
                            // Değer NSNumber olabilir
                            if let numValue = value as? NSNumber {
                                mappedDict[keyStr] = numValue.doubleValue
                                print("Anahtar: \(key) (tip: \(type(of: key))), Değer: \(numValue.doubleValue)")
                            } else if let doubleValue = value as? Double {
                                mappedDict[keyStr] = doubleValue
                                print("Anahtar: \(key) (tip: \(type(of: key))), Değer: \(doubleValue)")
                            } else {
                                print("Değer dönüştürülemedi: \(value) (tip: \(type(of: value)))")
                            }
                        }
                        
                        // Çıkarılan değerleri DigitResult'a dönüştür
                        for (key, value) in mappedDict {
                            if let digitValue = Int(key),
                               let digitType = DigitType(rawValue: digitValue) {
                                let result = DigitResult()
                                result.typeValue = digitValue
                                result.confidence = value
                                result.detectionDate = Date()
                                results.append(result)
                            }
                        }
                        
                        // Eğer dictionaryValue'dan bir sonuç çıkmadıysa diğer türleri deneyelim
                        if mappedDict.isEmpty {
                            // String değeri kontrol et
                            let stringValue = featureValue.stringValue
                            if !stringValue.isEmpty, let digitValue = Int(stringValue), let digitType = DigitType(rawValue: digitValue) {
                                // Tek bir string değeri varsa
                                print("String formatında sonuç: \(stringValue)")
                                
                                let result = DigitResult()
                                result.typeValue = digitValue
                                result.confidence = 1.0
                                result.detectionDate = Date()
                                results.append(result)
                            } else if let multiArrayValue = featureValue.multiArrayValue {
                                // Multi array formatı (bazı modeller bunu kullanır)
                                print("MultiArray formatında sonuç")
                                
                                // MultiArray'den sonuçları çıkar
                                let arraySize = multiArrayValue.count
                                if arraySize == 10 { // 0-9 arası rakamlar
                                    var confidences = [Double]()
                                    
                                    for i in 0..<arraySize {
                                        confidences.append(Double(truncating: multiArrayValue[i]))
                                    }
                                    
                                    // Softmax uygula - değerleri olasılık dağılımına dönüştür
                                    let sum = confidences.reduce(0, +)
                                    let normalizedConfidences = confidences.map { $0 / sum }
                                    
                                    // DigitResult'ları oluştur
                                    for (i, confidence) in normalizedConfidences.enumerated() {
                                        if let digitType = DigitType(rawValue: i) {
                                            let result = DigitResult()
                                            result.typeValue = i
                                            result.confidence = confidence
                                            result.detectionDate = Date()
                                            results.append(result)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Sonuçları güven değerine göre sırala
            let sortedResults = results.sorted { $0.confidence > $1.confidence }
            
            if !sortedResults.isEmpty {
                print("Model tahmin sonuçları bulundu, toplam \(sortedResults.count) sonuç.")
                if let top = sortedResults.first {
                    print("En yüksek tahmin: \(top.type.rawValue) (\(top.confidence * 100)%)")
                }
                return sortedResults
            } else {
                // Tüm prediction bilgilerini toplayarak detaylı hata mesajı oluştur
                var errorDetails = "Hiçbir biçimde model sonucu elde edilemedi!\n"
                errorDetails += "Model çıktı özellikleri: \(prediction.featureNames.joined(separator: ", "))\n"
                
                // Her bir özellik için detaylar
                for featureName in prediction.featureNames {
                    if let featureValue = prediction.featureValue(for: featureName) {
                        errorDetails += "Özellik '\(featureName)' bilgileri:\n"
                        errorDetails += "  - Tür: \(type(of: featureValue))\n"
                        
                        // MLFeatureValue türüne göre bilgiler ekle
                        let dict = featureValue.dictionaryValue
                        errorDetails += "  - dictionaryValue: \(dict)\n"
                        
                        if let multiArray = featureValue.multiArrayValue {
                            errorDetails += "  - multiArrayValue şekli: \(multiArray.shape)\n"
                            errorDetails += "  - multiArrayValue veri tipi: \(multiArray.dataType)\n"
                            
                            // İlk birkaç değeri dahil et
                            let count = min(multiArray.count, 5)
                            if count > 0 {
                                errorDetails += "  - İlk \(count) değer: "
                                for i in 0..<count {
                                    errorDetails += "\(multiArray[i])"
                                    if i < count - 1 {
                                        errorDetails += ", "
                                    }
                                }
                                errorDetails += "\n"
                            }
                        }
                        
                        errorDetails += "  - stringValue: \(featureValue.stringValue)\n"
                        errorDetails += "  - int64Value: \(featureValue.int64Value)\n"
                    } else {
                        errorDetails += "Özellik '\(featureName)' değerine erişilemedi\n"
                    }
                }
                
                print(errorDetails)
                throw ServiceError.modelPredictionFailed(errorDetails)
            }
        } catch {
            print("CoreML tahmin hatası: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Yardımcı Metodlar
    /// Geliştirme aşaması için mock veri
    private func createMockDigitResults() -> [DigitResult] {
        // Rastgele bir rakamı baskın olarak belirle
        let dominantDigit = Int.random(in: 0...9)
        var results = [DigitResult]()
        
        // Her rakam için bir sonuç oluştur
        for i in 0...9 {
            let digitType = DigitType(rawValue: i)!
            let confidence: Double
            
            if i == dominantDigit {
                // Baskın rakam için çok yüksek olasılık
                confidence = Double.random(in: 0.85...0.98)
            } else {
                // Diğer rakamlar için çok düşük olasılık
                confidence = Double.random(in: 0.001...0.05)
            }
            
            let result = DigitResult()
            result.typeValue = i
            result.confidence = confidence
            result.detectionDate = Date()
            results.append(result)
        }
        
        // Olasılıkların toplamı 1.0'a yakın olsun
        let total = results.reduce(0.0) { $0 + $1.confidence }
        let scaleFactor = 0.99 / total
        
        for result in results {
            result.confidence *= scaleFactor
        }
        
        print("Mock veri oluşturuldu: En yüksek olasılıklı rakam = \(dominantDigit)")
        
        return results
    }
    
    /// Sunucudan modeli indirme ve güncelleme (opsiyonel ileri seviye özellik)
    func downloadModelFromServer(url: URL) async throws {
        // Modeli indir
        let (downloadedModelURL, _) = try await URLSession.shared.download(from: url)
        
        // Geçici URL'den uygulama dokümanlarına kopyala
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("\(modelName).mlmodelc")
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.copyItem(at: downloadedModelURL, to: destinationURL)
        
        // Modeli yükle
        let config = MLModelConfiguration()
        config.computeUnits = .all
        mnistModel = try MLModel(contentsOf: destinationURL, configuration: config)
        isModelLoaded = true
        
        print("Model başarıyla indirildi ve yüklendi")
    }
} 