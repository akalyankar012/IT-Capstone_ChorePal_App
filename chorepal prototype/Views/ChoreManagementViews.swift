import SwiftUI

// MARK: - Chore Management View
struct ChoreManagementView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddChore = false
    @State private var selectedChore: Chore?
    @State private var showingEditChore = false
    @State private var selectedStatus: ChoreStatus = .all
    @State private var searchText = ""
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search chores...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach([ChoreStatus.all, .active, .completed, .overdue, .dueToday], id: \.self) { status in
                                FilterPill(
                                    status: status,
                                    isSelected: selectedStatus == status,
                                    action: { selectedStatus = status }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Chores List
                List {
                    ForEach(filteredChores) { chore in
                        ChoreManagementRowView(
                            chore: chore,
                            choreService: choreService,
                            authService: authService,
                            onEdit: {
                                selectedChore = chore
                                showingEditChore = true
                            }
                        )
                    }
                    .onDelete(perform: deleteChores)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Manage Chores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddChore = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(themeColor)
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
    
    private var filteredChores: [Chore] {
        // Get children IDs for the current parent
        let childrenIds = authService.currentParent?.children.map { $0.id } ?? []
        
        // Get chores for this parent (assigned to their children + unassigned)
        let parentChores = choreService.getChoresForParent(childrenIds: childrenIds)
        
        // Apply status filter
        let statusFiltered = parentChores.filter { chore in
            switch selectedStatus {
            case .all:
                return true
            case .active:
                return !chore.isCompleted
            case .completed:
                return chore.isCompleted
            case .overdue:
                return !chore.isCompleted && chore.dueDate < Date()
            case .dueToday:
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                let choreDate = calendar.startOfDay(for: chore.dueDate)
                return choreDate >= today && choreDate < tomorrow
            }
        }
        
        // Apply search filter
        if searchText.isEmpty {
            return statusFiltered
        } else {
            return statusFiltered.filter { chore in
                chore.title.localizedCaseInsensitiveContains(searchText) ||
                chore.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func deleteChores(offsets: IndexSet) {
        for index in offsets {
            let chore = filteredChores[index]
            choreService.deleteChore(chore)
        }
    }
}



// MARK: - Chore Management Row View
struct ChoreManagementRowView: View {
    let chore: Chore
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    let onEdit: () -> Void
    
    @State private var showingAssignmentSheet = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Completion Status
                Button(action: {
                    choreService.toggleChoreCompletion(chore)
                }) {
                    Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(chore.isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title and Points
                    HStack {
                        Text(chore.title)
                            .font(.system(size: 17, weight: .semibold))
                            .strikethrough(chore.isCompleted)
                            .foregroundColor(chore.isCompleted ? .gray : .primary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("\(chore.points)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                                .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    
                    // Description
                    Text(chore.description)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    // Due Date and Assignment
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("Due: \(chore.dueDate, style: .date)")
                                .font(.caption)
                        }
                        .foregroundColor(isOverdue ? .red : .gray)
                        
                        if let assignedChildId = chore.assignedToChildId,
                           let child = authService.currentParent?.children.first(where: { $0.id == assignedChildId }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                Text(child.name)
                                    .font(.caption)
                            }
                            .foregroundColor(themeColor)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "person.slash")
                                    .font(.caption)
                                Text("Unassigned")
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Actions Menu
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: { showingAssignmentSheet = true }) {
                        Label("Assign", systemImage: "person.badge.plus")
                    }
                    
                    if chore.assignedToChildId != nil {
                        Button(action: {
                            choreService.unassignChore(chore)
                        }) {
                            Label("Unassign", systemImage: "person.slash")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        choreService.deleteChore(chore)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            
            // Status Indicators
            HStack(spacing: 8) {
                if chore.isRequired {
                    Text("Required")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                
                if isOverdue {
                    Text("Overdue")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showingAssignmentSheet) {
            ChoreAssignmentView(chore: chore, choreService: choreService, authService: authService)
        }
    }
    
    private var isOverdue: Bool {
        !chore.isCompleted && chore.dueDate < Date()
    }
}

// MARK: - Chore Assignment View
struct ChoreAssignmentView: View {
    let chore: Chore
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Chore Info
                VStack(spacing: 12) {
                    Text("Assign Chore")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 8) {
                        Text(chore.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(chore.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(chore.points) points")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Children List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Assign to:")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    if let children = authService.currentParent?.children, !children.isEmpty {
                        LazyVStack(spacing: 8) {
                            ForEach(children) { child in
                                ChildAssignmentRow(
                                    child: child,
                                    isAssigned: chore.assignedToChildId == child.id,
                                    onAssign: {
                                        choreService.assignChoreToChild(chore, childId: child.id)
                                        dismiss()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No children available")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Add children in the Parent Dashboard first")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    }
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Child Assignment Row
struct ChildAssignmentRow: View {
    let child: Child
    let isAssigned: Bool
    let onAssign: () -> Void
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        Button(action: onAssign) {
            HStack(spacing: 12) {
                // Child Avatar
                Circle()
                    .fill(themeColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(child.name.prefix(1)).uppercased())
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(themeColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name)
                        .font(.system(size: 16, weight: .semibold))
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
                
                if isAssigned {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(themeColor)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Add Chore View
struct AddChoreView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var pointsValue = 5
    @State private var dueDate = Date()
    @State private var isRequired = false
    @State private var selectedChildId: UUID?
    @State private var showingChildSelection = false
    @State private var showingTemplates = false
    @State private var isAddingChore = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Title", text: $title)
                            .textFieldStyle(.plain)
                        TextField("Description", text: $description)
                            .textFieldStyle(.plain)
                    } header: {
                        Text("CHORE DETAILS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Section {
                        HStack {
                            Text("Points")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                Button {
                                    withAnimation {
                                        if pointsValue > 1 {
                                            pointsValue = max(1, pointsValue - 1)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(pointsValue > 1 ? themeColor : Color(.systemGray4))
                                        .font(.system(size: 24))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                Text("\(pointsValue)")
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(minWidth: 30)
                                
                                Button {
                                    withAnimation {
                                        if pointsValue < 100 {
                                            pointsValue = min(100, pointsValue + 1)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(pointsValue < 100 ? themeColor : Color(.systemGray4))
                                        .font(.system(size: 24))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    } header: {
                        Text("POINTS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Section {
                        DatePicker("Select Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                    } header: {
                        Text("DUE DATE")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Section {
                        Toggle("Required Chore", isOn: $isRequired)
                    } header: {
                        Text("TYPE")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    if let children = authService.currentParent?.children, !children.isEmpty {
                        Section {
                            Button(action: { showingChildSelection = true }) {
                                HStack {
                                    Text("Assign to Child")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if let selectedChildId = selectedChildId,
                                       let child = children.first(where: { $0.id == selectedChildId }) {
                                        Text(child.name)
                                            .foregroundColor(themeColor)
                                    } else {
                                        Text("Optional")
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        } header: {
                            Text("ASSIGNMENT")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add New Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isAddingChore ? "Adding..." : "Add") {
                        addChore()
                    }
                    .disabled(title.isEmpty || description.isEmpty || isAddingChore)
                }
            }
        }
        .presentationBackground(.background)
        .sheet(isPresented: $showingChildSelection) {
            ChildSelectionView(selectedChildId: $selectedChildId, authService: authService)
        }
        .sheet(isPresented: $showingTemplates) {
            ChoreTemplatesView(title: $title, description: $description, pointsValue: $pointsValue, isRequired: $isRequired)
        }
        .alert("Success!", isPresented: $showingSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Chore added successfully!")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func addChore() {
        guard !title.isEmpty && !description.isEmpty else {
            errorMessage = "Please fill in all required fields"
            showingErrorAlert = true
            return
        }
        
        isAddingChore = true
        
        // Simulate network delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let newChore = Chore(
                title: title,
                description: description,
                points: pointsValue,
                dueDate: dueDate,
                isCompleted: false,
                isRequired: isRequired,
                assignedToChildId: selectedChildId,
                createdAt: Date()
            )
            
            choreService.addChore(newChore)
            isAddingChore = false
            showingSuccessAlert = true
        }
    }
}

// MARK: - Child Selection View
struct ChildSelectionView: View {
    @Binding var selectedChildId: UUID?
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Child")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                if let children = authService.currentParent?.children, !children.isEmpty {
                    LazyVStack(spacing: 12) {
                        ForEach(children) { child in
                            Button(action: {
                                selectedChildId = child.id
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
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
                                    
                                    if selectedChildId == child.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No children available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Add children in the Parent Dashboard first")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Edit Chore View
struct EditChoreView: View {
    let chore: Chore
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var pointsValue: Int
    @State private var dueDate: Date
    @State private var isRequired: Bool
    @State private var selectedChildId: UUID?
    @State private var showingChildSelection = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    init(chore: Chore, choreService: ChoreService, authService: AuthService) {
        self.chore = chore
        self.choreService = choreService
        self.authService = authService
        _title = State(initialValue: chore.title)
        _description = State(initialValue: chore.description)
        _pointsValue = State(initialValue: chore.points)
        _dueDate = State(initialValue: chore.dueDate)
        _isRequired = State(initialValue: chore.isRequired)
        _selectedChildId = State(initialValue: chore.assignedToChildId)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Title", text: $title)
                            .textFieldStyle(.plain)
                        TextField("Description", text: $description)
                            .textFieldStyle(.plain)
                    } header: {
                        Text("CHORE DETAILS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Section {
                        HStack {
                            Text("Points")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                Button {
                                    withAnimation {
                                        if pointsValue > 1 {
                                            pointsValue = max(1, pointsValue - 1)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(pointsValue > 1 ? themeColor : Color(.systemGray4))
                                        .font(.system(size: 24))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                Text("\(pointsValue)")
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(minWidth: 30)
                                
                                Button {
                                    withAnimation {
                                        if pointsValue < 100 {
                                            pointsValue = min(100, pointsValue + 1)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(pointsValue < 100 ? themeColor : Color(.systemGray4))
                                        .font(.system(size: 24))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    } header: {
                        Text("POINTS")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Section {
                        DatePicker("Select Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                    } header: {
                        Text("DUE DATE")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Section {
                        Toggle("Required Chore", isOn: $isRequired)
                    } header: {
                        Text("TYPE")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    if let children = authService.currentParent?.children, !children.isEmpty {
                        Section {
                            Button(action: { showingChildSelection = true }) {
                                HStack {
                                    Text("Assign to Child")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if let selectedChildId = selectedChildId,
                                       let child = children.first(where: { $0.id == selectedChildId }) {
                                        Text(child.name)
                                            .foregroundColor(themeColor)
                                    } else {
                                        Text("Unassigned")
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        } header: {
                            Text("ASSIGNMENT")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Update the chore directly in the service
                        if let index = choreService.chores.firstIndex(where: { $0.id == chore.id }) {
                            choreService.chores[index].title = title
                            choreService.chores[index].description = description
                            choreService.chores[index].points = pointsValue
                            choreService.chores[index].dueDate = dueDate
                            choreService.chores[index].isRequired = isRequired
                            choreService.chores[index].assignedToChildId = selectedChildId
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty || description.isEmpty)
                }
            }
        }
        .presentationBackground(.background)
        .sheet(isPresented: $showingChildSelection) {
            ChildSelectionView(selectedChildId: $selectedChildId, authService: authService)
        }
    }
}

// MARK: - Chore Templates View
struct ChoreTemplatesView: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var pointsValue: Int
    @Binding var isRequired: Bool
    @Environment(\.dismiss) private var dismiss
    
    private let themeColor = Color(hex: "#a2cee3")
    
    private let templates = [
        ChoreTemplate(name: "Make Bed", description: "Make your bed neatly", points: 3, required: true),
        ChoreTemplate(name: "Clean Room", description: "Pick up toys and organize room", points: 5, required: true),
        ChoreTemplate(name: "Do Dishes", description: "Wash and put away dishes", points: 4, required: false),
        ChoreTemplate(name: "Take Out Trash", description: "Empty trash bins", points: 2, required: false),
        ChoreTemplate(name: "Feed Pet", description: "Feed and water the pet", points: 3, required: true),
        ChoreTemplate(name: "Homework", description: "Complete homework assignments", points: 8, required: true),
        ChoreTemplate(name: "Laundry", description: "Sort and fold laundry", points: 6, required: false),
        ChoreTemplate(name: "Set Table", description: "Set the table for meals", points: 2, required: false)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Chore Templates")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(templates) { template in
                            Button(action: {
                                title = template.name
                                description = template.description
                                pointsValue = template.points
                                isRequired = template.required
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text(template.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(template.points) pts")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeColor)
                                        
                                        if template.required {
                                            Text("Required")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ChoreTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let points: Int
    let required: Bool
} 