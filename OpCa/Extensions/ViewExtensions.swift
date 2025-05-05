import SwiftUI

// Environment key for high contrast
private struct HighContrastEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var highContrastEnabled: Bool {
        get { self[HighContrastEnabledKey.self] }
        set { self[HighContrastEnabledKey.self] = newValue }
    }
}

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
    
    func highContrastEnabled(_ enabled: Bool) -> some View {
        self.environment(\.highContrastEnabled, enabled)
            .accessibility(value: Text(enabled ? "High contrast mode enabled" : "High contrast mode disabled"))
            .modifier(HighContrastViewModifier(enabled: enabled))
    }
}

// Modifier to apply high contrast mode visual adjustments
struct HighContrastViewModifier: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        if enabled {
            content
                .contrast(1.5)
                .brightness(0.05)
                .saturation(1.2)
                .accessibilityLabel("High contrast mode enabled")
        } else {
            content
        }
    }
} 