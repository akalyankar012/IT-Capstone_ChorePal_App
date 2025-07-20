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
        HStack(spacing: 2) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: { selectedRange = range }) {
                    Text(range.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedRange == range ? .white : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedRange == range ? Color(hex: "#a2cee3") : Color(.systemGray5))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
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
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                    .frame(width: 24, height: 24)
                Text("Family Overview")
                    .font(.title3)
                    .fontWeight(.bold)
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
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
        VStack(spacing: 16) {
            // Icon and trend row
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                        .frame(width: 16, height: 16)
                }
            }
            
            // Value and title
            VStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                            .background(Color(.systemBackground))
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Chore Performance Chart
struct ChorePerformanceChart: View {
    @ObservedObject var choreService: ChoreService
    let timeRange: TimeRange
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(themeColor)
                    .frame(width: 24, height: 24)
                Text("Chore Performance")
                    .font(.title3)
                    .fontWeight(.bold)
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
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                                    .background(Color(.systemBackground))
                            )
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(choreService.getTotalPoints())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                                    .background(Color(.systemBackground))
                            )
                        Text("Total Points")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(choreService.getCompletedPoints())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                                    .background(Color(.systemBackground))
                            )
                        Text("Earned")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
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
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: 44, height: 120)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(width: 44, height: max(8, 120 * percentage))
                    .animation(.easeInOut(duration: 0.3), value: percentage)
            }
            
            VStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("\(value)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                            .background(Color(.systemBackground))
                    )
            }
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
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                    .frame(width: 24, height: 24)
                Text("Child Performance")
                    .font(.title3)
                    .fontWeight(.bold)
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
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
            HStack(spacing: 16) {
                // Child Avatar
                Circle()
                    .fill(themeColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(child.name.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeColor)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(child.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .frame(width: 14, height: 14)
                            Text("\(child.points) pts")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .frame(width: 14, height: 14)
                            Text("\(completedChores) completed")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
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
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                    .frame(width: 24, height: 24)
                Text("Reward Statistics")
                    .font(.title3)
                    .fontWeight(.bold)
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
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
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                    .frame(width: 24, height: 24)
                Text("Recent Activity")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(recentActivities.prefix(5), id: \.id) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
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