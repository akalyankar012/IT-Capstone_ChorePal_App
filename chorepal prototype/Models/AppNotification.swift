import Foundation
import SwiftUI

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case taskCreated
    case taskDueSoon
    case taskOverdue
    case photoSubmitted
    case photoApproved
    case photoRejected
    case pointsAwarded
    case rewardRedeemed
    
    var icon: String {
        switch self {
        case .taskCreated: return "plus.circle.fill"
        case .taskDueSoon: return "clock.fill"
        case .taskOverdue: return "exclamationmark.triangle.fill"
        case .photoSubmitted: return "photo.fill"
        case .photoApproved: return "checkmark.circle.fill"
        case .photoRejected: return "xmark.circle.fill"
        case .pointsAwarded: return "star.fill"
        case .rewardRedeemed: return "gift.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .taskCreated: return .blue
        case .taskDueSoon: return .orange
        case .taskOverdue: return .red
        case .photoSubmitted: return .purple
        case .photoApproved: return .green
        case .photoRejected: return .red
        case .pointsAwarded: return .yellow
        case .rewardRedeemed: return .purple
        }
    }
    
    var displayName: String {
        switch self {
        case .taskCreated: return "New Task"
        case .taskDueSoon: return "Due Soon"
        case .taskOverdue: return "Overdue"
        case .photoSubmitted: return "Photo Submitted"
        case .photoApproved: return "Approved"
        case .photoRejected: return "Needs Redo"
        case .pointsAwarded: return "Points Earned"
        case .rewardRedeemed: return "Reward Redeemed"
        }
    }
}

// MARK: - App Notification
struct AppNotification: Identifiable, Codable {
    let id: UUID
    let userId: UUID  // Parent or child ID
    let type: NotificationType
    let title: String
    let message: String
    let choreId: UUID?
    let timestamp: Date
    var isRead: Bool
    
    init(id: UUID = UUID(), userId: UUID, type: NotificationType, title: String, message: String, choreId: UUID? = nil, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.choreId = choreId
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

