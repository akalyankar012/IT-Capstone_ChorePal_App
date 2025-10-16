import SwiftUI

// MARK: - Gradient Background System
struct GradientBackground: View {
    let theme: AppTheme
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
    
    private var gradientColors: [Color] {
        switch theme {
        case .light:
            return [
                Color.white,           // Pure white
                Color(hex: "#fefeff"), // Very very light blue
                Color(hex: "#fafcff"), // Very very light blue
                Color(hex: "#f5f9ff"), // Very light blue
                Color(hex: "#f0f6ff"), // Light blue
                Color(hex: "#e8f2ff"), // Light blue
                Color(hex: "#ddeeff"), // Medium light blue
                Color(hex: "#d1e7ff"), // Medium light blue
                Color(hex: "#c4dfff"), // Medium blue
                Color(hex: "#b8d7ff"), // Medium blue
                Color(hex: "#b0d2ff")  // Slightly darker blue
            ]
        case .dark:
            return [
                Color(hex: "#0a1929"), // Very dark blue
                Color(hex: "#0d1d32"), // Dark blue
                Color(hex: "#0f1f3a"), // Dark blue
                Color(hex: "#14254b"), // Dark blue
                Color(hex: "#192b5c"), // Medium dark blue
                Color(hex: "#1e316d"), // Medium dark blue
                Color(hex: "#23377e"), // Medium blue
                Color(hex: "#283d8f"), // Medium blue
                Color(hex: "#2d43a0"), // Bright blue
                Color(hex: "#3249b1"), // Lighter blue
                Color(hex: "#3750c2")  // Even lighter blue
            ]
        }
    }
}

// MARK: - Card Background
struct CardBackground: View {
    let theme: AppTheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(cardColor)
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }
    
    private var cardColor: Color {
        switch theme {
        case .light:
            return Color.white.opacity(0.9)
        case .dark:
            return Color.black.opacity(0.3)
        }
    }
    
    private var shadowColor: Color {
        switch theme {
        case .light:
            return Color.black.opacity(0.1)
        case .dark:
            return Color.black.opacity(0.3)
        }
    }
}

// MARK: - Button Background
struct ButtonBackground: View {
    let theme: AppTheme
    let isPressed: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(buttonColor)
            .shadow(color: shadowColor, radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)
            .scaleEffect(isPressed ? 0.95 : 1.0)
    }
    
    private var buttonColor: Color {
        switch theme {
        case .light:
            return Color(hex: "#a2cee3")
        case .dark:
            return Color(hex: "#3b82f6")
        }
    }
    
    private var shadowColor: Color {
        switch theme {
        case .light:
            return Color(hex: "#a2cee3").opacity(0.3)
        case .dark:
            return Color(hex: "#3b82f6").opacity(0.4)
        }
    }
}

// MARK: - Theme Color Extension
extension Color {
    static func backgroundColor(_ theme: AppTheme) -> Color {
        switch theme {
        case .light:
            return Color(hex: "#f5f5f5")
        case .dark:
            return Color(hex: "#0a1929")
        }
    }
    
    static func textColor(_ theme: AppTheme) -> Color {
        switch theme {
        case .light:
            return Color.primary
        case .dark:
            return Color.white
        }
    }
}

// MARK: - Theme Toggle Button
struct ThemeToggleButton: View {
    @Binding var selectedTheme: AppTheme
    @State private var isAnimating = false
    
    private var themeColor: Color {
        switch selectedTheme {
        case .light:
            return Color(hex: "#a2cee3")
        case .dark:
            return Color(hex: "#3b82f6")
        }
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTheme = nextTheme
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: themeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                
                Text(themeName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(themeColor)
                    .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
    
    private var nextTheme: AppTheme {
        switch selectedTheme {
        case .light:
            return .dark
        case .dark:
            return .light
        }
    }
    
    private var themeIcon: String {
        switch selectedTheme {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    private var themeName: String {
        switch selectedTheme {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}
