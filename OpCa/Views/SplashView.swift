import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                
                Text("OpCa")
                    .font(.largeTitle.bold())
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                
                Text("Veterinary Diagnostic Tool")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 15)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.top, 40)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
            
            Spacer()
            
            Text("© 2025 OpCa. All rights reserved.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
                .opacity(isAnimating ? 0.7 : 0.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
} 