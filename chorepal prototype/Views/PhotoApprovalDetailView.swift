import SwiftUI

// MARK: - Photo Approval Detail View
struct PhotoApprovalDetailView: View {
    let photo: ChorePhoto
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @ObservedObject var photoApprovalService: PhotoApprovalService
    let onDismiss: () -> Void
    
    @State private var feedbackText = ""
    @State private var showApproveConfirmation = false
    @State private var showRejectConfirmation = false
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var imageScale: CGFloat = 1.0
    
    private let themeColor = Color(hex: "#a2cee3")
    
    private var chore: Chore? {
        choreService.chores.first { $0.id == photo.choreId }
    }
    
    private var child: Child? {
        authService.currentParent?.children.first { $0.id == photo.childId }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Photo display with pinch-to-zoom
                    ZStack {
                        if let uiImage = UIImage(data: photo.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(imageScale)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            imageScale = min(max(value, 1.0), 4.0)
                                        }
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom action sheet
                    VStack(spacing: 20) {
                        // Task info card
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(themeColor.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(child?.name.prefix(1).uppercased() ?? "?")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(themeColor)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(child?.name ?? "Unknown")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(chore?.title ?? "Unknown Task")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                        Text("\(chore?.points ?? 0)")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.orange)
                                    
                                    Text("points")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let description = chore?.description, !description.isEmpty {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                        
                        // Feedback text field (optional for approve, required for reject)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add a note (optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Great job! or Needs improvement...", text: $feedbackText, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                        
                        // Action buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                if feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    feedbackText = ""
                                }
                                showRejectConfirmation = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Reject")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)
                            
                            Button(action: {
                                if feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    feedbackText = "Great work!"
                                }
                                showApproveConfirmation = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Approve")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)
                        }
                        
                        if isProcessing {
                            ProgressView("Processing...")
                                .padding(.top, 8)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemGroupedBackground))
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .navigationTitle("Review Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
            .alert("Approve Photo?", isPresented: $showApproveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Approve") {
                    approvePhoto()
                }
            } message: {
                Text("Award \(chore?.points ?? 0) points to \(child?.name ?? "child") for completing this task?")
            }
            .alert("Reject Photo?", isPresented: $showRejectConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reject", role: .destructive) {
                    rejectPhoto()
                }
            } message: {
                if feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Please add feedback to help \(child?.name ?? "the child") understand what needs improvement.")
                } else {
                    Text("Send feedback: \"\(feedbackText)\"")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func approvePhoto() {
        guard let parentId = authService.currentParent?.id else {
            errorMessage = "Parent not found"
            showError = true
            return
        }
        
        isProcessing = true
        
        Task {
            let success = await photoApprovalService.approvePhoto(
                photo,
                approvedBy: parentId,
                feedback: feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : feedbackText
            )
            
            await MainActor.run {
                isProcessing = false
                
                if success {
                    // Award points to child and update chore
                    if let chore = chore {
                        // Award points (saves to Firestore automatically)
                        authService.awardPointsToChild(childId: photo.childId, points: chore.points)
                        
                        // Update chore status
                        var updatedChore = chore
                        updatedChore.isCompleted = true
                        updatedChore.photoProofStatus = .approved
                        updatedChore.parentFeedback = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : feedbackText
                        choreService.updateChore(updatedChore)
                        
                        print("✅ Awarded \(chore.points) points to child \(photo.childId)")
                        
                        // Send notification to child
                        Task {
                            let notificationService = NotificationService()
                            await notificationService.createNotification(
                                userId: photo.childId,
                                type: .photoApproved,
                                title: "Photo Approved! 🎉",
                                message: "Great job! You earned \(chore.points) points for \"\(chore.title)\"",
                                choreId: chore.id
                            )
                        }
                    }
                    
                    onDismiss()
                } else {
                    errorMessage = "Failed to approve photo. Please try again."
                    showError = true
                }
            }
        }
    }
    
    private func rejectPhoto() {
        guard let parentId = authService.currentParent?.id else {
            errorMessage = "Parent not found"
            showError = true
            return
        }
        
        let trimmedFeedback = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedFeedback.isEmpty {
            errorMessage = "Please provide feedback explaining why the photo was rejected."
            showError = true
            return
        }
        
        isProcessing = true
        
        Task {
            let success = await photoApprovalService.rejectPhoto(
                photo,
                rejectedBy: parentId,
                feedback: trimmedFeedback
            )
            
            await MainActor.run {
                isProcessing = false
                
                if success {
                    // Update chore status
                    if let chore = chore {
                        var updatedChore = chore
                        updatedChore.photoProofStatus = .rejected
                        updatedChore.parentFeedback = trimmedFeedback
                        choreService.updateChore(updatedChore)
                        
                        // Send notification to child
                        Task {
                            let notificationService = NotificationService()
                            await notificationService.createNotification(
                                userId: photo.childId,
                                type: .photoRejected,
                                title: "Photo Needs Retake",
                                message: "Please retake the photo for \"\(chore.title)\". Feedback: \(trimmedFeedback)",
                                choreId: chore.id
                            )
                        }
                    }
                    
                    onDismiss()
                } else {
                    errorMessage = "Failed to reject photo. Please try again."
                    showError = true
                }
            }
        }
    }
}

