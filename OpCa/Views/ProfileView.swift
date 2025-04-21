import SwiftUI

struct ProfileView: View {
    @ObservedObject var userManager = UserManager.shared
    @State private var showImagePicker = false
    @State private var profileImage: UIImage?
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var institution = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedTab = 0
    
    private let gradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Animasyonlu Header
                ZStack {
                    // Arka plan
                    WaveShape()
                        .fill(gradient)
                        .frame(height: 280)
                        .shadow(radius: 10)
                    
                    // Profil Resmi ve İsim
                    VStack {
                        ZStack(alignment: .bottomTrailing) {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 10)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 140, height: 140)
                                    .foregroundColor(.white)
                                    .shadow(radius: 10)
                            }
                            
                            Button(action: {
                                showImagePicker = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(radius: 5)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                }
                            }
                            .offset(x: 10, y: 10)
                        }
                        
                        Text(name.isEmpty ? "Kullanıcı Adı" : name)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                }
                
                // Sekme Görünümü
                CustomTabView(selectedTab: $selectedTab)
                    .padding(.top, -20)
                    .zIndex(1)
                
                // İçerik
                TabView(selection: $selectedTab) {
                    // Kişisel Bilgiler
                    PersonalInfoView(
                        name: $name,
                        email: $email,
                        phone: $phone,
                        institution: $institution
                    )
                    .tag(0)
                    
                    // İstatistikler
                    StatisticsView()
                        .tag(1)
                    
                    // Tercihler
                    PreferencesView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: UIScreen.main.bounds.height * 0.6)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $profileImage)
        }
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
}

// Dalga Şekli
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: width, y: height * 0.8))
        
        // Dalga efekti
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.9),
            control1: CGPoint(x: width * 0.75, y: height * 1.1),
            control2: CGPoint(x: width * 0.25, y: height * 0.7)
        )
        
        path.closeSubpath()
        return path
    }
}

// Özel Sekme Görünümü
struct CustomTabView: View {
    @Binding var selectedTab: Int
    private let tabs = ["Bilgiler", "İstatistikler", "Tercihler"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    Text(tabs[index])
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            ZStack {
                                if selectedTab == index {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 5)
                                }
                            }
                        )
                        .foregroundColor(selectedTab == index ? .blue : .gray)
                }
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.1), radius: 10)
        .padding(.horizontal)
    }
}

// Kişisel Bilgiler Görünümü
struct PersonalInfoView: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var institution: String
    
    var body: some View {
        VStack(spacing: 20) {
            InfoCard(title: "Kişisel Bilgiler") {
                CustomTextField(icon: "person.fill", placeholder: "Ad Soyad", text: $name)
                CustomTextField(icon: "envelope.fill", placeholder: "E-posta", text: $email)
                CustomTextField(icon: "phone.fill", placeholder: "Telefon", text: $phone)
                CustomTextField(icon: "building.2.fill", placeholder: "Kurum", text: $institution)
            }
            
            Button(action: {}) {
                Text("Değişiklikleri Kaydet")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.blue, .purple],
                                     startPoint: .leading,
                                     endPoint: .trailing)
                    )
                    .cornerRadius(15)
                    .shadow(color: .blue.opacity(0.3), radius: 5)
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

// İstatistikler Görünümü
struct StatisticsView: View {
    var body: some View {
        VStack(spacing: 20) {
            InfoCard(title: "Analiz İstatistikleri") {
                StatRow(title: "Toplam Analiz", value: "24", icon: "chart.bar.fill")
                StatRow(title: "Bu Ay", value: "8", icon: "calendar")
                StatRow(title: "Başarı Oranı", value: "%92", icon: "checkmark.circle.fill")
            }
        }
        .padding(.top)
    }
}

// Tercihler Görünümü
struct PreferencesView: View {
    @ObservedObject private var colorSchemeManager = ColorSchemeManager.shared
    @State private var notifications = true
    @State private var autoSave = true
    
    var body: some View {
        VStack(spacing: 20) {
            InfoCard(title: "Uygulama Tercihleri") {
                ToggleRow(title: "Karanlık Mod", 
                         icon: "moon.fill", 
                         isOn: $colorSchemeManager.isDarkMode)
                    .onChange(of: colorSchemeManager.isDarkMode) { newValue in
                        withAnimation {
                            // Dark mode değiştiğinde animasyon ekler
                            playHapticFeedback()
                        }
                    }
                
                ToggleRow(title: "Bildirimler", 
                         icon: "bell.fill", 
                         isOn: $notifications)
                
                ToggleRow(title: "Otomatik Kayıt", 
                         icon: "square.and.arrow.down.fill", 
                         isOn: $autoSave)
            }
        }
        .padding(.top)
    }
    
    private func playHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// Yardımcı Görünümler
struct InfoCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
        .padding(.horizontal)
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .bold()
                .foregroundColor(.blue)
        }
        .padding(.vertical, 5)
    }
}

struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
} 