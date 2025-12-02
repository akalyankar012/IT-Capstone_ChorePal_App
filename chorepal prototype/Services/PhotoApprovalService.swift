import Foundation
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
import UIKit

// Note: FirebaseStorage will need to be added via Xcode:
// File > Add Package Dependencies > Firebase > Select FirebaseStorage
// For now, we'll store images as base64 in Firestore (not recommended for production)

final class PhotoApprovalService: ObservableObject {
    @Published var pendingPhotos: [ChorePhoto] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var photosListener: ListenerRegistration?
    
    // MARK: - Setup Listener
    
    func startListening(for parentId: UUID) {
        stopListening()
        
        // Get current user's Firebase Auth UID to get children
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No authenticated user found for photo listening")
            return
        }
        
        // First, get all children for this parent
        Task {
            do {
                let childrenSnapshot = try await db.collection("children")
                    .whereField("parentId", isEqualTo: currentUser.uid)
                    .getDocuments()
                
                let childrenIds = childrenSnapshot.documents.compactMap { doc -> String? in
                    return doc.documentID
                }
                
                guard !childrenIds.isEmpty else {
                    print("⚠️ No children found for parent, no photos to show")
                    await MainActor.run {
                        self.pendingPhotos = []
                    }
                    return
                }
                
                // Firestore's whereIn can only handle up to 10 values
                // If more than 10 children, we'll need to query in batches
                if childrenIds.count <= 10 {
                    // Use whereIn query for up to 10 children
                    await self.setupPhotosListener(for: childrenIds)
                } else {
                    // For more than 10 children, query in batches
                    await self.setupPhotosListenerInBatches(for: childrenIds)
                }
                
            } catch {
                print("❌ Error getting children for photo filtering: \(error)")
                await MainActor.run {
                    self.pendingPhotos = []
                }
            }
        }
    }
    
    private func setupPhotosListener(for childrenIds: [String]) async {
        await MainActor.run {
            self.stopListening()
            
            self.photosListener = db.collection("chorePhotos")
                .whereField("approvalStatus", isEqualTo: "pending")
                .whereField("childId", in: childrenIds)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("❌ Error listening to photos: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("⚠️ No pending photos found")
                        return
                    }
                    
                    Task {
                        await self.loadPhotosFromDocuments(documents, filteringByChildrenIds: Set(childrenIds))
                    }
                }
        }
    }
    
    private func setupPhotosListenerInBatches(for childrenIds: [String]) async {
        // Firestore whereIn limit is 10, so we need to batch
        // For simplicity, we'll load all pending photos and filter in memory
        await MainActor.run {
            self.stopListening()
            
            self.photosListener = db.collection("chorePhotos")
                .whereField("approvalStatus", isEqualTo: "pending")
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("❌ Error listening to photos: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("⚠️ No pending photos found")
                        return
                    }
                    
                    Task {
                        await self.loadPhotosFromDocuments(documents, filteringByChildrenIds: Set(childrenIds))
                    }
                }
        }
    }
    
    private func loadPhotosFromDocuments(_ documents: [QueryDocumentSnapshot], filteringByChildrenIds: Set<String>? = nil) async {
        var photos: [ChorePhoto] = []
        
        for doc in documents {
            let data = doc.data()
            
            guard let choreIdString = data["choreId"] as? String,
                  let choreId = UUID(uuidString: choreIdString),
                  let childIdString = data["childId"] as? String,
                  let childId = UUID(uuidString: childIdString),
                  let imageUrl = data["imageUrl"] as? String,
                  let uploadedAt = (data["uploadedAt"] as? Timestamp)?.dateValue(),
                  let statusString = data["approvalStatus"] as? String,
                  let status = ApprovalStatus(rawValue: statusString) else {
                continue
            }
            
            // Filter by children IDs if provided (for batches with >10 children)
            if let childrenIds = filteringByChildrenIds {
                if !childrenIds.contains(childIdString) && !childrenIds.contains(doc.documentID) {
                    // Check both childIdString and document ID (in case childId is stored differently)
                    // Also check if the chore belongs to this parent via chore lookup
                    continue
                }
            }
            
            // Download image data
            if let imageData = await downloadImage(from: imageUrl) {
                let approvedByIdString = data["approvedByParentId"] as? String
                let approvedById = approvedByIdString != nil ? UUID(uuidString: approvedByIdString!) : nil
                let feedback = data["feedback"] as? String
                let processedAt = (data["processedAt"] as? Timestamp)?.dateValue()
                
                // Use the Firestore document ID as the photo ID
                let photoId = UUID(uuidString: doc.documentID) ?? UUID()
                
                let photo = ChorePhoto(
                    id: photoId,
                    choreId: choreId,
                    childId: childId,
                    imageData: imageData,
                    uploadedAt: uploadedAt,
                    approvalStatus: status,
                    approvedByParentId: approvedById,
                    feedback: feedback,
                    processedAt: processedAt
                )
                photos.append(photo)
            }
        }
        
        await MainActor.run {
            self.pendingPhotos = photos
            print("✅ Loaded \(photos.count) pending photos for parent")
        }
    }
    
    func stopListening() {
        photosListener?.remove()
        photosListener = nil
    }
    
    // MARK: - Submit Photo
    
    func submitPhoto(choreId: UUID, childId: UUID, imageData: Data) async -> Bool {
        do {
            // Compress image before upload
            guard let compressedData = compressImage(imageData) else {
                print("❌ Failed to compress image")
                return false
            }
            
            // Store as base64 (temporary solution until FirebaseStorage is added)
            let base64String = compressedData.base64EncodedString()
            
            // Save metadata to Firestore
            let photoId = UUID()
            let photoData: [String: Any] = [
                "choreId": choreId.uuidString,
                "childId": childId.uuidString,
                "imageUrl": "data:image/jpeg;base64,\(base64String)",
                "uploadedAt": FieldValue.serverTimestamp(),
                "approvalStatus": "pending"
            ]
            
            try await db.collection("chorePhotos")
                .document(photoId.uuidString)
                .setData(photoData)
            
            print("✅ Photo submitted successfully")
            return true
            
        } catch {
            print("❌ Error submitting photo: \(error)")
            return false
        }
    }
    
    // MARK: - Get Photos
    
    func getPendingPhotosForParent(parentId: UUID) async {
        isLoading = true
        
        do {
            // Get current user's Firebase Auth UID to get children
            guard let currentUser = Auth.auth().currentUser else {
                print("❌ No authenticated user found for photo loading")
                await MainActor.run {
                    isLoading = false
                    pendingPhotos = []
                }
                return
            }
            
            // Get all children for this parent
            let childrenSnapshot = try await db.collection("children")
                .whereField("parentId", isEqualTo: currentUser.uid)
                .getDocuments()
            
            let childrenIds = childrenSnapshot.documents.map { $0.documentID }
            
            guard !childrenIds.isEmpty else {
                print("⚠️ No children found for parent, no photos to show")
                await MainActor.run {
                    isLoading = false
                    pendingPhotos = []
                }
                return
            }
            
            // Filter photos by children IDs
            if childrenIds.count <= 10 {
                // Use whereIn query for up to 10 children
                let snapshot = try await db.collection("chorePhotos")
                    .whereField("approvalStatus", isEqualTo: "pending")
                    .whereField("childId", in: childrenIds)
                    .getDocuments()
                
                await loadPhotosFromDocuments(snapshot.documents)
            } else {
                // For more than 10 children, load all and filter in memory
                let snapshot = try await db.collection("chorePhotos")
                    .whereField("approvalStatus", isEqualTo: "pending")
                    .getDocuments()
                
                await loadPhotosFromDocuments(snapshot.documents, filteringByChildrenIds: Set(childrenIds))
            }
            
        } catch {
            print("❌ Error fetching pending photos: \(error)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func getPhotoForChore(choreId: UUID) async -> ChorePhoto? {
        do {
            let snapshot = try await db.collection("chorePhotos")
                .whereField("choreId", isEqualTo: choreId.uuidString)
                .order(by: "uploadedAt", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            guard let doc = snapshot.documents.first else {
                return nil
            }
            
            let data = doc.data()
            
            guard let choreIdString = data["choreId"] as? String,
                  let choreId = UUID(uuidString: choreIdString),
                  let childIdString = data["childId"] as? String,
                  let childId = UUID(uuidString: childIdString),
                  let imageUrl = data["imageUrl"] as? String,
                  let uploadedAt = (data["uploadedAt"] as? Timestamp)?.dateValue(),
                  let statusString = data["approvalStatus"] as? String,
                  let status = ApprovalStatus(rawValue: statusString) else {
                return nil
            }
            
            // Download image data
            guard let imageData = await downloadImage(from: imageUrl) else {
                return nil
            }
            
            let approvedByIdString = data["approvedByParentId"] as? String
            let approvedById = approvedByIdString != nil ? UUID(uuidString: approvedByIdString!) : nil
            let feedback = data["feedback"] as? String
            let processedAt = (data["processedAt"] as? Timestamp)?.dateValue()
            
            // Use the Firestore document ID as the photo ID
            let photoId = UUID(uuidString: doc.documentID) ?? UUID()
            
            return ChorePhoto(
                id: photoId,
                choreId: choreId,
                childId: childId,
                imageData: imageData,
                uploadedAt: uploadedAt,
                approvalStatus: status,
                approvedByParentId: approvedById,
                feedback: feedback,
                processedAt: processedAt
            )
            
        } catch {
            print("❌ Error fetching photo for chore: \(error)")
            return nil
        }
    }
    
    // MARK: - Approve/Reject Photo
    
    func approvePhoto(_ photo: ChorePhoto, approvedBy parentId: UUID, feedback: String? = nil) async -> Bool {
        do {
            let updateData: [String: Any] = [
                "approvalStatus": "approved",
                "approvedByParentId": parentId.uuidString,
                "feedback": feedback as Any,
                "processedAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("chorePhotos")
                .document(photo.id.uuidString)
                .updateData(updateData)
            
            // Remove from local pending list
            await MainActor.run {
                pendingPhotos.removeAll { $0.id == photo.id }
            }
            
            print("✅ Photo approved")
            return true
            
        } catch {
            print("❌ Error approving photo: \(error)")
            return false
        }
    }
    
    func rejectPhoto(_ photo: ChorePhoto, rejectedBy parentId: UUID, feedback: String) async -> Bool {
        do {
            let updateData: [String: Any] = [
                "approvalStatus": "rejected",
                "approvedByParentId": parentId.uuidString,
                "feedback": feedback,
                "processedAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("chorePhotos")
                .document(photo.id.uuidString)
                .updateData(updateData)
            
            // Remove from local pending list
            await MainActor.run {
                pendingPhotos.removeAll { $0.id == photo.id }
            }
            
            print("✅ Photo rejected")
            return true
            
        } catch {
            print("❌ Error rejecting photo: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func compressImage(_ imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else {
            return nil
        }
        
        // Resize to max dimension of 1024px
        let maxDimension: CGFloat = 1024
        var newSize = image.size
        
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let ratio = image.size.width / image.size.height
            
            if ratio > 1 {
                newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
            } else {
                newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Compress to JPEG with 0.7 quality
        return resizedImage?.jpegData(compressionQuality: 0.7)
    }
    
    private func downloadImage(from urlString: String) async -> Data? {
        // Check if it's a base64 data URL
        if urlString.hasPrefix("data:image/") {
            // Extract base64 data
            if let base64Start = urlString.range(of: "base64,") {
                let base64String = String(urlString[base64Start.upperBound...])
                return Data(base64Encoded: base64String)
            }
        }
        
        // Otherwise, download from URL
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            print("❌ Error downloading image: \(error)")
            return nil
        }
    }
    
    deinit {
        stopListening()
    }
}


