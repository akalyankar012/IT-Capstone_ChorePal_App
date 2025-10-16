import SwiftUI

// MARK: - Parent Notifications View
struct ParentNotificationsView: View {
    @ObservedObject var notificationService: NotificationService
    let parentId: UUID
    @State private var showUnreadOnly = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var filteredNotifications: [AppNotification] {
        if showUnreadOnly {
            return notificationService.notifications.filter { !$0.isRead }
        }
        return notificationService.notifications
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [themeColor.opacity(0.15), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if notificationService.isLoading {
                ProgressView("Loading notifications...")
            } else if notificationService.notifications.isEmpty {
                EmptyParentNotificationsView()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Filter toggle
                        HStack {
                            Button(action: { showUnreadOnly = false }) {
                                Text("All")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(showUnreadOnly ? .secondary : .white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(showUnreadOnly ? Color.clear : themeColor)
                                    .cornerRadius(20)
                            }
                            
                            Button(action: { showUnreadOnly = true }) {
                                HStack(spacing: 4) {
                                    Text("Unread")
                                    if notificationService.unreadCount > 0 {
                                        Text("(\(notificationService.unreadCount))")
                                    }
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(showUnreadOnly ? .white : .secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(showUnreadOnly ? themeColor : Color.clear)
                                .cornerRadius(20)
                            }
                            
                            Spacer()
                            
                            if notificationService.unreadCount > 0 {
                                Button(action: {
                                    Task {
                                        await notificationService.markAllAsRead(userId: parentId)
                                    }
                                }) {
                                    Text("Mark All Read")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeColor)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Notifications list
                        LazyVStack(spacing: 12) {
                            ForEach(filteredNotifications) { notification in
                                ParentNotificationCard(
                                    notification: notification,
                                    notificationService: notificationService
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
                .refreshable {
                    await notificationService.getNotificationsForUser(userId: parentId)
                }
            }
        }
        .onAppear {
            notificationService.startListening(for: parentId)
        }
    }
}

// MARK: - Parent Notification Card
struct ParentNotificationCard: View {
    let notification: AppNotification
    @ObservedObject var notificationService: NotificationService
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        Button(action: {
            if !notification.isRead {
                Task {
                    await notificationService.markAsRead(notificationId: notification.id)
                }
            }
        }) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(notification.type.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 22))
                        .foregroundColor(notification.type.color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if !notification.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    Text(notification.timestamp, style: .relative)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
                
                // Delete button
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(notification.isRead ? Color(.systemBackground) : Color(.systemBackground).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(notification.isRead ? Color.clear : notification.type.color.opacity(0.3), lineWidth: 2)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Notification", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await notificationService.deleteNotification(notificationId: notification.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this notification?")
        }
    }
}

// MARK: - Empty Parent Notifications View
struct EmptyParentNotificationsView: View {
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(themeColor.opacity(0.4))
            
            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("You'll see updates about photo submissions,\ntasks, and rewards here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

