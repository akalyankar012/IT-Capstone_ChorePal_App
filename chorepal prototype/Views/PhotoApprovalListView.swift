import SwiftUI

// MARK: - Photo Approval List View
struct PhotoApprovalListView: View {
    @ObservedObject var photoApprovalService: PhotoApprovalService
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPhoto: ChorePhoto?
    @State private var showApprovalDetail = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if photoApprovalService.isLoading {
                    ProgressView("Loading submissions...")
                } else if photoApprovalService.pendingPhotos.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(photoApprovalService.pendingPhotos) { photo in
                                PhotoSubmissionCard(
                                    photo: photo,
                                    choreService: choreService,
                                    authService: authService,
                                    themeColor: themeColor
                                )
                                .onTapGesture {
                                    selectedPhoto = photo
                                    showApprovalDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Photo Approvals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showApprovalDetail) {
                if let photo = selectedPhoto {
                    PhotoApprovalDetailView(
                        photo: photo,
                        choreService: choreService,
                        authService: authService,
                        photoApprovalService: photoApprovalService,
                        onDismiss: {
                            selectedPhoto = nil
                            showApprovalDetail = false
                        }
                    )
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(themeColor.opacity(0.5))
            
            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("No photo submissions to review right now.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Photo Submission Card
struct PhotoSubmissionCard: View {
    let photo: ChorePhoto
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    let themeColor: Color
    
    private var chore: Chore? {
        choreService.chores.first { $0.id == photo.choreId }
    }
    
    private var child: Child? {
        authService.currentParent?.children.first { $0.id == photo.childId }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Photo thumbnail
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(themeColor.opacity(0.3), lineWidth: 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Task details
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    // Child avatar
                    Circle()
                        .fill(themeColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(child?.name.prefix(1).uppercased() ?? "?")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(themeColor)
                        )
                    
                    Text(child?.name ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text(chore?.title ?? "Unknown Task")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Label("\(chore?.points ?? 0) pts", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Label(timeAgo(from: photo.uploadedAt), systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

