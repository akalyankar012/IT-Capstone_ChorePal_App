import Foundation
import Combine

class RewardService: ObservableObject {
    @Published var rewards: [Reward] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        rewards = Reward.sampleRewards
    }
    
    // MARK: - CRUD Operations
    
    func addReward(_ reward: Reward) {
        rewards.append(reward)
    }
    
    func updateReward(_ reward: Reward) {
        if let index = rewards.firstIndex(where: { $0.id == reward.id }) {
            rewards[index] = reward
        }
    }
    
    func deleteReward(_ reward: Reward) {
        rewards.removeAll { $0.id == reward.id }
    }
    
    func toggleRewardAvailability(_ reward: Reward) {
        if let index = rewards.firstIndex(where: { $0.id == reward.id }) {
            rewards[index].isAvailable.toggle()
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
        }
        
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



 