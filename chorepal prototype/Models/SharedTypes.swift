import SwiftUI

// MARK: - Activity Item
struct ActivityItem {
    let id: UUID
    let title: String
    let description: String
    let date: Date
    let type: ActivityType
}

enum ActivityType {
    case chore
    case reward
    
    var icon: String {
        switch self {
        case .chore: return "checkmark.circle.fill"
        case .reward: return "gift.fill"
        }
    }
} 