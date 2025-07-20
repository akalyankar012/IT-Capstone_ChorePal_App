import SwiftUI

// MARK: - Theme Manager
enum Theme: String {
    case light, dark
    
    var systemName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

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