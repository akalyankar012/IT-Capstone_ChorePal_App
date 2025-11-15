import Foundation
import Combine
import Firebase
import FirebaseFirestore

class RewardService: ObservableObject {
    @Published var rewards: [Reward] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        // Don't load data immediately - wait for authentication
        // Data will be loaded when user signs in
        
        // Listen for authentication events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadDataOnAuthentication),
            name: .userAuthenticated,
            object: nil
        )
    }
    
    @objc private func loadDataOnAuthentication() {
        loadRewardsFromFirestore()
    }
    
    private func loadSampleData() {
        rewards = Reward.sampleRewards
    }
    
    // MARK: - CRUD Operations
    
    func addReward(_ reward: Reward) {
        rewards.append(reward)
        // Save to Firestore
        Task {
            await updateRewardInFirestore(reward)
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
    
    private func loadRewardsFromFirestore() {
        Task {
            await loadRewardsFromFirestoreAsync()
        }
    }
    
    private func loadRewardsFromFirestoreAsync() async {
        do {
            let snapshot = try await db.collection("rewards").getDocuments()
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
                
                reward.createdAt = createdAtTimestamp.dateValue()
                loadedRewards.append(reward)
            }
            
            DispatchQueue.main.async {
                self.rewards = loadedRewards.isEmpty ? Reward.sampleRewards : loadedRewards
                print("✅ Loaded \(loadedRewards.count) rewards from Firestore")
            }
            
        } catch {
            print("❌ Error loading rewards from Firestore: \(error)")
            DispatchQueue.main.async {
                self.rewards = Reward.sampleRewards
            }
        }
    }
    
    private func updateRewardInFirestore(_ reward: Reward) async {
        do {
            var rewardData: [String: Any] = [
                "name": reward.name,
                "description": reward.description,
                "points": reward.points,
                "category": reward.category.rawValue,
                "isAvailable": reward.isAvailable,
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
            print("✅ Reward updated in Firestore: \(reward.name)")
            
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



 