import SwiftUI

// MARK: - Parent Dashboard View
struct ParentDashboardView: View {
    @ObservedObject var authService: AuthService
    @State private var showingAddChild = false
    @State private var selectedChild: Child?
    @State private var showingChildDetails = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    VStack(spacing: 8) {
                        Text("Welcome back!")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("Family Dashboard")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(themeColor)
                    }
                    .padding(.top, 20)
                    
                    // Family Overview Card
                    FamilyOverviewCard(authService: authService)
                    
                    // Children Management Section
                    ChildrenManagementSection(
                        authService: authService,
                        showingAddChild: $showingAddChild,
                        selectedChild: $selectedChild,
                        showingChildDetails: $showingChildDetails
                    )
                    
                    // Quick Actions Section
                    QuickActionsSection()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingAddChild) {
            AddChildView(authService: authService)
        }
        .fullScreenCover(item: $selectedChild) { child in
            ChildDetailsView(child: child, authService: authService)
        }
    }
}

// MARK: - Family Overview Card
struct FamilyOverviewCard: View {
    @ObservedObject var authService: AuthService
    
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
                    value: "\(activeChoresCount)",
                    icon: "checklist",
                    color: .green
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(completedChoresCount)",
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
    
    private var activeChoresCount: Int {
        // This will be implemented when we add chore management
        0
    }
    
    private var completedChoresCount: Int {
        // This will be implemented when we add chore management
        0
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
                    title: "Add Chore",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    // Will be implemented when we add chore management
                }
                
                QuickActionCard(
                    title: "Manage Rewards",
                    icon: "gift.fill",
                    color: .purple
                ) {
                    // Will be implemented when we add reward management
                }
                
                QuickActionCard(
                    title: "View Stats",
                    icon: "chart.bar.fill",
                    color: .blue
                ) {
                    // Will be implemented when we add statistics
                }
                
                QuickActionCard(
                    title: "Settings",
                    icon: "gearshape.fill",
                    color: .gray
                ) {
                    // Will be implemented when we add settings
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
                            value: "0", // Will be implemented with chore management
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
} 