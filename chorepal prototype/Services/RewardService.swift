import Foundation
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

class RewardService: ObservableObject {
    @Published var rewards: [Reward] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    private var storedParentId: String?
    
    init() {
        // Don't load data immediately - wait for authentication
        // Data will be loaded when user signs in
        
        // Listen for authentication events (both parent and child)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadDataOnAuthentication(_:)),
            name: .userAuthenticated,
            object: nil
        )
    }
    
    @objc private func loadDataOnAuthentication(_ notification: Notification) {
        // Get parentId from notification userInfo if available (for child logins)
        if let parentIdString = notification.userInfo?["parentId"] as? String {
            storedParentId = parentIdString
            loadRewardsFromFirestore(forParentId: parentIdString)
        } else {
            // Parent login (has Firebase Auth) or no parentId in notification
            loadRewardsFromFirestore()
        }
    }
    
    // Method to load rewards for a specific parent ID (used when child logs in)
    func loadRewardsForParent(parentId: String) {
        storedParentId = parentId
        loadRewardsFromFirestore(forParentId: parentId)
    }
    
    private func loadSampleData() {
        rewards = Reward.sampleRewards
    }
    
    // MARK: - CRUD Operations
    
    func addReward(_ reward: Reward) {
        // Get current user's parent ID from Firebase Auth
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No authenticated user found when adding reward")
            return
        }
        
        // Create a copy of the reward with parentId set (store Firebase Auth UID as string for parentId)
        var rewardWithParent = reward
        // For now, store the parentId as a UUID placeholder - it will be saved as Firebase Auth UID string in Firestore
        rewardWithParent.parentId = UUID()
        
        rewards.append(rewardWithParent)
        // Save to Firestore (will save parentId as Firebase Auth UID string)
        Task {
            await updateRewardInFirestore(rewardWithParent)
        }
    }
    
    func updateReward(_ reward: Reward) {
        if let index = rewards.firstIndex(where: { $0.id == reward.id }) {
            rewards[index] = reward
            // Save to Firestore
            Task {
                await updateRewardInFirestore(reward)
            }
        }
    }
    
    func deleteReward(_ reward: Reward) {
        rewards.removeAll { $0.id == reward.id }
        // Delete from Firestore
        Task {
            await deleteRewardFromFirestore(reward)
        }
    }
    
    func toggleRewardAvailability(_ reward: Reward) {
        if let index = rewards.firstIndex(where: { $0.id == reward.id }) {
            rewards[index].isAvailable.toggle()
            // Save to Firestore
            Task {
                await updateRewardInFirestore(rewards[index])
            }
        }
    }
    
    // MARK: - Reward Purchase
    
    func purchaseReward(_ reward: Reward, for childId: UUID, authService: AuthService) -> Bool {
        guard reward.isAvailable else { return false }
        
        // Get child's current points
        let child = authService.getChildrenForCurrentParent().first { $0.id == childId }
        guard let child = child, child.points >= reward.points else { return false }
        
        // Deduct points from child
        let newPoints = child.points - reward.points
        authService.updateChildPoints(childId: childId, points: newPoints)
        
        // Mark reward as purchased
        if let index = rewards.firstIndex(where: { $0.id == reward.id }) {
            rewards[index].purchasedAt = Date()
            rewards[index].purchasedByChildId = childId
            
            // Save reward update to Firestore and notify parent
            Task {
                await updateRewardInFirestore(rewards[index])
                
                // Send notification to parent about reward purchase
                if let parentId = authService.currentParent?.id {
                    let notificationService = NotificationService()
                    await notificationService.createNotification(
                        userId: parentId,
                        type: .rewardRedeemed,
                        title: "Reward Purchased! 🎁",
                        message: "\(child.name) purchased \"\(reward.name)\" for \(reward.points) points",
                        choreId: nil
                    )
                    print("✅ Notification sent to parent \(parentId) for reward purchase: \(reward.name)")
                }
            }
        }
        
        return true
    }
    
    func redeemReward(_ reward: Reward, byChild child: Child, authService: AuthService) -> Bool {
        guard reward.isAvailable else { return false }
        guard child.points >= reward.points else { return false }
        
        // Deduct points from child
        authService.deductPointsFromChild(childId: child.id, points: reward.points)
        
        // Mark reward as purchased
        if let index = rewards.firstIndex(where: { $0.id == reward.id }) {
            rewards[index].purchasedAt = Date()
            rewards[index].purchasedByChildId = child.id
            rewards[index].isAvailable = false // Mark as unavailable after purchase
            
            // Save reward update to Firestore
            Task {
                await updateRewardInFirestore(rewards[index])
                
                // Send notification to parent about reward redemption
                if let parentId = authService.currentParent?.id {
                    let notificationService = NotificationService()
                    await notificationService.createNotification(
                        userId: parentId,
                        type: .rewardRedeemed,
                        title: "Reward Redeemed! 🎁",
                        message: "\(child.name) redeemed \"\(reward.name)\" for \(reward.points) points",
                        choreId: nil
                    )
                    print("✅ Notification sent to parent \(parentId) for reward redemption: \(reward.name)")
                }
            }
        }
        
        print("✅ Reward redeemed: \(reward.name) for \(child.name) (-\(reward.points) points)")
        return true
    }
    
    // MARK: - Queries
    
    func getAvailableRewards() -> [Reward] {
        return rewards.filter { $0.isAvailable && $0.purchasedAt == nil }
    }
    
    func getPurchasedRewards() -> [Reward] {
        return rewards.filter { $0.purchasedAt != nil }
    }
    
    func getRewardsForChild(_ childId: UUID) -> [Reward] {
        return rewards.filter { $0.purchasedByChildId == childId }
    }
    
    func getRewardsByCategory(_ category: RewardCategory) -> [Reward] {
        return rewards.filter { $0.category == category }
    }
    
    // MARK: - Firestore Operations
    
    private func loadRewardsFromFirestore(forParentId: String? = nil) {
        Task {
            await loadRewardsFromFirestoreAsync(forParentId: forParentId)
        }
    }
    
    private func loadRewardsFromFirestoreAsync(forParentId: String? = nil) async {
        do {
            // Get parent ID - either from parameter, Firebase Auth (parent), or stored parentId (child)
            var parentIdToQuery: String?
            
            if let forParentId = forParentId {
                // Explicit parent ID provided (from child login)
                parentIdToQuery = forParentId
                print("📋 Loading rewards for specified parent: \(parentIdToQuery ?? "nil")")
            } else if let currentUser = Auth.auth().currentUser {
                // Parent is logged in via Firebase Auth
                parentIdToQuery = currentUser.uid
                print("📋 Loading rewards for parent (Firebase Auth): \(parentIdToQuery ?? "nil")")
            } else if let storedParentId = storedParentId {
                // Use stored parent ID (from previous child login)
                parentIdToQuery = storedParentId
                print("📋 Loading rewards for stored parent ID: \(parentIdToQuery ?? "nil")")
            } else {
                print("❌ Could not determine parent ID for reward loading")
                DispatchQueue.main.async {
                    self.rewards = []
                }
                return
            }
            
            guard let parentId = parentIdToQuery else {
                print("❌ No parent ID found for reward loading")
                DispatchQueue.main.async {
                    self.rewards = []
                }
                return
            }
            
            // Filter rewards by parentId (using Firebase Auth UID string)
            let snapshot = try await db.collection("rewards")
                .whereField("parentId", isEqualTo: parentId)
                .getDocuments()
            
            var loadedRewards: [Reward] = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                guard let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let points = data["points"] as? Int,
                      let categoryString = data["category"] as? String,
                      let category = RewardCategory(rawValue: categoryString),
                      let isAvailable = data["isAvailable"] as? Bool,
                      let createdAtTimestamp = data["createdAt"] as? Timestamp else {
                    print("❌ Invalid reward data in document: \(document.documentID)")
                    continue
                }
                
                var reward = Reward(
                    name: name,
                    description: description,
                    points: points,
                    category: category,
                    isAvailable: isAvailable
                )
                
                // Handle optional fields
                if let purchasedAtTimestamp = data["purchasedAt"] as? Timestamp {
                    reward.purchasedAt = purchasedAtTimestamp.dateValue()
                }
                
                if let purchasedByChildIdString = data["purchasedByChildId"] as? String,
                   let purchasedByChildId = UUID(uuidString: purchasedByChildIdString) {
                    reward.purchasedByChildId = purchasedByChildId
                }
                
                // Load parentId if it exists (parentId is stored as Firebase Auth UID string)
                // We'll use it for filtering, but don't need to convert to UUID since we filter by string
                if let _ = data["parentId"] as? String {
                    // ParentId exists in Firestore (as Firebase Auth UID string)
                    // We'll use it for filtering in the query above
                }
                
                reward.createdAt = createdAtTimestamp.dateValue()
                loadedRewards.append(reward)
            }
            
            DispatchQueue.main.async {
                self.rewards = loadedRewards
                print("✅ Loaded \(loadedRewards.count) rewards from Firestore for parent \(parentId)")
            }
            
        } catch {
            print("❌ Error loading rewards from Firestore: \(error)")
            DispatchQueue.main.async {
                self.rewards = []
            }
        }
    }
    
    private func updateRewardInFirestore(_ reward: Reward) async {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                print("❌ No authenticated user found for reward update")
                return
            }
            
            var rewardData: [String: Any] = [
                "name": reward.name,
                "description": reward.description,
                "points": reward.points,
                "category": reward.category.rawValue,
                "isAvailable": reward.isAvailable,
                "parentId": currentUser.uid, // Always set parentId to current user
                "createdAt": Timestamp(date: reward.createdAt),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            if let purchasedAt = reward.purchasedAt {
                rewardData["purchasedAt"] = Timestamp(date: purchasedAt)
            }
            
            if let purchasedByChildId = reward.purchasedByChildId {
                rewardData["purchasedByChildId"] = purchasedByChildId.uuidString
            }
            
            try await db.collection("rewards").document(reward.id.uuidString).setData(rewardData, merge: true)
            print("✅ Reward updated in Firestore: \(reward.name) for parent \(currentUser.uid)")
            
        } catch {
            print("❌ Error updating reward in Firestore: \(error)")
        }
    }
    
    private func deleteRewardFromFirestore(_ reward: Reward) async {
        do {
            try await db.collection("rewards").document(reward.id.uuidString).delete()
            print("✅ Reward deleted from Firestore: \(reward.name)")
            
        } catch {
            print("❌ Error deleting reward from Firestore: \(error)")
        }
    }
    
    // MARK: - Statistics
    
    func getTotalRewards() -> Int {
        return rewards.count
    }
    
    func getAvailableRewardsCount() -> Int {
        return getAvailableRewards().count
    }
    
    func getPurchasedRewardsCount() -> Int {
        return getPurchasedRewards().count
    }
    
    func getTotalPointsSpent() -> Int {
        return getPurchasedRewards().reduce(0) { $0 + $1.points }
    }
    
    // MARK: - Validation
    
    func validateReward(_ reward: Reward) -> Bool {
        return !reward.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               reward.points > 0 &&
               reward.points <= 1000
    }
    
    // MARK: - Search and Filter
    
    func searchRewards(query: String) -> [Reward] {
        if query.isEmpty {
            return rewards
        }
        
        return rewards.filter { reward in
            reward.name.localizedCaseInsensitiveContains(query) ||
            reward.description.localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterRewards(by status: RewardStatus) -> [Reward] {
        switch status {
        case .all:
            return rewards
        case .available:
            return getAvailableRewards()
        case .purchased:
            return getPurchasedRewards()
        case .unavailable:
            return rewards.filter { !$0.isAvailable }
        }
    }
}



 