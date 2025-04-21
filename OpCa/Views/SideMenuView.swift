import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @ObservedObject var userManager = UserManager.shared
    @State private var selectedMenuItem: MenuItem?
    @State private var showProfile = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showFAQ = false
    @State private var showStore = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: 
                    Gradient(colors: [Color.blue.opacity(0.9), Color.blue.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    // Profil Bölümü
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .foregroundColor(.white)
                        
                        Text(userManager.currentUser?.name ?? "Kullanıcı")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        Text(userManager.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                    
                    Divider()
                        .background(Color.white.opacity(0.7))
                    
                    // Menü Öğeleri
                    VStack(spacing: 5) {
                        // Profil Butonu
                        NavigationLink(destination: ProfileView(), isActive: $showProfile) {
                            Button(action: {
                                showProfile = true
                                withAnimation {
                                    isShowing = false
                                }
                            }) {
                                MenuRow(item: .profile)
                            }
                        }
                        
                        // Geçmiş Butonu
                        NavigationLink(destination: Text("Geçmiş Analizler").navigationTitle("Geçmiş"), isActive: $showHistory) {
                            Button(action: {
                                showHistory = true
                                withAnimation {
                                    isShowing = false
                                }
                            }) {
                                MenuRow(item: .history)
                            }
                        }
                        
                        // Mağaza Butonu
                        NavigationLink(destination: StoreView(), isActive: $showStore) {
                            Button(action: {
                                showStore = true
                                withAnimation {
                                    isShowing = false
                                }
                            }) {
                                MenuRow(item: .store)
                            }
                        }
                        
                        // Hakkımızda Butonu
                        NavigationLink(destination: Text("Hakkımızda").navigationTitle("Hakkımızda"), isActive: $showAbout) {
                            Button(action: {
                                showAbout = true
                                withAnimation {
                                    isShowing = false
                                }
                            }) {
                                MenuRow(item: .about)
                            }
                        }
                        
                        // SSS Butonu
                        NavigationLink(destination: Text("SSS").navigationTitle("SSS"), isActive: $showFAQ) {
                            Button(action: {
                                showFAQ = true
                                withAnimation {
                                    isShowing = false
                                }
                            }) {
                                MenuRow(item: .faq)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Çıkış Butonu
                    Button(action: {
                        withAnimation {
                            userManager.logout()
                            isShowing = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Çıkış Yap")
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                }
                .padding()
                .frame(maxWidth: 300)
                .background(Color.clear)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.move(edge: .leading))
        }
    }
}

struct MenuRow: View {
    let item: MenuItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.icon)
                .frame(width: 24, height: 24)
            
            Text(item.title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .opacity(0.7)
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
        )
    }
}

enum MenuItem: CaseIterable {
    case profile
    case history
    case store
    case settings
    case about
    case faq
    
    var title: String {
        switch self {
        case .profile: return "Profil"
        case .history: return "Geçmiş"
        case .store: return "Mağaza"
        case .settings: return "Ayarlar"
        case .about: return "Hakkımızda"
        case .faq: return "SSS"
        }
    }
    
    var icon: String {
        switch self {
        case .profile: return "person.fill"
        case .history: return "clock.fill"
        case .store: return "cart.fill"
        case .settings: return "gear"
        case .about: return "info.circle.fill"
        case .faq: return "questionmark.circle.fill"
        }
    }
} 