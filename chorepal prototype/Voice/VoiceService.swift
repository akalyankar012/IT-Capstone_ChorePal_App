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
        isLoading = true
        defer { isLoading = false }
        
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
        
        if !phraseHints.isEmpty {
            request.setValue(phraseHints.joined(separator: ","), forHTTPHeaderField: "x-phrase-hints")
        }
        
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
    
    func parseTranscript(_ transcript: String, children: [VoiceChild]) async throws -> ParseResult {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: config.parseEndpoint) else {
            throw VoiceError.networkError
        }
        
        let parseRequest = ParseRequest(
            transcript: transcript,
            children: children,
            currentDate: ISO8601DateFormatter().string(from: Date())
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
        
        let parseResult = try JSONDecoder().decode(ParseResult.self, from: data)
        print("✅ Parse result: \(parseResult)")
        return parseResult
    }
    
    // MARK: - Complete Voice Flow
    
    func processVoiceCommand(audioData: Data, children: [VoiceChild], phraseHints: [String] = []) async throws -> ParseResult {
        // Step 1: Convert speech to text
        let transcript = try await uploadSTT(audioData: audioData, phraseHints: phraseHints)
        
        // Step 2: Parse transcript
        let parseResult = try await parseTranscript(transcript, children: children)
        
        return parseResult
    }
}

// MARK: - Helper Models

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
    let project: String?
    let region: String?
}

