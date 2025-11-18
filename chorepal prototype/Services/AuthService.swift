import Foundation
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - Notification Names
extension Notification.Name {
    static let childPointsUpdated = Notification.Name("childPointsUpdated")
    static let choreUpdated = Notification.Name("choreUpdated")
    static let rewardUpdated = Notification.Name("rewardUpdated")
    static let userAuthenticated = Notification.Name("userAuthenticated")
}

class AuthService: ObservableObject {
    @Published var currentParent: Parent?
    @Published var currentChild: Child?
    @Published var authState: AuthState = .none
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    


    // Real-time listeners
    private var childrenListener: ListenerRegistration?
    private var choresListener: ListenerRegistration?
    private var rewardsListener: ListenerRegistration?
    
    // Temporary storage for testing
    private var parents: [Parent] = []
    private var children: [Child] = []
    
    init() {
        // Add sample data for testing
        setupSampleData()
        
        // Listen for Firebase auth state changes
        _ = auth.addStateDidChangeListener { [weak self] _, user in
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
        let sampleChild1 = Child(name: "Emma", pin: "1234", parentId: sampleParent.id, avatar: "girl")
        let sampleChild2 = Child(name: "Liam", pin: "5678", parentId: sampleParent.id, avatar: "boy")
        
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
        guard currentParent != nil else {
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
                "totalPointsEarned": child.totalPointsEarned,
                "avatar": child.avatar,
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
        // Remove from local arrays
        children.removeAll { $0.id == child.id }
        currentParent?.children.removeAll { $0.id == child.id }
        
        // Update the published property to trigger UI refresh
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        // Delete from Firestore
        Task {
            await deleteChildFromFirestore(child)
        }
    }
    
    private func deleteChildFromFirestore(_ child: Child) async {
        guard let currentUser = auth.currentUser else {
            print("❌ Error: No Firebase user found when deleting child")
            return
        }
        
        do {
            // Use a batch write to ensure atomic deletion
            let batch = db.batch()
            
            // Delete child document
            let childRef = db.collection("children").document(child.id.uuidString)
            batch.deleteDocument(childRef)
            
            // Remove child reference from parent document
            let parentRef = db.collection("parents").document(currentUser.uid)
            batch.updateData([
                "children": FieldValue.arrayRemove([child.id.uuidString])
            ], forDocument: parentRef)
            
            // Commit the batch
            try await batch.commit()
            print("✅ Child deleted from Firestore: \(child.name)")
            print("✅ Child reference removed from parent document")
            
            // Force refresh the parent data from Firestore
            await refreshParentData()
            
        } catch {
            print("❌ Error deleting child from Firestore: \(error)")
            // Revert local changes if Firestore deletion failed
            await MainActor.run {
                // Re-add the child to local arrays if deletion failed
                if !self.children.contains(where: { $0.id == child.id }) {
                    self.children.append(child)
                    self.currentParent?.children.append(child)
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    // MARK: - Data Refresh
    
    private func refreshParentData() async {
        guard let currentUser = auth.currentUser else { return }
        
        do {
            let parentDoc = try await db.collection("parents").document(currentUser.uid).getDocument()
            
            if let parentData = parentDoc.data() {
                let childrenIds = parentData["children"] as? [String] ?? []
                
                // Fetch all children documents
                var fetchedChildren: [Child] = []
                for childId in childrenIds {
                    let childDoc = try await db.collection("children").document(childId).getDocument()
                    if let childData = childDoc.data() {
                        let childIdUUID = UUID(uuidString: childId) ?? UUID()
                        let parentIdUUID = UUID(uuidString: parentData["id"] as? String ?? "") ?? UUID()
                        let childName = childData["name"] as? String ?? ""
                        let childPin = childData["pin"] as? String ?? ""
                        let childPoints = childData["points"] as? Int ?? 0
                        let childTotalPoints = childData["totalPointsEarned"] as? Int ?? 0
                        
                        var child = Child(
                            id: childIdUUID,
                            name: childName,
                            pin: childPin,
                            parentId: parentIdUUID
                        )
                        child.points = childPoints
                        child.totalPointsEarned = childTotalPoints
                        fetchedChildren.append(child)
                    }
                }
                
                // Update local data
                let finalChildren = fetchedChildren
                await MainActor.run {
                    self.children = finalChildren
                    self.currentParent?.children = finalChildren
                    self.objectWillChange.send()
                }
                
                print("✅ Parent data refreshed from Firestore")
            }
        } catch {
            print("❌ Error refreshing parent data: \(error)")
        }
    }
    
    // MARK: - Child Points Management
    
    func awardPointsToChild(childId: UUID, points: Int) {
        if let childIndex = children.firstIndex(where: { $0.id == childId }) {
            children[childIndex].points += points
            children[childIndex].totalPointsEarned += points
        }
        
        if let childIndex = currentParent?.children.firstIndex(where: { $0.id == childId }) {
            currentParent?.children[childIndex].points += points
            currentParent?.children[childIndex].totalPointsEarned += points
        }
        
        // Update current child if it's the same child
        if currentChild?.id == childId {
            currentChild?.points += points
            currentChild?.totalPointsEarned += points
        }
        
        // Save points update to Firestore
        Task {
            await updateChildPointsInFirestore(childId: childId, points: children.first(where: { $0.id == childId })?.points ?? 0, totalPointsEarned: children.first(where: { $0.id == childId })?.totalPointsEarned ?? 0)
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
        
        // Save points update to Firestore
        Task {
            await updateChildPointsInFirestore(childId: childId, points: children.first(where: { $0.id == childId })?.points ?? 0, totalPointsEarned: children.first(where: { $0.id == childId })?.totalPointsEarned ?? 0)
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
        
        // Save points update to Firestore
        Task {
            await updateChildPointsInFirestore(childId: childId, points: points, totalPointsEarned: children.first(where: { $0.id == childId })?.totalPointsEarned ?? 0)
        }
    }
    
    func getChildrenForCurrentParent() -> [Child] {
        return currentParent?.children ?? []
    }
    
    // MARK: - Firestore Points Management
    
    private func updateChildPointsInFirestore(childId: UUID, points: Int, totalPointsEarned: Int) async {
        do {
            try await db.collection("children").document(childId.uuidString).updateData([
                "points": points,
                "totalPointsEarned": totalPointsEarned,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            print("✅ Child points updated in Firestore: \(childId) -> \(points) points, \(totalPointsEarned) total earned")
            
            // Post notification to refresh parent dashboard
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .childPointsUpdated, object: nil)
            }
            
        } catch {
            print("❌ Error updating child points in Firestore: \(error)")
        }
    }
    
    func refreshChildrenData(parentId: UUID) {
        loadChildrenForParent(parentId: parentId)
    }
    
    // MARK: - Data Migration
    
    private func migrateChildDataIfNeeded(_ child: Child) async {
        // Check if child needs migration (has points but no totalPointsEarned)
        if child.points > 0 && child.totalPointsEarned == 0 {
            print("🔄 Migrating child data: \(child.name) - setting totalPointsEarned to \(child.points)")
            
            // Update the child's totalPointsEarned to match their current points
            await updateChildPointsInFirestore(
                childId: child.id, 
                points: child.points, 
                totalPointsEarned: child.points
            )
        }
    }
    
    func addChild(name: String, avatar: String = "boy") async -> String {
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
        
        let newChild = Child(name: name, pin: pin, parentId: parent.id, avatar: avatar)
        
        await MainActor.run {
            children.append(newChild)
            currentParent?.children.append(newChild)
            isLoading = false
        }
        
        // Save child to Firestore
        await saveChildToFirestore(newChild)
        
        // Save avatar to local store for quick access
        AvatarStore.setChildAvatarName(avatar, for: newChild.id)
        
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
            // Search for child in Firestore by PIN (no Firebase Auth required)
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
            let childId = UUID(uuidString: document.documentID) ?? UUID()
            let parentId = UUID(uuidString: parentIdString) ?? UUID()
            let avatar = data["avatar"] as? String ?? "boy"
            var child = Child(id: childId, name: name, pin: childPin, parentId: parentId, avatar: avatar)
            child.points = data["points"] as? Int ?? 0
            child.totalPointsEarned = data["totalPointsEarned"] as? Int ?? 0
            
            // Save avatar to local store for quick access
            AvatarStore.setChildAvatarName(avatar, for: childId)
            
            print("✅ Child found: \(name) with PIN: \(childPin)")
            print("📊 Child points: \(child.points), Total earned: \(child.totalPointsEarned)")
            
            // Set the current child and update auth state
            await MainActor.run {
                self.currentChild = child
                self.authState = .authenticated
                self.isLoading = false
            }
            
            // Trigger data loading for authenticated child
            NotificationCenter.default.post(name: .userAuthenticated, object: nil)
            
            print("✅ Child authentication successful")
            return true
            
        } catch {
            print("❌ Error during child authentication: \(error)")
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
            // If we have a current child, just clear the child data (no Firebase Auth needed)
            if currentChild != nil {
                currentChild = nil
                authState = .none
                print("✅ Child signed out successfully")
                return
            }
            
            // For parents, sign out from Firebase Auth
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
            // Clear any cached data first to prevent stale data
            children.removeAll()
            currentParent = nil
            
            loadParentData(userId: user.uid)
            setupRealTimeListeners() // Setup real-time listeners for parent
            
            // Trigger data loading for authenticated parent
            NotificationCenter.default.post(name: .userAuthenticated, object: nil)
        } else {
            // This is a child user - but we're not using Firebase Auth for children anymore
            // Children are authenticated via PIN only
            print("⚠️ Child Firebase Auth detected - this shouldn't happen with new PIN-only auth")
        }
    }
    
    private func handleSignOut() {
        cleanupRealTimeListeners() // Cleanup listeners before signing out
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
                            let avatar = data["avatar"] as? String ?? "boy"
                            var child = Child(id: childId, name: name, pin: pin, parentId: parentId, avatar: avatar)
                            child.points = data["points"] as? Int ?? 0
                            child.totalPointsEarned = data["totalPointsEarned"] as? Int ?? 0
                            print("🔍 Loading child from Firestore: \(name) - Points: \(child.points), Total Earned: \(child.totalPointsEarned), Avatar: \(avatar)")
                            
                            // Save avatar to local store for quick access
                            AvatarStore.setChildAvatarName(avatar, for: childId)
                            
                            loadedChildren.append(child)
                            print("Loaded child: \(name) with PIN: \(pin)")
                            
                            // Migrate child data if needed
                            Task {
                                await self?.migrateChildDataIfNeeded(child)
                            }
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
        let sampleChild1 = Child(name: "Emma", pin: "1234", parentId: parent.id, avatar: "girl")
        let sampleChild2 = Child(name: "Liam", pin: "5678", parentId: parent.id, avatar: "boy")
        parent.children = [sampleChild1, sampleChild2]
        
        // Update local arrays
        children = [sampleChild1, sampleChild2]
        
        currentParent = parent
        authState = .authenticated
        print("Mock parent created successfully with \(parent.children.count) children")
    }
    
    // Child data loading is now handled directly in signInChild method
    // No separate loadChildData method needed for PIN-based authentication
    
    private func loadChildFromDocument(_ document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        print("🔍 Loading child from document with data: \(data)")
        
        // Handle both string and integer PIN values
        let pin: String
        if let pinString = data["pin"] as? String {
            pin = pinString
        } else if let pinNumber = data["pin"] as? Int {
            pin = String(pinNumber)
        } else {
            print("❌ PIN field not found or invalid type")
            return
        }
        
        if let name = data["name"] as? String,
           let parentIdString = data["parentId"] as? String {
            
            // The parentId in Firestore is stored as a Firebase Auth UID (string), not a UUID
            // We need to handle this differently
            let parentId: UUID
            if let uuid = UUID(uuidString: parentIdString) {
                parentId = uuid
            } else {
                // If it's not a valid UUID, create a new UUID for the parent
                // This is a fallback for when parentId is a Firebase Auth UID
                parentId = UUID()
                print("⚠️ ParentId is not a valid UUID, using generated UUID: \(parentId)")
            }
            
            let childId = UUID(uuidString: document.documentID) ?? UUID()
            let avatar = data["avatar"] as? String ?? "boy"
            var child = Child(id: childId, name: name, pin: pin, parentId: parentId, avatar: avatar)
            child.points = data["points"] as? Int ?? 0
            child.totalPointsEarned = data["totalPointsEarned"] as? Int ?? 0
            print("🔍 Loading child from document: \(name) - Points: \(child.points), Total Earned: \(child.totalPointsEarned), Avatar: \(avatar)")
            
            // Save avatar to local store for quick access
            AvatarStore.setChildAvatarName(avatar, for: childId)
            
            print("✅ Child data loaded successfully: \(name) with PIN: \(pin)")
            print("🔧 Setting currentChild and authState to .authenticated")
            currentChild = child
            authState = .authenticated
            print("🔧 Auth state updated: \(String(describing: authState))")
            print("🔧 Current child set: \(currentChild?.name ?? "nil")")
        } else {
            print("❌ Invalid child data structure - missing required fields")
            print("🔍 Name: \(data["name"] ?? "nil")")
            print("🔍 ParentId: \(data["parentId"] ?? "nil")")
        }
    }
    
    // Mock child creation no longer needed with PIN-based authentication
    
    // MARK: - Helper Methods
    
    // MARK: - Real-time Listeners
    
    private func setupRealTimeListeners() {
        guard let currentUser = auth.currentUser else { return }
        
        // Listen for children changes
        childrenListener = db.collection("children")
            .whereField("parentId", isEqualTo: currentUser.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error listening for children changes: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    var loadedChildren: [Child] = []
                    for document in documents {
                        let data = document.data()
                        if let name = data["name"] as? String,
                           let pin = data["pin"] as? String,
                           let parentIdString = data["parentId"] as? String {
                            
                            let childId = UUID(uuidString: document.documentID) ?? UUID()
                            let avatar = data["avatar"] as? String ?? "boy"
                            var child = Child(id: childId, name: name, pin: pin, parentId: UUID(uuidString: parentIdString) ?? UUID(), avatar: avatar)
                            child.points = data["points"] as? Int ?? 0
                            child.totalPointsEarned = data["totalPointsEarned"] as? Int ?? 0
                            
                            // Save avatar to local store for quick access
                            AvatarStore.setChildAvatarName(avatar, for: childId)
                            
                            loadedChildren.append(child)
                        }
                    }
                    
                    // Update parent with real-time children data
                    self?.currentParent?.children = loadedChildren
                    self?.children = loadedChildren
                    print("🔄 Real-time children update: \(loadedChildren.count) children")
                }
            }
    }
    
    private func cleanupRealTimeListeners() {
        childrenListener?.remove()
        choresListener?.remove()
        rewardsListener?.remove()
        childrenListener = nil
        choresListener = nil
        rewardsListener = nil
    }
} 