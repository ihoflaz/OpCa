import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable
class MNISTViewModel: Identifiable {
    var id = UUID()
    
    private let apiService = APIService()
    private let mnistService = MNISTService.shared
    
    var analysisState: AnalysisState = .ready
    var progress: Double = 0.0
    var imageData: Data?
    var digitResults: [DigitResult] = []
    var selectedDigit: DigitType?
    var digitInfo: DigitInfo?
    var errorMessage: String?
    var showError = false
    var notes: String = ""
    var location: String = ""
    
    var isDrawingMode: Bool = false // Çizim modu mu yoksa kamera mı kullanılıyor
    var drawingPaths: [UIBezierPath] = [] // Çizim yolları
    
    // Tahmin ayarları
    var useDirectCoreML: Bool = true // Doğrudan CoreML yerine Vision framework kullansın mı?
    
    enum AnalysisState {
        case ready
        case processing
        case completed
        case failed
    }
    
    init() {
        // MNIST modunu etkinleştir
        apiService.analysisMode = .mnist
    }
    
    func analyzeImage(_ imageData: Data) async {
        guard analysisState != .processing else { return }
        
        self.imageData = imageData
        self.analysisState = .processing
        self.progress = 0.0
        
        // İlerlemeyi simüle et
        let progressTask = Task { @MainActor in
            for i in 1...10 {
                try await Task.sleep(for: .seconds(0.2))
                self.progress = Double(i) / 10.0
            }
        }
        
        do {
            // Görüntüyü MNIST modeliyle analiz et
            let image = UIImage(data: imageData)
            
            if let image = image {
                print("MNIST analizi başlatılıyor: \(image.size.width)x\(image.size.height)")
                
                // CoreML doğrudan veya Vision framework ile tahmin
                self.digitResults = try await (useDirectCoreML ? 
                                              mnistService.recognizeDigitDirectly(from: image) :
                                              mnistService.recognizeDigit(from: image))
                
                // Analiz tamamlandı
                self.analysisState = .completed
                progressTask.cancel()
                self.progress = 1.0
                
                // En yüksek olasılıklı rakamı otomatik olarak seç
                if let dominant = digitResults.max(by: { $0.confidence < $1.confidence }) {
                    print("En yüksek tahmin: \(dominant.type.rawValue) (\(dominant.confidence * 100)%)")
                    selectDigit(dominant.type)
                }
            } else {
                throw ServiceError.invalidResponse
            }
        } catch {
            self.analysisState = .failed
            self.errorMessage = error.localizedDescription
            self.showError = true
            progressTask.cancel()
            self.progress = 0.0
            print("Görüntü analizi hatası: \(error.localizedDescription)")
        }
    }
    
    func analyzeDrawing() async {
        guard analysisState != .processing else { return }
        
        self.analysisState = .processing
        self.progress = 0.0
        
        // İlerlemeyi simüle et
        let progressTask = Task { @MainActor in
            for i in 1...5 {
                try await Task.sleep(for: .seconds(0.2))
                self.progress = Double(i) / 5.0
            }
        }
        
        // Çizimi görüntüye dönüştür
        guard let drawingImage = ImageProcessor.createImageFromDrawing(
            paths: drawingPaths,
            size: CGSize(width: 280, height: 280)
        ) else {
            self.analysisState = .failed
            self.errorMessage = "Çizim görüntüye dönüştürülemedi"
            self.showError = true
            progressTask.cancel()
            return
        }
        
        // Görüntüyü Data'ya dönüştür
        guard let drawingData = drawingImage.jpegData(compressionQuality: 0.8) else {
            self.analysisState = .failed
            self.errorMessage = "Çizim veri formatına dönüştürülemedi"
            self.showError = true
            progressTask.cancel()
            return
        }
        
        self.imageData = drawingData
        
        do {
            print("Çizim analizi başlatılıyor")
            
            // CoreML doğrudan veya Vision framework ile tahmin
            self.digitResults = try await (useDirectCoreML ? 
                                          mnistService.recognizeDigitDirectly(from: drawingImage) :
                                          mnistService.recognizeDigit(from: drawingImage))
            
            self.analysisState = .completed
            progressTask.cancel()
            self.progress = 1.0
            
            // En yüksek olasılıklı rakamı otomatik olarak seç
            if let dominant = digitResults.max(by: { $0.confidence < $1.confidence }) {
                print("En yüksek tahmin: \(dominant.type.rawValue) (\(dominant.confidence * 100)%)")
                selectDigit(dominant.type)
            }
        } catch {
            self.analysisState = .failed
            self.errorMessage = error.localizedDescription
            self.showError = true
            progressTask.cancel()
            self.progress = 0.0
            print("Çizim analizi hatası: \(error.localizedDescription)")
        }
    }
    
    func selectDigit(_ digitType: DigitType) {
        selectedDigit = digitType
        
        // Rakam bilgilerini getir
        Task {
            do {
                digitInfo = try await apiService.getDigitInfo(for: digitType)
                
                // API'den veri gelmezse veya hata oluşursa demo veri kullan
                if digitInfo == nil {
                    digitInfo = createDemoDigitInfo(for: digitType)
                }
            } catch {
                print("Rakam bilgileri yüklenemedi, demo veriler kullanılacak: \(error.localizedDescription)")
                // API hatası durumunda demo veri göster
                digitInfo = createDemoDigitInfo(for: digitType)
            }
        }
    }
    
    // Demo rakam bilgileri (API yokken kullanılır)
    private func createDemoDigitInfo(for digitType: DigitType) -> DigitInfo {
        let descriptions = [
            "Sıfır (0) rakamı, matematik sisteminin temel rakamlarından biridir. Boşluğu veya yokluğu temsil eder.",
            "Bir (1) rakamı, sayı sisteminin ilk pozitif tam sayısı ve tek rakamıdır.",
            "İki (2) rakamı, çift sayıların başlangıcı ve ilk asal sayıdır.",
            "Üç (3) rakamı, önemli bir asal sayı ve birçok kültürde kutsal kabul edilir.",
            "Dört (4) rakamı, ilk tam kare (2²) sayıdır ve geometride kare şeklinin köşelerini ifade eder.",
            "Beş (5) rakamı, bir asal sayı ve insanların bir elindeki parmak sayısıdır.",
            "Altı (6) rakamı, ilk mükemmel sayıdır (bölenlerinin toplamı kendisine eşittir: 1+2+3=6).",
            "Yedi (7) rakamı, bir asal sayı ve birçok kültürde şans getirdiğine inanılan rakamdır.",
            "Sekiz (8) rakamı, ilk küp sayının (2³) değeridir ve Uzak Doğu kültürlerinde şanslı sayı kabul edilir.",
            "Dokuz (9) rakamı, 3'ün karesi (3²) ve tek basamaklı sayıların en büyüğüdür."
        ]
        
        let index = digitType.rawValue
        let safeIndex = min(index, descriptions.count - 1)
        
        return DigitInfo(
            id: String(digitType.rawValue),
            value: digitType.rawValue,
            description: descriptions[safeIndex],
            examples: []
        )
    }
    
    func saveAnalysis(context: ModelContext) -> Analysis? {
        guard let imageData = imageData, !digitResults.isEmpty else {
            errorMessage = "Kaydedilecek analiz verisi yok"
            showError = true
            return nil
        }
        
        let analysis = Analysis(
            imageData: imageData,
            location: location.isEmpty ? nil : location,
            timestamp: Date(),
            notes: notes,
            analysisType: .mnist,
            results: [],
            digitResults: digitResults,
            isUploaded: false
        )
        
        context.insert(analysis)
        
        // Otomatik senkronizasyon etkinse, analizi yükle
        if UserDefaults.standard.bool(forKey: "autoDataSync") {
            Task {
                await uploadAnalysis(analysis, context: context)
            }
        }
        
        return analysis
    }
    
    func uploadAnalysis(_ analysis: Analysis, context: ModelContext) async {
        do {
            let success = try await apiService.uploadAnalysis(analysis)
            
            if success {
                analysis.isUploaded = true
                analysis.uploadTimestamp = Date()
                try context.save()
            }
        } catch {
            print("Analiz yüklenirken hata: \(error.localizedDescription)")
            // Bir sonraki seferde yeniden denenecek
        }
    }
    
    func reset() {
        imageData = nil
        digitResults = []
        selectedDigit = nil
        digitInfo = nil
        analysisState = .ready
        progress = 0.0
        notes = ""
        location = ""
        drawingPaths.removeAll() // Çizimleri temizle
    }
    
    func addPath(_ path: UIBezierPath) {
        drawingPaths.append(path)
    }
    
    func clearDrawing() {
        drawingPaths.removeAll()
        print("Çizim temizlendi")
    }
    
    func analyzeCurrentDrawing() async {
        // Daha önceki analiz verilerini temizle
        analysisState = .ready
        digitResults = []
        selectedDigit = nil
        digitInfo = nil
        errorMessage = nil
        showError = false
        
        // Çizim varsa analiz et
        if !drawingPaths.isEmpty {
            await analyzeDrawing()
        } else {
            errorMessage = "Lütfen önce bir rakam çizin"
            showError = true
        }
    }
    
    func toggleCoreMLMethod() {
        useDirectCoreML.toggle()
        print("CoreML yöntemi değiştirildi: \(useDirectCoreML ? "Doğrudan CoreML" : "Vision Framework")")
    }
} 