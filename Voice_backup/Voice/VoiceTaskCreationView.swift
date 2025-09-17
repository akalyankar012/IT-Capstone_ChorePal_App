import SwiftUI

// MARK: - Voice Task Creation View
struct VoiceTaskCreationView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var voiceService = VoiceService()
    @StateObject private var speechBack = SpeechBack()
    @StateObject private var wavRecorder = WAVRecorder()
    
    @State private var isRecording = false
    @State private var transcript = ""
    @State private var isLoading = false
    @State private var currentQuestion = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var conversationStep = 0 // 0: initial, 1: follow-up, 2: complete
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeColor)
                    
                    Text("Voice Task Creation")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Speak your chore assignment naturally")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Status Display
                VStack(spacing: 16) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    } else if !transcript.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transcript:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(transcript)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    if !currentQuestion.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Question:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(currentQuestion)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(themeColor.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Voice Controls
                VStack(spacing: 20) {
                    // Record Button
                    Button(action: toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : themeColor)
                                .frame(width: 80, height: 80)
                                .scaleEffect(isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: isRecording)
                            
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isLoading)
                    
                    Text(isRecording ? "Tap to stop recording" : "Tap to start recording")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if conversationStep > 0 {
                        Button(action: resetConversation) {
                            Text("Start Over")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            setupVoiceComponents()
        }
        .alert("Voice Task Creation", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func setupVoiceComponents() {
        // Request microphone permission
        wavRecorder.requestPermissions { granted in
            if !granted {
                alertMessage = "Microphone permission is required for voice tasks"
                showingAlert = true
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        transcript = ""
        currentQuestion = ""
        
        wavRecorder.startRecording { success in
            if !success {
                isRecording = false
                alertMessage = "Failed to start recording"
                showingAlert = true
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        isLoading = true
        
        wavRecorder.stopRecording { audioData in
            guard let audioData = audioData else {
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = "Failed to record audio"
                    showingAlert = true
                }
                return
            }
            
            processAudio(audioData)
        }
    }
    
    private func processAudio(_ audioData: Data) {
        Task {
            do {
                let transcript = try await voiceService.uploadSTT(audioData: audioData)
                
                await MainActor.run {
                    isLoading = false
                    self.transcript = transcript
                    parseTranscript(transcript)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Speech recognition failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func parseTranscript(_ transcript: String) {
        guard let children = authService.currentParent?.children else {
            alertMessage = "No children found. Please add children first."
            showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let parseResult = try await voiceService.parseTranscript(transcript, children: children.map { VoiceChild(id: $0.id, name: $0.name) })
                
                await MainActor.run {
                    isLoading = false
                    handleParseResult(parseResult)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to parse transcript: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func handleParseResult(_ result: ParseResult) {
        if result.needsFollowup {
            // Ask follow-up question
            currentQuestion = result.question ?? "Please provide more information"
            conversationStep = 1
            
            // Speak the question
            speechBack.speak(currentQuestion)
            
        } else if let taskFields = result.result {
            // Create the chore
            createChore(from: taskFields)
        }
    }
    
    private func createChore(from taskFields: TaskFields) {
        guard let child = authService.currentParent?.children.first(where: { $0.id == taskFields.childId }) else {
            alertMessage = "Child not found"
            showingAlert = true
            return
        }
        
        // Parse the due date
        let dueDate: Date
        if let dueAtString = taskFields.dueAt {
            let formatter = ISO8601DateFormatter()
            dueDate = formatter.date(from: dueAtString) ?? Date()
        } else {
            dueDate = Date()
        }
        
        // Create new chore
        let newChore = Chore(
            title: taskFields.title,
            description: "Created via voice command",
            points: taskFields.points,
            dueDate: dueDate,
            assignedToChildId: taskFields.childId,
            isRequired: true,
            isCompleted: false,
            createdAt: Date()
        )
        
        // Save to Firestore
        choreService.addChore(newChore)
        
        // Speak confirmation
        let confirmation = "Done — \(taskFields.title) for \(child.name), due \(dueDate.formatted(date: .abbreviated, time: .omitted)), worth \(taskFields.points) points"
        speechBack.speak(confirmation)
        
        // Reset conversation
        conversationStep = 2
        transcript = ""
        currentQuestion = ""
        
        // Show success message
        alertMessage = "Chore created successfully!"
        showingAlert = true
    }
    
    private func resetConversation() {
        conversationStep = 0
        transcript = ""
        currentQuestion = ""
    }
}

// MARK: - Preview
struct VoiceTaskCreationView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceTaskCreationView(
            choreService: ChoreService(),
            authService: AuthService()
        )
        .previewDisplayName("Voice Task Creation")
    }
}
