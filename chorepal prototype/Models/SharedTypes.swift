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

// UI compatibility
typealias AppTheme = Theme
extension Theme { var icon: String { systemName } }

// Child avatar enum used by updated UI
enum ChildAvatar: String, CaseIterable, Codable {
    case boy
    case girl
    
    var displayName: String {
        switch self { case .boy: return "Boy"; case .girl: return "Girl" }
    }
    
    var fallbackIcon: String {
        switch self { case .boy: return "person.fill"; case .girl: return "person.fill" }
    }
}
