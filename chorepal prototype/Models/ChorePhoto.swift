import Foundation

enum ApprovalStatus: String, Codable {
    case pending
    case approved
    case rejected
    
    var icon: String {
        switch self {
        case .pending: return "hourglass"
        case .approved: return "checkmark.seal.fill"
        case .rejected: return "xmark.seal.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "#FFA500"
        case .approved: return "#4CAF50"
        case .rejected: return "#FF3B30"
        }
    }
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
}

struct ChorePhoto: Identifiable, Codable {
    let id: UUID
    let choreId: UUID
    let childId: UUID
    let imageData: Data
    let uploadedAt: Date
    var approvalStatus: ApprovalStatus
    
    init(choreId: UUID, childId: UUID, imageData: Data, uploadedAt: Date = Date(), approvalStatus: ApprovalStatus = .pending) {
        self.id = UUID()
        self.choreId = choreId
        self.childId = childId
        self.imageData = imageData
        self.uploadedAt = uploadedAt
        self.approvalStatus = approvalStatus
    }
}


