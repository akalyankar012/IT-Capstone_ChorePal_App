import Foundation

enum UserRole {
    case parent
    case child
    case none
}

struct Chore: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var points: Int
    var dueDate: Date
    var isCompleted: Bool
    var isRequired: Bool
    var createdAt: Date
    
    static let sampleChores = [
        Chore(title: "Take Out Trash", 
              description: "Empty all trash bins and replace bags", 
              points: 5, 
              dueDate: Date().addingTimeInterval(86400), 
              isCompleted: false,
              isRequired: true,
              createdAt: Date()),
        Chore(title: "Make Bed", 
              description: "Straighten sheets and arrange pillows", 
              points: 5, 
              dueDate: Date().addingTimeInterval(86400), 
              isCompleted: false,
              isRequired: false,
              createdAt: Date()),
        Chore(title: "Clean Rooms", 
              description: "Pick up toys and vacuum floor", 
              points: 5, 
              dueDate: Date().addingTimeInterval(86400), 
              isCompleted: false,
              isRequired: false,
              createdAt: Date())
    ]
}

struct Reward: Identifiable {
    let id = UUID()
    var name: String
    var points: Int
    var purchasedAt: Date?
    
    static let sampleRewards = [
        Reward(name: "Candy Bar", points: 15, purchasedAt: nil),
        Reward(name: "Movie Ticket", points: 55, purchasedAt: nil),
        Reward(name: "Free \"Skip Chore\" Pass", points: 200, purchasedAt: nil)
    ]
}

struct CompletedChore: Identifiable {
    let id = UUID()
    let choreId: UUID
    let title: String
    let points: Int
    let completedAt: Date
}

struct RewardHistory: Identifiable {
    let id = UUID()
    let name: String
    let points: Int
    let purchasedAt: Date
}

class AchievementManager: ObservableObject {
    @Published var completedChores: [CompletedChore] = []
    @Published var rewardHistory: [RewardHistory] = []
    
    var choresCompleted: Int {
        completedChores.count
    }
    
    var lifetimePoints: Int {
        completedChores.reduce(0) { $0 + $1.points }
    }
    
    var currentPoints: Int {
        lifetimePoints - pointsSpent
    }
    
    var pointsSpent: Int {
        rewardHistory.reduce(0) { $0 + $1.points }
    }
    
    func addCompletedChore(_ chore: Chore) {
        let completedChore = CompletedChore(
            choreId: chore.id,
            title: chore.title,
            points: chore.points,
            completedAt: Date()
        )
        completedChores.append(completedChore)
    }
    
    func removeCompletedChore(_ chore: Chore) {
        completedChores.removeAll { $0.choreId == chore.id }
    }
    
    func deductPoints(name: String, points: Int) {
        guard points <= currentPoints else { return }
        let reward = RewardHistory(name: name, points: points, purchasedAt: Date())
        rewardHistory.append(reward)
    }
} 