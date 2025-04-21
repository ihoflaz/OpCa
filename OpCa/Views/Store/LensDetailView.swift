import SwiftUI

struct LensDetailView: View {
    let lens: Lens
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Lens Görseli
                    Image(systemName: "../../1.webp")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .padding()
                    
                    // Lens Bilgileri
                    VStack(alignment: .leading, spacing: 20) {
                        // Başlık ve Fiyat
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(lens.name)
                                    .font(.title)
                                    .bold()
                                Text(lens.shortDescription)
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text(String(format: "%.2f TL", lens.price))
                                .font(.title2)
                                .bold()
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        // Detaylı Açıklama
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Ürün Açıklaması")
                                .font(.headline)
                            Text(lens.fullDescription)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Teknik Özellikler
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Teknik Özellikler")
                                .font(.headline)
                            
                            SpecificationRow(title: "Büyütme", value: lens.magnification)
                            SpecificationRow(title: "Uyumluluk", value: lens.compatibility)
                        }
                        .padding(.horizontal)
                        
                        // Özellikler
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Özellikler")
                                .font(.headline)
                            
                            ForEach(lens.features, id: \.self) { feature in
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(feature)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Satın Al Butonu
                    Button(action: {
                        // Satın alma işlemi
                    }) {
                        HStack {
                            Image(systemName: "cart.fill.badge.plus")
                            Text("Satın Al")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                        .shadow(color: .blue.opacity(0.3), radius: 5)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct SpecificationRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
} 
