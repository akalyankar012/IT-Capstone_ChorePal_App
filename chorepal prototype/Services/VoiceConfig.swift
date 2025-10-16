import Foundation
import Combine

// MARK: - Voice Configuration
struct VoiceConfig {
    static let apiBaseURL = "http://192.168.1.176:3000"
}

// MARK: - Voice Configuration Service
class VoiceConfigService: ObservableObject {
    static let shared = VoiceConfigService()
    
    @Published var apiBaseURL = "http://192.168.1.176:3000"
    
    var healthEndpoint: String {
        "\(apiBaseURL)/health"
    }
    
    var sttEndpoint: String {
        "\(apiBaseURL)/voice/stt"
    }
    
    var parseEndpoint: String {
        "\(apiBaseURL)/voice/parse"
    }
    
    var baseURL: String {
        apiBaseURL
    }
    
    private init() {}
    
    func loadSavedConfiguration() {
        // Load from UserDefaults or other storage if needed
        if let savedURL = UserDefaults.standard.string(forKey: "voice_api_base_url") {
            apiBaseURL = savedURL
        }
    }
    
    func updateBaseURL(_ newURL: String) {
        apiBaseURL = newURL
        UserDefaults.standard.set(newURL, forKey: "voice_api_base_url")
    }
}
