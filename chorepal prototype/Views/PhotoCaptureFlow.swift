import SwiftUI
import UIKit
import AVFoundation

// MARK: - Photo Capture Flow
struct PhotoCaptureFlow: View {
    let chore: Chore
    let childId: UUID
    @ObservedObject var photoApprovalService: PhotoApprovalService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cameraPermissionDenied = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if capturedImage == nil {
                    // Initial state - show camera prompt
                    VStack(spacing: 24) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(themeColor.opacity(0.15))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 50))
                                .foregroundColor(themeColor)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Take a Photo")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Show that you completed:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(chore.title)
                                .font(.headline)
                                .foregroundColor(themeColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        Button(action: checkCameraPermissionAndOpen) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Open Camera")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeColor)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                } else {
                    // Photo captured - show preview
                    VStack(spacing: 0) {
                        // Photo preview
                        GeometryReader { geometry in
                            if let image = capturedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                        .background(Color.black)
                        
                        // Action buttons
                        VStack(spacing: 16) {
                            if isUploading {
                                ProgressView("Uploading photo...")
                                    .padding()
                            } else if uploadSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Photo submitted for approval!")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                                .padding()
                            } else {
                                HStack(spacing: 12) {
                                    Button(action: { capturedImage = nil }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Retake")
                                        }
                                        .font(.headline)
                                        .foregroundColor(themeColor)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                    
                                    Button(action: uploadPhoto) {
                                        HStack {
                                            Image(systemName: "checkmark")
                                            Text("Submit")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(themeColor)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 20)
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationTitle("Photo Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isUploading {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $capturedImage)
            }
            .alert("Camera Access Required", isPresented: $cameraPermissionDenied) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Open Settings") {
                    openSettings()
                }
            } message: {
                Text("ChorePal needs access to your camera to take photos. Please enable camera access in Settings.")
            }
            .alert("Upload Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: uploadSuccess) { success in
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func checkCameraPermissionAndOpen() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        cameraPermissionDenied = true
                    }
                }
            }
            
        case .denied, .restricted:
            cameraPermissionDenied = true
            
        @unknown default:
            cameraPermissionDenied = true
        }
    }
    
    private func uploadPhoto() {
        guard let image = capturedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image. Please try again."
            showError = true
            return
        }
        
        isUploading = true
        
        Task {
            let success = await photoApprovalService.submitPhoto(
                choreId: chore.id,
                childId: childId,
                imageData: imageData
            )
            
            await MainActor.run {
                isUploading = false
                
                if success {
                    uploadSuccess = true
                } else {
                    errorMessage = "Failed to upload photo. Please check your connection and try again."
                    showError = true
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
        dismiss()
    }
}

// MARK: - Camera Picker
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

