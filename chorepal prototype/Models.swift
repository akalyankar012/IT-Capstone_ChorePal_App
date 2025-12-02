import Foundation 

enum UserRole {
    case parent
    case child
    case none
}

// MARK: - Authentication Models
struct Parent: Identifiable, Codable {
    var id: UUID
    var phoneNumber: String
    var password: String
    var isVerified: Bool = false
    var children: [Child] = []
    var createdAt: Date = Date()
    
    init(phoneNumber: String, password: String) {
        self.id = UUID()
        self.phoneNumber = phoneNumber
        self.password = password
    }
    
    init(id: UUID, phoneNumber: String, password: String) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.password = password
    }
}

struct Child: Identifiable, Codable {
    var id: UUID
    var name: String
    var pin: String
    var parentId: UUID
    var points: Int = 0
    var totalPointsEarned: Int = 0 // Track total points earned from chores
    var avatar: String = "boy" // Avatar selection (boy/girl)
    var createdAt: Date = Date()
    
    init(name: String, pin: String, parentId: UUID, avatar: String = "boy") {
        self.id = UUID()
        self.name = name
        self.pin = pin
        self.parentId = parentId
        self.avatar = avatar
    }
    
    init(id: UUID, name: String, pin: String, parentId: UUID, avatar: String = "boy") {
        self.id = id
        self.name = name
        self.pin = pin
        self.parentId = parentId
        self.avatar = avatar
    }
}

enum AuthState {
    case none
    case signUp
    case verifyPhone
    case signIn
    case authenticated
}

enum RewardCategory: String, CaseIterable, Codable {
    case food = "Food & Treats"
    case entertainment = "Entertainment"
    case privileges = "Privileges"
    case toys = "Toys & Games"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .entertainment: return "tv"
        case .privileges: return "star"
        case .toys: return "gamecontroller"
        case .other: return "gift"
        }
    }
    
    var color: String {
        switch self {
        case .food: return "#FF6B6B"
        case .entertainment: return "#4ECDC4"
        case .privileges: return "#45B7D1"
        case .toys: return "#96CEB4"
        case .other: return "#FFEAA7"
        }
    }
}

enum RewardStatus: String, CaseIterable {
    case all = "All"
    case available = "Available"
    case purchased = "Purchased"
    case unavailable = "Unavailable"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .available: return "checkmark.circle"
        case .purchased: return "bag"
        case .unavailable: return "xmark.circle"
        }
    }
}

// MARK: - Existing Models
struct Chore: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var points: Int
    var dueDate: Date
    var isCompleted: Bool
    var isRequired: Bool
    var assignedToChildId: UUID?
    var parentId: UUID?  // ID of the parent who created this chore
    var createdAt: Date
    var requiresPhotoProof: Bool = true
    var photoProofStatus: PhotoProofStatus?
    var parentFeedback: String?
    
    static let sampleChores = [
        Chore(title: "Take Out Trash", 
              description: "Empty all trash bins and replace bags", 
              points: 5, 
              dueDate: Date().addingTimeInterval(86400), 
              isCompleted: false,
              isRequired: true,
              assignedToChildId: nil,
              createdAt: Date()),
        Chore(title: "Make Bed", 
              description: "Straighten sheets and arrange pillows", 
              points: 5, 
              dueDate: Date().addingTimeInterval(86400), 
              isCompleted: false,
              isRequired: false,
              assignedToChildId: nil,
              createdAt: Date()),
        Chore(title: "Clean Rooms", 
              description: "Pick up toys and vacuum floor", 
              points: 5, 
              dueDate: Date().addingTimeInterval(86400), 
              isCompleted: false,
              isRequired: false,
              assignedToChildId: nil,
              createdAt: Date())
    ]
}

struct Reward: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var points: Int
    var category: RewardCategory
    var isAvailable: Bool
    var purchasedAt: Date?
    var purchasedByChildId: UUID?
    var parentId: UUID?
    var createdAt: Date
    
    init(name: String, description: String = "", points: Int, category: RewardCategory = .other, isAvailable: Bool = true, purchasedAt: Date? = nil, purchasedByChildId: UUID? = nil, parentId: UUID? = nil) {
        self.name = name
        self.description = description
        self.points = points
        self.category = category
        self.isAvailable = isAvailable
        self.purchasedAt = purchasedAt
        self.purchasedByChildId = purchasedByChildId
        self.parentId = parentId
        self.createdAt = Date()
    }
    
    static let sampleRewards = [
        Reward(name: "Candy Bar", description: "Choose your favorite candy", points: 15, category: .food),
        Reward(name: "Movie Ticket", description: "Watch a movie of your choice", points: 55, category: .entertainment),
        Reward(name: "Skip Chore Pass", description: "Skip one chore without penalty", points: 200, category: .privileges),
        Reward(name: "Ice Cream", description: "Get ice cream from your favorite place", points: 25, category: .food),
        Reward(name: "Video Game Time", description: "Extra 30 minutes of video game time", points: 30, category: .entertainment),
        Reward(name: "New Toy", description: "Pick a toy under $20", points: 100, category: .toys),
        Reward(name: "Stay Up Late", description: "Stay up 30 minutes past bedtime", points: 75, category: .privileges),
        Reward(name: "Pizza Night", description: "Choose dinner for the family", points: 150, category: .food)
    ]
}

struct CompletedChore: Identifiable {
    var id = UUID()
    let choreId: UUID
    let title: String
    let points: Int
    let completedAt: Date
}

struct RewardHistory: Identifiable {
    var id = UUID()
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
 