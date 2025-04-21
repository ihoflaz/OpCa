import SwiftUI

struct ContentView: View {
    @StateObject private var imageProcessor = ImageProcessor()
    @ObservedObject private var colorSchemeManager = ColorSchemeManager.shared
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showMenu = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        Image(systemName: "photo.on.rectangle")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .foregroundColor(.blue.opacity(0.7))
                            .padding()
                    }
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Mikroskop Görüntüsü Çek")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    if imageProcessor.isAnalyzing {
                        ProgressView("Görüntü Analiz Ediliyor...")
                            .padding()
                    }
                    
                    if let result = imageProcessor.analysisResult {
                        ResultView(result: result)
                    }
                    
                    Spacer()
                }
                .navigationTitle("OpCa")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation {
                                showMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Yan Menü
                if showMenu {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showMenu = false
                            }
                        }
                    
                    SideMenuView(isShowing: $showMenu)
                }
            }
        }
        .preferredColorScheme(colorSchemeManager.isDarkMode ? .dark : .light)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                imageProcessor.analyzeImage(image)
            }
        }
    }
}

#Preview {
    ContentView()
} 
