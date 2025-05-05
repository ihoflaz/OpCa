import SwiftUI

extension View {
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
    }
    
    func cardStyle() -> some View {
        self
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2)
            .padding(.horizontal)
    }
    
    func largeTouchTarget() -> some View {
        self
            .contentShape(Rectangle())
            .padding(10)
    }
    
    func highContrastText() -> some View {
        self
            .font(.body.weight(.medium))
            .foregroundStyle(.primary)
    }
} 