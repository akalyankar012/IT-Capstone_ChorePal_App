import SwiftUI
import Foundation
import UIKit

// MARK: - Avatar View Component
struct AvatarView: View {
    let avatarName: String
    let size: CGFloat
    let themeColor: Color
    
    init(avatarName: String, size: CGFloat = 50, themeColor: Color = Color(hex: "#a2cee3")) {
        self.avatarName = avatarName
        self.size = size
        self.themeColor = themeColor
    }
    
    var body: some View {
        Group {
            if let avatar = ChildAvatar(rawValue: avatarName) {
                // Try to load any available images from the IT-Capstone asset names
                let candidateNames: [String] = {
                    switch avatar {
                    case .boy:
                        return [
                            "boy_avatar", "boy_avatar_1", "boy_avatar_2", "boy_avatar_3", "boy_avatar_4", "boy"
                        ]
                    case .girl:
                        return [
                            "girl_avatar", "girl_avatar_1", "girl_avatar_2", "girl_avatar_3", "girl_avatar_4", "girl"
                        ]
                    }
                }()
                let resolvedName = candidateNames.first(where: { UIImage(named: $0) != nil })
                
                if let resolvedName = resolvedName {
                    Image(resolvedName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(themeColor, lineWidth: 2)
                        )
                } else {
                    // Fallback to system icon
                    Image(systemName: avatar.fallbackIcon)
                        .font(.system(size: size * 0.6))
                        .foregroundColor(themeColor)
                        .frame(width: size, height: size)
                        .background(
                            Circle()
                                .fill(themeColor.opacity(0.2))
                        )
                }
            } else {
                // Default fallback
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size * 0.6))
                    .foregroundColor(themeColor)
                    .frame(width: size, height: size)
                    .background(
                        Circle()
                            .fill(themeColor.opacity(0.2))
                    )
            }
        }
    }
}

// MARK: - Parent Dashboard View
struct ParentDashboardView: View {
    @ObservedObject var authService: AuthService
    @StateObject private var choreService = ChoreService()
    @StateObject private var rewardService = RewardService()
    @StateObject private var localizationService = LocalizationService()
    @StateObject private var photoApprovalService = PhotoApprovalService()
    @State private var showingAddChild = false
    @State private var selectedChild: Child?
    @State private var showingChildDetails = false
    @State private var showingPhotoApprovals = false
    @State private var selectedTab = 0
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .light
    @State private var isAnimating = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fixed Welcome Section (above nav bar)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome back")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTheme == .light ? .gray : Color.white.opacity(0.7))
                        
                        Text("Family Dashboard")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(themeColor)
                    }
                    
                    Spacer()
                    
                    // Photo Approval Button
                    Button(action: {
                        showingPhotoApprovals = true
                    }) {
                        ZStack {
                            Image(systemName: "photo.badge.checkmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(themeColor)
                            
                            // Badge for pending photos
                            if !photoApprovalService.pendingPhotos.isEmpty {
                                Text("\(photoApprovalService.pendingPhotos.count)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 14, height: 14)
                                    .background(
                                        Circle()
                                            .fill(Color.red)
                                    )
                                    .offset(x: 7, y: -7)
                            }
                        }
                        .frame(width: 36, height: 36)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedTheme = selectedTheme == .light ? .dark : .light
                            isAnimating.toggle()
                        }
                    }) {
                        Image(systemName: selectedTheme.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(selectedTheme == .light ? Color(hex: "#a2cee3") : Color(hex: "#3b82f6"))
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Color(.systemBackground))
                
                // Fixed Navigation Bar (always visible)
                HStack(spacing: 0) {
                    TabButton(
                        title: localizationService.localizedString(for: "overview"),
                        icon: "house",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: localizationService.localizedString(for: "calendar"),
                        icon: "calendar",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    TabButton(
                        title: localizationService.localizedString(for: "settings"),
                        icon: "gearshape",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Color(.systemBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        ParentOverviewView(
                            authService: authService,
                            choreService: choreService,
                            showingAddChild: $showingAddChild,
                            selectedChild: $selectedChild,
                            showingChildDetails: $showingChildDetails,
                            showingPhotoApprovals: $showingPhotoApprovals,
                            photoApprovalService: photoApprovalService,
                            selectedTheme: $selectedTheme,
                            isAnimating: $isAnimating
                        )
                    case 1:
                        ParentCalendarView(
                            choreService: choreService,
                            authService: authService,
                            photoApprovalService: photoApprovalService,
                            showingPhotoApprovals: $showingPhotoApprovals,
                            selectedTheme: $selectedTheme,
                            isAnimating: $isAnimating
                        )
                    case 2:
                        ParentSettingsView(
                            selectedTheme: $selectedTheme,
                            authService: authService,
                            isAnimating: $isAnimating,
                            showingPhotoApprovals: $showingPhotoApprovals,
                            photoApprovalService: photoApprovalService
                        )
                    default:
                        ParentOverviewView(
                            authService: authService,
                            choreService: choreService,
                            showingAddChild: $showingAddChild,
                            selectedChild: $selectedChild,
                            showingChildDetails: $showingChildDetails,
                            showingPhotoApprovals: $showingPhotoApprovals,
                            photoApprovalService: photoApprovalService,
                            selectedTheme: $selectedTheme,
                            isAnimating: $isAnimating
                        )
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .navigationBarTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
        .preferredColorScheme(selectedTheme == .light ? .light : .dark)
        .fullScreenCover(isPresented: $showingAddChild) {
            AddChildView(authService: authService)
        }
        .fullScreenCover(item: $selectedChild) { child in
            ChildDetailsView(child: child, authService: authService, choreService: choreService)
        }
        .sheet(isPresented: $showingPhotoApprovals) {
            PhotoApprovalListView(
                photoApprovalService: photoApprovalService,
                choreService: choreService,
                authService: authService
            )
        }
        .onAppear {
            // Start listening for pending photos when parent dashboard appears
            if let parentId = authService.currentParent?.id {
                photoApprovalService.startListening(for: parentId)
            }
        }
        .onDisappear {
            // Stop listening when leaving dashboard
            photoApprovalService.stopListening()
        }
    }
}

// MARK: - Family Overview Card
struct FamilyOverviewCard: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var choreService: ChoreService
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                Text("Family Overview")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Children",
                    value: "\(authService.currentParent?.children.count ?? 0)",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Total Points",
                    value: "\(totalFamilyPoints)",
                    icon: "star.fill",
                    color: .yellow
                )
            }
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Active Chores",
                    value: "\(choreService.getActiveChoresCount())",
                    icon: "checklist",
                    color: .green
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(choreService.getCompletedChoresCount())",
                    icon: "checkmark.circle.fill",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var totalFamilyPoints: Int {
        authService.currentParent?.children.reduce(0) { $0 + $1.points } ?? 0
    }
    

}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.06), color.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Children Management Section
struct ChildrenManagementSection: View {
    @ObservedObject var authService: AuthService
    @Binding var showingAddChild: Bool
    @Binding var selectedChild: Child?
    @Binding var showingChildDetails: Bool
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                Text("Children")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                
                Button(action: { showingAddChild = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeColor)
                }
            }
            
            if let children = authService.currentParent?.children, !children.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(children) { child in
                        ChildRowView(child: child) {
                            selectedChild = child
                            showingChildDetails = true
                        }
                    }
                }
            } else {
                EmptyChildrenView()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Child Row View
struct ChildRowView: View {
    let child: Child
    let onTap: () -> Void
    
    @State private var isPressed = false
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Child Avatar
                AvatarView(
                    avatarName: child.avatar,
                    size: 56,
                    themeColor: themeColor
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(child.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 10) {
                        HStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.15))
                                    .frame(width: 20, height: 20)
                                
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                            }
                            Text("\(child.points)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("PIN: \(child.pin)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeColor)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(themeColor.opacity(0.2), lineWidth: 1.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Empty Children View
struct EmptyChildrenView: View {
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No children added yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Add your first child to get started with ChorePal!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @StateObject private var rewardService = RewardService()
    @State private var showingChoreManagement = false
    @State private var showingRewardManagement = false
    @State private var showingStatistics = false
    @State private var showingVoiceTaskCreation = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(themeColor)
                Text("Quick Actions")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Voice Task",
                    icon: "mic.fill",
                    color: themeColor
                ) {
                    showingVoiceTaskCreation = true
                }
                
                QuickActionCard(
                    title: "Manage Chores",
                    icon: "list.bullet",
                    color: .green
                ) {
                    showingChoreManagement = true
                }
                
                QuickActionCard(
                    title: "Manage Rewards",
                    icon: "gift.fill",
                    color: .purple
                ) {
                    showingRewardManagement = true
                }
                
                QuickActionCard(
                    title: "View Stats",
                    icon: "chart.bar.fill",
                    color: .orange
                ) {
                    showingStatistics = true
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .fullScreenCover(isPresented: $showingVoiceTaskCreation) {
            VoiceTaskCreationView(choreService: choreService, authService: authService)
        }
        .sheet(isPresented: $showingChoreManagement) {
            ChoreManagementView(choreService: choreService, authService: authService)
        }
        .sheet(isPresented: $showingRewardManagement) {
            ManageRewardsView(rewardService: rewardService, authService: authService)
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(
                choreService: choreService,
                rewardService: rewardService,
                authService: authService
            )
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.08), color.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Add Child View
struct AddChildView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var childName = ""
    @State private var selectedAvatar = ChildAvatar.boy
    @State private var showingSuccessModal = false
    @State private var generatedPin = ""
    @State private var createdChildName = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(themeColor)
                    
                    Text("Add New Child")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("A unique 4-digit PIN will be generated automatically")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Avatar Selection - Simple + Button Interface
                VStack(spacing: 16) {
                    Text("Choose Avatar")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 20) {
                        ForEach(ChildAvatar.allCases, id: \.self) { avatar in
                            Button(action: {
                                selectedAvatar = avatar
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        AvatarView(avatarName: avatar.rawValue, size: 80, themeColor: themeColor)
                                        
                                        // Selection indicator
                                        if selectedAvatar == avatar {
                                            Circle()
                                                .stroke(themeColor, lineWidth: 4)
                                                .frame(width: 88, height: 88)
                                        }
                                    }
                                    
                                    Text(avatar.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedAvatar == avatar ? themeColor : .gray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.bottom, 20)
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Child's Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter child's name", text: $childName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    // Info about automatic PIN generation
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(themeColor)
                            .font(.system(size: 16))
                        
                        Text("A unique 4-digit PIN will be generated and shown after creation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(themeColor.opacity(0.1))
                    .cornerRadius(8)
                    
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: addChild) {
                        Text("Add Child")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canAddChild ? themeColor : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!canAddChild)
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
        .overlay {
            if showingSuccessModal {
                ChildCreatedSuccessModal(
                    childName: createdChildName,
                    pin: generatedPin,
                    isPresented: $showingSuccessModal,
                    onDismiss: {
                        dismiss()
                    }
                )
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canAddChild: Bool {
        !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addChild() {
        let trimmedName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            let pin = await authService.addChild(name: trimmedName, avatar: selectedAvatar.rawValue)
            
            if !pin.isEmpty {
                createdChildName = trimmedName
                generatedPin = pin
                childName = ""
                selectedAvatar = .boy // Reset to default
                showingSuccessModal = true
            } else {
                errorMessage = authService.errorMessage ?? "Failed to add child"
                showingErrorAlert = true
            }
        }
    }
}

// MARK: - Child Details View
struct ChildDetailsView: View {
    let child: Child
    @ObservedObject var authService: AuthService
    @ObservedObject var choreService: ChoreService
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Child Avatar and Info
                    VStack(spacing: 16) {
                        AvatarView(
                            avatarName: child.avatar,
                            size: 100,
                            themeColor: themeColor
                        )
                        
                        VStack(spacing: 8) {
                            Text(child.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Member since \(child.createdAt, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Current Points",
                            value: "\(child.points)",
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        StatCard(
                            title: "Active Chores",
                            value: "\(activeChoresCount)",
                            icon: "checklist",
                            color: .green
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // PIN Information
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(themeColor)
                            Text("Login PIN")
                                .font(.headline)
                            Spacer()
                        }
                        
                        HStack {
                            Text(child.pin)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(themeColor)
                            
                            Spacer()
                            
                            Button(action: copyPIN) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(themeColor)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: { /* Will implement edit functionality */ }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Child")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeColor)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showingDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove Child")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Child Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Remove Child", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removeChild()
            }
        } message: {
            Text("Are you sure you want to remove \(child.name)? This action cannot be undone.")
        }
    }
    
    private func copyPIN() {
        UIPasteboard.general.string = child.pin
        // You could add a toast notification here
    }
    
    private func removeChild() {
        authService.removeChild(child)
        dismiss()
    }
    
    private var activeChoresCount: Int {
        return choreService.getChoresForChild(child.id).filter { !$0.isCompleted }.count
    }
} 


// MARK: - Parent Overview View
struct ParentOverviewView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var choreService: ChoreService
    @Binding var showingAddChild: Bool
    @Binding var selectedChild: Child?
    @Binding var showingChildDetails: Bool
    @Binding var showingPhotoApprovals: Bool
    @ObservedObject var photoApprovalService: PhotoApprovalService
    @Binding var selectedTheme: AppTheme
    @Binding var isAnimating: Bool
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Actions Section
                QuickActionsSection(choreService: choreService, authService: authService)
                    .padding(.top, 12)
                
                // Family Overview Card
                FamilyOverviewCard(authService: authService, choreService: choreService)
                
                // Children Management Section (moved to bottom)
                ChildrenManagementSection(
                    authService: authService,
                    showingAddChild: $showingAddChild,
                    selectedChild: $selectedChild,
                    showingChildDetails: $showingChildDetails
                )
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .refreshable {
            // Simple refresh with animation
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        }
    }
    
}

// MARK: - Parent Calendar View
struct ParentCalendarView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @ObservedObject var photoApprovalService: PhotoApprovalService
    @Binding var showingPhotoApprovals: Bool
    @Binding var selectedTheme: AppTheme
    @Binding var isAnimating: Bool
    @State private var selectedChore: Chore?
    @State private var currentMonth = Date()
    
    private let themeColor = Color(hex: "#a2cee3")
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, equalTo: date2, toGranularity: .day)
    }
    
    private func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, equalTo: date2, toGranularity: .month)
    }
    
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday = 1
        return calendar
    }
    
    private var currentMonthComponents: DateComponents {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        return components
    }
    
    private var firstDayOfMonth: Date {
        calendar.date(from: currentMonthComponents)!
    }
    
    private var lastDayOfMonth: Date {
        calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth)!
    }
    
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: currentMonth)!.count
    }
    
    private var firstWeekdayOfMonth: Int {
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        return weekday
    }
    
    private var numberOfWeeks: Int {
        let firstWeekday = firstWeekdayOfMonth - 1
        let totalDays = firstWeekday + daysInMonth
        return Int(ceil(Double(totalDays) / 7.0))
    }
    
    private func dateFor(day: Int) -> Date {
        var components = currentMonthComponents
        components.day = day
        return calendar.date(from: components) ?? Date()
    }
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Calendar header
                HStack {
                    Button(action: {
                        withAnimation {
                            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(themeColor)
                    }
                    
                    Spacer()
                    
                    Text(monthString)
                        .font(.system(size: 24, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(themeColor)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Calendar grid
                VStack(spacing: 24) {
                    // Days of week header
                    HStack(spacing: 0) {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Calendar days
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 12) {
                        ForEach(0..<(numberOfWeeks * 7), id: \.self) { index in
                            let weekday = index % 7
                            let weekNumber = index / 7
                            let day = (weekNumber * 7 + weekday + 1) - (firstWeekdayOfMonth - 1)
                            
                            if day > 0 && day <= daysInMonth {
                                let date = dateFor(day: day)
                                let isSelectedDate = selectedChore.map { isSameDay(date, $0.dueDate) } ?? false
                                let hasChoresDueToday = familyChores.contains { isSameDay(date, $0.dueDate) }
                                
                                Text("\(day)")
                                    .font(.system(size: 16))
                                    .frame(height: 36)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Circle()
                                            .fill(isSelectedDate ? themeColor : (hasChoresDueToday ? themeColor.opacity(0.2) : Color.clear))
                                            .frame(width: 36, height: 36)
                                    )
                                    .foregroundColor(isSelectedDate ? .white : .primary)
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Divider with proper spacing
                Divider()
                    .padding(.vertical, 24)
                
                // Chores List
                VStack(spacing: 0) {
                    ForEach(familyChores.indices, id: \.self) { index in
                        ParentChoreRow(
                            chore: familyChores[index],
                            choreService: choreService,
                            authService: authService,
                            photoApprovalService: photoApprovalService
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedChore?.id == familyChores[index].id {
                                    selectedChore = nil // Deselect if tapping the same chore
                                } else {
                                    selectedChore = familyChores[index]
                                    // Navigate to the month of the selected chore
                                    if !isSameMonth(currentMonth, familyChores[index].dueDate) {
                                        currentMonth = familyChores[index].dueDate
                                    }
                                }
                            }
                        }
                        .background(selectedChore?.id == familyChores[index].id ? themeColor.opacity(0.1) : Color.clear)
                        
                        if index < familyChores.count - 1 {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var familyChores: [Chore] {
        let childrenIds = authService.currentParent?.children.map { $0.id } ?? []
        return choreService.getChoresForParent(childrenIds: childrenIds)
    }
}

// MARK: - Parent Settings View
struct ParentSettingsView: View {
    @Binding var selectedTheme: AppTheme
    @ObservedObject var authService: AuthService
    @Binding var isAnimating: Bool
    @Binding var showingPhotoApprovals: Bool
    @ObservedObject var photoApprovalService: PhotoApprovalService
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Section
                VStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeColor)
                    
                    Text("Family Account")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Manage your family settings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Settings List
                VStack(spacing: 0) {

                    // Language Section
                    VStack(spacing: 0) {
                        HStack {
                            Text("Language")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        
                        Button(action: {
                            // Language picker removed
                        }) {
                            HStack {
                                Text("🇺🇸")
                                    .font(.title2)
                                
                                Text("English")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(.systemBackground))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    // Family Section
                    VStack(spacing: 0) {
                        HStack {
                            Text("Family")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(themeColor)
                            Text("\(authService.currentParent?.children.count ?? 0) Children")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                    }
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    
                    // Account Section
                    VStack(spacing: 0) {
                        HStack {
                            Text("Account")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        
                        Button(action: {
                            authService.signOut()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                    }
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Parent Chore Row
struct ParentChoreRow: View {
    let chore: Chore
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @ObservedObject var photoApprovalService: PhotoApprovalService
    @State private var showingPhotoDetail = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        HStack(spacing: 16) {
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
                    
                    if let assignedChildId = chore.assignedToChildId,
                       let child = authService.currentParent?.children.first(where: { $0.id == assignedChildId }) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(themeColor)
                            Text(child.name)
                                .font(.caption)
                                .foregroundColor(themeColor)
                        }
                    }
                }
                
                // Photo Status Section
                if let assignedChildId = chore.assignedToChildId,
                   let parentId = authService.currentParent?.id {
                    PhotoStatusSection(
                        chore: chore,
                        childId: assignedChildId,
                        parentId: parentId,
                        photoApprovalService: photoApprovalService,
                        showingPhotoDetail: $showingPhotoDetail
                    )
                }
            }
            
            Spacer()
            
            // Status indicator
            Button(action: {
                choreService.toggleChoreCompletion(chore)
            }) {
                Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(chore.isCompleted ? .green : themeColor)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingPhotoDetail) {
            // Photo approval detail disabled in this build
            EmptyView()
        }
    }
} 

// MARK: - Photo Status Section
struct PhotoStatusSection: View {
    let chore: Chore
    let childId: UUID
    let parentId: UUID
    @ObservedObject var photoApprovalService: PhotoApprovalService
    @Binding var showingPhotoDetail: Bool
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        // Temporary: Photo approval functionality will be accessed through dedicated views
        let pendingPhoto: ChorePhoto? = nil
        let approvedPhoto: ChorePhoto? = nil
        let rejectedPhoto: ChorePhoto? = nil
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.caption)
                    .foregroundColor(themeColor)
                Text("Photo Status")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if let pendingPhoto = pendingPhoto {
                // Pending Photo - Show approve/reject buttons
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("Photo uploaded - needs approval")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            Task {
                                _ = await photoApprovalService.approvePhoto(pendingPhoto, approvedBy: parentId)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                Text("Approve")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(6)
                        }
                        
                        Button(action: {
                            Task {
                                _ = await photoApprovalService.rejectPhoto(pendingPhoto, rejectedBy: parentId, feedback: "Needs improvement")
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                Text("Reject")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(6)
                        }
                        
                        Button(action: {
                            showingPhotoDetail = true
                        }) {
                            Image(systemName: "eye.fill")
                                .font(.caption2)
                                .foregroundColor(themeColor)
                                .padding(4)
                                .background(themeColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            } else if let approvedPhoto = approvedPhoto {
                // Approved Photo
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("Photo approved")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button(action: {
                        showingPhotoDetail = true
                    }) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(themeColor)
                            .padding(4)
                            .background(themeColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            } else if let rejectedPhoto = rejectedPhoto {
                // Rejected Photo
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("Photo rejected")
                        .font(.caption2)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button(action: {
                        showingPhotoDetail = true
                    }) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(themeColor)
                            .padding(4)
                            .background(themeColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            } else {
                // No photo uploaded
                HStack(spacing: 6) {
                    Image(systemName: "camera")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("No photo uploaded")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.top, 4)
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
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isSelected ? .white : (Color.primary.opacity(0.7)))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .white : (Color.primary.opacity(0.7)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? themeColor : Color.clear)
                    .shadow(color: isSelected ? themeColor.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Child Created Success Modal
struct ChildCreatedSuccessModal: View {
    let childName: String
    let pin: String
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var animateCheckmark = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            // Modal content
            VStack(spacing: 0) {
                // Success icon with animation
                ZStack {
                    Circle()
                        .fill(themeColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeColor)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                        .opacity(animateCheckmark ? 1.0 : 0.0)
                }
                .padding(.top, 32)
                .padding(.bottom, 20)
                
                // Title
                Text("Child Added Successfully!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 10)
                
                // Child name
                Text(childName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeColor)
                    .padding(.bottom, 24)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 10)
                
                // PIN section
                VStack(spacing: 12) {
                    Text("Login PIN")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    // PIN display with copy button
                    HStack(spacing: 16) {
                        Text(pin)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(themeColor)
                            .tracking(8)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeColor.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(themeColor.opacity(0.3), lineWidth: 2)
                                    )
                            )
                        
                        Button(action: copyPIN) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(themeColor)
                                .padding(12)
                                .background(themeColor.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    
                    Text("Save this PIN - it's needed for login")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 10)
                
                // Action button
                Button(action: dismissModal) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
            }
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(showContent ? 1.0 : 0.9)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animateCheckmark = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showContent = true
            }
        }
    }
    
    private func dismissModal() {
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = false
            animateCheckmark = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            onDismiss()
        }
    }
    
    private func copyPIN() {
        UIPasteboard.general.string = pin
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
