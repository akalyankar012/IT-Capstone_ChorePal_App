import Foundation

// MARK: - Voice Task Models
// Note: Child type is already defined in Models.swift

// MARK: - Voice Error Types
enum VoiceError: Error, LocalizedError {
    case networkError
    case serverError(String)
    case parsingError
    case recordingError
    case permissionDenied
    case uploadFailed
    case parsingFailed
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .serverError(let message):
            return "Server error: \(message)"
        case .parsingError:
            return "Failed to parse response"
        case .recordingError:
            return "Audio recording failed"
        case .permissionDenied:
            return "Microphone permission denied"
        case .uploadFailed:
            return "Audio upload failed"
        case .parsingFailed:
            return "Transcript parsing failed"
        case .recordingFailed:
            return "Audio recording failed"
        }
    }
}

struct TaskFields: Codable {
    let childId: String
    let title: String
    let dueAt: String
    let points: Int
}

struct ParseResult: Codable {
    let needsFollowup: Bool
    let missing: [String]?
    let question: String?
    let result: TaskFields?
    let error: String?
    let details: String?
}

struct ParseError: Codable {
    let error: String
    let details: String
}

// MARK: - Additional Voice Types
struct VoiceChild: Codable {
    let id: String
    let name: String
}

struct STTResponse: Codable {
    let transcript: String
    
    var text: String {
        return transcript
    }
}

struct ParseRequest: Codable {
    let transcript: String
    let children: [VoiceChild]
    let currentDate: String?
}

// MARK: - Chat Message Types
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    let isProcessing: Bool
    
    init(text: String, isUser: Bool, isProcessing: Bool = false) {
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        self.isProcessing = isProcessing
    }
}
