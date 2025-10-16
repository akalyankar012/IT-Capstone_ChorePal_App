import Foundation
import SwiftUI

// MARK: - Photo Proof Status
enum PhotoProofStatus: String, Codable {
    case notSubmitted    // Child hasn't submitted photo yet
    case pending         // Photo submitted, awaiting parent review
    case approved        // Parent approved, points awarded
    case rejected        // Parent rejected with feedback
    
    var icon: String {
        switch self {
        case .notSubmitted: return "camera.fill"
        case .pending: return "hourglass"
        case .approved: return "checkmark.seal.fill"
        case .rejected: return "xmark.seal.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .notSubmitted: return .blue
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .notSubmitted: return "Take Photo"
        case .pending: return "Pending Approval"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
}

// MARK: - Approval Status (Legacy, keeping for compatibility)
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

// MARK: - Chore Photo
struct ChorePhoto: Identifiable, Codable {
    let id: UUID
    let choreId: UUID
    let childId: UUID
    let imageData: Data
    let uploadedAt: Date
    var approvalStatus: ApprovalStatus
    var approvedByParentId: UUID?
    var feedback: String?
    var processedAt: Date?
    
    init(id: UUID = UUID(), choreId: UUID, childId: UUID, imageData: Data, uploadedAt: Date = Date(), approvalStatus: ApprovalStatus = .pending, approvedByParentId: UUID? = nil, feedback: String? = nil, processedAt: Date? = nil) {
        self.id = id
        self.choreId = choreId
        self.childId = childId
        self.imageData = imageData
        self.uploadedAt = uploadedAt
        self.approvalStatus = approvalStatus
        self.approvedByParentId = approvedByParentId
        self.feedback = feedback
        self.processedAt = processedAt
    }
}


