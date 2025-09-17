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
    @State private var currentTaskContext: TaskFields? = nil // Store partial task info
    
    // Chat UI states
    @State private var chatMessages: [ChatMessage] = []
    @State private var recordingAnimation = false
    @State private var isProcessing = false
    @State private var sessionId: String? = nil
    
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
                    .onChange(of: chatMessages.count) { _, _ in
                        if let lastMessage = chatMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isRecording) { _, _ in
                        if isRecording {
                            withAnimation {
                                proxy.scrollTo("recording", anchor: .bottom)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Recording Controls
                VStack(spacing: 24) {
                    // Status text
                    if !isRecording && !isProcessing {
                        Text(conversationStep == 0 ? "Tap and hold to speak" : "Tap and hold to respond")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Recording button with visualizer
                    ZStack {
                        // Background circle with shadow
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Recording button
                        Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            ZStack {
                                // Main button circle with recording animation
                                Circle()
                                    .fill(isRecording ? Color.red : themeColor)
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(isRecording ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: isRecording)
                                    .shadow(
                                        color: isRecording ? Color.red.opacity(0.6) : Color.clear,
                                        radius: isRecording ? 15 : 0,
                                        x: 0,
                                        y: 0
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: isRecording)
                                
                                // Multiple recording animation rings
                                if isRecording {
                                    ForEach(0..<3, id: \.self) { index in
                                        Circle()
                                            .stroke(Color.red.opacity(0.4 - Double(index) * 0.1), lineWidth: 2)
                                            .frame(width: 100 + CGFloat(index * 20), height: 100 + CGFloat(index * 20))
                                            .scaleEffect(recordingAnimation ? 1.5 : 1.0)
                                            .opacity(recordingAnimation ? 0.0 : 1.0)
                                            .animation(
                                                Animation.easeInOut(duration: 1.2)
                                                    .repeatForever(autoreverses: false)
                                                    .delay(Double(index) * 0.2),
                                                value: recordingAnimation
                                            )
                                    }
                                }
                                
                                // Icon with recording animation
                                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                                    .scaleEffect(isRecording ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: isRecording)
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
                    }
                    
                    // Status indicators
                    if isRecording {
                        VStack(spacing: 12) {
                            // Animated visualizer bars
                            HStack(spacing: 3) {
                                ForEach(0..<5, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.red)
                                        .frame(width: 4, height: 12)
                                        .scaleEffect(y: recordingAnimation ? CGFloat.random(in: 0.3...2.0) : 1.0)
                                        .animation(
                                            Animation.easeInOut(duration: 0.4)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(index) * 0.15),
                                            value: recordingAnimation
                                        )
                                }
                            }
                            .frame(height: 24)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(recordingAnimation ? 1.3 : 1.0)
                                    .animation(
                                        Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                        value: recordingAnimation
                                    )
                                
                                Text("Recording...")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            }
                            
                            Text("Release to stop")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .opacity(0.8)
                        }
                    } else if isProcessing {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                
                                Text("Processing...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.bottom, 30)
                .background(
                    ZStack {
                        Color(.systemBackground)
                        
                        // Subtle recording background animation
                        if isRecording {
                            Circle()
                                .fill(Color.red.opacity(0.05))
                                .frame(width: 200, height: 200)
                                .scaleEffect(recordingAnimation ? 1.2 : 1.0)
                                .opacity(recordingAnimation ? 0.0 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                                    value: recordingAnimation
                                )
                                .offset(y: -50)
                        }
                    }
                )
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
        AVAudioApplication.requestRecordPermission { granted in
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
        // Enhanced haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Additional haptic for recording start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }
        
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
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        isRecording = false
        recordingAnimation = false
        isProcessing = true
        
        // Check minimum recording duration (at least 2 seconds for better accuracy)
        if wavRecorder.recordingDuration < 2.0 {
            DispatchQueue.main.async {
                self.isProcessing = false
                // Remove recording placeholder
                if let lastMessage = self.chatMessages.last, lastMessage.isProcessing {
                    self.chatMessages.removeLast()
                }
                // Add AI message instead of modal
                let aiMessage = ChatMessage(text: "Please record for at least 2 seconds. Try speaking longer.", isUser: false)
                self.chatMessages.append(aiMessage)
                self.speechBack.speak("Please record for at least 2 seconds. Try speaking longer.")
            }
            return
        }
        
        // Remove recording placeholder and add processing message
        if let lastMessage = chatMessages.last, lastMessage.isProcessing {
            chatMessages.removeLast()
        }
        
        let processingMessage = ChatMessage(text: "🔄 Processing your speech...", isUser: false, isProcessing: true)
        chatMessages.append(processingMessage)
        
        if let _ = wavRecorder.stopRecording() {
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
                    isRecording = false
                    recordingAnimation = false
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
        
        // Add context about what was already discussed
        let contextInfo = getConversationContext()
        
        Task {
            do {
                let voiceResponse = try await voiceService.parseTranscript(transcript, children: children.map { VoiceChild(id: $0.id.uuidString, name: $0.name) }, sessionId: sessionId, context: contextInfo)
                
                await MainActor.run {
                    isProcessing = false
                    handleVoiceResponse(voiceResponse)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    isRecording = false
                    recordingAnimation = false
                    alertMessage = "Failed to parse transcript: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func getConversationContext() -> String {
        // Get recent conversation context with better formatting
        let recentMessages = chatMessages.suffix(6) // Last 6 messages for more context
        var contextParts: [String] = []
        
        for message in recentMessages {
            if message.isUser {
                contextParts.append("User: \(message.text)")
            } else {
                contextParts.append("AI: \(message.text)")
            }
        }
        
        let context = contextParts.joined(separator: " | ")
        return "Conversation history: \(context)"
    }
    
    // MARK: - Voice Response Handling
    private func handleVoiceResponse(_ response: VoiceResponse) {
        print("🔍 Voice response: \(response)")
        
        // Reset recording state
        isRecording = false
        recordingAnimation = false
        
        // Store sessionId for future requests
        if let newSessionId = response.sessionId {
            sessionId = newSessionId
        }
        
        // Use the exact sentence from the server
        let aiMessage = ChatMessage(text: response.speak, isUser: false)
        chatMessages.append(aiMessage)
        speechBack.speak(response.speak)
        
        if response.needsFollowup {
            // Handle follow-up question
            conversationStep = 1
        } else if response.result != nil {
            // Handle confirmed task creation
            if let taskFields = response.result {
                print("✅ Creating chore: \(taskFields)")
                createChore(from: taskFields)
            } else {
                print("❌ No task fields in confirmed response")
                let errorMessage = ChatMessage(text: "❌ Could not extract task information", isUser: false)
                chatMessages.append(errorMessage)
                speechBack.speak("Sorry, I couldn't understand what task you want to create.")
            }
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
        
        // Create new chore with clean description
        let newChore = Chore(
            title: taskFields.title,
            description: taskFields.title, // Use the natural title as description
            points: taskFields.points,
            dueDate: dueDate,
            isCompleted: false,
            isRequired: true,
            assignedToChildId: child.id,
            createdAt: Date()
        )
        
        // Save to Firestore
        Task {
            choreService.addChore(newChore)
            
            await MainActor.run {
                // Add success message (clean confirmation)
                let successMessage = ChatMessage(text: "✅ \(taskFields.title) for \(child.name), due \(formatDate(dueDate)), worth \(taskFields.points) points", isUser: false)
                chatMessages.append(successMessage)
                
                // Speak confirmation
                let confirmationText = "Done! \(taskFields.title) for \(child.name), due \(formatDate(dueDate)), worth \(taskFields.points) points."
                speechBack.speak(confirmationText)
                
                conversationStep = 2
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
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(themeColor)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
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
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(themeColor)
                        .rotationEffect(.degrees(animationRotation))
                        .animation(
                            Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                            value: animationRotation
                        )
                    
                    Text("🔄 Processing...")
                        .font(.subheadline)
                        .foregroundColor(themeColor)
                }
                
                Text("Please wait")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
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