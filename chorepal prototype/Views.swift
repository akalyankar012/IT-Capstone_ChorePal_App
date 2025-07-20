import SwiftUI 

// MARK: - Theme Manager
enum Theme: String {
    case light, dark
    
    var systemName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - Main View
struct ContentView: View {
    @State private var selectedRole: UserRole = .none
    @State private var selectedTab = 1  // Default to tasks tab
    @AppStorage("selectedTheme") private var selectedTheme: Theme = .light
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var authService = AuthService()
    @StateObject private var choreService = ChoreService()
    @StateObject private var rewardService = RewardService()
    @State private var chores = Chore.sampleChores
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Authentication Flow
                if authService.authState != .authenticated {
                    authenticationView
                } else if selectedRole == .none {
                    RoleSelectionView(selectedRole: $selectedRole, selectedTheme: $selectedTheme, authService: authService)
                } else if selectedRole == .parent && authService.authState == .authenticated {
                    // Show Parent Dashboard for authenticated parents
                    ParentDashboardView(authService: authService)
                } else if selectedRole == .child && authService.authState == .authenticated {
                    // Show Child Dashboard for authenticated children
                    ChildDashboardView(
                        authService: authService,
                        choreService: choreService,
                        rewardService: rewardService
                    )
                } else {
                    TabView(selection: $selectedTab) {
                        NavigationView {
                            CalendarView(role: selectedRole, chores: $chores, achievementManager: achievementManager)
                        }
                        .tag(0)
                        
                        NavigationView {
                            HomeView(role: selectedRole, chores: $chores, achievementManager: achievementManager, choreService: choreService, authService: authService)
                        }
                        .tag(1)
                        
                        NavigationView {
                            SettingsView(role: selectedRole, selectedTheme: $selectedTheme, selectedRole: $selectedRole, selectedTab: $selectedTab, authService: authService)
                        }
                        .tag(2)
                    }
                    .overlay(alignment: .bottom) {
                        // Custom Tab Bar
                        HStack(spacing: 0) {
                            let tabs = [
                                (id: 0, icon: "calendar", title: "Calendar"),
                                (id: 1, icon: "house", title: "Home"),
                                (id: 2, icon: "gearshape", title: "Settings")
                            ]
                            
                            ForEach(tabs, id: \.id) { tab in
                                Button(action: {
                                    selectedTab = tab.id
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: tab.icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(selectedTab == tab.id ? .black : .gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color(.systemGray6))
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    }
                }
            }
            .onChange(of: selectedRole) { newRole in
                if newRole != .none {
                    selectedTab = 1  // Reset to tasks tab when role changes
                }
            }
        }
        .preferredColorScheme(selectedTheme == .light ? .light : .dark)
    }
    
    @ViewBuilder
    private var authenticationView: some View {
        if selectedRole == .child && authService.authState == .none {
            // Show child login directly
            ChildLoginView(authService: authService, selectedRole: $selectedRole)
        } else {
            switch authService.authState {
            case .none:
                // Show role selection first, then auth
                RoleSelectionView(selectedRole: $selectedRole, selectedTheme: $selectedTheme, authService: authService)
            case .signUp:
                ParentSignUpView(authService: authService)
            case .verifyPhone:
                PhoneVerificationView(authService: authService)
            case .signIn:
                ParentSignInView(authService: authService)
            case .authenticated:
                // This should not happen here, but just in case
                RoleSelectionView(selectedRole: $selectedRole, selectedTheme: $selectedTheme, authService: authService)
            }
        }
    }
}

// MARK: - Role Selection View
struct RoleSelectionView: View {
    @Binding var selectedRole: UserRole
    @Binding var selectedTheme: Theme
    @ObservedObject var authService: AuthService
    @State private var isAnimating = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
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
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
            
            // App Logo/Mascot
            Image("potato")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
                .cornerRadius(40)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.bottom, 40)
            
            VStack(spacing: 16) {
                Text("Welcome to ChorePal!")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(themeColor)
                    .multilineTextAlignment(.center)
                
                Text("Who are you today?")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            .padding(.bottom, 40)
            
            VStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        selectedRole = .parent
                        authService.authState = .signUp
                    }
                }) {
                    HStack {
                        Image(systemName: "person.2")
                            .font(.title2)
                        Text("I'm a Grown-up")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(themeColor.opacity(0.2))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation {
                        selectedRole = .child
                        // For child, go directly to PIN login
                        authService.authState = .none // Reset to show child login
                    }
                }) {
                    HStack {
                        Image(systemName: "person")
                            .font(.title2)
                        Text("I'm a Kid")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(themeColor.opacity(0.2))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Sign In option for parents - moved below both buttons
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Button("Sign In") {
                        withAnimation {
                            selectedRole = .parent
                            authService.authState = .signIn
                        }
                    }
                    .foregroundColor(themeColor)
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}

// Add Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Update all views to use the theme color
extension View {
    func themeColor() -> Color {
        Color(hex: "#a2cee3")
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    let role: UserRole
    @Binding var chores: [Chore]
    @ObservedObject var achievementManager: AchievementManager
    private let themeColor = Color(hex: "#a2cee3")
    @State private var selectedChore: Chore?
    @State private var currentMonth = Date()
    
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
        VStack(spacing: 0) {
            // Points display at top
            if role == .child {
                NavigationLink(destination: AchievementsView(achievementManager: achievementManager)) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(achievementManager.currentPoints) Points")
                            .foregroundColor(.primary)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                }
                .padding(.top, 16)
            }
            
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
            .padding(.horizontal)
            .padding(.top, role == .child ? 20 : 36)
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
                
                // Calendar days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 12) {
                    ForEach(0..<(numberOfWeeks * 7), id: \.self) { index in
                        let weekday = index % 7
                        let weekNumber = index / 7
                        let day = (weekNumber * 7 + weekday + 1) - (firstWeekdayOfMonth - 1)
                        
                        if day > 0 && day <= daysInMonth {
                            let date = dateFor(day: day)
                            let isSelectedDate = selectedChore.map { isSameDay(date, $0.dueDate) } ?? false
                            let hasChoresDueToday = chores.contains { isSameDay(date, $0.dueDate) }
                            
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
            }
            .padding(.horizontal, 16)
            
            // Divider with proper spacing
            Divider()
                .padding(.vertical, 24)
            
            // Chores List
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(chores.indices, id: \.self) { index in
                        ChoreRowView(chore: chores[index], onToggleComplete: { completed in
                            chores[index].isCompleted = completed
                            if completed {
                                achievementManager.addCompletedChore(chores[index])
                            } else {
                                achievementManager.removeCompletedChore(chores[index])
                            }
                        })
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedChore?.id == chores[index].id {
                                    selectedChore = nil // Deselect if tapping the same chore
                                } else {
                                    selectedChore = chores[index]
                                    // Navigate to the month of the selected chore
                                    if !isSameMonth(currentMonth, chores[index].dueDate) {
                                        currentMonth = chores[index].dueDate
                                    }
                                }
                            }
                        }
                        .background(selectedChore?.id == chores[index].id ? themeColor.opacity(0.1) : Color.clear)
                        
                        if index < chores.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .navigationTitle(role == .parent ? "Manage Chores" : "View Chores")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Home View
struct HomeView: View {
    let role: UserRole
    @Binding var chores: [Chore]
    @ObservedObject var achievementManager: AchievementManager
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @State private var showingAddChore = false
    @State private var selectedChore: Chore?
    
    var body: some View {
        VStack(spacing: 0) {
            // Points Summary Card
            NavigationLink(
                destination: role == .parent ? 
                    AnyView(ParentPointsView(achievementManager: achievementManager)) :
                    AnyView(AchievementsView(achievementManager: achievementManager))
            ) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("\(achievementManager.currentPoints)")
                            .font(.system(size: 32, weight: .bold))
                        Text("Points")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    
                    Text(role == .parent ? "Tap to manage points" : "Tap to view achievements")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
                .padding(.top, 16)
            }
            
            // Chores List
            List {
                ForEach(choreService.chores) { chore in
                    ChoreRowView(chore: chore, onToggleComplete: { completed in
                        var updatedChore = chore
                        updatedChore.isCompleted = completed
                        choreService.updateChore(updatedChore)
                        if completed {
                            achievementManager.addCompletedChore(updatedChore)
                        } else {
                            achievementManager.removeCompletedChore(updatedChore)
                        }
                    })
                    .swipeActions(edge: .trailing) {
                        if role == .parent {
                            Button(role: .destructive) {
                                if !chore.isCompleted {
                                    achievementManager.removeCompletedChore(chore)
                                }
                                choreService.deleteChore(chore)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                selectedChore = chore
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(themeColor())
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(role == .parent ? "Manage Chores" : "My Chores")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if role == .parent {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddChore = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(themeColor())
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingAddChore) {
            AddChoreView(choreService: choreService, authService: authService)
        }
        .fullScreenCover(item: $selectedChore) { chore in
            EditChoreView(chore: chore, choreService: choreService, authService: authService)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    let role: UserRole
    @Binding var selectedTheme: Theme
    @Binding var selectedRole: UserRole
    @Binding var selectedTab: Int
    @ObservedObject var authService: AuthService
    @State private var isAnimating = false
    
    var body: some View {
        List {
            Section("Appearance") {
                HStack {
                    Image(systemName: selectedTheme == .light ? "sun.max.fill" : "moon.fill")
                        .foregroundColor(selectedTheme == .light ? .yellow : themeColor())
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
            }
            
            Section {
                Button(action: {
                    selectedTab = 1  // Set to tasks tab first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedRole = .none  // Then change role
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.left.circle.fill")
                            .foregroundColor(.red)
                        Text("Change Role")
                            .foregroundColor(.red)
                    }
                }
            }
            
            Section {
                Button(action: {
                    authService.signOut()
                    selectedRole = .none
                    selectedTab = 1
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Supporting Views
struct ChoreRowView: View {
    let chore: Chore
    let onToggleComplete: (Bool) -> Void
    @State private var isCompleted: Bool
    private let themeColor = Color(hex: "#a2cee3")
    
    init(chore: Chore, onToggleComplete: @escaping (Bool) -> Void) {
        self.chore = chore
        self.onToggleComplete = onToggleComplete
        _isCompleted = State(initialValue: chore.isCompleted)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(chore.title)
                    .font(.system(size: 17, weight: .semibold))
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .gray : .primary)
                
                Text(chore.description)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("Due: \(chore.dueDate, style: .date)")
                    Text("•")
                    Text("Created: \(chore.createdAt, style: .date)")
                }
                .font(.system(size: 12))
                .foregroundColor(Color(.systemGray2))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Button(action: {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isCompleted.toggle()
                        onToggleComplete(isCompleted)
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(isCompleted ? Color.clear : Color(.systemGray4), lineWidth: 1.5)
                            .background(
                                Circle()
                                    .fill(isCompleted ? themeColor : Color.clear)
                            )
                            .frame(width: 24, height: 24)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Text("\(chore.points) pts")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Text(chore.isRequired ? "Required" : "Elective")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray2))
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .opacity(isCompleted ? 0.8 : 1.0)
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @ObservedObject var achievementManager: AchievementManager
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack {
            Text("My Achievements")
                .font(.system(size: 32, weight: .bold))
                .padding(.top, 40)
            
            Spacer()
            
            // Stats Grid
            VStack(spacing: 50) {
                HStack(spacing: 60) {
                    // Chores Completed
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(themeColor)
                        Text("\(achievementManager.choresCompleted)")
                            .font(.system(size: 36, weight: .bold))
                        Text("Chores\nCompleted")
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Lifetime Points
                    VStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 44))
                            .foregroundColor(themeColor)
                        Text("\(achievementManager.lifetimePoints)")
                            .font(.system(size: 36, weight: .bold))
                        Text("Lifetime\nPoints")
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                    }
                }
                
                HStack(spacing: 60) {
                    // Current Points
                    VStack(spacing: 12) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(themeColor)
                        Text("\(achievementManager.currentPoints)")
                            .font(.system(size: 36, weight: .bold))
                        Text("Current\nPoints")
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Points Spent
                    VStack(spacing: 12) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 44))
                            .foregroundColor(themeColor)
                        Text("\(achievementManager.pointsSpent)")
                            .font(.system(size: 36, weight: .bold))
                        Text("Points\nSpent")
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Keep up the great work!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeColor)
                
                Text("Every chore completed brings you closer to your rewards!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("My Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}



// MARK: - Parent Points View
struct ParentPointsView: View {
    @ObservedObject var achievementManager: AchievementManager
    @State private var showingDeductPoints = false
    @State private var deductionName = ""
    @State private var deductionPoints = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Points Summary
                VStack(spacing: 8) {
                    Text("\(achievementManager.currentPoints)")
                        .font(.system(size: 48, weight: .bold))
                    Text("Available Points")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 2)
                .padding(.horizontal)
                
                // Deduct Points Button
                Button(action: { showingDeductPoints = true }) {
                    HStack {
                        Image(systemName: "minus.circle.fill")
                        Text("Deduct Points")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Reward History
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reward History")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if achievementManager.rewardHistory.isEmpty {
                        Text("No rewards redeemed yet")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(achievementManager.rewardHistory.sorted(by: { $0.purchasedAt > $1.purchasedAt })) { reward in
                            VStack(spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(reward.name)
                                            .font(.headline)
                                        Text(reward.purchasedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("-\(reward.points) pts")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                }
                                Divider()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Points Management")
        .sheet(isPresented: $showingDeductPoints) {
            NavigationView {
                Form {
                    Section("Deduct Points") {
                        TextField("Reward Name", text: $deductionName)
                        TextField("Points to Deduct", text: $deductionPoints)
                            .keyboardType(.numberPad)
                    }
                }
                .navigationTitle("Deduct Points")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingDeductPoints = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Deduct") {
                            guard let points = Int(deductionPoints),
                                  points > 0 else {
                                alertMessage = "Please enter a valid number of points"
                                showingAlert = true
                                return
                            }
                            
                            guard points <= achievementManager.currentPoints else {
                                alertMessage = "Not enough points available"
                                showingAlert = true
                                return
                            }
                            
                            achievementManager.deductPoints(name: deductionName, points: points)
                            showingDeductPoints = false
                            deductionName = ""
                            deductionPoints = ""
                        }
                        .disabled(deductionName.isEmpty || deductionPoints.isEmpty)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDisplayName("Full App")
            
            RoleSelectionView(
                selectedRole: .constant(.none), 
                selectedTheme: .constant(.light),
                authService: AuthService()
            )
            .previewDisplayName("Role Selection")
            
            HomeView(
                role: .child,
                chores: .constant(Chore.sampleChores),
                achievementManager: AchievementManager(),
                choreService: ChoreService(),
                authService: AuthService()
            )
            .previewDisplayName("Home View")
        }
    }
} 
 