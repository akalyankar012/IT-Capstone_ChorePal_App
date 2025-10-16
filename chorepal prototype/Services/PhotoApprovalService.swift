import Foundation
import Combine

// No-op stub to satisfy UI references; does not enable feature
final class PhotoApprovalService: ObservableObject {
    @Published var pendingPhotos: [ChorePhoto] = []

    func getPhotosForChore(choreId: UUID, childId: UUID) -> [ChorePhoto] { [] }
    func approvePhoto(_ photo: ChorePhoto, approvedBy: UUID) { }
    func rejectPhoto(_ photo: ChorePhoto, rejectedBy: UUID) { }
}


