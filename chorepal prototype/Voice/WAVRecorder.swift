import Foundation
import AVFoundation
import Combine

// MARK: - WAV Audio Recorder

class WAVRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var error: VoiceError?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingURL: URL?
    
    // Audio settings for Google Speech-to-Text
    private let audioSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 16000.0,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsNonInterleaved: false
    ]
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopRecording()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            self.error = .recordingFailed
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording() {
        guard !isRecording else { return }
        
        do {
            // Create temporary file URL
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            recordingURL = documentsPath.appendingPathComponent("voice_recording_\(Date().timeIntervalSince1970).wav")
            
            // Initialize recorder
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: audioSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            // Start recording
            let success = audioRecorder?.record() ?? false
            if success {
                isRecording = true
                recordingDuration = 0
                startTimer()
                print("🎤 Started recording to: \(recordingURL!.path)")
            } else {
                throw VoiceError.recordingFailed
            }
            
        } catch {
            print("❌ Failed to start recording: \(error)")
            self.error = .recordingFailed
        }
    }
    
    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
        
        let recordedURL = recordingURL
        recordingURL = nil
        
        print("🛑 Stopped recording")
        return recordedURL
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.recordingDuration += 0.1
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // MARK: - Audio Data Access
    
    func getRecordingData() -> Data? {
        guard let url = recordingURL, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("📊 Recording data size: \(data.count) bytes")
            return data
        } catch {
            print("❌ Failed to read recording data: \(error)")
            return nil
        }
    }
    
    func cleanup() {
        if let url = recordingURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
    }
}

// MARK: - AVAudioRecorderDelegate

extension WAVRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("❌ Recording failed")
            self.error = .recordingFailed
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ Recording encode error: \(error?.localizedDescription ?? "Unknown")")
        self.error = .recordingFailed
    }
}
