import Foundation
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    @Published var currentParent: Parent?
    @Published var currentChild: Child?
    @Published var authState: AuthState = .none
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // Temporary storage for testing
    private var parents: [Parent] = []
    private var children: [Child] = []
    
    init() {
        // Add sample data for testing
        setupSampleData()
        
        // Listen for Firebase auth state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    // User is signed in
                    self?.handleFirebaseUser(user)
                } else {
                    // User is signed out
                    self?.handleSignOut()
                }
            }
        }
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
        
        do {
            // Clean phone number (remove any formatting)
            let cleanPhoneNumber = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            
            // Create email from phone number for Firebase Auth
            let email = "\(cleanPhoneNumber)@parent.chorepal.com"
            
            print("Creating Firebase account with email: \(email)")
            
            // Create user with Firebase Auth
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create parent profile in Firestore
            let parentData: [String: Any] = [
                "phoneNumber": phoneNumber,
                "email": email,
                "createdAt": FieldValue.serverTimestamp(),
                "isVerified": false
            ]
            
            try await db.collection("parents").document(result.user.uid).setData(parentData)
            
            await MainActor.run {
                authState = .verifyPhone
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                // More detailed error handling for sign up
                if let authError = error as? AuthErrorCode {
                    switch authError.code {
                    case .emailAlreadyInUse:
                        errorMessage = "This phone number is already registered. Please sign in instead."
                    case .weakPassword:
                        errorMessage = "Password is too weak. Please choose a stronger password."
                    case .invalidEmail:
                        errorMessage = "Invalid phone number format."
                    case .networkError:
                        errorMessage = "Network error. Please check your connection."
                    default:
                        errorMessage = "Authentication error: \(authError.localizedDescription)"
                    }
                } else {
                    errorMessage = "Error: \(error.localizedDescription)"
                }
                print("Firebase Auth Error (Sign Up): \(error)")
                isLoading = false
            }
            return false
        }
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
        
        do {
            // Clean phone number (remove any formatting)
            let cleanPhoneNumber = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            
            // Create email from phone number for Firebase Auth
            let email = "\(cleanPhoneNumber)@parent.chorepal.com"
            
            print("Signing in with email: \(email)")
            
            // Sign in with Firebase Auth
            try await auth.signIn(withEmail: email, password: password)
            
            // Firebase auth state listener will handle the rest
            await MainActor.run {
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                // More detailed error handling for sign in
                if let authError = error as? AuthErrorCode {
                    switch authError.code {
                    case .userNotFound:
                        errorMessage = "No account found with this phone number. Please sign up first."
                    case .wrongPassword:
                        errorMessage = "Incorrect password. Please try again."
                    case .invalidEmail:
                        errorMessage = "Invalid phone number format."
                    case .networkError:
                        errorMessage = "Network error. Please check your connection."
                    default:
                        errorMessage = "Authentication error: \(authError.localizedDescription)"
                    }
                } else {
                    errorMessage = "Error: \(error.localizedDescription)"
                }
                print("Firebase Auth Error (Sign In): \(error)")
                isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Child Management
    
    func addChild(_ child: Child) {
        children.append(child)
        currentParent?.children.append(child)
    }
    
    func removeChild(_ child: Child) {
        children.removeAll { $0.id == child.id }
        currentParent?.children.removeAll { $0.id == child.id }
    }
    
    // MARK: - Child Points Management
    
    func awardPointsToChild(childId: UUID, points: Int) {
        if let childIndex = children.firstIndex(where: { $0.id == childId }) {
            children[childIndex].points += points
        }
        
        if let childIndex = currentParent?.children.firstIndex(where: { $0.id == childId }) {
            currentParent?.children[childIndex].points += points
        }
        
        // Update current child if it's the same child
        if currentChild?.id == childId {
            currentChild?.points += points
        }
    }
    
    func deductPointsFromChild(childId: UUID, points: Int) {
        if let childIndex = children.firstIndex(where: { $0.id == childId }) {
            children[childIndex].points = max(0, children[childIndex].points - points)
        }
        
        if let childIndex = currentParent?.children.firstIndex(where: { $0.id == childId }) {
            currentParent?.children[childIndex].points = max(0, (currentParent?.children[childIndex].points ?? 0) - points)
        }
        
        // Update current child if it's the same child
        if currentChild?.id == childId {
            currentChild?.points = max(0, (currentChild?.points ?? 0) - points)
        }
    }
    
    func updateChildPoints(childId: UUID, points: Int) {
        if let childIndex = children.firstIndex(where: { $0.id == childId }) {
            children[childIndex].points = points
        }
        
        if let childIndex = currentParent?.children.firstIndex(where: { $0.id == childId }) {
            currentParent?.children[childIndex].points = points
        }
        
        // Update current child if it's the same child
        if currentChild?.id == childId {
            currentChild?.points = points
        }
    }
    
    func getChildrenForCurrentParent() -> [Child] {
        return currentParent?.children ?? []
    }
    
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
        do {
            try auth.signOut()
            // Firebase auth state listener will handle the rest
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Firebase User Handling
    
    private func handleFirebaseUser(_ user: User) {
        // Check if this is a parent or child user
        if user.email?.contains("@parent") == true {
            // This is a parent user
            loadParentData(userId: user.uid)
        } else {
            // This is a child user
            loadChildData(userId: user.uid)
        }
    }
    
    private func handleSignOut() {
        currentParent = nil
        currentChild = nil
        authState = .none
        errorMessage = nil
    }
    
    private func loadParentData(userId: String) {
        // Load parent data from Firestore
        db.collection("parents").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    // Parent data exists, load it
                    // For now, we'll use mock data until we set up Firestore
                    self?.authState = .authenticated
                } else {
                    // New parent, create profile
                    self?.authState = .authenticated
                }
            }
        }
    }
    
    private func loadChildData(userId: String) {
        // Load child data from Firestore
        db.collection("children").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    // Child data exists, load it
                    // For now, we'll use mock data until we set up Firestore
                    self?.authState = .authenticated
                } else {
                    // New child, create profile
                    self?.authState = .authenticated
                }
            }
        }
    }
    
    // MARK: - Helper Methods
} 