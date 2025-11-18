import SwiftUI
import UIKit

// MARK: - Task Completion Celebration (lightweight)
struct TaskCompletionCelebration: View {
    @State private var animate = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            if showConfetti {
                ForEach(0..<50, id: \.self) { _ in
                    TaskConfettiParticle()
                        .offset(
                            x: CGFloat.random(in: -200...200),
                            y: animate ? -1000 : 1000
                        )
                        .animation(
                            .easeOut(duration: Double.random(in: 2...4))
                            .delay(Double.random(in: 0...1)),
                            value: animate
                        )
                }
            }
        }
        .onAppear {
            animate = true
            showConfetti = true
        }
    }
}

struct TaskConfettiParticle: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
    private let shapes = ["circle.fill", "square.fill", "triangle.fill", "diamond.fill"]
    
    var body: some View {
        Image(systemName: shapes.randomElement() ?? "circle.fill")
            .foregroundColor(colors.randomElement() ?? .blue)
            .font(.system(size: CGFloat.random(in: 8...16)))
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.linear(duration: Double.random(in: 2...4)).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    scale = CGFloat.random(in: 0.5...1.5)
                }
            }
    }
}

// MARK: - Animated Background (icons + floating shapes)
struct BackgroundChoresAnimation: View {
    @State private var animate = false
    
    private let icons = [
        // Home/utility
        "house.fill", "gearshape.fill", "person.fill", "bell.fill", "clock.fill",
        // Chores/tasks
        "list.bullet", "list.bullet.clipboard", "checkmark.circle.fill", "broom", "sparkles",
        // Rewards/points
        "star.fill", "trophy.fill", "gift.fill", "bag.fill", "cart.fill",
        // Learning/fun
        "book.fill", "gamecontroller.fill", "pencil",
        // Schedule/metrics
        "calendar", "chart.bar.fill",
        // Friendly extras
        "heart.fill", "flame.fill", "leaf.fill", "camera.fill"
    ]
    
    var body: some View {
        ZStack {
            ForEach(0..<28, id: \.self) { index in
                ChoreIconParticle(
                    iconName: icons[index % icons.count],
                    delay: Double(index) * 0.1
                )
            }
            ForEach(0..<10, id: \.self) { index in
                FloatingElement(
                    index: index,
                    delay: Double(index) * 0.3
                )
            }
        }
        .onAppear { animate = true }
    }
}

struct FloatingElement: View {
    let index: Int
    let delay: Double
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0.25
    
    private let shapes = ["circle.fill", "square.fill", "triangle.fill", "diamond.fill", "hexagon.fill"]
    private let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .yellow]
    
    var body: some View {
        Image(systemName: shapes.randomElement() ?? "circle.fill")
            .font(.system(size: CGFloat.random(in: 8...18), weight: .bold))
            .foregroundColor(colors.randomElement()?.opacity(0.35) ?? .blue.opacity(0.35))
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            .onAppear { startFloatingAnimation() }
    }
    
    private func startFloatingAnimation() {
        offset = CGSize(
            width: CGFloat.random(in: -UIScreen.main.bounds.width...UIScreen.main.bounds.width),
            height: CGFloat.random(in: -UIScreen.main.bounds.height...UIScreen.main.bounds.height)
        )
        withAnimation(.easeInOut(duration: Double.random(in: 18...28)).repeatForever(autoreverses: true).delay(delay)) {
            offset = CGSize(
                width: CGFloat.random(in: -UIScreen.main.bounds.width...UIScreen.main.bounds.width),
                height: CGFloat.random(in: -UIScreen.main.bounds.height...UIScreen.main.bounds.height)
            )
        }
        withAnimation(.linear(duration: Double.random(in: 30...45)).repeatForever(autoreverses: false).delay(delay)) {
            rotation = 360
        }
        withAnimation(.easeInOut(duration: Double.random(in: 12...20)).repeatForever(autoreverses: true).delay(delay)) {
            opacity = Double.random(in: 0.15...0.25)
        }
    }
}

struct ChoreIconParticle: View {
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0.55
    @State private var scale: CGFloat = 1.0
    @State private var bounceDirection: CGSize = .zero
    let iconName: String
    let delay: Double
    
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: CGFloat.random(in: 22...36), weight: .bold))
            .foregroundColor([Color.blue, Color.green, Color.orange, Color.purple, Color.red].randomElement()?.opacity(0.65) ?? .blue.opacity(0.65))
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .offset(offset)
            .blendMode(.plusLighter)
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            .onAppear {
                startBouncingAnimation()
            }
    }
    
    private func startBouncingAnimation() {
        offset = CGSize(
            width: CGFloat.random(in: -300...300),
            height: CGFloat.random(in: -600...600)
        )
        bounceDirection = CGSize(
            width: CGFloat.random(in: -1...1),
            height: CGFloat.random(in: -1...1)
        )
        animateBounce()
        withAnimation(.linear(duration: Double.random(in: 3...6)).repeatForever(autoreverses: false).delay(delay)) {
            rotation = 360
        }
        withAnimation(.easeInOut(duration: Double.random(in: 3.0...5.0)).repeatForever(autoreverses: true).delay(delay)) {
            opacity = Double.random(in: 0.35...0.6)
        }
    }
    
    private func animateBounce() {
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        let screenHeight: CGFloat = UIScreen.main.bounds.height
        var nextX = offset.width + bounceDirection.width * 24
        var nextY = offset.height + bounceDirection.height * 24
        if nextX > screenWidth/2 + 100 {
            bounceDirection.width = -abs(bounceDirection.width)
            nextX = screenWidth/2 + 100
        } else if nextX < -screenWidth/2 - 100 {
            bounceDirection.width = abs(bounceDirection.width)
            nextX = -screenWidth/2 - 100
        }
        if nextY > screenHeight/2 + 100 {
            bounceDirection.height = -abs(bounceDirection.height)
            nextY = screenHeight/2 + 100
        } else if nextY < -screenHeight/2 - 100 {
            bounceDirection.height = abs(bounceDirection.height)
            nextY = -screenHeight/2 - 100
        }
        withAnimation(.easeInOut(duration: Double.random(in: 10...16)).delay(delay)) {
            offset = CGSize(width: nextX, height: nextY)
        }
        withAnimation(.easeInOut(duration: Double.random(in: 8...14)).delay(delay)) {
            scale = Double.random(in: 0.96...1.04)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 8...14)) {
            animateBounce()
        }
    }
}

// MARK: - Child-Friendly Background (stars + clouds)
struct ChildFriendlyBackground: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            ForEach(0..<6, id: \.self) { index in
                StarView(index: index)
            }
            ForEach(0..<3, id: \.self) { index in
                CloudView(index: index)
            }
        }
    }
}

struct StarView: View {
    let index: Int
    @State private var animate = false
    
    var body: some View {
        Image(systemName: "star.fill")
            .foregroundColor(.yellow.opacity(0.3))
            .font(.system(size: 16))
            .position(x: 100 + CGFloat(index * 50), y: 150 + CGFloat(index * 30))
            .scaleEffect(animate ? 1.3 : 0.7)
            .opacity(animate ? 0.8 : 0.3)
            .onAppear {
                let duration = 2.0 + Double(index) * 0.3
                let delay = Double(index) * 0.2
                let animation = Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                withAnimation(animation) { animate = true }
            }
    }
}

struct CloudView: View {
    let index: Int
    @State private var animate = false
    
    var body: some View {
        Image(systemName: "cloud.fill")
            .foregroundColor(.gray.opacity(0.2))
            .font(.system(size: 40))
            .position(x: 150 + CGFloat(index * 100), y: 200 + CGFloat(index * 50))
            .offset(x: animate ? 30 : -30)
            .onAppear {
                let duration = 6.0 + Double(index) * 2.0
                let delay = Double(index) * 1.0
                let animation = Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                withAnimation(animation) { animate = true }
            }
    }
}


