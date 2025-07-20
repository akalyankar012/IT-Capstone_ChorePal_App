import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var currentParent: Parent?
    @Published var currentChild: Child?
    @Published var authState: AuthState = .none
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Mock data storage
    private var parents: [Parent] = []
    private var children: [Child] = []
    
    init() {
        // Add sample data for testing
        setupSampleData()
    }
    
    private func setupSampleData() {
        // Add a sample parent
        var sampleParent = Parent(phoneNumber: "5551234567", password: "password123")
        sampleParent.isVerified = true
        parents.append(sampleParent)
        
        // Add sample children with known PINs
        let sampleChild1 = Child(name: "Emma", pin: "1234", parentId: sampleParent.id)
        let sampleChild2 = Child(name: "Liam", pin: "5678", parentId: sampleParent.id)
        
        children.append(sampleChild1)
        children.append(sampleChild2)
        
        // Add children to parent
        sampleParent.children.append(sampleChild1)
        sampleParent.children.append(sampleChild2)
    }
    
    // MARK: - Parent Authentication
    
    func signUpParent(phoneNumber: String, password: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Check if phone number already exists
        if parents.contains(where: { $0.phoneNumber == phoneNumber }) {
            await MainActor.run {
                errorMessage = "Phone number already registered"
                isLoading = false
            }
            return false
        }
        
        // Create new parent
        let newParent = Parent(phoneNumber: phoneNumber, password: password)
        
        await MainActor.run {
            parents.append(newParent)
            currentParent = newParent
            authState = .verifyPhone
            isLoading = false
        }
        
        return true
    }
    
    func verifyPhoneCode(code: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock verification - any 6-digit code works
        guard code.count == 6, code.allSatisfy({ $0.isNumber }) else {
            await MainActor.run {
                errorMessage = "Invalid verification code"
                isLoading = false
            }
            return false
        }
        
        await MainActor.run {
            currentParent?.isVerified = true
            authState = .authenticated
            isLoading = false
        }
        
        return true
    }
    
    func signInParent(phoneNumber: String, password: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Find parent
        guard let parent = parents.first(where: { $0.phoneNumber == phoneNumber }) else {
            await MainActor.run {
                errorMessage = "Phone number not found"
                isLoading = false
            }
            return false
        }
        
        // Check password
        guard parent.password == password else {
            await MainActor.run {
                errorMessage = "Incorrect password"
                isLoading = false
            }
            return false
        }
        
        await MainActor.run {
            currentParent = parent
            authState = .authenticated
            isLoading = false
        }
        
        return true
    }
    
    // MARK: - Child Management
    
    func addChild(name: String) async -> String {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Generate 4-digit PIN
        let pin = String(format: "%04d", Int.random(in: 1000...9999))
        
        guard let parent = currentParent else {
            await MainActor.run {
                errorMessage = "No parent logged in"
                isLoading = false
            }
            return ""
        }
        
        let newChild = Child(name: name, pin: pin, parentId: parent.id)
        
        await MainActor.run {
            children.append(newChild)
            currentParent?.children.append(newChild)
            isLoading = false
        }
        
        return pin
    }
    
    // MARK: - Child Authentication
    
    func signInChild(pin: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Find child by PIN
        guard let child = children.first(where: { $0.pin == pin }) else {
            await MainActor.run {
                errorMessage = "Invalid PIN"
                isLoading = false
            }
            return false
        }
        
        await MainActor.run {
            currentChild = child
            authState = .authenticated
            isLoading = false
        }
        
        return true
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        currentParent = nil
        currentChild = nil
        authState = .none
        errorMessage = nil
    }
    
    // MARK: - Helper Methods
    
    func getChildrenForCurrentParent() -> [Child] {
        guard let parent = currentParent else { return [] }
        return children.filter { $0.parentId == parent.id }
    }
    
    func updateChildPoints(childId: UUID, points: Int) {
        if let index = children.firstIndex(where: { $0.id == childId }) {
            children[index].points = points
        }
        if let index = currentParent?.children.firstIndex(where: { $0.id == childId }) {
            currentParent?.children[index].points = points
        }
    }
} 