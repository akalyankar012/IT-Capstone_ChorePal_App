import SwiftUI

struct ChildNotificationsView: View {
    let childId: UUID
    @StateObject private var notificationService = NotificationService()
    @State private var showDeleteAlert = false
    @State private var notificationToDelete: AppNotification?
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .light
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ZStack {
            if notificationService.isLoading {
                ProgressView("Loading notifications...")
                    .padding()
            } else if notificationService.notifications.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No Notifications")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("You're all caught up!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(notificationService.notifications) { notification in
                            NotificationCard(
                                notification: notification,
                                selectedTheme: selectedTheme,
                                themeColor: themeColor,
                                onTap: {
                                    Task {
                                        await notificationService.markAsRead(notificationId: notification.id)
                                    }
                                },
                                onDelete: {
                                    notificationToDelete = notification
                                    showDeleteAlert = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            notificationService.startListening(for: childId)
        }
        .onDisappear {
            notificationService.stopListening()
        }
        .alert("Delete Notification", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let notification = notificationToDelete {
                    Task {
                        await notificationService.deleteNotification(notificationId: notification.id)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this notification?")
        }
    }
}

// MARK: - Notification Card
struct NotificationCard: View {
    let notification: AppNotification
    let selectedTheme: AppTheme
    let themeColor: Color
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Circle()
                    .fill(notification.type.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: notification.type.icon)
                            .font(.system(size: 18))
                            .foregroundColor(notification.type.color)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Text(timeAgo(from: notification.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .glassCard(isLightMode: selectedTheme == .light, themeColor: themeColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(notification.isRead ? Color.clear : themeColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
}
