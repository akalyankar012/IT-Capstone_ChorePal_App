import SwiftUI

private struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isLightMode: Bool
    let themeColor: Color
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(.systemBackground).opacity(isLightMode ? 0.95 : 0.25))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(isLightMode ? 0.9 : 0.55))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(themeColor.opacity(isLightMode ? 0.08 : 0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isLightMode ? 0.18 : 0.35), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 12, isLightMode: Bool, themeColor: Color) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, isLightMode: isLightMode, themeColor: themeColor))
    }
    
    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

