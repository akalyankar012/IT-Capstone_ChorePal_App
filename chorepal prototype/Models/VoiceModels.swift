import Foundation

// MARK: - Voice Task Models

struct VoiceChild: Codable, Identifiable {
    let id: String
    let name: String
}

struct TaskFields: Codable {
    let childId: String
    let title: String
    let dueAt: String // ISO 8601 format
    let points: Int
}

struct ParseResult: Codable {
    let needsFollowup: Bool
    let missing: [String]?
    let question: String?
    let result: TaskFields?
    
    init(needsFollowup: Bool, missing: [String]? = nil, question: String? = nil, result: TaskFields? = nil) {
        self.needsFollowup = needsFollowup
        self.missing = missing
        self.question = question
        self.result = result
    }
}

// MARK: - API Request/Response Models

struct STTRequest {
    let audio: Data
    let phraseHints: [String]
}

struct STTResponse: Codable {
    let text: String
}

struct ParseRequest: Codable {
    let transcript: String
    let children: [VoiceChild]
    let currentDate: String?
    
    init(transcript: String, children: [VoiceChild], currentDate: String? = nil) {
        self.transcript = transcript
        self.children = children
        self.currentDate = currentDate
    }
}

// MARK: - Voice Configuration

struct VoiceConfig {
    static let shared = VoiceConfig()
    
    // Server configuration
    let apiBaseURL: String
    let sttEndpoint: String
    let parseEndpoint: String
    
    // Audio configuration
    let sampleRate: Double = 16000.0
    let channels: UInt32 = 1
    let bitDepth: UInt32 = 16
    
    private init() {
        // Use LAN IP when testing on device, localhost for simulator
        #if targetEnvironment(simulator)
        self.apiBaseURL = "http://localhost:3000"
        #else
        // Replace with your Mac's LAN IP when testing on device
        self.apiBaseURL = "http://192.168.1.100:3000" // Update this IP
        #endif
        
        self.sttEndpoint = "\(apiBaseURL)/voice/stt"
        self.parseEndpoint = "\(apiBaseURL)/voice/parse"
    }
    
    func updateAPIBaseURL(_ newURL: String) -> VoiceConfig {
        return VoiceConfig(apiBaseURL: newURL)
    }
    
    private init(apiBaseURL: String) {
        self.apiBaseURL = apiBaseURL
        self.sttEndpoint = "\(apiBaseURL)/voice/stt"
        self.parseEndpoint = "\(apiBaseURL)/voice/parse"
    }
}

// MARK: - Voice State

enum VoiceState {
    case idle
    case recording
    case processing
    case speaking
    case error(String)
}

enum VoiceError: LocalizedError {
    case recordingFailed
    case uploadFailed
    case parsingFailed
    case networkError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .recordingFailed:
            return "Failed to record audio"
        case .uploadFailed:
            return "Failed to upload audio to server"
        case .parsingFailed:
            return "Failed to parse voice command"
        case .networkError:
            return "Network connection error"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
