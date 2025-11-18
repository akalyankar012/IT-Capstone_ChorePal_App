import SwiftUI

// MARK: - Child Reward Card (Available Rewards)
struct ChildRewardCard: View {
    let reward: Reward
    let currentPoints: Int
    let selectedTheme: AppTheme
    let themeColor: Color
    let onRedeem: () -> Void
    
    private var canAfford: Bool {
        currentPoints >= reward.points
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: reward.category.icon)
                .foregroundColor(Color(hex: reward.category.color))
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(Color(hex: reward.category.color).opacity(0.2))
                .cornerRadius(10)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(selectedTheme == .light ? .primary : .white)
                
                if !reward.description.isEmpty {
                    Text(reward.description)
                        .font(.caption)
                        .foregroundColor(selectedTheme == .light ? .gray : Color.white.opacity(0.85))
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    // Points cost
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(reward.points) pts")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(canAfford ? themeColor : .red)
                    }
                    
                    // Affordability indicator
                    if canAfford {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Eligible")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Need \(reward.points - currentPoints) more")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Redeem button
            Button(action: onRedeem) {
                Text("Redeem")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canAfford ? themeColor : Color.gray.opacity(0.5))
                    .cornerRadius(8)
            }
            .disabled(!canAfford)
        }
        .padding(14)
        .glassCard(isLightMode: selectedTheme == .light, themeColor: themeColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(canAfford ? themeColor.opacity(0.25) : Color.clear, lineWidth: 1.5)
        )
        .opacity(canAfford ? 1.0 : 0.7)
    }
}

// MARK: - Redeemed Reward Card
struct RedeemedRewardCard: View {
    let reward: Reward
    let selectedTheme: AppTheme
    let themeColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: reward.category.icon)
                .foregroundColor(Color(hex: reward.category.color))
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(Color(hex: reward.category.color).opacity(0.2))
                .cornerRadius(10)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reward.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(selectedTheme == .light ? .primary : .white)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if !reward.description.isEmpty {
                    Text(reward.description)
                        .font(.caption)
                        .foregroundColor(selectedTheme == .light ? .gray : Color.white.opacity(0.85))
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    // Points spent
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(reward.points) pts")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(themeColor)
                    }
                    
                    Text("•")
                        .foregroundColor(selectedTheme == .light ? .gray : Color.white.opacity(0.7))
                    
                    // Redeemed date
                    if let purchasedAt = reward.purchasedAt {
                        Text("Redeemed \(purchasedAt, style: .date)")
                            .font(.caption2)
                            .foregroundColor(selectedTheme == .light ? .gray : Color.white.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // Redeemed badge
            VStack(spacing: 4) {
                Image(systemName: "gift.fill")
                    .font(.title3)
                    .foregroundColor(themeColor)
            }
        }
        .padding(14)
        .glassCard(isLightMode: selectedTheme == .light, themeColor: themeColor)
    }
}

