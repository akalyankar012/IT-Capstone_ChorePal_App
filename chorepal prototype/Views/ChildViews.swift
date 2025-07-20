import SwiftUI

// MARK: - Child Dashboard View
struct ChildDashboardView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var choreService: ChoreService
    @ObservedObject var rewardService: RewardService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var showingRewardRedemption = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        // Child Avatar
                        Circle()
                            .fill(themeColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(currentChild?.name.prefix(1).uppercased() ?? "C"))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(themeColor)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentChild?.name ?? "Child")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text("\(currentChild?.points ?? 0) points")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .padding(.bottom, 16)
                
                // Tab Selector
                HStack(spacing: 0) {
                    TabButton(
                        title: "Chores",
                        icon: "list.bullet",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "Rewards",
                        icon: "gift",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    TabButton(
                        title: "Progress",
                        icon: "chart.bar",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    ChildChoresView(
                        choreService: choreService,
                        authService: authService
                    )
                    .tag(0)
                    
                    ChildRewardsView(
                        rewardService: rewardService,
                        authService: authService,
                        showingRedemption: $showingRewardRedemption
                    )
                    .tag(1)
                    
                    ChildProgressView(
                        choreService: choreService,
                        authService: authService
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingRewardRedemption) {
            RewardRedemptionView(
                rewardService: rewardService,
                authService: authService
            )
        }
    }
    
    private var currentChild: Child? {
        authService.currentChild
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? themeColor : .gray)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? themeColor : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeColor.opacity(0.1) : Color.clear)
            )
        }
    }
}

// MARK: - Child Chores View
struct ChildChoresView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ChildStatCard(
                        title: "Today's Chores",
                        value: "\(todayChoresCount)",
                        icon: "calendar",
                        color: .blue
                    )
                    
                    ChildStatCard(
                        title: "Completed Today",
                        value: "\(completedTodayCount)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                .padding(.horizontal, 20)
                
                // Chores List
                VStack(spacing: 16) {
                    HStack {
                        Text("Your Chores")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    if childChores.isEmpty {
                        EmptyChoresView()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(childChores) { chore in
                                ChildChoreRow(
                                    chore: chore,
                                    onComplete: {
                                        completeChore(chore)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var currentChild: Child? {
        authService.currentChild
    }
    
    private var childChores: [Chore] {
        guard let child = currentChild else { return [] }
        return choreService.getChoresForChild(child.id)
    }
    
    private var todayChoresCount: Int {
        childChores.count
    }
    
    private var completedTodayCount: Int {
        guard let child = currentChild else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        return choreService.getChoresForChild(child.id)
            .filter { chore in
                chore.isCompleted && 
                Calendar.current.isDate(chore.createdAt, inSameDayAs: today)
            }
            .count
    }
    
    private func completeChore(_ chore: Chore) {
        choreService.toggleChoreCompletion(chore)
        
        // Award points to child
        if let child = currentChild {
            authService.awardPointsToChild(childId: child.id, points: chore.points)
        }
    }
}

// MARK: - Child Chore Row
struct ChildChoreRow: View {
    let chore: Chore
    let onComplete: () -> Void
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        HStack(spacing: 16) {
            // Chore Icon
            Circle()
                .fill(themeColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundColor(themeColor)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(chore.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(chore.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(chore.points) pts")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(chore.dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Complete Button
            Button(action: onComplete) {
                Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(chore.isCompleted ? .green : themeColor)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Empty Chores View
struct EmptyChoresView: View {
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("All caught up!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("You've completed all your chores. Great job!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Child Stat Card
struct ChildStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                        .background(Color(.systemBackground))
                )
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Child Rewards View
struct ChildRewardsView: View {
    @ObservedObject var rewardService: RewardService
    @ObservedObject var authService: AuthService
    @Binding var showingRedemption: Bool
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Points Summary
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("\(currentChild?.points ?? 0)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Points Available")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                            .background(Color(.systemBackground))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Available Rewards
                VStack(spacing: 16) {
                    HStack {
                        Text("Available Rewards")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    if availableRewards.isEmpty {
                        EmptyRewardsView()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(availableRewards) { reward in
                                ChildRewardRow(
                                    reward: reward,
                                    canAfford: (currentChild?.points ?? 0) >= reward.points,
                                    onRedeem: {
                                        redeemReward(reward)
                                    },
                                    authService: authService
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var currentChild: Child? {
        authService.currentChild
    }
    
    private var availableRewards: [Reward] {
        rewardService.getAvailableRewards()
    }
    
    private func redeemReward(_ reward: Reward) {
        guard let child = currentChild else { return }
        
        if child.points >= reward.points {
            rewardService.purchaseReward(reward, for: child.id, authService: authService)
            showingRedemption = true
        }
    }
}

// MARK: - Child Reward Row
struct ChildRewardRow: View {
    let reward: Reward
    let canAfford: Bool
    let onRedeem: () -> Void
    @ObservedObject var authService: AuthService
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        HStack(spacing: 16) {
            // Reward Icon
            Circle()
                .fill(Color(hex: reward.category.color).opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: reward.category.icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: reward.category.color))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(reward.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(reward.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(reward.points) pts")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(reward.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: reward.category.color).opacity(0.1))
                        )
                }
            }
            
            Spacer()
            
            // Redeem Button
            Button(action: onRedeem) {
                Text(canAfford ? "Redeem" : "Need \(reward.points - (currentChild?.points ?? 0)) more")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(canAfford ? themeColor : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(!canAfford)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var currentChild: Child? {
        authService.currentChild
    }
}

// MARK: - Empty Rewards View
struct EmptyRewardsView: View {
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No rewards available")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Complete more chores to unlock rewards!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Child Progress View
struct ChildProgressView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Weekly Progress
                VStack(spacing: 16) {
                    HStack {
                        Text("This Week's Progress")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ChildProgressCard(
                            title: "Chores Done",
                            value: "\(weeklyCompletedCount)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        ChildProgressCard(
                            title: "Points Earned",
                            value: "\(weeklyPointsEarned)",
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        ChildProgressCard(
                            title: "Streak",
                            value: "\(currentStreak)",
                            icon: "flame.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 20)
                }
                
                // Recent Activity
                VStack(spacing: 16) {
                    HStack {
                        Text("Recent Activity")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    if recentActivity.isEmpty {
                        Text("No recent activity")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(recentActivity, id: \.id) { activity in
                                ChildActivityRow(activity: activity)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var weeklyCompletedCount: Int {
        guard let child = authService.currentChild else { return 0 }
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return choreService.getChoresForChild(child.id)
            .filter { chore in
                chore.isCompleted && 
                chore.createdAt >= weekStart
            }
            .count
    }
    
    private var weeklyPointsEarned: Int {
        guard let child = authService.currentChild else { return 0 }
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return choreService.getChoresForChild(child.id)
            .filter { chore in
                chore.isCompleted && 
                chore.createdAt >= weekStart
            }
            .reduce(0) { $0 + $1.points }
    }
    
    private var currentStreak: Int {
        // This would need to be calculated based on consecutive days with completed chores
        return 3 // Placeholder
    }
    
    private var recentActivity: [ActivityItem] {
        guard let child = authService.currentChild else { return [] }
        let chores = choreService.getChoresForChild(child.id)
            .filter { $0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)
        
        return chores.map { chore in
            ActivityItem(
                id: chore.id,
                title: "Completed: \(chore.title)",
                description: "Earned \(chore.points) points",
                date: chore.createdAt,
                type: .chore
            )
        }
    }
}

// MARK: - Child Progress Card
struct ChildProgressCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                        .background(Color(.systemBackground))
                )
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Activity Row
struct ChildActivityRow: View {
    let activity: ActivityItem
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(themeColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: activity.type.icon)
                        .font(.title3)
                        .foregroundColor(themeColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(activity.date, style: .relative)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Reward Redemption View
struct RewardRedemptionView: View {
    @ObservedObject var rewardService: RewardService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Success Animation
                VStack(spacing: 20) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 80))
                        .foregroundColor(themeColor)
                        .scaleEffect(1.2)
                    
                    Text("Reward Redeemed!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Congratulations! You've successfully redeemed your reward.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Action Button
                Button(action: { dismiss() }) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
} 