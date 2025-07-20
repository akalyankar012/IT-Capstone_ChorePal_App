import SwiftUI

// MARK: - Parent Dashboard View
struct ParentDashboardView: View {
    @ObservedObject var authService: AuthService
    @StateObject private var choreService = ChoreService()
    @StateObject private var rewardService = RewardService()
    @State private var showingAddChild = false
    @State private var selectedChild: Child?
    @State private var showingChildDetails = false
    @State private var selectedTab = 0
    @AppStorage("selectedTheme") private var selectedTheme: Theme = .light
    @State private var isAnimating = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back!")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("Family Dashboard")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(themeColor)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTheme = selectedTheme == .light ? .dark : .light
                                isAnimating.toggle()
                            }
                        }) {
                            Image(systemName: selectedTheme.systemName)
                                .font(.title2)
                                .foregroundColor(selectedTheme == .light ? .yellow : themeColor)
                                .padding()
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .padding(.bottom, 16)
                
                // Tab Selector
                HStack(spacing: 0) {
                    TabButton(
                        title: "Overview",
                        icon: "house",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "Calendar",
                        icon: "calendar",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    TabButton(
                        title: "Settings",
                        icon: "gearshape",
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    ParentOverviewView(
                        authService: authService,
                        choreService: choreService,
                        showingAddChild: $showingAddChild,
                        selectedChild: $selectedChild,
                        showingChildDetails: $showingChildDetails
                    )
                    .tag(0)
                    
                    ParentCalendarView(
                        choreService: choreService,
                        authService: authService
                    )
                    .tag(1)
                    
                    ParentSettingsView(
                        selectedTheme: $selectedTheme,
                        authService: authService,
                        isAnimating: $isAnimating
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .preferredColorScheme(selectedTheme == .light ? .light : .dark)
        .fullScreenCover(isPresented: $showingAddChild) {
            AddChildView(authService: authService)
        }
        .fullScreenCover(item: $selectedChild) { child in
                            ChildDetailsView(child: child, authService: authService, choreService: choreService)
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
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Child Row View
struct ChildRowView: View {
    let child: Child
    let onTap: () -> Void
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Child Avatar
                Circle()
                    .fill(themeColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(child.name.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("\(child.points) points")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "key.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("PIN: \(child.pin)")
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
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .fullScreenCover(isPresented: $showingChoreManagement) {
            ChoreManagementView(choreService: choreService, authService: authService)
        }
        .fullScreenCover(isPresented: $showingRewardManagement) {
            ManageRewardsView(rewardService: rewardService, authService: authService)
        }
        .fullScreenCover(isPresented: $showingStatistics) {
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
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Child View
struct AddChildView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var childName = ""
    @State private var generatedPIN = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
                    
                    Text("Create a new child account with a unique PIN")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Login PIN")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("PIN will be generated", text: .constant(generatedPIN.isEmpty ? "Click Generate" : generatedPIN))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(true)
                            
                            Button(action: generatePIN) {
                                Text("Generate")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(themeColor)
                                    .cornerRadius(8)
                            }
                        }
                    }
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
        .alert("Add Child", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            generatePIN()
        }
    }
    
    private var canAddChild: Bool {
        !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !generatedPIN.isEmpty
    }
    
    private func generatePIN() {
        generatedPIN = String(format: "%04d", Int.random(in: 1000...9999))
    }
    
    private func addChild() {
        guard let parent = authService.currentParent else {
            alertMessage = "Error: Parent not found"
            showingAlert = true
            return
        }
        
        let trimmedName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if PIN already exists
        let existingPINs = parent.children.map { $0.pin }
        if existingPINs.contains(generatedPIN) {
            alertMessage = "Error: PIN already exists. Please generate a new PIN."
            showingAlert = true
            generatePIN()
            return
        }
        
        // Create new child
        let newChild = Child(name: trimmedName, pin: generatedPIN, parentId: parent.id)
        
        // Add child to parent
        authService.addChild(newChild)
        
        alertMessage = "Child '\(trimmedName)' added successfully with PIN: \(generatedPIN)"
        showingAlert = true
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
                        Circle()
                            .fill(themeColor.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(child.name.prefix(1)).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(themeColor)
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
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Family Overview Card
                FamilyOverviewCard(authService: authService, choreService: choreService)
                
                // Children Management Section
                ChildrenManagementSection(
                    authService: authService,
                    showingAddChild: $showingAddChild,
                    selectedChild: $selectedChild,
                    showingChildDetails: $showingChildDetails
                )
                
                // Quick Actions Section
                QuickActionsSection(choreService: choreService, authService: authService)
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $showingAddChild) {
            AddChildView(authService: authService)
        }
        .fullScreenCover(item: $selectedChild) { child in
            ChildDetailsView(child: child, authService: authService, choreService: choreService)
        }
    }
}

// MARK: - Parent Calendar View
struct ParentCalendarView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
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
                            authService: authService
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
    @Binding var selectedTheme: Theme
    @ObservedObject var authService: AuthService
    @Binding var isAnimating: Bool
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Section
                VStack(spacing: 16) {
                    Circle()
                        .fill(themeColor.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(themeColor)
                        )
                    
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
                    // Appearance Section
                    VStack(spacing: 0) {
                        HStack {
                            Text("Appearance")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        
                        HStack {
                            Image(systemName: selectedTheme == .light ? "sun.max.fill" : "moon.fill")
                                .foregroundColor(selectedTheme == .light ? .yellow : themeColor)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            
                            Text("Light Mode")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { selectedTheme == .light },
                                set: { newValue in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0.3)) {
                                        selectedTheme = newValue ? .light : .dark
                                        isAnimating.toggle()
                                    }
                                }
                            ))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                    }
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Family Section
                    VStack(spacing: 0) {
                        HStack {
                            Text("Family")
                                .font(.headline)
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
                    
                    // Account Section
                    VStack(spacing: 0) {
                        HStack {
                            Text("Account")
                                .font(.headline)
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