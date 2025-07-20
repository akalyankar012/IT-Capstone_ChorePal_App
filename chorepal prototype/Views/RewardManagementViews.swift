import SwiftUI

// MARK: - Manage Rewards View
struct ManageRewardsView: View {
    @ObservedObject var rewardService: RewardService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddReward = false
    @State private var selectedReward: Reward?
    @State private var showingEditReward = false
    @State private var selectedStatus: RewardStatus = .all
    @State private var selectedCategory: RewardCategory?
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
                        TextField("Search rewards...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach([RewardStatus.all, .available, .purchased, .unavailable], id: \.self) { status in
                                FilterPill(
                                    status: status,
                                    isSelected: selectedStatus == status,
                                    action: { selectedStatus = status }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button(action: { selectedCategory = nil }) {
                                Text("All Categories")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == nil ? themeColor : Color(.systemGray5))
                                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                                    .cornerRadius(16)
                            }
                            
                            ForEach(RewardCategory.allCases, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: category.icon)
                                            .font(.caption)
                                        Text(category.rawValue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == category ? Color(hex: category.color) : Color(.systemGray5))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Rewards List
                List {
                    ForEach(filteredRewards) { reward in
                        RewardRowView(
                            reward: reward,
                            onToggleAvailability: {
                                rewardService.toggleRewardAvailability(reward)
                            },
                            onEdit: {
                                selectedReward = reward
                                showingEditReward = true
                            },
                            onDelete: {
                                rewardService.deleteReward(reward)
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Manage Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddReward = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingAddReward) {
            AddRewardView(rewardService: rewardService)
        }
        .sheet(isPresented: $showingEditReward) {
            if let reward = selectedReward {
                EditRewardView(reward: reward, rewardService: rewardService)
            }
        }
    }
    
    private var filteredRewards: [Reward] {
        var rewards = rewardService.filterRewards(by: selectedStatus)
        
        if !searchText.isEmpty {
            rewards = rewardService.searchRewards(query: searchText)
        }
        
        if let category = selectedCategory {
            rewards = rewards.filter { $0.category == category }
        }
        
        return rewards
    }
}

// MARK: - Reward Row View
struct RewardRowView: View {
    let reward: Reward
    let onToggleAvailability: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            Image(systemName: reward.category.icon)
                .font(.title2)
                .foregroundColor(Color(hex: reward.category.color))
                .frame(width: 40, height: 40)
                .background(Color(hex: reward.category.color).opacity(0.1))
                .cornerRadius(10)
            
            // Reward Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reward.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(reward.points) pts")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeColor)
                }
                
                if !reward.description.isEmpty {
                    Text(reward.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(reward.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: reward.category.color).opacity(0.2))
                        .foregroundColor(Color(hex: reward.category.color))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    if let purchasedAt = reward.purchasedAt {
                        Text("Purchased \(purchasedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(reward.isAvailable ? "Available" : "Unavailable")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(reward.isAvailable ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .foregroundColor(reward.isAvailable ? .green : .red)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(themeColor)
            
            if reward.purchasedAt == nil {
                Button {
                    onToggleAvailability()
                } label: {
                    Label(reward.isAvailable ? "Disable" : "Enable", systemImage: reward.isAvailable ? "xmark.circle" : "checkmark.circle")
                }
                .tint(reward.isAvailable ? .orange : .green)
            }
        }
    }
}

// MARK: - Add Reward View
struct AddRewardView: View {
    @ObservedObject var rewardService: RewardService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var pointsValue = 25
    @State private var pointsText = "25"
    @State private var selectedCategory: RewardCategory = .other
    @State private var isAvailable = true
    @State private var showingTemplates = false
    @State private var isAddingReward = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private func updatePoints(_ newValue: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            pointsValue = newValue
            pointsText = "\(newValue)"
        }
    }
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reward Details") {
                    HStack {
                        TextField("Reward Name", text: $name)
                        
                        Button(action: { showingTemplates = true }) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(themeColor)
                        }
                    }
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(RewardCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Points & Availability") {
                    HStack {
                        Text("Points Required")
                        Spacer()
                        HStack(spacing: 16) {
                            Button(action: {
                                updatePoints(max(1, pointsValue - 5))
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(themeColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            TextField("Points", text: $pointsText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.headline)
                                .frame(width: 60)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: pointsText) { newValue in
                                    if let points = Int(newValue), points >= 1, points <= 1000 {
                                        pointsValue = points
                                    }
                                }
                            
                            Button(action: {
                                updatePoints(min(1000, pointsValue + 5))
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(themeColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Text("Points range: 1-1000")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Available for Purchase", isOn: $isAvailable)
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: selectedCategory.icon)
                                .foregroundColor(Color(hex: selectedCategory.color))
                            Text(name.isEmpty ? "Reward Name" : name)
                                .font(.headline)
                            Spacer()
                            Text("\(pointsValue) pts")
                                .font(.subheadline)
                                .foregroundColor(themeColor)
                        }
                        
                        if !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(selectedCategory.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: selectedCategory.color).opacity(0.2))
                            .foregroundColor(Color(hex: selectedCategory.color))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isAddingReward ? "Adding..." : "Add") {
                        addReward()
                    }
                    .disabled(name.isEmpty || isAddingReward)
                }
            }
        }
        .presentationBackground(.background)
        .sheet(isPresented: $showingTemplates) {
            RewardTemplatesView(
                name: $name,
                description: $description,
                pointsValue: $pointsValue,
                selectedCategory: $selectedCategory
            )
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Reward added successfully!")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func addReward() {
        guard !name.isEmpty else {
            errorMessage = "Please enter a reward name"
            showingErrorAlert = true
            return
        }
        
        isAddingReward = true
        
        // Simulate network delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let newReward = Reward(
                name: name,
                description: description,
                points: pointsValue,
                category: selectedCategory,
                isAvailable: isAvailable
            )
            
            rewardService.addReward(newReward)
            isAddingReward = false
            showingSuccessAlert = true
        }
    }
}

// MARK: - Edit Reward View
struct EditRewardView: View {
    let reward: Reward
    @ObservedObject var rewardService: RewardService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var description: String
    @State private var pointsValue: Int
    @State private var pointsText: String
    @State private var selectedCategory: RewardCategory
    @State private var isAvailable: Bool
    
    private let themeColor = Color(hex: "#a2cee3")
    
    private func updatePoints(_ newValue: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            pointsValue = newValue
            pointsText = "\(newValue)"
        }
    }
    
    init(reward: Reward, rewardService: RewardService) {
        self.reward = reward
        self.rewardService = rewardService
        _name = State(initialValue: reward.name)
        _description = State(initialValue: reward.description)
        _pointsValue = State(initialValue: reward.points)
        _pointsText = State(initialValue: "\(reward.points)")
        _selectedCategory = State(initialValue: reward.category)
        _isAvailable = State(initialValue: reward.isAvailable)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Reward Details") {
                    TextField("Reward Name", text: $name)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(RewardCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Points & Availability") {
                    HStack {
                        Text("Points Required")
                        Spacer()
                        HStack(spacing: 16) {
                            Button(action: {
                                let newValue = max(1, pointsValue - 5)
                                pointsValue = newValue
                                pointsText = "\(newValue)"
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(themeColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            TextField("Points", text: $pointsText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.headline)
                                .frame(width: 60)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: pointsText) { newValue in
                                    if let points = Int(newValue), points >= 1, points <= 1000 {
                                        pointsValue = points
                                    }
                                }
                            
                            Button(action: {
                                let newValue = min(1000, pointsValue + 5)
                                pointsValue = newValue
                                pointsText = "\(newValue)"
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(themeColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Text("Points range: 1-1000")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Available for Purchase", isOn: $isAvailable)
                }
            }
            .navigationTitle("Edit Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReward()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationBackground(.background)
    }
    
    private func saveReward() {
        var updatedReward = reward
        updatedReward.name = name
        updatedReward.description = description
        updatedReward.points = pointsValue
        updatedReward.category = selectedCategory
        updatedReward.isAvailable = isAvailable
        
        rewardService.updateReward(updatedReward)
        dismiss()
    }
}

// MARK: - Reward Templates View
struct RewardTemplatesView: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var pointsValue: Int
    @Binding var selectedCategory: RewardCategory
    @Environment(\.dismiss) private var dismiss
    
    private let themeColor = Color(hex: "#a2cee3")
    
    private let templates = [
        RewardTemplate(name: "Candy Bar", description: "Choose your favorite candy", points: 15, category: .food),
        RewardTemplate(name: "Ice Cream", description: "Get ice cream from your favorite place", points: 25, category: .food),
        RewardTemplate(name: "Pizza Night", description: "Choose dinner for the family", points: 150, category: .food),
        RewardTemplate(name: "Movie Ticket", description: "Watch a movie of your choice", points: 55, category: .entertainment),
        RewardTemplate(name: "Video Game Time", description: "Extra 30 minutes of video game time", points: 30, category: .entertainment),
        RewardTemplate(name: "Skip Chore Pass", description: "Skip one chore without penalty", points: 200, category: .privileges),
        RewardTemplate(name: "Stay Up Late", description: "Stay up 30 minutes past bedtime", points: 75, category: .privileges),
        RewardTemplate(name: "New Toy", description: "Pick a toy under $20", points: 100, category: .toys)
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templates, id: \.name) { template in
                    Button(action: {
                        name = template.name
                        description = template.description
                        pointsValue = template.points
                        selectedCategory = template.category
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: template.category.icon)
                                .font(.title2)
                                .foregroundColor(Color(hex: template.category.color))
                                .frame(width: 40, height: 40)
                                .background(Color(hex: template.category.color).opacity(0.1))
                                .cornerRadius(10)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(template.points) pts")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeColor)
                                }
                                
                                Text(template.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                Text(template.category.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: template.category.color).opacity(0.2))
                                    .foregroundColor(Color(hex: template.category.color))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Reward Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationBackground(.background)
    }
}

// MARK: - Supporting Types

struct RewardTemplate {
    let name: String
    let description: String
    let points: Int
    let category: RewardCategory
}

struct FilterPill: View {
    let status: any FilterStatus
    let isSelected: Bool
    let action: () -> Void
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.caption)
                Text(status.title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? themeColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

protocol FilterStatus {
    var title: String { get }
    var icon: String { get }
}

extension ChoreStatus: FilterStatus {}
extension RewardStatus: FilterStatus {} 