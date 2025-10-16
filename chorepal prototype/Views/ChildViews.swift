import SwiftUI
import Foundation

// NOTE: Sanitized Child UI – notification and camera features removed

struct ChildDashboardView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var choreService: ChoreService
    @ObservedObject var rewardService: RewardService
    @Binding var selectedRole: UserRole
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .light
    @State private var selectedTab = 0
    @State private var isAnimating = false

    private let themeColor = Color(hex: "#a2cee3")

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground(theme: selectedTheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top header (avatar + points + theme toggle)
                    HStack {
                        AvatarView(avatarName: authService.currentChild?.name ?? "C", size: 50, themeColor: themeColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(authService.currentChild?.name ?? "Child")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(selectedTheme == .light ? .primary : .white)
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2)
                                Text("\(authService.currentChild?.points ?? 0) points")
                                    .font(.caption)
                                    .foregroundColor(selectedTheme == .light ? .gray : Color.white.opacity(0.8))
                            }
                        }
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedTheme = selectedTheme == .light ? .dark : .light
                                isAnimating.toggle()
                            }
                        }) {
                            Image(systemName: selectedTheme.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selectedTheme == .light ? themeColor : Color(hex: "#3b82f6"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                    // Tabs (Tasks, Rewards, Achievements, Calendar, Settings)
                    HStack(spacing: 4) {
                        childTabButton("Tasks", icon: "list.bullet", id: 0)
                        childTabButton("Rewards", icon: "gift", id: 1)
                        childTabButton("Stats", icon: "chart.bar", id: 2)
                        childTabButton("Calendar", icon: "calendar", id: 3)
                        childTabButton("Settings", icon: "gearshape", id: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                    TabView(selection: $selectedTab) {
                        // Reuse existing simplified Home/Calendar/Settings patterns where possible
                        ChildChoresLiteView(choreService: choreService, authService: authService)
                            .tag(0)
                        ChildRewardsLiteView(rewardService: rewardService, authService: authService)
                            .tag(1)
                        AchievementsView(achievementManager: AchievementManager())
                            .tag(2)
                        CalendarView(role: .child, chores: .constant(Chore.sampleChores), achievementManager: AchievementManager())
                            .tag(3)
                        ChildSettingsLiteView(selectedTheme: $selectedTheme, authService: authService, isAnimating: $isAnimating, selectedRole: $selectedRole)
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(selectedTheme == .light ? .light : .dark)
    }

    private func childTabButton(_ title: String, icon: String, id: Int) -> some View {
        Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selectedTab = id } }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedTab == id ? themeColor : (selectedTheme == .light ? Color.gray : Color.white.opacity(0.6)))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(selectedTab == id ? themeColor : (selectedTheme == .light ? Color.gray : Color.white.opacity(0.6)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(RoundedRectangle(cornerRadius: 10).fill(selectedTab == id ? themeColor.opacity(0.15) : Color.clear))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lite child views (no camera/notifications)

struct ChildChoresLiteView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .light
    private let themeColor = Color(hex: "#a2cee3")

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(childChores) { chore in
                    HStack(spacing: 12) {
                        Circle().fill(themeColor.opacity(0.3)).frame(width: 44, height: 44)
                            .overlay(Image(systemName: "checkmark.circle").foregroundColor(themeColor))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chore.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedTheme == .light ? .primary : .white)
                            Text(chore.description)
                                .font(.caption)
                                .foregroundColor(selectedTheme == .light ? .gray : Color.white.opacity(0.7))
                                .lineLimit(2)
                            HStack(spacing: 10) {
                                Label("\(chore.points) pts", systemImage: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(selectedTheme == .light ? .gray : Color.white.opacity(0.6))
                                Label(chore.dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(selectedTheme == .light ? .gray : Color.white.opacity(0.6))
                            }
                        }
                        Spacer()
                        Button(action: { choreService.toggleChoreCompletion(chore) }) {
                            Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3).foregroundColor(chore.isCompleted ? .green : themeColor)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemBackground).opacity(selectedTheme == .light ? 0.9 : 0.2))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    private var childChores: [Chore] {
        guard let child = authService.currentChild else { return [] }
        return choreService.getChoresForChild(child.id)
    }
}

struct ChildRewardsLiteView: View {
    @ObservedObject var rewardService: RewardService
    @ObservedObject var authService: AuthService
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .light
    private let themeColor = Color(hex: "#a2cee3")
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(rewardService.getAvailableRewards()) { reward in
                    HStack(spacing: 12) {
                        Image(systemName: reward.category.icon)
                            .foregroundColor(Color(hex: reward.category.color))
                            .frame(width: 40, height: 40)
                            .background(Color(hex: reward.category.color).opacity(0.2)).cornerRadius(8)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reward.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedTheme == .light ? .primary : .white)
                            if !reward.description.isEmpty {
                                Text(reward.description)
                                    .font(.caption)
                                    .foregroundColor(selectedTheme == .light ? .gray : Color.white.opacity(0.7))
                            }
                            Text("\(reward.points) pts")
                                .font(.caption)
                                .foregroundColor(themeColor)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.systemBackground).opacity(selectedTheme == .light ? 0.9 : 0.2))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}

struct ChildSettingsLiteView: View {
    @Binding var selectedTheme: AppTheme
    @ObservedObject var authService: AuthService
    @Binding var isAnimating: Bool
    @Binding var selectedRole: UserRole
    private let themeColor = Color(hex: "#a2cee3")
    var body: some View {
        List {
            Section("Appearance") {
                HStack {
                    Image(systemName: selectedTheme == .light ? "sun.max.fill" : "moon.fill")
                        .foregroundColor(selectedTheme == .light ? .yellow : themeColor)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    Toggle("Light Mode", isOn: Binding(
                        get: { selectedTheme == .light },
                        set: { newValue in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0.3)) {
                                selectedTheme = newValue ? .light : .dark
                                isAnimating.toggle()
                            }
                        }
                    ))
                }
                .listRowBackground(Color(.systemBackground).opacity(0.7))
            }
            Section {
                Button(action: {
                    authService.signOut(); selectedRole = .none
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(.red)
                        Text("Sign Out").foregroundColor(.red)
                    }
                }
                .listRowBackground(Color(.systemBackground).opacity(0.7))
            }
        }
        .scrollContentBackground(.hidden)
    }
}


