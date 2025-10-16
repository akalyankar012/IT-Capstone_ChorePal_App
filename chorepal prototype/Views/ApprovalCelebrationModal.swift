import SwiftUI

// MARK: - Approval Celebration Modal
struct ApprovalCelebrationModal: View {
    let approvedChores: [Chore]
    let totalPoints: Int
    @Binding var isPresented: Bool
    
    @State private var balloons: [BalloonData] = []
    @State private var showContent = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            // Balloons layer (behind content)
            ForEach(balloons) { balloon in
                BalloonView(color: balloon.color)
                    .offset(x: balloon.xOffset, y: balloon.yOffset)
                    .opacity(balloon.opacity)
            }
            
            // Content card
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .scaleEffect(showContent ? 1.0 : 0.1)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: showContent)
                    
                    Text("Great Job!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
                    
                    Text("Your tasks were approved!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.4).delay(0.4), value: showContent)
                }
                .padding(.top, 40)
                .padding(.bottom, 24)
                
                // Approved tasks list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(approvedChores.enumerated()), id: \.element.id) { index, chore in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.green)
                                            .font(.system(size: 18, weight: .bold))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(chore.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                        Text("+\(chore.points) points")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .opacity(showContent ? 1 : 0)
                            .offset(x: showContent ? 0 : -50)
                            .animation(.easeOut(duration: 0.4).delay(0.5 + Double(index) * 0.1), value: showContent)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 300)
                
                // Total points earned
                VStack(spacing: 8) {
                    Text("Total Earned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("\(totalPoints)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(themeColor)
                    }
                }
                .padding(.vertical, 24)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: showContent)
                
                // Dismiss button
                Button(action: dismissModal) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.9), value: showContent)
            }
            .frame(maxWidth: 400)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(20)
        }
        .onAppear {
            showContent = true
            startBalloonAnimation()
        }
    }
    
    private func dismissModal() {
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    private func startBalloonAnimation() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        
        // Create 15 balloons
        for i in 0..<15 {
            let delay = Double(i) * 0.2
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let balloon = BalloonData(
                    id: UUID(),
                    color: colors.randomElement() ?? .blue,
                    xOffset: CGFloat.random(in: -150...150),
                    yOffset: UIScreen.main.bounds.height / 2 + 100,
                    opacity: 1.0
                )
                
                balloons.append(balloon)
                
                // Animate balloon rising
                withAnimation(.linear(duration: 4.0)) {
                    if let index = balloons.firstIndex(where: { $0.id == balloon.id }) {
                        balloons[index].yOffset = -UIScreen.main.bounds.height / 2 - 200
                        balloons[index].opacity = 0.0
                    }
                }
                
                // Remove balloon after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    balloons.removeAll { $0.id == balloon.id }
                }
            }
        }
    }
}

// MARK: - Balloon Data
struct BalloonData: Identifiable {
    let id: UUID
    let color: Color
    var xOffset: CGFloat
    var yOffset: CGFloat
    var opacity: Double
}

// MARK: - Balloon View
struct BalloonView: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Balloon body
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: color.opacity(0.5), radius: 5, x: 0, y: 3)
            
            // Balloon string
            Rectangle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 1, height: 30)
                .offset(y: 40)
        }
    }
}

// MARK: - Preview
struct ApprovalCelebrationModal_Previews: PreviewProvider {
    static var previews: some View {
        ApprovalCelebrationModal(
            approvedChores: [
                Chore(title: "Clean Room", description: "Tidy up", points: 25, dueDate: Date(), isCompleted: true, isRequired: true, assignedToChildId: nil, createdAt: Date()),
                Chore(title: "Do Homework", description: "Math homework", points: 30, dueDate: Date(), isCompleted: true, isRequired: true, assignedToChildId: nil, createdAt: Date())
            ],
            totalPoints: 55,
            isPresented: .constant(true)
        )
    }
}

