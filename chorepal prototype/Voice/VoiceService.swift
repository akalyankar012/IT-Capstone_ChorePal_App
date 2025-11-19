import Foundation
import Combine

// MARK: - Voice API Service

class VoiceService: ObservableObject {
    @Published var isLoading = false
    @Published var error: VoiceError?
    
    private let config = VoiceConfigService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        config.loadSavedConfiguration()
    }
    
    // MARK: - Health Check
    
    func checkServerHealth() async throws -> Bool {
        guard let url = URL(string: config.healthEndpoint) else {
            throw VoiceError.networkError
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VoiceError.networkError
        }
        
        let healthData = try JSONDecoder().decode(HealthResponse.self, from: data)
        print("✅ Server health check passed: \(healthData)")
        return true
    }
    
    // MARK: - Speech-to-Text
    
    func uploadSTT(audioData: Data, phraseHints: [String] = []) async throws -> String {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        guard let url = URL(string: config.sttEndpoint) else {
            throw VoiceError.networkError
        }
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        print("DEBUG: Audio data size in VoiceService before sending: \(audioData.count) bytes")
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add common chore-related phrase hints for better accuracy
        let defaultHints = ["make", "create", "assign", "task", "chore", "clean", "wash", "dishes", "room", "bed", "trash", "points", "tomorrow", "today", "Friday", "child", "children", "worth", "should", "be", "completed", "when", "who", "what", "how", "many", "name", "person"]
        let allHints = phraseHints + defaultHints
        request.setValue(allHints.joined(separator: ","), forHTTPHeaderField: "x-phrase-hints")
        
        request.httpBody = body
        
        print("🎤 Uploading audio to STT endpoint...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoiceError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ STT upload failed: \(httpResponse.statusCode) - \(errorMessage)")
            throw VoiceError.uploadFailed
        }
        
        let sttResponse = try JSONDecoder().decode(STTResponse.self, from: data)
        print("✅ STT response: \(sttResponse.text)")
        return sttResponse.text
    }
    
    // MARK: - Parse Transcript
    
    func parseTranscript(_ transcript: String, children: [VoiceChild], sessionId: String? = nil, context: String? = nil) async throws -> VoiceResponse {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        guard let url = URL(string: config.parseEndpoint) else {
            throw VoiceError.networkError
        }
        
        let parseRequest = ParseRequest(
            transcript: transcript,
            children: children,
            currentDate: ISO8601DateFormatter().string(from: Date()),
            conversationContext: context,
            sessionId: sessionId
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(parseRequest)
        } catch {
            print("❌ Failed to encode parse request: \(error)")
            throw VoiceError.networkError
        }
        
        print("🤖 Sending transcript to parse endpoint...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoiceError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Parse request failed: \(httpResponse.statusCode) - \(errorMessage)")
            throw VoiceError.parsingFailed
        }
        
        let voiceResponse = try JSONDecoder().decode(VoiceResponse.self, from: data)
        print("✅ Voice response: \(voiceResponse)")
        return voiceResponse
    }
    
    // MARK: - Session Management
    
    func startVoiceSession(userId: String, children: [VoiceChild]) async throws -> String {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        guard let url = URL(string: "\(config.baseURL)/voice/session/start") else {
            throw VoiceError.networkError
        }
        
        let sessionRequest = SessionStartRequest(
            userId: userId,
            children: children
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(sessionRequest)
        } catch {
            print("❌ Failed to encode session start request: \(error)")
            throw VoiceError.networkError
        }
        
        print("🆕 Starting new voice session...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoiceError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Session start failed: \(httpResponse.statusCode) - \(errorMessage)")
            throw VoiceError.networkError
        }
        
        let sessionResponse = try JSONDecoder().decode(SessionStartResponse.self, from: data)
        print("✅ Session started: \(sessionResponse.sessionId)")
        return sessionResponse.sessionId
    }
    
    // MARK: - Turn Processing
    
    func processTurn(audioData: Data, sessionId: String, turnId: String, turnIndex: Int, userId: String, children: [VoiceChild], phraseHints: [String] = []) async throws -> VoiceResponse {
        // Step 1: Convert speech to text
        let transcript = try await uploadSTT(audioData: audioData, phraseHints: phraseHints)
        
        // Step 2: Process turn
        return try await processTurnWithTranscript(transcript: transcript, sessionId: sessionId, turnId: turnId, turnIndex: turnIndex, userId: userId, children: children)
    }
    
    func processTurnWithTranscript(transcript: String, sessionId: String, turnId: String, turnIndex: Int, userId: String, children: [VoiceChild]) async throws -> VoiceResponse {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        // TEMPORARY FIX: Use legacy parse endpoint until server issue is resolved
        guard let url = URL(string: config.parseEndpoint) else {
            throw VoiceError.networkError
        }
        
        let parseRequest = ParseRequest(
            transcript: transcript,
            children: children,
            currentDate: ISO8601DateFormatter().string(from: Date()),
            conversationContext: nil,
            sessionId: sessionId
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(parseRequest)
        } catch {
            print("❌ Failed to encode parse request: \(error)")
            throw VoiceError.networkError
        }
        
        print("🔄 Processing transcript with legacy endpoint...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoiceError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Parse request failed: \(httpResponse.statusCode) - \(errorMessage)")
            throw VoiceError.networkError
        }
        
        let voiceResponse = try JSONDecoder().decode(VoiceResponse.self, from: data)
        print("✅ Transcript processed: \(voiceResponse)")
        return voiceResponse
    }
    
    // MARK: - Complete Voice Flow (Legacy - for backward compatibility)
    
    func processVoiceCommand(audioData: Data, children: [VoiceChild], sessionId: String? = nil, phraseHints: [String] = []) async throws -> VoiceResponse {
        // Step 1: Convert speech to text
        let transcript = try await uploadSTT(audioData: audioData, phraseHints: phraseHints)
        
        // Step 2: Parse transcript
        let voiceResponse = try await parseTranscript(transcript, children: children, sessionId: sessionId, context: nil)
        
        return voiceResponse
    }
}

// MARK: - Helper Models

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let project: String?
    let region: String?
}

struct SessionStartRequest: Codable {
    let userId: String
    let children: [VoiceChild]
}

struct SessionStartResponse: Codable {
    let sessionId: String
    let status: String
    let message: String
}

struct TurnRequest: Codable {
    let transcript: String
    let children: [VoiceChild]
    let currentDate: String
}

