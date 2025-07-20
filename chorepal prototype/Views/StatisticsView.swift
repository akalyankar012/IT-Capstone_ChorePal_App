import SwiftUI
import Charts

// MARK: - Statistics View
struct StatisticsView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var rewardService: RewardService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedChild: Child?
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Selector
                    TimeRangeSelector(selectedRange: $selectedTimeRange)
                    
                    // Family Overview Stats
                    FamilyOverviewStats(
                        choreService: choreService,
                        rewardService: rewardService,
                        authService: authService
                    )
                    
                    // Chore Performance Chart
                    ChorePerformanceChart(
                        choreService: choreService,
                        timeRange: selectedTimeRange
                    )
                    
                    // Child Performance Comparison
                    ChildPerformanceComparison(
                        choreService: choreService,
                        authService: authService,
                        selectedChild: $selectedChild
                    )
                    
                    // Reward Statistics
                    RewardStatistics(
                        rewardService: rewardService,
                        authService: authService
                    )
                    
                    // Recent Activity
                    RecentActivitySection(
                        choreService: choreService,
                        rewardService: rewardService
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Family Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedChild) { child in
            ChildStatisticsView(
                child: child,
                choreService: choreService,
                rewardService: rewardService
            )
        }
    }
}

// MARK: - Time Range Selector
struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: { selectedRange = range }) {
                    Text(range.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedRange == range ? .white : .primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selectedRange == range ? Color(hex: "#a2cee3") : Color(.systemGray6))
                        .cornerRadius(0)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

// MARK: - Family Overview Stats
struct FamilyOverviewStats: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var rewardService: RewardService
    @ObservedObject var authService: AuthService
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                    .frame(width: 24, height: 24)
                Text("Family Overview")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticsCard(
                    title: "Total Children",
                    value: "\(authService.currentParent?.children.count ?? 0)",
                    icon: "person.2.fill",
                    color: .blue,
                    trend: nil
                )
                
                StatisticsCard(
                    title: "Total Points Earned",
                    value: "\(choreService.getCompletedPoints())",
                    icon: "star.fill",
                    color: .yellow,
                    trend: .up
                )
                
                StatisticsCard(
                    title: "Completion Rate",
                    value: "\(completionRate)%",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    trend: completionRate > 70 ? .up : .down
                )
                
                StatisticsCard(
                    title: "Rewards Redeemed",
                    value: "\(rewardService.getPurchasedRewardsCount())",
                    icon: "gift.fill",
                    color: .purple,
                    trend: nil
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var completionRate: Int {
        let total = choreService.getTotalChores()
        let completed = choreService.getCompletedChoresCount()
        return total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0
    }
}

// MARK: - Enhanced Stat Card
struct StatisticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                        .frame(width: 16, height: 16)
                }
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Chore Performance Chart
struct ChorePerformanceChart: View {
    @ObservedObject var choreService: ChoreService
    let timeRange: TimeRange
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(themeColor)
                    .frame(width: 24, height: 24)
                Text("Chore Performance")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Simple bar chart representation
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    ChartBar(
                        label: "Completed",
                        value: choreService.getCompletedChoresCount(),
                        total: choreService.getTotalChores(),
                        color: .green
                    )
                    
                    ChartBar(
                        label: "Active",
                        value: choreService.getActiveChoresCount(),
                        total: choreService.getTotalChores(),
                        color: .orange
                    )
                    
                    ChartBar(
                        label: "Overdue",
                        value: choreService.getOverdueChoresCount(),
                        total: choreService.getTotalChores(),
                        color: .red
                    )
                }
                
                // Summary stats
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(choreService.getCompletedChoresCount())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(choreService.getTotalPoints())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeColor)
                        Text("Total Points")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(choreService.getCompletedPoints())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        Text("Earned")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Chart Bar
struct ChartBar: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        total > 0 ? Double(value) / Double(total) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 100)
                    .cornerRadius(8)
                
                Rectangle()
                    .fill(color)
                    .frame(width: 40, height: max(4, 100 * percentage))
                    .cornerRadius(8)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text("\(value)")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Child Performance Comparison
struct ChildPerformanceComparison: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @Binding var selectedChild: Child?
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                    .frame(width: 24, height: 24)
                Text("Child Performance")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let children = authService.currentParent?.children, !children.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(children) { child in
                        ChildPerformanceRow(
                            child: child,
                            choreService: choreService
                        ) {
                            selectedChild = child
                        }
                    }
                }
            } else {
                Text("No children added yet")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Child Performance Row
struct ChildPerformanceRow: View {
    let child: Child
    @ObservedObject var choreService: ChoreService
    let onTap: () -> Void
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Child Avatar
                Circle()
                    .fill(themeColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(child.name.prefix(1)).uppercased())
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .frame(width: 12, height: 12)
                            Text("\(child.points) pts")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .frame(width: 12, height: 12)
                            Text("\(completedChores) completed")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var completedChores: Int {
        choreService.getChoresForChild(child.id).filter { $0.isCompleted }.count
    }
}

// MARK: - Reward Statistics
struct RewardStatistics: View {
    @ObservedObject var rewardService: RewardService
    @ObservedObject var authService: AuthService
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                    .frame(width: 24, height: 24)
                Text("Reward Statistics")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticsCard(
                    title: "Available Rewards",
                    value: "\(rewardService.getAvailableRewardsCount())",
                    icon: "gift",
                    color: .blue,
                    trend: nil
                )
                
                StatisticsCard(
                    title: "Total Redeemed",
                    value: "\(rewardService.getPurchasedRewardsCount())",
                    icon: "gift.fill",
                    color: .purple,
                    trend: nil
                )
                
                StatisticsCard(
                    title: "Points Spent",
                    value: "\(rewardService.getTotalPointsSpent())",
                    icon: "dollarsign.circle.fill",
                    color: .orange,
                    trend: nil
                )
                
                StatisticsCard(
                    title: "Avg. Reward Cost",
                    value: "\(averageRewardCost) pts",
                    icon: "chart.bar.fill",
                    color: .green,
                    trend: nil
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var averageRewardCost: Int {
        let purchasedRewards = rewardService.getPurchasedRewards()
        return purchasedRewards.isEmpty ? 0 : purchasedRewards.reduce(0) { $0 + $1.points } / purchasedRewards.count
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var rewardService: RewardService
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                    .frame(width: 24, height: 24)
                Text("Recent Activity")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(recentActivities.prefix(5), id: \.id) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var recentActivities: [ActivityItem] {
        var activities: [ActivityItem] = []
        
        // Add completed chores
        for chore in choreService.getCompletedChores() {
            activities.append(ActivityItem(
                id: UUID(),
                type: .choreCompleted,
                title: "\(chore.title) completed",
                subtitle: "+\(chore.points) points",
                timestamp: Date(),
                icon: "checkmark.circle.fill",
                color: .green
            ))
        }
        
        // Add purchased rewards
        for reward in rewardService.getPurchasedRewards() {
            activities.append(ActivityItem(
                id: UUID(),
                type: .rewardPurchased,
                title: "\(reward.name) purchased",
                subtitle: "-\(reward.points) points",
                timestamp: Date(),
                icon: "gift.fill",
                color: .purple
            ))
        }
        
        // Sort by timestamp and return recent ones
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(activity.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Types

enum TimeRange: CaseIterable {
    case week, month, quarter, year
    
    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
}

enum TrendDirection {
    case up, down
    
    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        }
    }
}

struct ActivityItem {
    let id: UUID
    let type: ActivityType
    let title: String
    let subtitle: String
    let timestamp: Date
    let icon: String
    let color: Color
}

enum ActivityType {
    case choreCompleted
    case rewardPurchased
}

// MARK: - Child Statistics View
struct ChildStatisticsView: View {
    let child: Child
    @ObservedObject var choreService: ChoreService
    @ObservedObject var rewardService: RewardService
    @Environment(\.dismiss) private var dismiss
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Child Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(themeColor.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(child.name.prefix(1)).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(themeColor)
                            )
                        
                        Text(child.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Child Stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatisticsCard(
                            title: "Current Points",
                            value: "\(child.points)",
                            icon: "star.fill",
                            color: .yellow,
                            trend: nil
                        )
                        
                        StatisticsCard(
                            title: "Chores Completed",
                            value: "\(completedChores)",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            trend: nil
                        )
                        
                        StatisticsCard(
                            title: "Active Chores",
                            value: "\(activeChores)",
                            icon: "clock.fill",
                            color: .orange,
                            trend: nil
                        )
                        
                        StatisticsCard(
                            title: "Rewards Redeemed",
                            value: "\(redeemedRewards)",
                            icon: "gift.fill",
                            color: .purple,
                            trend: nil
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Recent Chores
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                                .foregroundColor(themeColor)
                            Text("Recent Chores")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(childChores.prefix(5), id: \.id) { chore in
                                HStack {
                                    Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(chore.isCompleted ? .green : .gray)
                                    
                                    Text(chore.title)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(chore.points) pts")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(child.name)'s Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var childChores: [Chore] {
        choreService.getChoresForChild(child.id)
    }
    
    private var completedChores: Int {
        childChores.filter { $0.isCompleted }.count
    }
    
    private var activeChores: Int {
        childChores.filter { !$0.isCompleted }.count
    }
    
    private var redeemedRewards: Int {
        rewardService.getRewardsForChild(child.id).count
    }
} 