import SwiftUI

struct PointsCounterView: View {
    let totalPoints: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text("\(totalPoints) Points")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#a2cee3").opacity(colorScheme == .dark ? 0.3 : 0.2))
        )
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            Spacer()
            
            // Calendar Tab
            TabBarButton(
                iconName: "calendar",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            Spacer()
            
            // Home Tab
            TabBarButton(
                iconName: "house.fill",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            Spacer()
            
            // Settings Tab
            TabBarButton(
                iconName: "gearshape.fill",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
            
            Spacer()
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
}

struct TabBarButton: View {
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? Color(hex: "#a2cee3") : .gray)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isSelected ? Color(hex: "#a2cee3").opacity(0.2) : Color.clear)
                )
        }
    }
}

struct CalendarView: View {
    @EnvironmentObject private var choreModel: ChoreModel
    @Environment(\.colorScheme) var colorScheme
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    @State private var selectedDate = Date()
    @State private var selectedMonth = Date()
    
    private var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDates(for: dateInterval)
    }
    
    private var choresByDate: [Date: [Chore]] {
        Dictionary(grouping: choreModel.chores) { chore in
            calendar.startOfDay(for: chore.dueDate)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Month selector
            HStack {
                Button(action: { selectPreviousMonth() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(hex: "#a2cee3"))
                }
                
                Text(monthFormatter.string(from: selectedMonth))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                
                Button(action: { selectNextMonth() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(hex: "#a2cee3"))
                }
            }
            .padding(.horizontal)
            
            // Day labels
            HStack {
                ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(
                        date: date,
                        selectedDate: $selectedDate,
                        chores: choresByDate[calendar.startOfDay(for: date)] ?? [],
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                    )
                }
            }
            
            // Selected day's chores
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    let selectedDayChores = choresByDate[calendar.startOfDay(for: selectedDate)] ?? []
                    
                    if selectedDayChores.isEmpty {
                        Text("No chores scheduled for this day")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(selectedDayChores) { chore in
                            ChoreCalendarRow(chore: chore)
                        }
                    }
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "#a2cee3").opacity(0.1))
            )
        }
        .padding()
    }
    
    private func selectPreviousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private func selectNextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
}

struct DayCell: View {
    let date: Date
    @Binding var selectedDate: Date
    let chores: [Chore]
    let isCurrentMonth: Bool
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        Button(action: { selectedDate = date }) {
            VStack {
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 16))
                    .fontWeight(calendar.isDate(date, inSameDayAs: selectedDate) ? .bold : .regular)
                    .foregroundColor(isCurrentMonth ? .primary : .gray)
                
                if !chores.isEmpty {
                    Circle()
                        .fill(Color(hex: "#a2cee3"))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(calendar.isDate(date, inSameDayAs: selectedDate) 
                        ? Color(hex: "#a2cee3").opacity(0.2) 
                        : Color.clear)
            )
        }
    }
}

struct ChoreCalendarRow: View {
    let chore: Chore
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(chore.title)
                    .font(.headline)
                Text(chore.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("\(chore.points) pts")
                .font(.caption)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#a2cee3").opacity(0.2))
                )
        }
        .padding(.vertical, 4)
    }
}

extension Calendar {
    func generateDates(for dateInterval: DateInterval) -> [Date] {
        var dates: [Date] = []
        var date = dateInterval.start
        
        while date < dateInterval.end {
            dates.append(date)
            guard let newDate = self.date(byAdding: .day, value: 1, to: date) else { break }
            date = newDate
        }
        
        return dates
    }
}

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isRotating = false
    
    var body: some View {
        List {
            Section(header: Text("Appearance")) {
                Toggle(isOn: $isDarkMode) {
                    HStack(spacing: 12) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(isDarkMode ? .purple : .orange)
                            .rotationEffect(.degrees(isRotating ? 360 : 0))
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isRotating)
                        Text(isDarkMode ? "Dark Mode" : "Light Mode")
                    }
                }
                .tint(Color(hex: "#a2cee3"))
                .onChange(of: isDarkMode) { newValue in
                    isRotating.toggle()
                    setAppearance()
                }
            }
        }
        .navigationTitle("Settings")
        .background(Color(hex: "#a2cee3").opacity(0.1))
    }
    
    private func setAppearance() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
                }
            }
        }
    }
}

struct HomeView: View {
    let userRole: UserRole
    @EnvironmentObject private var choreModel: ChoreModel
    @State private var showingAddChore = false
    @State private var showingEditChore = false
    @State private var showingPointsManagement = false
    @State private var showingStats = false
    @State private var choreToEdit: Chore?
    @State private var selectedTab = 1  // Default to home tab
    @Environment(\.colorScheme) var colorScheme
    
    var totalPoints: Int {
        choreModel.totalAccumulatedPoints
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(hex: "#a2cee3")
                    .opacity(colorScheme == .dark ? 0.05 : 0.1)
                    .ignoresSafeArea()
                
                VStack {
                    if userRole == .parent {
                        switch selectedTab {
                        case 0:
                            CalendarView()
                        case 1:
                            parentHomeContent
                        case 2:
                            SettingsView()
                        default:
                            EmptyView()
                        }
                    } else {
                        childHomeContent
                    }
                    
                    if userRole == .parent {
                        CustomTabBar(selectedTab: $selectedTab)
                            .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle(userRole == .parent ? "Manage Chores" : "My Chores")
            .toolbarBackground(Color(hex: "#a2cee3").opacity(0.2), for: .navigationBar)
            .toolbar {
                if userRole == .parent {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showingPointsManagement = true
                        }) {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                Text("\(totalPoints)")
                            }
                            .foregroundColor(Color(hex: "#a2cee3"))
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddChore = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "#a2cee3"))
                                .font(.system(size: 24))
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingAddChore) {
                AddChoreView(isPresented: $showingAddChore) { title, description, points, dueDate in
                    choreModel.addChore(
                        title: title,
                        description: description,
                        points: points,
                        dueDate: dueDate
                    )
                }
            }
            .fullScreenCover(isPresented: $showingEditChore) {
                if let chore = choreToEdit {
                    EditChoreView(chore: chore, isPresented: $showingEditChore) { title, description, points, dueDate in
                        choreModel.editChore(
                            chore,
                            title: title,
                            description: description,
                            points: points,
                            dueDate: dueDate
                        )
                    }
                }
            }
            .onChange(of: showingEditChore) { isShowing in
                if !isShowing {
                    choreToEdit = nil
                }
            }
            .fullScreenCover(isPresented: $showingPointsManagement) {
                PointsManagementView()
            }
            .fullScreenCover(isPresented: $showingStats) {
                StatsView()
            }
        }
        .preferredColorScheme(UserDefaults.standard.bool(forKey: "isDarkMode") ? .dark : .light)
    }
    
    @ViewBuilder
    private var parentHomeContent: some View {
        VStack {
            List {
                ForEach(choreModel.chores.sorted(by: { $0.dueDate < $1.dueDate })) { chore in
                    ChoreRowView(chore: chore, userRole: userRole) { updatedChore in
                        choreModel.toggleChoreCompletion(chore: updatedChore)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#a2cee3").opacity(chore.isCompleted ? 0.2 : 0.05))
                            .padding(.vertical, 4)
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if userRole == .parent {
                            Button(role: .destructive) {
                                choreModel.deleteChore(chore)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                choreToEdit = chore
                                showingEditChore = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Color(hex: "#a2cee3"))
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }
    
    @ViewBuilder
    private var childHomeContent: some View {
        VStack {
            HStack {
                PointsCounterView(totalPoints: totalPoints)
                
                Spacer()
                
                Button(action: {
                    showingStats = true
                }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#a2cee3"))
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color(hex: "#a2cee3").opacity(0.2))
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            List {
                ForEach(choreModel.chores.sorted(by: { $0.dueDate < $1.dueDate })) { chore in
                    ChoreRowView(chore: chore, userRole: userRole) { updatedChore in
                        choreModel.toggleChoreCompletion(chore: updatedChore)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#a2cee3").opacity(chore.isCompleted ? 0.2 : 0.05))
                            .padding(.vertical, 4)
                    )
                }
            }
            .listStyle(.inset)
        }
    }
}

#Preview {
    HomeView(userRole: .child)
        .environmentObject(ChoreModel())
} 