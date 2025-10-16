import SwiftUI

struct ParentNotificationsView: View {
    let parentId: UUID
    @StateObject private var notificationService = NotificationService()
    @State private var showDeleteAlert = false
    @State private var notificationToDelete: AppNotification?
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !notificationService.notifications.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Mark All Read") {
                            Task {
                                await notificationService.markAllAsRead(userId: parentId)
                            }
                        }
                        .font(.subheadline)
                    }
                }
            }
            .onAppear {
                notificationService.startListening(for: parentId)
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
}
