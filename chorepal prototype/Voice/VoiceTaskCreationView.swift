import SwiftUI
import AVFoundation

// MARK: - Voice Task Creation View
struct VoiceTaskCreationView: View {
    @ObservedObject var choreService: ChoreService
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var voiceService = VoiceService()
    @StateObject private var speechBack = SpeechBack()
    @StateObject private var wavRecorder = WAVRecorder()
    
    @State private var isRecording = false
    @State private var isLoading = false
    @State private var transcript = ""
    @State private var currentQuestion = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var conversationStep = 0 // 0: initial, 1: follow-up, 2: complete
    
    // Chat UI states
    @State private var chatMessages: [ChatMessage] = []
    @State private var recordingAnimation = false
    @State private var isProcessing = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Text("Voice Tasks")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(themeColor)
                        .opacity(conversationStep == 2 ? 1 : 0)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                }
                .background(Color(.systemBackground))
                
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message
                            if chatMessages.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(themeColor)
                                    
                                    Text("Speak your chore assignment")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    Text("Example: \"Make dishes for Emma tomorrow worth 20 points\"")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .padding(.vertical, 40)
                            }
                            
                            // Chat messages
                            ForEach(chatMessages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            // Recording indicator
                            if isRecording {
                                RecordingIndicatorView()
                                    .id("recording")
                            }
                            
                            // Processing indicator
                            if isProcessing {
                                ProcessingIndicatorView()
                                    .id("processing")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                    .onChange(of: chatMessages.count) { _ in
                        if let lastMessage = chatMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isRecording) { _ in
                        if isRecording {
                            withAnimation {
                                proxy.scrollTo("recording", anchor: .bottom)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Recording Controls
                VStack(spacing: 20) {
                    // Status text
                    if !isRecording && !isProcessing {
                        Text(conversationStep == 0 ? "Tap and hold to speak" : "Tap and hold to respond")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Recording button
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : themeColor)
                                .frame(width: 80, height: 80)
                                .scaleEffect(isRecording ? (recordingAnimation ? 1.2 : 1.0) : 1.0)
                                .animation(
                                    isRecording ? 
                                    Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) :
                                    .default,
                                    value: recordingAnimation
                                )
                            
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isProcessing)
                    .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
                        if pressing && !isRecording && !isProcessing {
                            startRecording()
                        } else if !pressing && isRecording {
                            stopRecording()
                        }
                    }, perform: {})
                    
                    // Recording status
                    if isRecording {
                        VStack(spacing: 8) {
                            Text("Recording...")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text("Release to stop")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else if isProcessing {
                        Text("Processing your request...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 30)
                .background(Color(.systemBackground))
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            setupVoiceComponents()
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Voice Setup
    private func setupVoiceComponents() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.alertMessage = "Microphone permission is required for voice tasks"
                    self.showingAlert = true
                }
            }
        }
    }
    
    // MARK: - Recording Functions
    private func startRecording() {
        isRecording = true
        recordingAnimation = true
        transcript = ""
        currentQuestion = ""
        
        // Add user message placeholder
        let userMessage = ChatMessage(text: "🎤 Recording...", isUser: true, isProcessing: true)
        chatMessages.append(userMessage)
        
        wavRecorder.startRecording()
    }
    
    private func stopRecording() {
        isRecording = false
        recordingAnimation = false
        isProcessing = true
        
        // Check minimum recording duration (at least 1 second)
        if wavRecorder.recordingDuration < 1.0 {
            DispatchQueue.main.async {
                self.isProcessing = false
                // Remove recording placeholder
                if let lastMessage = self.chatMessages.last, lastMessage.isProcessing {
                    self.chatMessages.removeLast()
                }
                // Add AI message instead of modal
                let aiMessage = ChatMessage(text: "Please record for at least 1 second. Try speaking longer.", isUser: false)
                self.chatMessages.append(aiMessage)
                self.speechBack.speak("Please record for at least 1 second. Try speaking longer.")
            }
            return
        }
        
        // Remove recording placeholder and add processing message
        if let lastMessage = chatMessages.last, lastMessage.isProcessing {
            chatMessages.removeLast()
        }
        
        let processingMessage = ChatMessage(text: "🔄 Processing your speech...", isUser: false, isProcessing: true)
        chatMessages.append(processingMessage)
        
        if wavRecorder.stopRecording() != nil {
            if let audioData = wavRecorder.getRecordingData() {
                print("🎤 Recording completed - Duration: \(wavRecorder.recordingDuration)s, Size: \(audioData.count) bytes")
                wavRecorder.clearRecordingURL() // Clear the URL after getting data
                processAudio(audioData)
            } else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.alertMessage = "Failed to get recording data"
                    self.showingAlert = true
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.alertMessage = "Failed to stop recording"
                self.showingAlert = true
            }
        }
    }
    
    // MARK: - Audio Processing
    private func processAudio(_ audioData: Data) {
        Task {
            do {
                let transcript = try await voiceService.uploadSTT(audioData: audioData)
                
                await MainActor.run {
                    // Remove processing message
                    if let lastMessage = chatMessages.last, lastMessage.isProcessing {
                        chatMessages.removeLast()
                    }
                    
                    // Add user transcript
                    let userMessage = ChatMessage(text: transcript, isUser: true)
                    chatMessages.append(userMessage)
                    
                    // Process transcript
                    processTranscript(transcript)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Remove processing message
                    if let lastMessage = chatMessages.last, lastMessage.isProcessing {
                        chatMessages.removeLast()
                    }
                    alertMessage = "Failed to process audio: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func processTranscript(_ transcript: String) {
        let children = authService.currentParent?.children ?? []
        
        Task {
            do {
                let parseResult = try await voiceService.parseTranscript(transcript, children: children.map { VoiceChild(id: $0.id.uuidString, name: $0.name) })
                
                await MainActor.run {
                    isProcessing = false
                    handleParseResult(parseResult)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Failed to parse transcript: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    // MARK: - Parse Result Handling
    private func handleParseResult(_ result: ParseResult) {
        print("🔍 Parse result: \(result)")
        
        if let error = result.error {
            print("❌ Parse error: \(error)")
            let errorMessage = ChatMessage(text: "❌ Error: \(error)", isUser: false)
            chatMessages.append(errorMessage)
            speechBack.speak("Sorry, there was an error processing your request.")
            return
        }
        
        if result.needsFollowup {
            print("🤖 Needs follow-up: \(result.question ?? "No question")")
            // Ask follow-up question
            if let question = result.question {
                let aiMessage = ChatMessage(text: "🤖 \(question)", isUser: false)
                chatMessages.append(aiMessage)
                speechBack.speak(question)
                conversationStep = 1
            }
        } else if let taskFields = result.result {
            print("✅ Creating chore: \(taskFields)")
            // Create the chore
            createChore(from: taskFields)
        } else {
            print("❌ No task fields in result")
            let errorMessage = ChatMessage(text: "❌ Could not extract task information", isUser: false)
            chatMessages.append(errorMessage)
            speechBack.speak("Sorry, I couldn't understand what task you want to create.")
        }
    }
    
    // MARK: - Chore Creation
    private func createChore(from taskFields: TaskFields) {
        guard let child = authService.currentParent?.children.first(where: { $0.id.uuidString == taskFields.childId }) else {
            let errorMessage = ChatMessage(text: "❌ Child not found", isUser: false)
            chatMessages.append(errorMessage)
            speechBack.speak("Sorry, I couldn't find that child.")
            return
        }
        
        // Parse the due date
        let dueDate: Date
        let formatter = ISO8601DateFormatter()
        dueDate = formatter.date(from: taskFields.dueAt) ?? Date()
        
        // Create new chore
        let newChore = Chore(
            title: taskFields.title,
            description: "Created via voice command",
            points: taskFields.points,
            dueDate: dueDate,
            isCompleted: false,
            isRequired: true,
            assignedToChildId: child.id,
            createdAt: Date()
        )
        
        // Save to Firestore
        Task {
            do {
                try await choreService.addChore(newChore)
                
                await MainActor.run {
                    // Add success message
                    let successMessage = ChatMessage(text: "✅ Task created: \(taskFields.title) for \(child.name), due \(formatDate(dueDate)), worth \(taskFields.points) points", isUser: false)
                    chatMessages.append(successMessage)
                    
                    // Speak confirmation
                    let confirmationText = "Done! \(taskFields.title) for \(child.name), due \(formatDate(dueDate)), worth \(taskFields.points) points."
                    speechBack.speak(confirmationText)
                    
                    conversationStep = 2
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(text: "❌ Failed to save task: \(error.localizedDescription)", isUser: false)
                    chatMessages.append(errorMessage)
                    speechBack.speak("Sorry, I couldn't save the task.")
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(20)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Recording Indicator View
struct RecordingIndicatorView: View {
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationScale)
                        .animation(
                            Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                            value: animationScale
                        )
                    
                    Text("🎤 Recording...")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                
                Text("Release to stop")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            
            Spacer()
        }
        .onAppear {
            animationScale = 1.3
        }
    }
}

// MARK: - Processing Indicator View
struct ProcessingIndicatorView: View {
    @State private var animationRotation: Double = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(animationRotation))
                        .animation(
                            Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                            value: animationRotation
                        )
                    
                    Text("🔄 Processing...")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Text("Please wait")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            
            Spacer()
        }
        .onAppear {
            animationRotation = 360
        }
    }
}

// MARK: - Preview
struct VoiceTaskCreationView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceTaskCreationView(
            choreService: ChoreService(),
            authService: AuthService()
        )
    }
}