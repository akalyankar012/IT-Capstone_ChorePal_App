import Foundation
import AVFoundation
import Combine

// MARK: - Speech Synthesis Service

class SpeechBack: NSObject, ObservableObject {
    @Published var isSpeaking = false
    @Published var error: VoiceError?
    
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    
    // Voice configuration - Jarvis-style settings
    private let voiceLanguage = "en-GB" // British sophistication
    private let speechRate: Float = 0.5  // Deliberate pace
    private let speechPitch: Float = 0.8 // Lower, authoritative tone
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to setup audio session for speech: \(error)")
        }
    }
    
    // MARK: - Speech Control
    
    func speak(_ text: String, rate: Float? = nil, pitch: Float? = nil) {
        guard !text.isEmpty else { return }
        
        // Stop any current speech
        stopSpeaking()
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate ?? speechRate
        utterance.pitchMultiplier = pitch ?? speechPitch
        utterance.volume = 1.0
        
        // Use configured voice
        if let voice = AVSpeechSynthesisVoice(language: voiceLanguage) {
            utterance.voice = voice
        }
        
        currentUtterance = utterance
        synthesizer.speak(utterance)
        
        print("🔊 Speaking: \(text)")
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentUtterance = nil
    }
    
    // MARK: - Predefined Messages
    
    func speakWelcome() {
        speak("Welcome to voice task creation. Tap and hold the microphone to start recording your task.")
    }
    
    func speakRecordingStart() {
        speak("Recording started. Speak your task now.")
    }
    
    func speakRecordingStop() {
        speak("Recording stopped. Processing your request.")
    }
    
    func speakProcessing() {
        speak("Processing your voice command.")
    }
    
    func speakFollowUp(_ question: String) {
        speak("I need more information. \(question)")
    }
    
    func speakConfirmation(_ task: TaskFields, childName: String) {
        let dueDate = formatDateForSpeech(task.dueAt)
        let message = "Done! \(task.title) for \(childName), due \(dueDate), worth \(task.points) points."
        speak(message)
    }
    
    func speakError(_ message: String) {
        speak("Sorry, there was an error: \(message)")
    }
    
    // MARK: - Voice Selection
    
    func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices()
    }
    
    func getEnglishVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.hasPrefix("en")
        }
    }
    
    func setVoice(language: String) {
        // This would be used to change the voice at runtime
        // For now, we'll use the configured voice
        print("🎤 Voice set to: \(language)")
    }
    
    // MARK: - Date Formatting
    
    private func formatDateForSpeech(_ isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoDate) else {
            return "at the specified time"
        }
        
        let speechFormatter = DateFormatter()
        speechFormatter.dateStyle = .medium
        speechFormatter.timeStyle = .short
        speechFormatter.timeZone = TimeZone(identifier: "America/Chicago")
        
        return speechFormatter.string(from: date)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechBack: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
        print("🔊 Speech started")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
        print("🔊 Speech finished")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
        print("🔊 Speech cancelled")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // Optional: Handle word highlighting or other visual feedback
    }
}

