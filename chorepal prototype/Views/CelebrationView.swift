import SwiftUI

// MARK: - Celebration Animation Overlay
struct CelebrationView: View {
    @Binding var isShowing: Bool
    @State private var balloons: [Balloon] = []
    @State private var confetti: [Confetti] = []
    
    var body: some View {
        ZStack {
            // Balloons
            ForEach(balloons) { balloon in
                BalloonShape()
                    .fill(balloon.color)
                    .frame(width: 30, height: 40)
                    .offset(x: balloon.x, y: balloon.y)
                    .opacity(balloon.opacity)
            }
            
            // Confetti pieces
            ForEach(confetti) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: 8, height: 8)
                    .rotationEffect(.degrees(piece.rotation))
                    .offset(x: piece.x, y: piece.y)
                    .opacity(piece.opacity)
            }
        }
        .allowsHitTesting(false) // Don't block touches
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Create balloons
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for i in 0..<12 {
            let balloon = Balloon(
                id: UUID(),
                x: CGFloat.random(in: -screenWidth/2...screenWidth/2),
                y: screenHeight/2, // Start at bottom
                color: [.red, .blue, .green, .yellow, .purple, .orange, .pink].randomElement()!,
                opacity: 1.0
            )
            balloons.append(balloon)
            
            // Animate balloon upward
            withAnimation(
                .easeOut(duration: Double.random(in: 2.0...3.5))
                .delay(Double(i) * 0.1)
            ) {
                if let index = balloons.firstIndex(where: { $0.id == balloon.id }) {
                    balloons[index].y = -screenHeight/2 - 100 // Move to top and beyond
                    balloons[index].x += CGFloat.random(in: -50...50) // Slight horizontal drift
                }
            }
            
            // Fade out near the end
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 + Double(i) * 0.1) {
                withAnimation(.easeOut(duration: 0.5)) {
                    if let index = balloons.firstIndex(where: { $0.id == balloon.id }) {
                        balloons[index].opacity = 0
                    }
                }
            }
        }
        
        // Create confetti burst
        for i in 0..<30 {
            let piece = Confetti(
                id: UUID(),
                x: 0, // Start from center
                y: 0,
                rotation: 0,
                color: [.red, .blue, .green, .yellow, .purple, .orange, .pink].randomElement()!,
                opacity: 1.0
            )
            confetti.append(piece)
            
            // Animate confetti explosion
            let angle = Double(i) * (360.0 / 30.0) // Spread evenly in circle
            let distance = CGFloat.random(in: 100...200)
            let destX = cos(angle * .pi / 180) * distance
            let destY = sin(angle * .pi / 180) * distance
            
            withAnimation(
                .easeOut(duration: 1.0)
                .delay(0.1)
            ) {
                if let index = confetti.firstIndex(where: { $0.id == piece.id }) {
                    confetti[index].x = destX
                    confetti[index].y = destY
                    confetti[index].rotation = Double.random(in: 0...360)
                }
            }
            
            // Fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    if let index = confetti.firstIndex(where: { $0.id == piece.id }) {
                        confetti[index].opacity = 0
                    }
                }
            }
        }
        
        // Hide celebration after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            isShowing = false
        }
    }
}

// MARK: - Balloon Data Model
struct Balloon: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let color: Color
    var opacity: Double
}

// MARK: - Confetti Data Model
struct Confetti: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    let color: Color
    var opacity: Double
}

// MARK: - Balloon Shape
struct BalloonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Balloon body (oval)
        path.addEllipse(in: CGRect(x: 0, y: 0, width: width, height: height * 0.8))
        
        // Balloon tie (triangle at bottom)
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.8))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.9))
        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.9))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Success Banner (Alternative celebration)
struct SuccessBanner: View {
    @Binding var isShowing: Bool
    let message: String
    let points: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Checkmark icon
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isShowing ? 1.0 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isShowing)
            
            // Message
            Text(message)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            // Points earned
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("+\(points) points!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.green.opacity(0.95))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .offset(y: isShowing ? 0 : -200)
        .opacity(isShowing ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isShowing)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}

