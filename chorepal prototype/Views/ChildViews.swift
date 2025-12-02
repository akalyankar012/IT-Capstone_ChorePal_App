import SwiftUI
import Foundation

// NOTE: Sanitized Child UI – notification and camera features removed

struct ChildDashboardView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var choreService: ChoreService
    @ObservedObject var rewardService: RewardService
    @StateObject private var notificationService = NotificationService()
    @Binding var selectedRole: UserRole
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .light
    @State private var selectedTab = 0
    @State private var isAnimating = false
    @State private var showApprovalCelebration = false
    @State private var newlyApprovedChores: [Chore] = []

    private let themeColor = Color(hex: "#a2cee3")

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground(theme: selectedTheme).ignoresSafeArea()
                BackgroundChoresAnimation()
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    // Top header (avatar + points + theme toggle)
                    HStack {
                        AvatarView(avatarName: authService.currentChild?.avatar ?? "boy", size: 50, themeColor: themeColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(authService.currentChild?.name ?? "Child")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(selectedTheme == .light ? .primary : .white)
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption2)
                                Text("\(authService.currentChild?.points ?? 0) points")
                                    .font(.caption)
                                    .foregroundColor(selectedTheme == .light ? .black : Color.white.opacity(0.8))
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

                    // Tabs (Tasks, Rewards, Notifications, Calendar, Settings)
                    HStack(spacing: 6) {
                        childTabButton("Tasks", icon: "list.bullet", id: 0)
                        childTabButton("Rewards", icon: "gift", id: 1)
                        childTabButtonWithBadge("Alerts", icon: "bell.fill", id: 2, badgeCount: notificationService.unreadCount)
                        childTabButton("Calendar", icon: "calendar", id: 3)
                        childTabButton("Settings", icon: "gearshape", id: 4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedTheme == .light ? Color.white : Color.black.opacity(0.3))
                            .shadow(color: Color.black.opacity(selectedTheme == .light ? 0.08 : 0.3), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    // Content view based on selected tab (no swipe-through)
                    Group {
                        switch selectedTab {
                        case 0:
                            ChildChoresLiteView(choreService: choreService, authService: authService)
                        case 1:
                            ChildRewardsLiteView(rewardService: rewardService, authService: authService)
                        case 2:
                            if let childId = authService.currentChild?.id {
                                ChildNotificationsView(childId: childId)
                            } else {
                                Text("No child logged in")
                            }
                        case 3:
                            CalendarView(role: .child, chores: .constant(Chore.sampleChores), achievementManager: AchievementManager())
                        case 4:
                            ChildSettingsLiteView(selectedTheme: $selectedTheme, authService: authService, isAnimating: $isAnimating, selectedRole: $selectedRole)
                        default:
                            ChildChoresLiteView(choreService: choreService, authService: authService)
                        }
                    }
                    .id(selectedTab)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                checkForNewApprovals()
            }
        }
        .preferredColorScheme(selectedTheme == .light ? .light : .dark)
        .overlay(
            Group {
                if showApprovalCelebration {
                    ApprovalCelebrationModal(
                        approvedChores: newlyApprovedChores,
                        totalPoints: newlyApprovedChores.reduce(0) { $0 + $1.points },
                        isPresented: $showApprovalCelebration
                    )
                    .transition(.opacity)
                    .zIndex(999)
                }
            }
        )
    }
    
    private func checkForNewApprovals() {
        guard let childId = authService.currentChild?.id else {
            print("❌ No child logged in for celebration check")
            return
        }
        
        print("🎉 DEBUG: Starting celebration check for child: \(childId)")
        
        // Wait a bit for chores to load from Firestore
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("🎉 DEBUG: Total chores loaded: \(self.choreService.chores.count)")
            
            // Get list of previously celebrated chores
            let celebratedKey = "celebratedChores_\(childId.uuidString)"
            let celebratedIds = UserDefaults.standard.array(forKey: celebratedKey) as? [String] ?? []
            print("🎉 DEBUG: Previously celebrated chore IDs: \(celebratedIds.count)")
            
            // Find ALL chores for this child
            let childChores = self.choreService.chores.filter { $0.assignedToChildId == childId }
            print("🎉 DEBUG: Child's chores: \(childChores.count)")
            
            // Find chores that were approved BUT NOT YET CELEBRATED
            let newlyApprovedChores = childChores.filter { chore in
                let isApproved = chore.photoProofStatus == .approved
                let alreadyCelebrated = celebratedIds.contains(chore.id.uuidString)
                print("🎉 DEBUG: Chore '\(chore.title)' - status: \(String(describing: chore.photoProofStatus)), completed: \(chore.isCompleted), approved: \(isApproved), celebrated: \(alreadyCelebrated)")
                return isApproved && chore.isCompleted && !alreadyCelebrated
            }
            
            print("🎉 DEBUG: Found \(newlyApprovedChores.count) NEW approved chores (not yet celebrated)")
            
            // Show modal if there are NEW approved chores
            if !newlyApprovedChores.isEmpty {
                print("🎉 DEBUG: Showing celebration modal for \(newlyApprovedChores.count) chores!")
                self.newlyApprovedChores = newlyApprovedChores
                
                // Small delay for smooth appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        self.showApprovalCelebration = true
                    }
                }
                
                // Mark these chores as celebrated
                let newCelebratedIds = celebratedIds + newlyApprovedChores.map { $0.id.uuidString }
                UserDefaults.standard.set(newCelebratedIds, forKey: celebratedKey)
                print("🎉 DEBUG: Marked \(newlyApprovedChores.count) chores as celebrated. Total celebrated: \(newCelebratedIds.count)")
            } else {
                print("🎉 DEBUG: No new approved chores to celebrate")
            }
        }
    }

    private func childTabButton(_ title: String, icon: String, id: Int) -> some View {
        Button(action: {
            var transaction = Transaction(animation: nil)
            withTransaction(transaction) {
                selectedTab = id
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: selectedTab == id ? .semibold : .medium))
                    .foregroundColor(selectedTab == id ? themeColor : (selectedTheme == .light ? Color.black.opacity(0.7) : Color.white.opacity(0.7)))
                Text(title)
                    .font(.system(size: 10, weight: selectedTab == id ? .semibold : .medium))
                    .foregroundColor(selectedTab == id ? themeColor : (selectedTheme == .light ? Color.black.opacity(0.7) : Color.white.opacity(0.7)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                Capsule()
                    .fill(selectedTab == id ? themeColor.opacity(0.2) : Color.clear)
                    .shadow(color: selectedTab == id ? themeColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func childTabButtonWithBadge(_ title: String, icon: String, id: Int, badgeCount: Int) -> some View {
        Button(action: {
            var transaction = Transaction(animation: nil)
            withTransaction(transaction) {
                selectedTab = id
            }
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: selectedTab == id ? .semibold : .medium))
                        .foregroundColor(selectedTab == id ? themeColor : (selectedTheme == .light ? Color.black.opacity(0.7) : Color.white.opacity(0.7)))
                    
                    if badgeCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Text("\(badgeCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 10, y: -10)
                            .shadow(color: Color.red.opacity(0.5), radius: 3, x: 0, y: 2)
                    }
                }
                Text(title)
                    .font(.system(size: 10, weight: selectedTab == id ? .semibold : .medium))
                    .foregroundColor(selectedTab == id ? themeColor : (selectedTheme == .light ? Color.black.opacity(0.7) : Color.white.opacity(0.7)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                Capsule()
                    .fill(selectedTab == id ? themeColor.opacity(0.2) : Color.clear)
                    .shadow(color: selectedTab == id ? themeColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lite child views (no camera/notifications)

struct ChildChoresLiteView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @StateObject private var photoApprovalService = PhotoApprovalService()
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .light
    @State private var showCelebration = false
    @State private var showSuccessBanner = false
    @State private var completedChorePoints = 0
    @State private var selectedChoreForPhoto: Chore?
    private let themeColor = Color(hex: "#a2cee3")

    var body: some View {
        ZStack {
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
                                    .foregroundColor(selectedTheme == .light ? .black : Color.white.opacity(0.88))
                                    .lineLimit(2)
                                HStack(spacing: 10) {
                                    Label("\(chore.points) pts", systemImage: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(selectedTheme == .light ? .black : Color.white.opacity(0.82))
                                    Label(chore.dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                        .font(.caption)
                                        .foregroundColor(selectedTheme == .light ? .black : Color.white.opacity(0.82))
                                }
                            }
                            Spacer()
                            
                            // Show photo proof status button
                            choreActionButton(for: chore)
                        }
                        .padding(12)
                        .glassCard(isLightMode: selectedTheme == .light, themeColor: themeColor)
                    }
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            
            // Celebration overlay
            if showCelebration {
                CelebrationView(isShowing: $showCelebration)
            }
            
            // Success banner
            if showSuccessBanner {
                VStack {
                    SuccessBanner(
                        isShowing: $showSuccessBanner,
                        message: "Great Job!",
                        points: completedChorePoints
                    )
                    .padding(.top, 60)
                    Spacer()
                }
            }
        }
        .fullScreenCover(item: $selectedChoreForPhoto) { chore in
            if let childId = authService.currentChild?.id {
                PhotoCaptureFlow(
                    chore: chore,
                    childId: childId,
                    photoApprovalService: photoApprovalService,
                    choreService: choreService,
                    authService: authService
                )
            } else {
                Text("Error: No child logged in")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            // Load chores for the logged-in child when view appears
            if let childId = authService.currentChild?.id {
                print("📋 ChildChoresLiteView appeared - loading chores for child: \(childId)")
                choreService.loadChoresForLoggedInChild(childId)
            }
        }
    }

    private var childChores: [Chore] {
        guard let child = authService.currentChild else { return [] }
        return choreService.getChoresForChild(child.id)
    }
    
    @ViewBuilder
    private func choreActionButton(for chore: Chore) -> some View {
        let status = chore.photoProofStatus ?? .notSubmitted
        
        switch status {
        case .notSubmitted:
            // Show "Upload Photo" button
            Button(action: {
                selectedChoreForPhoto = chore
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.badge.arrow.down")
                        .font(.system(size: 14))
                    Text("Upload Photo")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeColor)
                .cornerRadius(20)
            }
            
        case .pending:
            // Show pending status
            HStack(spacing: 6) {
                Image(systemName: "hourglass")
                    .font(.system(size: 14))
                Text("Pending")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange)
            .cornerRadius(20)
            
        case .approved:
            // Show approved status
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14))
                Text("Approved")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.green)
            .cornerRadius(20)
            
        case .rejected:
            // Show rejected status with option to retake
            Button(action: {
                selectedChoreForPhoto = chore
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.seal.fill")
                        .font(.system(size: 14))
                    Text("Retake")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(20)
            }
        }
    }
}

struct ChildRewardsLiteView: View {
    @ObservedObject var rewardService: RewardService
    @ObservedObject var authService: AuthService
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .light
    @State private var selectedRewardTab = 0 // 0 = Available, 1 = My Rewards
    @State private var showingRedeemConfirm = false
    @State private var selectedReward: Reward?
    @State private var showingSuccessAlert = false
    @State private var alertMessage = ""
    
    private let themeColor = Color(hex: "#a2cee3")
    
    private var currentPoints: Int {
        authService.currentChild?.points ?? 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Points display at top
            HStack {
                Image(systemName: "star.fill").foregroundColor(.yellow).font(.title3)
                Text("\(currentPoints) Points Available")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(selectedTheme == .light ? .primary : .white)
            }
            .padding(.vertical, 12)
            
            // Tab selector
            HStack(spacing: 0) {
                rewardTabButton("Available", id: 0)
                rewardTabButton("My Rewards", id: 1)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Content
            ScrollView {
                VStack(spacing: 12) {
                    if selectedRewardTab == 0 {
                        // Available Rewards
                        ForEach(rewardService.getAvailableRewards()) { reward in
                            ChildRewardCard(
                                reward: reward,
                                currentPoints: currentPoints,
                                selectedTheme: selectedTheme,
                                themeColor: themeColor,
                                onRedeem: {
                                    selectedReward = reward
                                    showingRedeemConfirm = true
                                }
                            )
                        }
                    } else {
                        // My Rewards (redeemed)
                        let myRewards = rewardService.getRewardsForChild(authService.currentChild?.id ?? UUID())
                        if myRewards.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(themeColor.opacity(0.5))
                                Text("No rewards yet!")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedTheme == .light ? .black : Color.white.opacity(0.9))
                                Text("Complete chores to earn points and redeem rewards")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(selectedTheme == .light ? .black : Color.white.opacity(0.8))
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(myRewards) { reward in
                                RedeemedRewardCard(reward: reward, selectedTheme: selectedTheme, themeColor: themeColor)
                            }
                        }
                    }
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .alert("Redeem Reward?", isPresented: $showingRedeemConfirm, presenting: selectedReward) { reward in
            Button("Cancel", role: .cancel) { }
            Button("Redeem \(reward.points) pts") {
                redeemReward(reward)
            }
        } message: { reward in
            Text("Are you sure you want to redeem '\(reward.name)' for \(reward.points) points?")
        }
        .alert("Success!", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func rewardTabButton(_ title: String, id: Int) -> some View {
        Button(action: { withAnimation { selectedRewardTab = id } }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selectedRewardTab == id ? themeColor : (selectedTheme == .light ? Color.black : Color.white.opacity(0.9)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectedRewardTab == id ? themeColor.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func redeemReward(_ reward: Reward) {
        guard let child = authService.currentChild else { return }
        
        let success = rewardService.redeemReward(reward, byChild: child, authService: authService)
        
        if success {
            alertMessage = "🎉 You redeemed '\(reward.name)'! Enjoy your reward."
            showingSuccessAlert = true
        } else {
            alertMessage = "❌ Not enough points to redeem this reward."
            showingSuccessAlert = true
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


