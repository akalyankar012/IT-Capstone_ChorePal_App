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
    @State private var turnIndex = 0
    @State private var userId: String = ""
    @State private var isSessionReady = false
    @State private var lastChildrenSignature = ""
    
    // Enhanced animation states
    @State private var pulseAnimation = false
    @State private var waveAnimation = false
    @State private var shimmerAnimation = false
    @State private var bounceAnimation = false
    @State private var rotationAnimation = false
    @State private var scaleAnimation = false
    
    private let themeColor = Color(hex: "#a2cee3")
    private let accentColor = Color(hex: "#4A90E2")
    private let successColor = Color(hex: "#4CAF50")
    private let warningColor = Color(hex: "#FF9800")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced Header with Animations
                VStack(spacing: 16) {
                    HStack {
                        Button("Cancel") {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                dismiss()
                            }
                        }
                        .foregroundColor(.red)
                        .font(.system(size: 16, weight: .medium))
                        .scaleEffect(bounceAnimation ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounceAnimation)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(accentColor)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                            
                            Text("Voice Tasks")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button("Done") {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                dismiss()
                            }
                        }
                        .foregroundColor(successColor)
                        .font(.system(size: 16, weight: .semibold))
                        .opacity(conversationStep == 2 ? 1 : 0)
                        .scaleEffect(conversationStep == 2 ? 1.0 : 0.8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: conversationStep)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Animated progress indicator
                    if conversationStep > 0 {
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(index < conversationStep ? accentColor : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index < conversationStep ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.1), value: conversationStep)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    Divider()
                        .background(LinearGradient(colors: [.clear, accentColor.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                }
                .background(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Enhanced Welcome message with animations
                            if chatMessages.isEmpty {
                                VStack(spacing: 24) {
                                    // Animated microphone icon
                                    ZStack {
                                        // Pulsing background circles
                                        ForEach(0..<3, id: \.self) { index in
                                            Circle()
                                                .stroke(accentColor.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                                                .frame(width: 80 + CGFloat(index * 20), height: 80 + CGFloat(index * 20))
                                                .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                                                .opacity(pulseAnimation ? 0.0 : 1.0)
                                                .animation(
                                                    Animation.easeInOut(duration: 2.0)
                                                        .repeatForever(autoreverses: false)
                                                        .delay(Double(index) * 0.3),
                                                    value: pulseAnimation
                                                )
                                        }
                                        
                                        // Main microphone icon
                                        Image(systemName: "mic.fill")
                                            .font(.system(size: 50, weight: .medium))
                                            .foregroundColor(accentColor)
                                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                                    }
                                    .onAppear {
                                        pulseAnimation = true
                                    }
                                    
                                    VStack(spacing: 12) {
                                        Text("Create a Task with Your Voice")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                        
                                        Text("Say the child's name, task, due date/time, and points")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                        
                                        Text("Example: \"Make Emma wash dishes tomorrow at 5pm for 20 points\"")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary.opacity(0.8))
                                            .italic()
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                            .opacity(shimmerAnimation ? 0.7 : 1.0)
                                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: shimmerAnimation)
                                    }
                                    
                                    // Animated dots
                                    HStack(spacing: 8) {
                                        ForEach(0..<3, id: \.self) { index in
                                            Circle()
                                                .fill(accentColor)
                                                .frame(width: 8, height: 8)
                                                .scaleEffect(waveAnimation ? 1.5 : 1.0)
                                                .opacity(waveAnimation ? 0.3 : 1.0)
                                                .animation(
                                                    Animation.easeInOut(duration: 1.0)
                                                        .repeatForever(autoreverses: true)
                                                        .delay(Double(index) * 0.2),
                                                    value: waveAnimation
                                                )
                                        }
                                    }
                                    .onAppear {
                                        waveAnimation = true
                                    }
                                }
                                .padding(.vertical, 60)
                                .onAppear {
                                    shimmerAnimation = true
                                }
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
                        Text(conversationStep == 0 ? "Tap to start recording" : "Tap again to respond")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if !isSessionReady {
                        Text("Connecting to voice assistant…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Enhanced Recording button with advanced animations
                    ZStack {
                        // Animated background with gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isRecording ? 
                                        [Color.red.opacity(0.1), Color.red.opacity(0.05)] :
                                        [accentColor.opacity(0.1), accentColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .scaleEffect(isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.5), value: isRecording)
                            .shadow(
                                color: isRecording ? Color.red.opacity(0.3) : accentColor.opacity(0.2),
                                radius: isRecording ? 20 : 10,
                                x: 0,
                                y: 0
                            )
                            .animation(.easeInOut(duration: 0.5), value: isRecording)
                        
                        // Multiple animated rings for recording
                        if isRecording {
                            ForEach(0..<4, id: \.self) { index in
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.red.opacity(0.6), Color.red.opacity(0.2)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 90 + CGFloat(index * 25), height: 90 + CGFloat(index * 25))
                                    .scaleEffect(recordingAnimation ? 1.8 : 1.0)
                                    .opacity(recordingAnimation ? 0.0 : 0.8)
                                    .animation(
                                        Animation.easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.3),
                                        value: recordingAnimation
                                    )
                            }
                        }
                        
                        // Main button with enhanced styling
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                if isRecording {
                                    stopRecording()
                                } else {
                                    startRecording()
                                }
                            }
                        }) {
                            ZStack {
                                // Button background with gradient
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: isRecording ? 
                                                [Color.red, Color.red.opacity(0.8)] :
                                                [accentColor, accentColor.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 85, height: 85)
                                    .scaleEffect(isRecording ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isRecording)
                                    .shadow(
                                        color: isRecording ? Color.red.opacity(0.4) : accentColor.opacity(0.3),
                                        radius: isRecording ? 12 : 8,
                                        x: 0,
                                        y: 4
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: isRecording)
                                
                                // Inner glow effect
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .scaleEffect(isRecording ? 1.2 : 1.0)
                                    .opacity(isRecording ? 0.8 : 0.4)
                                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRecording)
                                
                                // Icon with enhanced animation
                                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundColor(.white)
                                    .scaleEffect(isRecording ? 1.2 : 1.0)
                                    .rotationEffect(.degrees(isRecording ? 180 : 0))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isRecording)
                            }
                        }
                        .disabled(isProcessing)
                        .scaleEffect(bounceAnimation ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounceAnimation)
                    }
                    
                    // Enhanced Status indicators with advanced animations
                    if isRecording {
                        VStack(spacing: 16) {
                            // Advanced audio visualizer
                            HStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.red, Color.red.opacity(0.6)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 6, height: 20)
                                        .scaleEffect(y: recordingAnimation ? CGFloat.random(in: 0.2...2.5) : 1.0)
                                        .animation(
                                            Animation.easeInOut(duration: 0.6)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(index) * 0.1),
                                            value: recordingAnimation
                                        )
                                }
                            }
                            .frame(height: 30)
                            .padding(.horizontal, 20)
                            
                            // Recording status with enhanced styling
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.2))
                                        .frame(width: 16, height: 16)
                                        .scaleEffect(recordingAnimation ? 1.5 : 1.0)
                                        .opacity(recordingAnimation ? 0.0 : 1.0)
                                        .animation(
                                            Animation.easeInOut(duration: 1.0)
                                                .repeatForever(autoreverses: false),
                                            value: recordingAnimation
                                        )
                                    
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 12, height: 12)
                                        .scaleEffect(recordingAnimation ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recordingAnimation)
                                }
                                
                                Text("Recording...")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.red)
                                    .opacity(recordingAnimation ? 0.8 : 1.0)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: recordingAnimation)
                            }
                            
                            Text("Tap again to stop")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .opacity(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.red.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    } else if isProcessing {
                        VStack(spacing: 16) {
                            // Enhanced processing indicator
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(accentColor.opacity(0.3), lineWidth: 3)
                                        .frame(width: 24, height: 24)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.7)
                                        .stroke(
                                            LinearGradient(
                                                colors: [accentColor, accentColor.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                        )
                                        .frame(width: 24, height: 24)
                                        .rotationEffect(.degrees(rotationAnimation ? 360 : 0))
                                        .animation(
                                            Animation.linear(duration: 1.0)
                                                .repeatForever(autoreverses: false),
                                            value: rotationAnimation
                                        )
                                }
                                
                                Text("Processing...")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(accentColor)
                            }
                            
                            Text("Please wait")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .opacity(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(accentColor.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        .onAppear {
                            rotationAnimation = true
                        }
                    }
                }
                .padding(.bottom, 30)
                .background(
                    ZStack {
                        // Enhanced background with gradient
                        LinearGradient(
                            colors: [
                                Color(.systemBackground),
                                Color(.systemBackground).opacity(0.95),
                                accentColor.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Animated background elements
                        if isRecording {
                            // Multiple pulsing circles
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.red.opacity(0.1 - Double(index) * 0.03),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 50,
                                            endRadius: 150
                                        )
                                    )
                                    .frame(width: 300 + CGFloat(index * 100), height: 300 + CGFloat(index * 100))
                                    .scaleEffect(recordingAnimation ? 1.5 : 1.0)
                                    .opacity(recordingAnimation ? 0.0 : 1.0)
                                    .animation(
                                        Animation.easeInOut(duration: 2.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.5),
                                        value: recordingAnimation
                                    )
                                    .offset(y: -100 - CGFloat(index * 20))
                            }
                        } else {
                            // Subtle ambient animation
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [accentColor.opacity(0.05), Color.clear],
                                        center: .center,
                                        startRadius: 50,
                                        endRadius: 200
                                    )
                                )
                                .frame(width: 400, height: 400)
                                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                .opacity(pulseAnimation ? 0.3 : 0.1)
                                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulseAnimation)
                                .offset(y: -150)
                        }
                    }
                )
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            setupVoiceComponents()
            startNewSession()
            
            // Start ambient animations
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
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
    
    // MARK: - Session Management
    private func startNewSession() {
        guard let parent = authService.currentParent else {
            alertMessage = "No parent logged in"
            showingAlert = true
            return
        }
        
        userId = parent.id.uuidString
        let children = parent.children.map { VoiceChild(id: $0.id.uuidString, name: $0.name) }
        
        Task {
            do {
                let newSessionId = try await voiceService.startVoiceSession(userId: userId, children: children)
                await MainActor.run {
                    sessionId = newSessionId
                    turnIndex = 0
                    conversationStep = 0
                    currentTaskContext = nil
                    print("🆕 Started new session: \(newSessionId)")
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to start voice session: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    // MARK: - Enhanced Recording Functions
    private func startRecording() {
        // Prevent multiple recording starts
        guard !isRecording && !isProcessing else {
            print("⚠️ Recording already in progress, ignoring start request")
            return
        }
        
        print("🎤 startRecording() - sessionId: \(sessionId ?? "nil"), conversationStep: \(conversationStep)")
        
        // Enhanced haptic feedback sequence
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Additional haptic feedback for recording start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }
        
        // Success haptic after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        // Don't clear session - let the server manage it properly
        isRecording = true
        recordingAnimation = true
        transcript = ""
        currentQuestion = ""
        
        // Add user message placeholder
        let userMessage = ChatMessage(text: "Recording...", isUser: true, isProcessing: true)
        chatMessages.append(userMessage)
        
        wavRecorder.startRecording()
    }
    
    private func stopRecording() {
        // Enhanced haptic feedback sequence
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Additional haptic for recording stop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }
        
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
        guard let sessionId = sessionId else {
            print("❌ No session ID available")
            DispatchQueue.main.async {
                self.isProcessing = false
                self.alertMessage = "No active session. Please try again."
                self.showingAlert = true
            }
            return
        }
        
        let turnId = UUID().uuidString
        let currentTurnIndex = turnIndex
        turnIndex += 1
        
        Task {
            do {
                let voiceResponse = try await voiceService.processTurn(
                    audioData: audioData,
                    sessionId: sessionId,
                    turnId: turnId,
                    turnIndex: currentTurnIndex,
                    userId: userId,
                    children: authService.currentParent?.children.map { VoiceChild(id: $0.id.uuidString, name: $0.name) } ?? []
                )
                
                await MainActor.run {
                    // Remove processing message
                    if let lastMessage = chatMessages.last, lastMessage.isProcessing {
                        chatMessages.removeLast()
                    }
                    
                    // User transcript is handled by the server response
                    
                    // Handle the response
                    handleVoiceResponse(voiceResponse)
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
                    
                    // Handle session errors by restarting
                    if case VoiceError.sessionExpired = error {
                        print("🔄 Session expired, restarting...")
                        startNewSession()
                    } else {
                        alertMessage = "Failed to process audio: \(error.localizedDescription)"
                        showingAlert = true
                    }
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
    @MainActor
    private func handleVoiceResponse(_ response: VoiceResponse) {
        print("🔍 handleVoiceResponse() - sessionId: \(sessionId ?? "nil"), conversationStep: \(conversationStep)")
        print("🔍 Voice response: \(response)")

        // All UI updates are now guaranteed to be on main thread via @MainActor
            // Reset recording and processing state
            self.isRecording = false
            self.recordingAnimation = false
            self.isProcessing = false
            
            // Remove any processing message
            if let lastMessage = self.chatMessages.last, lastMessage.isProcessing {
                self.chatMessages.removeLast()
            }
            
            // Use the exact sentence from the server
            let aiMessage = ChatMessage(text: response.speak, isUser: false)
            self.chatMessages.append(aiMessage)
            
            // Speak the response
            self.speechBack.speak(response.speak)
            
            if response.needsFollowup {
                // Handle follow-up question
                self.conversationStep = 1
            } else if response.result != nil {
                // Handle confirmed task creation
                if let taskFields = response.result {
                    print("✅ Creating chore: \(taskFields)")
                    self.createChore(from: taskFields)
                    
                    // Don't start new session immediately - let user continue with more tasks
                    // Only start new session if explicitly requested
                } else {
                    print("❌ No task fields in confirmed response")
                    let errorMessage = ChatMessage(text: "❌ Could not extract task information", isUser: false)
                    self.chatMessages.append(errorMessage)
                    self.speechBack.speak("Sorry, I couldn't understand what task you want to create.")
                }
            } else {
                // Handle cases where no followup and no result (e.g., cancellation, noop)
                print("ℹ️ No follow-up or result, likely noop or cancellation.")
                // Don't clear session - let it continue for follow-ups
            }
            
            print("🔍 handleVoiceResponse() - After: sessionId: \(self.sessionId ?? "nil"), conversationStep: \(self.conversationStep)")
    }
    
    // MARK: - Chore Creation
    private func createChore(from taskFields: TaskFields) {
        print("✅ createChore() - sessionId: \(sessionId ?? "nil"), conversationStep: \(conversationStep)")
        
        guard let child = authService.currentParent?.children.first(where: { $0.id.uuidString == taskFields.childId }) else {
            let errorMessage = ChatMessage(text: "❌ Child not found", isUser: false)
            chatMessages.append(errorMessage)
            speechBack.speak("Sorry, I couldn't find that child.")
            return
        }
        
        // Parse the due date - server now sends Unix timestamp
        let dueDate: Date
        if let timestamp = Double(taskFields.dueAt) {
            dueDate = Date(timeIntervalSince1970: timestamp / 1000) // Convert from milliseconds to seconds
        } else {
            // Fallback to ISO parsing if it's still a string
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone(identifier: "UTC")
            dueDate = formatter.date(from: taskFields.dueAt) ?? Date()
        }
        
        print("🗓️ Server date: \(taskFields.dueAt)")
        print("🗓️ Parsed date: \(dueDate)")
        print("🗓️ Local timezone: \(TimeZone.current.identifier)")
        print("🗓️ Date in local time: \(DateFormatter.localizedString(from: dueDate, dateStyle: .medium, timeStyle: .short))")
        
        // Verify the date is correct
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        print("🗓️ Date components: year=\(components.year ?? 0), month=\(components.month ?? 0), day=\(components.day ?? 0), hour=\(components.hour ?? 0), minute=\(components.minute ?? 0)")
        
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
                // Add success message (clean confirmation) - don't speak, server already spoke the confirmation
                let successMessage = ChatMessage(text: "Task created: \(taskFields.title) for \(child.name), due \(formatDate(dueDate)), worth \(taskFields.points) points", isUser: false)
                chatMessages.append(successMessage)
                
                // Don't speak here - the server response was already spoken in handleVoiceResponse
                print("✅ createChore() - Task created successfully")
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

// MARK: - Enhanced Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage
    @State private var appearAnimation = false
    @State private var shimmerAnimation = false
    
    private let themeColor = Color(hex: "#a2cee3")
    private let accentColor = Color(hex: "#4A90E2")
    private let successColor = Color(hex: "#4CAF50")
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                        Text(message.text)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [themeColor, themeColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(22)
                            .shadow(
                                color: themeColor.opacity(0.4),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                            .scaleEffect(appearAnimation ? 1.0 : 0.8)
                            .opacity(appearAnimation ? 1.0 : 0.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                    
                    Text(formatTime(message.timestamp))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        // AI avatar
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                            .scaleEffect(appearAnimation ? 1.0 : 0.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: appearAnimation)
                        
                        Text(message.text)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(.systemGray6), Color(.systemGray5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.primary)
                            .cornerRadius(22)
                            .shadow(
                                color: .black.opacity(0.08),
                                radius: 6,
                                x: 0,
                                y: 3
                            )
                            .scaleEffect(appearAnimation ? 1.0 : 0.8)
                            .opacity(appearAnimation ? 1.0 : 0.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appearAnimation)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                        .padding(.leading, 32)
                }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation {
                appearAnimation = true
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Enhanced Recording Indicator View
struct RecordingIndicatorView: View {
    @State private var animationScale: CGFloat = 1.0
    @State private var pulseAnimation = false
    @State private var waveAnimation = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        // Pulsing background
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 16, height: 16)
                            .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: false),
                                value: pulseAnimation
                            )
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .scaleEffect(animationScale)
                            .animation(
                                Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                value: animationScale
                            )
                    }
                    
                    Text("Recording...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                        .opacity(waveAnimation ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: waveAnimation)
                }
                
                Text("Tap again to stop")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.red.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(
                color: Color.red.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
            
            Spacer()
        }
        .onAppear {
            animationScale = 1.3
            pulseAnimation = true
            waveAnimation = true
        }
    }
}

// MARK: - Enhanced Processing Indicator View
struct ProcessingIndicatorView: View {
    @State private var animationRotation: Double = 0
    @State private var pulseAnimation = false
    @State private var shimmerAnimation = false
    
    private let accentColor = Color(hex: "#4A90E2")
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        // Outer ring
                        Circle()
                            .stroke(accentColor.opacity(0.3), lineWidth: 3)
                            .frame(width: 24, height: 24)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                        
                        // Spinning progress ring
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(animationRotation))
                            .animation(
                                Animation.linear(duration: 1.0)
                                    .repeatForever(autoreverses: false),
                                value: animationRotation
                            )
                    }
                    
                    Text("Processing...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)
                        .opacity(shimmerAnimation ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: shimmerAnimation)
                }
                
                Text("Please wait")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(accentColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(
                color: accentColor.opacity(0.1),
                radius: 6,
                x: 0,
                y: 3
            )
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75)
            
            Spacer()
        }
        .onAppear {
            animationRotation = 360
            pulseAnimation = true
            shimmerAnimation = true
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