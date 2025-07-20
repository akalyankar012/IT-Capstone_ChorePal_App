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
            print("Phone number: \(phoneNumber)")
            print("Clean phone number: \(cleanPhoneNumber)")
            
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
        
        // Check if user is already signed in
        if let currentUser = auth.currentUser {
            print("User already signed in: \(currentUser.email ?? "no email")")
            
            // If the user is already signed in with the same email, just return success
            let cleanPhoneNumber = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            let expectedEmail = "\(cleanPhoneNumber)@parent.chorepal.com"
            
            if currentUser.email == expectedEmail {
                print("User already signed in with correct email, proceeding...")
                // Load parent data
                handleFirebaseUser(currentUser)
                await MainActor.run {
                    isLoading = false
                }
                return true
            } else {
                // Different user, sign out first
                print("Different user signed in, signing out first...")
                try? await auth.signOut()
            }
        }
        
        do {
            // Clean phone number (remove any formatting)
            let cleanPhoneNumber = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            
            // Create email from phone number for Firebase Auth
            let email = "\(cleanPhoneNumber)@parent.chorepal.com"
            
            print("Signing in with email: \(email)")
            print("Phone number: \(phoneNumber)")
            print("Clean phone number: \(cleanPhoneNumber)")
            
            // Try to sign in with Firebase Auth
            do {
                try await auth.signIn(withEmail: email, password: password)
            } catch {
                print("Sign in failed, checking error type...")
                print("Error: \(error)")
                
                // Check if user doesn't exist (try to create account)
                if let authError = error as? AuthErrorCode {
                    print("Auth error code: \(authError.code.rawValue)")
                    
                    if authError.code == .userNotFound {
                        print("User not found, creating new account...")
                        do {
                            let result = try await auth.createUser(withEmail: email, password: password)
                            
                            // Store parent data in Firestore
                            let parentData: [String: Any] = [
                                "phoneNumber": cleanPhoneNumber,
                                "isVerified": true,
                                "createdAt": FieldValue.serverTimestamp()
                            ]
                            
                            try await db.collection("parents").document(result.user.uid).setData(parentData)
                            print("New parent account created successfully")
                        } catch {
                            print("Failed to create account: \(error)")
                            throw error
                        }
                    } else if authError.code.rawValue == 17004 || authError.code == .wrongPassword || authError.code == .invalidCredential {
                        print("Invalid password for existing account. Creating new account...")
                        
                        // Create a new account with a different email to avoid conflicts
                        let timestamp = Int(Date().timeIntervalSince1970)
                        let newEmail = "\(cleanPhoneNumber)_\(timestamp)@parent.chorepal.com"
                        print("Creating new account with email: \(newEmail)")
                        
                        do {
                            let result = try await auth.createUser(withEmail: newEmail, password: password)
                            
                            // Store parent data in Firestore
                            let parentData: [String: Any] = [
                                "phoneNumber": cleanPhoneNumber,
                                "isVerified": true,
                                "createdAt": FieldValue.serverTimestamp()
                            ]
                            
                            try await db.collection("parents").document(result.user.uid).setData(parentData)
                            print("New parent account created successfully with new email")
                        } catch {
                            print("Failed to create account with new email: \(error)")
                            throw error
                        }
                    } else {
                        // Re-throw other auth errors
                        throw error
                    }
                } else {
                    // Re-throw non-auth errors
                    throw error
                }
            }
            
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
        // Add to local arrays
        children.append(child)
        currentParent?.children.append(child)
        
        // Save to Firestore
        Task {
            await saveChildToFirestore(child)
        }
    }
    
    private func saveChildToFirestore(_ child: Child) async {
        guard let parent = currentParent else {
            print("Error: No parent found when saving child")
            return
        }
        
        // Get the current Firebase user to get the correct parent document ID
        guard let currentUser = auth.currentUser else {
            print("Error: No Firebase user found when saving child")
            return
        }
        
        do {
            let childData: [String: Any] = [
                "name": child.name,
                "pin": child.pin,
                "parentId": currentUser.uid, // Use Firebase Auth UID instead of UUID
                "points": child.points,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            // Save child to Firestore
            try await db.collection("children").document(child.id.uuidString).setData(childData)
            print("✅ Child saved to Firestore successfully: \(child.name) with PIN: \(child.pin)")
            print("📝 Child document ID: \(child.id.uuidString)")
            print("📝 Child data saved: \(childData)")
            
            // Update parent document to include child reference
            try await db.collection("parents").document(currentUser.uid).updateData([
                "children": FieldValue.arrayUnion([child.id.uuidString])
            ])
            print("Parent updated with child reference")
            
        } catch {
            print("Error saving child to Firestore: \(error)")
        }
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
        print("🎲 Generated PIN for new child: \(pin)")
        
        guard let parent = currentParent else {
            await MainActor.run {
                errorMessage = "Parent not found"
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
        
        // Save child to Firestore
        await saveChildToFirestore(newChild)
        
        return pin
    }
    
    // MARK: - Child Authentication
    
    func signInChild(pin: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        print("🔍 Searching for child with PIN: \(pin)")
        
        do {
            // Search for child in Firestore by PIN
            let snapshot = try await db.collection("children")
                .whereField("pin", isEqualTo: pin)
                .getDocuments()
            
            print("📊 Found \(snapshot.documents.count) children with PIN: \(pin)")
            
            guard let document = snapshot.documents.first else {
                print("❌ No child found with PIN: \(pin)")
                await MainActor.run {
                    errorMessage = "Invalid PIN - no child found"
                    isLoading = false
                }
                return false
            }
            
            let data = document.data()
            print("📄 Child document data: \(data)")
            
            guard let name = data["name"] as? String,
                  let childPin = data["pin"] as? String,
                  let parentIdString = data["parentId"] as? String else {
                print("❌ Invalid child data structure")
                await MainActor.run {
                    errorMessage = "Invalid child data"
                    isLoading = false
                }
                return false
            }
            
            // Create child object from Firestore data
            // Use the document ID as the child ID, or generate a new UUID if it's not valid
            let childId: UUID
            if let uuid = UUID(uuidString: document.documentID) {
                childId = uuid
            } else {
                childId = UUID()
            }
            
            let parentId = UUID(uuidString: parentIdString) ?? UUID()
            var child = Child(id: childId, name: name, pin: childPin, parentId: parentId)
            child.points = data["points"] as? Int ?? 0
            
            // Create Firebase account for child if it doesn't exist
            let childEmail = "\(child.id.uuidString)@child.chorepal.com"
            // Pad PIN to meet Firebase's minimum 6-character password requirement
            let childPassword = "\(pin)00" // Add "00" to make it 6 characters
            
            print("🔐 Attempting Firebase Auth with email: \(childEmail)")
            
            do {
                // Try to sign in with Firebase (using padded password)
                try await auth.signIn(withEmail: childEmail, password: childPassword)
                print("✅ Firebase Auth sign in successful")
                
                // Firebase auth state listener will handle the rest
                await MainActor.run {
                    isLoading = false
                }
                
                return true
            } catch {
                print("❌ Firebase Auth sign in failed: \(error.localizedDescription)")
                print("🔍 Error type: \(type(of: error))")
                print("🔍 Error domain: \(error as NSError).domain")
                print("🔍 Error code: \((error as NSError).code)")
                
                // Check if it's a user not found error or invalid credential
                let nsError = error as NSError
                if nsError.domain == "FIRAuthErrorDomain" {
                    print("🔍 Firebase Auth error detected")
                    
                    if nsError.code == 17011 || nsError.code == 17004 {
                        print("👶 Creating new Firebase Auth account for child")
                        
                        do {
                            // Create child account in Firebase
                            let result = try await auth.createUser(withEmail: childEmail, password: childPassword)
                            print("✅ Firebase Auth account created successfully")
                            
                            // Update the existing child document with the Firebase Auth UID
                            let childUpdateData: [String: Any] = [
                                "firebaseAuthUid": result.user.uid
                            ]
                            
                            try await db.collection("children").document(child.id.uuidString).updateData(childUpdateData)
                            print("✅ Child data updated in Firestore with new Firebase UID: \(result.user.uid)")
                            
                            // Firebase auth state listener will handle the rest
                            await MainActor.run {
                                isLoading = false
                            }
                            
                            return true
                        } catch {
                            print("❌ Failed to create Firebase Auth account: \(error.localizedDescription)")
                            await MainActor.run {
                                errorMessage = "Failed to create account: \(error.localizedDescription)"
                                isLoading = false
                            }
                            return false
                        }
                    } else {
                        print("❌ Unexpected Firebase Auth error code: \(nsError.code)")
                        await MainActor.run {
                            errorMessage = "Authentication error: \(error.localizedDescription)"
                            isLoading = false
                        }
                        return false
                    }
                } else {
                    print("❌ Non-Firebase Auth error: \(error)")
                    await MainActor.run {
                        errorMessage = "Authentication error: \(error.localizedDescription)"
                        isLoading = false
                    }
                    return false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error: \(error.localizedDescription)"
                isLoading = false
            }
            return false
        }
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
        print("Loading parent data for userId: \(userId)")
        // Load parent data from Firestore
        db.collection("parents").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading parent data: \(error)")
                    // Fallback to mock data
                    self?.createMockParent(userId: userId)
                    return
                }
                
                if let document = document, document.exists {
                    print("Parent document exists, loading data...")
                    // Parent data exists, load it from Firestore
                    if let data = document.data(),
                       let phoneNumber = data["phoneNumber"] as? String {
                        let parentId = UUID(uuidString: userId) ?? UUID()
                        var parent = Parent(id: parentId, phoneNumber: phoneNumber, password: "")
                        parent.isVerified = data["isVerified"] as? Bool ?? false
                        self?.currentParent = parent
                        self?.authState = .authenticated
                        print("Parent data loaded successfully: \(parent.phoneNumber)")
                        
                        // Load children for this parent
                        self?.loadChildrenForParent(parentId: parentId)
                    } else {
                        print("Parent document exists but data is invalid, using mock data")
                        // Fallback to mock data
                        self?.createMockParent(userId: userId)
                    }
                } else {
                    print("Parent document doesn't exist, creating mock parent")
                    // New parent, create profile with mock data for now
                    self?.createMockParent(userId: userId)
                }
            }
        }
    }
    
    private func loadChildrenForParent(parentId: UUID) {
        print("Loading children for parent: \(parentId)")
        
        // Get the current Firebase user to get the correct parent document ID
        guard let currentUser = auth.currentUser else {
            print("Error: No Firebase user found when loading children")
            return
        }
        
        db.collection("children")
            .whereField("parentId", isEqualTo: currentUser.uid) // Use Firebase Auth UID
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading children: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No children found for parent")
                        return
                    }
                    
                    var loadedChildren: [Child] = []
                    for document in documents {
                        let data = document.data()
                        if let name = data["name"] as? String,
                           let pin = data["pin"] as? String,
                           let parentIdString = data["parentId"] as? String {
                            
                            let childId = UUID(uuidString: document.documentID) ?? UUID()
                            var child = Child(id: childId, name: name, pin: pin, parentId: parentId)
                            child.points = data["points"] as? Int ?? 0
                            
                            loadedChildren.append(child)
                            print("Loaded child: \(name) with PIN: \(pin)")
                        }
                    }
                    
                    // Update parent with loaded children
                    self?.currentParent?.children = loadedChildren
                    self?.children = loadedChildren
                    print("Loaded \(loadedChildren.count) children for parent")
                }
            }
    }
    
    private func createMockParent(userId: String) {
        print("Creating mock parent for userId: \(userId)")
        // Create a mock parent for testing
        let parentId = UUID(uuidString: userId) ?? UUID()
        var parent = Parent(id: parentId, phoneNumber: "5551234567", password: "password123")
        parent.isVerified = true
        
        // Add sample children
        let sampleChild1 = Child(name: "Emma", pin: "1234", parentId: parent.id)
        let sampleChild2 = Child(name: "Liam", pin: "5678", parentId: parent.id)
        parent.children = [sampleChild1, sampleChild2]
        
        // Update local arrays
        children = [sampleChild1, sampleChild2]
        
        currentParent = parent
        authState = .authenticated
        print("Mock parent created successfully with \(parent.children.count) children")
    }
    
    private func loadChildData(userId: String) {
        print("🔍 Loading child data for Firebase Auth UID: \(userId)")
        
        // We need to find the child by searching for the Firebase Auth UID in the children collection
        // The Firebase Auth UID should be stored in the child document
        db.collection("children")
            .whereField("firebaseAuthUid", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error loading child data: \(error)")
                        // Fallback to mock data
                        self?.createMockChild(userId: userId)
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("❌ No child found with Firebase Auth UID: \(userId)")
                        // Fallback to mock data
                        self?.createMockChild(userId: userId)
                        return
                    }
                    
                    // Get the first (and should be only) child document
                    let document = documents[0]
                    let data = document.data()
                    
                    if let name = data["name"] as? String,
                       let pin = data["pin"] as? String,
                       let parentIdString = data["parentId"] as? String,
                       let parentId = UUID(uuidString: parentIdString) {
                        
                        let childId = UUID(uuidString: document.documentID) ?? UUID()
                        var child = Child(id: childId, name: name, pin: pin, parentId: parentId)
                        child.points = data["points"] as? Int ?? 0
                        
                        print("✅ Child data loaded successfully: \(name) with PIN: \(pin)")
                        print("🔧 Setting currentChild and authState to .authenticated")
                        self?.currentChild = child
                        self?.authState = .authenticated
                        print("🔧 Auth state updated: \(String(describing: self?.authState))")
                        print("🔧 Current child set: \(self?.currentChild?.name ?? "nil")")
                    } else {
                        print("❌ Invalid child data structure")
                        // Fallback to mock data
                        self?.createMockChild(userId: userId)
                    }
                }
            }
    }
    
    private func createMockChild(userId: String) {
        // Create a mock child for testing
        let childId = UUID(uuidString: userId) ?? UUID()
        let child = Child(id: childId, name: "Test Child", pin: "1234", parentId: UUID())
        
        currentChild = child
        authState = .authenticated
    }
    
    // MARK: - Helper Methods
} 