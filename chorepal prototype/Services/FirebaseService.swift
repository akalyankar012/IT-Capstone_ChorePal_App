import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        setupAuthStateListener()
    }
    
    // MARK: - Authentication State Listener
    
    private func setupAuthStateListener() {
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Phone Authentication
    
    func signInWithPhone(phoneNumber: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let result = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            // Store verification ID for later use
            UserDefaults.standard.set(result, forKey: "verificationID")
            
            await MainActor.run {
                isLoading = false
            }
            return true
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
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
        
        guard let verificationID = UserDefaults.standard.string(forKey: "verificationID") else {
            await MainActor.run {
                errorMessage = "Verification ID not found"
                isLoading = false
            }
            return false
        }
        
        do {
            let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
            let result = try await auth.signIn(with: credential)
            
            // Check if user exists in Firestore
            let userExists = try await checkUserExists(userId: result.user.uid)
            
            if !userExists {
                // Create new user document
                try await createUserDocument(userId: result.user.uid, phoneNumber: result.user.phoneNumber ?? "")
            }
            
            await MainActor.run {
                isLoading = false
            }
            return true
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            return false
        }
    }
    
    // MARK: - User Management
    
    private func checkUserExists(userId: String) async throws -> Bool {
        let document = try await db.collection("users").document(userId).getDocument()
        return document.exists
    }
    
    private func createUserDocument(userId: String, phoneNumber: String) async throws {
        let userData: [String: Any] = [
            "id": userId,
            "phoneNumber": phoneNumber,
            "createdAt": Timestamp(),
            "isVerified": true
        ]
        
        try await db.collection("users").document(userId).setData(userData)
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try auth.signOut()
            UserDefaults.standard.removeObject(forKey: "verificationID")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
} 