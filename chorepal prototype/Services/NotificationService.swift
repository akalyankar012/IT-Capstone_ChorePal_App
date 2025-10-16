import Foundation
import Combine
import Firebase
import FirebaseFirestore

class NotificationService: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var notificationsListener: ListenerRegistration?
    private var currentUserId: UUID?
    
    // MARK: - Setup Listener
    
    func startListening(for userId: UUID) {
        currentUserId = userId
        stopListening()
        
        notificationsListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId.uuidString)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to notifications: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No notifications found")
                    return
                }
                
                var loadedNotifications = documents.compactMap { doc -> AppNotification? in
                    let data = doc.data()
                    
                    guard let userIdString = data["userId"] as? String,
                          let userId = UUID(uuidString: userIdString),
                          let typeString = data["type"] as? String,
                          let type = NotificationType(rawValue: typeString),
                          let title = data["title"] as? String,
                          let message = data["message"] as? String,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                          let isRead = data["isRead"] as? Bool else {
                        return nil
                    }
                    
                    let choreIdString = data["choreId"] as? String
                    let choreId = choreIdString != nil ? UUID(uuidString: choreIdString!) : nil
                    
                    return AppNotification(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        userId: userId,
                        type: type,
                        title: title,
                        message: message,
                        choreId: choreId,
                        timestamp: timestamp,
                        isRead: isRead
                    )
                }
                
                // Sort by timestamp descending (newest first)
                loadedNotifications.sort { $0.timestamp > $1.timestamp }
                
                self.notifications = loadedNotifications
                self.updateUnreadCount()
                print("✅ Loaded \(self.notifications.count) notifications")
            }
    }
    
    func stopListening() {
        notificationsListener?.remove()
        notificationsListener = nil
    }
    
    // MARK: - Create Notification
    
    func createNotification(userId: UUID, type: NotificationType, title: String, message: String, choreId: UUID? = nil) async {
        // Check for duplicate recent notifications to prevent flooding
        if await shouldPreventDuplicate(userId: userId, type: type, choreId: choreId) {
            print("⚠️ Preventing duplicate notification: \(type.rawValue)")
            return
        }
        
        let notification = AppNotification(
            userId: userId,
            type: type,
            title: title,
            message: message,
            choreId: choreId
        )
        
        do {
            let notificationData: [String: Any] = [
                "userId": userId.uuidString,
                "type": type.rawValue,
                "title": title,
                "message": message,
                "choreId": choreId?.uuidString as Any,
                "timestamp": FieldValue.serverTimestamp(),
                "isRead": false
            ]
            
            try await db.collection("notifications")
                .document(notification.id.uuidString)
                .setData(notificationData)
            
            print("✅ Notification created: \(title)")
            
        } catch {
            print("❌ Error creating notification: \(error)")
        }
    }
    
    // MARK: - Duplicate Prevention
    
    private func shouldPreventDuplicate(userId: UUID, type: NotificationType, choreId: UUID?) async -> Bool {
        // Prevent same notification type for same chore within 1 hour
        let oneHourAgo = Date().addingTimeInterval(-3600)
        
        do {
            var query = db.collection("notifications")
                .whereField("userId", isEqualTo: userId.uuidString)
                .whereField("type", isEqualTo: type.rawValue)
                .whereField("timestamp", isGreaterThan: Timestamp(date: oneHourAgo))
            
            if let choreId = choreId {
                query = query.whereField("choreId", isEqualTo: choreId.uuidString)
            }
            
            let snapshot = try await query.getDocuments()
            return !snapshot.documents.isEmpty
            
        } catch {
            print("❌ Error checking for duplicates: \(error)")
            return false
        }
    }
    
    // MARK: - Get Notifications
    
    func getNotificationsForUser(userId: UUID) async {
        isLoading = true
        
        do {
            let snapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userId.uuidString)
                .limit(to: 50)
                .getDocuments()
            
            var loadedNotifications = snapshot.documents.compactMap { doc -> AppNotification? in
                let data = doc.data()
                
                guard let userIdString = data["userId"] as? String,
                      let userId = UUID(uuidString: userIdString),
                      let typeString = data["type"] as? String,
                      let type = NotificationType(rawValue: typeString),
                      let title = data["title"] as? String,
                      let message = data["message"] as? String,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                      let isRead = data["isRead"] as? Bool else {
                    return nil
                }
                
                let choreIdString = data["choreId"] as? String
                let choreId = choreIdString != nil ? UUID(uuidString: choreIdString!) : nil
                
                return AppNotification(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    userId: userId,
                    type: type,
                    title: title,
                    message: message,
                    choreId: choreId,
                    timestamp: timestamp,
                    isRead: isRead
                )
            }
            
            // Sort by timestamp descending (newest first)
            loadedNotifications.sort { $0.timestamp > $1.timestamp }
            
            notifications = loadedNotifications
            updateUnreadCount()
            print("✅ Fetched \(notifications.count) notifications")
            
        } catch {
            print("❌ Error fetching notifications: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Mark as Read
    
    func markAsRead(notificationId: UUID) async {
        do {
            try await db.collection("notifications")
                .document(notificationId.uuidString)
                .updateData(["isRead": true])
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                await MainActor.run {
                    notifications[index].isRead = true
                    updateUnreadCount()
                }
            }
            
            print("✅ Notification marked as read")
            
        } catch {
            print("❌ Error marking notification as read: \(error)")
        }
    }
    
    func markAllAsRead(userId: UUID) async {
        do {
            let snapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userId.uuidString)
                .whereField("isRead", isEqualTo: false)
                .getDocuments()
            
            let batch = db.batch()
            
            for document in snapshot.documents {
                batch.updateData(["isRead": true], forDocument: document.reference)
            }
            
            try await batch.commit()
            
            // Update local state
            await MainActor.run {
                for index in notifications.indices {
                    notifications[index].isRead = true
                }
                updateUnreadCount()
            }
            
            print("✅ All notifications marked as read")
            
        } catch {
            print("❌ Error marking all as read: \(error)")
        }
    }
    
    // MARK: - Delete Notification
    
    func deleteNotification(notificationId: UUID) async {
        do {
            try await db.collection("notifications")
                .document(notificationId.uuidString)
                .delete()
            
            // Update local state
            await MainActor.run {
                notifications.removeAll { $0.id == notificationId }
                updateUnreadCount()
            }
            
            print("✅ Notification deleted")
            
        } catch {
            print("❌ Error deleting notification: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    func getUnreadCount(userId: UUID) async -> Int {
        do {
            let snapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userId.uuidString)
                .whereField("isRead", isEqualTo: false)
                .getDocuments()
            
            return snapshot.documents.count
            
        } catch {
            print("❌ Error getting unread count: \(error)")
            return 0
        }
    }
    
    deinit {
        stopListening()
    }
}

