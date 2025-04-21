import SwiftUI

struct StoreView: View {
    @State private var selectedLens: Lens?
    @State private var showLensDetail = false
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DIPLE Lensler")
                            .font(.title)
                            .bold()
                        Text("Profesyonel mikroskop lensleri")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                
                // Lens Grid
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Lens.sampleLenses) { lens in
                        LensCard(lens: lens)
                            .onTapGesture {
                                selectedLens = lens
                                showLensDetail = true
                            }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Mağaza")
        .sheet(isPresented: $showLensDetail) {
            if let lens = selectedLens {
                LensDetailView(lens: lens)
            }
        }
    }
}

struct LensCard: View {
    let lens: Lens
    
    var body: some View {
        VStack(alignment: .leading) {
            // Lens Görseli
            Image("../../1.webp")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 120)
                .foregroundColor(.blue)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.blue.opacity(0.1))
                )
            
            // Lens Bilgileri
            VStack(alignment: .leading, spacing: 8) {
                Text(lens.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(lens.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                Text(String(format: "%.2f TL", lens.price))
                    .font(.title3)
                    .bold()
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }
}

struct Lens: Identifiable {
    let id = UUID()
    let name: String
    let shortDescription: String
    let fullDescription: String
    let price: Double
    let magnification: String
    let compatibility: String
    let features: [String]
    
    static let sampleLenses = [
        Lens(
            name: "DIPLE RED",
            shortDescription: "35x Büyütme",
            fullDescription: "DIPLE RED, 35x büyütme gücü ile hücre yapılarını net bir şekilde görüntülemenizi sağlar.",
            price: 1299.99,
            magnification: "35x",
            compatibility: "Tüm akıllı telefonlar",
            features: [
                "35x büyütme gücü",
                "Kolay montaj",
                "Yüksek çözünürlük",
                "Taşınabilir tasarım"
            ]
        ),
        Lens(
            name: "DIPLE GREY",
            shortDescription: "75x Büyütme",
            fullDescription: "DIPLE GREY, 75x büyütme güc�� ile mikroorganizmaları detaylı inceleme imkanı sunar.",
            price: 1799.99,
            magnification: "75x",
            compatibility: "Tüm akıllı telefonlar",
            features: [
                "75x büyütme gücü",
                "Profesyonel görüntü kalitesi",
                "Dayanıklı yapı",
                "Geniş görüş alanı"
            ]
        ),
        Lens(
            name: "DIPLE GREY",
            shortDescription: "75x Büyütme",
            fullDescription: "DIPLE GREY, 75x büyütme güc�� ile mikroorganizmaları detaylı inceleme imkanı sunar.",
            price: 1799.99,
            magnification: "75x",
            compatibility: "Tüm akıllı telefonlar",
            features: [
                "75x büyütme gücü",
                "Profesyonel görüntü kalitesi",
                "Dayanıklı yapı",
                "Geniş görüş alanı"
            ]
        ),
        Lens(
            name: "DIPLE GREY",
            shortDescription: "75x Büyütme",
            fullDescription: "DIPLE GREY, 75x büyütme güc�� ile mikroorganizmaları detaylı inceleme imkanı sunar.",
            price: 1799.99,
            magnification: "75x",
            compatibility: "Tüm akıllı telefonlar",
            features: [
                "75x büyütme gücü",
                "Profesyonel görüntü kalitesi",
                "Dayanıklı yapı",
                "Geniş görüş alanı"
            ]
        ),
        Lens(
            name: "DIPLE GREY",
            shortDescription: "75x Büyütme",
            fullDescription: "DIPLE GREY, 75x büyütme güc�� ile mikroorganizmaları detaylı inceleme imkanı sunar.",
            price: 1799.99,
            magnification: "75x",
            compatibility: "Tüm akıllı telefonlar",
            features: [
                "75x büyütme gücü",
                "Profesyonel görüntü kalitesi",
                "Dayanıklı yapı",
                "Geniş görüş alanı"
            ]
        ),
        Lens(
            name: "DIPLE GREY",
            shortDescription: "75x Büyütme",
            fullDescription: "DIPLE GREY, 75x büyütme güc�� ile mikroorganizmaları detaylı inceleme imkanı sunar.",
            price: 1799.99,
            magnification: "75x",
            compatibility: "Tüm akıllı telefonlar",
            features: [
                "75x büyütme gücü",
                "Profesyonel görüntü kalitesi",
                "Dayanıklı yapı",
                "Geniş görüş alanı"
            ]
        ),
        Lens(
            name: "DIPLE GREY",
            shortDescription: "75x Büyütme",
            fullDescription: "DIPLE GREY, 75x büyütme güc�� ile mikroorganizmaları detaylı inceleme imkanı sunar.",
            price: 1799.99,
            magnification: "75x",
            compatibility: "Tüm akıllı telefonlar",
            features: [
                "75x büyütme gücü",
                "Profesyonel görüntü kalitesi",
                "Dayanıklı yapı",
                "Geniş görüş alanı"
            ]
        ),
        Lens(
            name: "DIPLE GREY",
            shortDescription: "75x Büyütme",
            fullDescription: "DIPLE GREY, 75x büyütme güc�� ile mikroorganizmaları detaylı inceleme imkanı sunar.",
            price: 1799.99,
            magnification: "75x",
            compatibility: "Tüm akıllı telefonlar",
            features: [
                "75x büyütme gücü",
                "Profesyonel görüntü kalitesi",
                "Dayanıklı yapı",
                "Geniş görüş alanı"
            ]
        ),
        Lens(
            name: "DIPLE GREY",
            shortDescription: "75x Büyütme",
            fullDescription: "DIPLE GREY, 75x büyütme güc�� ile mikroorganizmaları detaylı inceleme imkanı sunar.",
            price: 1799.99,
            magnification: "75x",
            compatibility: "Tüm akıllı telefonlar",
            features: [
                "75x büyütme gücü",
                "Profesyonel görüntü kalitesi",
                "Dayanıklı yapı",
                "Geniş görüş alanı"
            ]
        ),
        Lens(
            name: "DIPLE BLACK",
            shortDescription: "150x Büyütme",
            fullDescription: "DIPLE BLACK, 150x büyütme gücü ile profesyonel mikroskop deneyimi sunar.",
            price: 2299.99,
            magnification: "150x",
            compatibility: "Tüm akıllı telefonlar",
            features: [
                "150x büyütme gücü",
                "Ultra net görüntü",
                "Profesyonel kullanım",
                "Gelişmiş optik sistem"
            ]
        )
    ]
} 
