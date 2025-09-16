import SwiftUI
import AVFoundation

// MARK: - Voice Task Creation View

struct VoiceView: View {
    @StateObject private var recorder = WAVRecorder()
    @StateObject private var speechBack = SpeechBack()
    @StateObject private var voiceService = VoiceService()
    @StateObject private var configService = VoiceConfigService.shared
    
    @State private var voiceState: VoiceState = .idle
    @State private var transcript = ""
    @State private var conversationHistory: [ConversationMessage] = []
    @State private var currentTask: TaskFields?
    @State private var showConfig = false
    
    // Get children from existing service (you'll need to adapt this)
    @State private var children: [VoiceChild] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Conversation History
                conversationView
                
                // Main Controls
                mainControlsView
                
                // Status and Transcript
                statusView
                
                Spacer()
            }
            .padding()
            .navigationTitle("Voice Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Config") {
                        showConfig = true
                    }
                }
            }
            .sheet(isPresented: $showConfig) {
                VoiceConfigView()
            }
        }
        .onAppear {
            loadChildren()
            speechBack.speakWelcome()
        }
        .onChange(of: voiceState) { newState in
            handleStateChange(newState)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Voice Task Creation")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap and hold the microphone to create tasks")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Conversation View
    
    private var conversationView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(conversationHistory) { message in
                    ConversationBubble(message: message)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Main Controls
    
    private var mainControlsView: some View {
        VStack(spacing: 20) {
            // Microphone Button
            Button(action: handleMicButtonPress) {
                ZStack {
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 120, height: 120)
                        .scaleEffect(recorder.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: recorder.isRecording)
                    
                    Image(systemName: buttonIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
            .disabled(voiceService.isLoading || speechBack.isSpeaking)
            
            // Action Button
            if voiceState == .processing {
                Button("Cancel") {
                    cancelProcessing()
                }
                .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        VStack(spacing: 8) {
            // Status Text
            Text(statusText)
                .font(.headline)
                .foregroundColor(statusColor)
            
            // Transcript
            if !transcript.isEmpty {
                Text("Transcript: \(transcript)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Loading Indicator
            if voiceService.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonColor: Color {
        switch voiceState {
        case .idle:
            return .blue
        case .recording:
            return .red
        case .processing:
            return .orange
        case .speaking:
            return .purple
        case .error:
            return .red
        }
    }
    
    private var buttonIcon: String {
        switch voiceState {
        case .idle:
            return "mic.fill"
        case .recording:
            return "stop.fill"
        case .processing:
            return "gear"
        case .speaking:
            return "speaker.wave.2.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusText: String {
        switch voiceState {
        case .idle:
            return "Ready to record"
        case .recording:
            return "Recording... (\(String(format: "%.1f", recorder.recordingDuration))s)"
        case .processing:
            return "Processing..."
        case .speaking:
            return "Speaking..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var statusColor: Color {
        switch voiceState {
        case .idle:
            return .primary
        case .recording:
            return .red
        case .processing:
            return .orange
        case .speaking:
            return .purple
        case .error:
            return .red
        }
    }
    
    // MARK: - Actions
    
    private func handleMicButtonPress() {
        switch voiceState {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        default:
            break
        }
    }
    
    private func startRecording() {
        voiceState = .recording
        transcript = ""
        recorder.startRecording()
        speechBack.speakRecordingStart()
        
        addMessage("You", "Started recording...", isUser: true)
    }
    
    private func stopRecording() {
        guard let audioURL = recorder.stopRecording() else {
            voiceState = .error("Failed to stop recording")
            return
        }
        
        voiceState = .processing
        speechBack.speakRecordingStop()
        
        Task {
            await processRecording(audioURL: audioURL)
        }
    }
    
    private func processRecording(audioURL: URL) async {
        do {
            guard let audioData = try? Data(contentsOf: audioURL) else {
                throw VoiceError.recordingFailed
            }
            
            // Create phrase hints from children names
            let phraseHints = children.map { $0.name } + ["points", "tomorrow", "today", "tonight"]
            
            // Process voice command
            let result = try await voiceService.processVoiceCommand(
                audioData: audioData,
                children: children,
                phraseHints: phraseHints
            )
            
            await MainActor.run {
                handleParseResult(result)
            }
            
        } catch {
            await MainActor.run {
                voiceState = .error(error.localizedDescription)
                speechBack.speakError(error.localizedDescription)
                addMessage("System", "Error: \(error.localizedDescription)", isUser: false)
            }
        }
    }
    
    private func handleParseResult(_ result: ParseResult) {
        if result.needsFollowup {
            // Need more information
            voiceState = .idle
            transcript = ""
            
            if let question = result.question {
                speechBack.speakFollowUp(question)
                addMessage("Assistant", question, isUser: false)
            }
        } else if let task = result.result {
            // Task created successfully
            voiceState = .idle
            currentTask = task
            
            // Find child name
            let childName = children.first { $0.id == task.childId }?.name ?? "Unknown"
            
            speechBack.speakConfirmation(task, childName: childName)
            addMessage("Assistant", "Task created: \(task.title) for \(childName)", isUser: false)
            
            // TODO: Save to Firestore using existing ChoreService
            saveTaskToFirestore(task)
        }
    }
    
    private func cancelProcessing() {
        voiceState = .idle
        transcript = ""
    }
    
    private func handleStateChange(_ newState: VoiceState) {
        // Handle state-specific actions
        switch newState {
        case .speaking:
            break
        case .idle:
            break
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadChildren() {
        // TODO: Load children from existing AuthService or ChoreService
        // For now, using mock data
        children = [
            VoiceChild(id: "child1", name: "Emma"),
            VoiceChild(id: "child2", name: "Zayn"),
            VoiceChild(id: "child3", name: "Liam")
        ]
    }
    
    private func addMessage(_ sender: String, _ text: String, isUser: Bool) {
        let message = ConversationMessage(
            id: UUID(),
            sender: sender,
            text: text,
            isUser: isUser,
            timestamp: Date()
        )
        conversationHistory.append(message)
    }
    
    private func saveTaskToFirestore(_ task: TaskFields) {
        // TODO: Integrate with existing ChoreService
        print("💾 Saving task to Firestore: \(task)")
    }
}

// MARK: - Conversation Models

struct ConversationMessage: Identifiable {
    let id: UUID
    let sender: String
    let text: String
    let isUser: Bool
    let timestamp: Date
}

struct ConversationBubble: View {
    let message: ConversationMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.sender)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(message.text)
                    .padding()
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(12)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

// MARK: - Configuration View

struct VoiceConfigView: View {
    @StateObject private var configService = VoiceConfigService.shared
    @State private var apiURL: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Server Configuration") {
                    TextField("API Base URL", text: $apiURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Test Connection") {
                        Task {
                            await testConnection()
                        }
                    }
                }
                
                Section("Current Settings") {
                    Text("Base URL: \(configService.apiBaseURL)")
                    Text("Status: \(configService.isConfigured ? "Configured" : "Not Configured")")
                }
            }
            .navigationTitle("Voice Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveConfiguration()
                    }
                }
            }
        }
        .onAppear {
            apiURL = configService.apiBaseURL
        }
    }
    
    private func testConnection() async {
        // TODO: Implement connection test
    }
    
    private func saveConfiguration() {
        configService.updateAPIBaseURL(apiURL)
        dismiss()
    }
}

#Preview {
    VoiceView()
}
