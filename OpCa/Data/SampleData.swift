import Foundation
import SwiftUI
import SwiftData

/// Demo veriler oluşturmak için yardımcı sınıf
class SampleDataGenerator {
    
    /// ModelContext'e demo veriler ekler
    static func populateSampleData(context: ModelContext) {
        // Eğer veriler zaten eklendiyse tekrar ekleme
        let descriptor = FetchDescriptor<Analysis>()
        let existingCount: Int
        
        do {
            existingCount = try context.fetchCount(descriptor)
            if existingCount > 0 {
                print("Demo veriler zaten eklenmiş, tekrar ekleme atlanıyor")
                return
            }
        } catch {
            print("Demo veri kontrolü sırasında hata: \(error.localizedDescription)")
            return
        }
        
        // Demo parazit görselleri için güvenli bir görsel oluşturma fonksiyonu
        func createSampleImage(color: Color) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
            return renderer.image { context in
                // Arka plan
                UIColor.systemGray6.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
                
                // Renkli bir daire çiz
                UIColor(color).setFill()
                context.fill(CGRect(x: 75, y: 75, width: 150, height: 150).insetBy(dx: 10, dy: 10))
                
                // Çerçeve
                UIColor.darkGray.setStroke()
                context.stroke(CGRect(x: 0, y: 0, width: 300, height: 300).insetBy(dx: 5, dy: 5))
            }
        }
        
        // Farklı parazit türleri için farklı renkli görüntüler oluştur
        let demoImages = [
            createSampleImage(color: .red),      // Neosporosis
            createSampleImage(color: .orange),   // Echinococcosis
            createSampleImage(color: .yellow),   // Coenurosis
            createSampleImage(color: .blue),     // Genel örnek 1
            createSampleImage(color: .green)     // Genel örnek 2
        ]
        
        // Demo konumlar
        let locations = [
            "Ankara Veteriner Fakültesi",
            "İstanbul Hayvan Hastanesi",
            "Konya Çiftlik Bölgesi",
            "Erzurum Hayvancılık Merkezi",
            "İzmir Veteriner Kliniği",
            "Bursa Köy Veteriner İstasyonu"
        ]
        
        // Demo notlar
        let notes = [
            "Köpekte Neosporosis şüphesi tespit edildi, tedaviye başlandı",
            "Echinococcosis analiz sonuçları, hayvan sahibine bildirildi",
            "Coenurosis enfeksiyonu, erken evre, takip gerekiyor",
            "Rutin kontrol, parazit bulgusu yok",
            "Evcil hayvanda yaygın parazit enfeksiyonu, ilaç tedavisi uygulandı",
            "Çiftlik hayvanlarında görülen parazit kontrolü"
        ]
        
        // Geçmiş tarihler oluşturalım
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        
        // Son 30 gün için demo veriler oluştur
        for i in 0..<15 {
            // Tarih oluştur (bugünden geriye doğru)
            dateComponents.day = -i
            let date = calendar.date(byAdding: dateComponents, to: Date()) ?? Date()
            
            // Her parazit türü için farklı güven değerleri oluştur (gerçekçi dağılım için)
            let parasiteType: ParasiteType
            let confidence: Double
            let detectionDate = date
            let otherParasites: [ParasiteResult]
            
            switch i % 3 {
            case 0:
                parasiteType = .neosporosis
                confidence = Double.random(in: 0.75...0.95)
                otherParasites = [
                    ParasiteResult(type: .echinococcosis, confidence: Double.random(in: 0.05...0.15), detectionDate: detectionDate),
                    ParasiteResult(type: .coenurosis, confidence: Double.random(in: 0.02...0.1), detectionDate: detectionDate)
                ]
            case 1:
                parasiteType = .echinococcosis
                confidence = Double.random(in: 0.7...0.9)
                otherParasites = [
                    ParasiteResult(type: .neosporosis, confidence: Double.random(in: 0.1...0.2), detectionDate: detectionDate),
                    ParasiteResult(type: .coenurosis, confidence: Double.random(in: 0.05...0.15), detectionDate: detectionDate)
                ]
            case 2:
                parasiteType = .coenurosis
                confidence = Double.random(in: 0.65...0.85)
                otherParasites = [
                    ParasiteResult(type: .neosporosis, confidence: Double.random(in: 0.05...0.15), detectionDate: detectionDate),
                    ParasiteResult(type: .echinococcosis, confidence: Double.random(in: 0.1...0.3), detectionDate: detectionDate)
                ]
            default:
                parasiteType = .neosporosis
                confidence = 0.8
                otherParasites = []
            }
            
            // Dominant parazit sonucu
            let dominantResult = ParasiteResult(
                type: parasiteType,
                confidence: confidence,
                detectionDate: detectionDate
            )
            
            // Tüm sonuçları birleştir
            var results = [dominantResult]
            results.append(contentsOf: otherParasites)
            
            // Demo görsel
            let imageIndex = i % demoImages.count
            let imageData = demoImages[imageIndex].pngData()
            
            // Demo konum
            let locationIndex = i % locations.count
            let location = locations[locationIndex]
            
            // Demo not
            let noteIndex = i % notes.count
            let note = notes[noteIndex]
            
            // Analiz oluştur
            let analysis = Analysis(
                imageData: imageData,
                location: location,
                timestamp: date,
                notes: note,
                results: results,
                isUploaded: i > 5  // İlk 5 analiz yüklenmemiş olsun
            )
            
            // Yükleme tarihi ekle
            if analysis.isUploaded {
                // Analizden 1-3 saat sonra yüklenmiş gibi
                let hoursLater = Int.random(in: 1...3)
                dateComponents.hour = hoursLater
                analysis.uploadTimestamp = calendar.date(byAdding: dateComponents, to: date)
                dateComponents.hour = 0 // Sıfırla
            }
            
            // Modele ekle
            context.insert(analysis)
        }
        
        // Değişiklikleri kaydet
        do {
            try context.save()
            print("Demo veriler başarıyla eklendi")
        } catch {
            print("Demo verileri kaydederken hata: \(error.localizedDescription)")
        }
    }
} 