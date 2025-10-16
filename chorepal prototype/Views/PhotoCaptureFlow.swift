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
                        
                        Text("DEBUG: PhotoCaptureFlow is showing!")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.yellow)
                        
                        ZStack {
                            Circle()
                                .fill(themeColor.opacity(0.15))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 50))
                                .foregroundColor(themeColor)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Upload Photo Proof")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Select a photo to prove you completed:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(chore.title)
                                .font(.headline)
                                .foregroundColor(themeColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            print("🔘 DEBUG: Upload Photo button tapped")
                            print("🔘 DEBUG: Setting showCamera = true")
                            showCamera = true
                            print("🔘 DEBUG: showCamera is now: \(showCamera)")
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title3)
                                Text("UPLOAD PHOTO")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        
                        Text("DEBUG: Tap the blue button above")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding()
                            .background(Color.black.opacity(0.1))
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
        print("🔍 DEBUG: Checking camera permission...")
        print("🔍 DEBUG: Camera available: \(UIImagePickerController.isSourceTypeAvailable(.camera))")
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("🔍 DEBUG: Camera permission status: \(status.rawValue)")
        
        switch status {
        case .authorized:
            print("✅ DEBUG: Camera authorized, opening...")
            showCamera = true
            
        case .notDetermined:
            print("⚠️ DEBUG: Camera permission not determined, requesting...")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    print("🔍 DEBUG: Permission granted: \(granted)")
                    if granted {
                        self.showCamera = true
                    } else {
                        self.cameraPermissionDenied = true
                    }
                }
            }
            
        case .denied, .restricted:
            print("❌ DEBUG: Camera permission denied or restricted")
            cameraPermissionDenied = true
            
        @unknown default:
            print("❌ DEBUG: Unknown camera permission status")
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
        print("📸 DEBUG: Creating UIImagePickerController for photo library...")
        let picker = UIImagePickerController()
        
        // Use photo library only (camera removed to avoid issues)
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        
        // IMPORTANT: Don't set modalPresentationStyle when used in a sheet
        // The sheet handles the presentation
        
        print("✅ DEBUG: UIImagePickerController configured for photo library")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        print("📸 DEBUG: updateUIViewController called")
    }
    
    func makeCoordinator() -> Coordinator {
        print("📸 DEBUG: Creating Coordinator")
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
            super.init()
            print("📸 DEBUG: Coordinator initialized")
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("✅ DEBUG: Image picked!")
            if let uiImage = info[.originalImage] as? UIImage {
                print("✅ DEBUG: Got UIImage: \(uiImage.size)")
                parent.image = uiImage
            } else {
                print("❌ DEBUG: Failed to get image from info")
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("⚠️ DEBUG: User cancelled picker")
            parent.dismiss()
        }
    }
}

