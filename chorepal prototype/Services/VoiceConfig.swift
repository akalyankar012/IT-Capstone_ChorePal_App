import Foundation

// MARK: - Voice Configuration Service

class VoiceConfigService: ObservableObject {
    static let shared = VoiceConfigService()
    
    @Published var apiBaseURL: String
    @Published var isConfigured: Bool = false
    
    private init() {
        // Default configuration
        #if targetEnvironment(simulator)
        self.apiBaseURL = "http://localhost:3000"
        #else
        // Default LAN IP - user should update this
        self.apiBaseURL = "http://192.168.1.100:3000"
        #endif
    }
    
    func updateAPIBaseURL(_ newURL: String) {
        self.apiBaseURL = newURL
        self.isConfigured = true
        UserDefaults.standard.set(newURL, forKey: "VoiceAPIBaseURL")
    }
    
    func loadSavedConfiguration() {
        if let savedURL = UserDefaults.standard.string(forKey: "VoiceAPIBaseURL") {
            self.apiBaseURL = savedURL
            self.isConfigured = true
        }
    }
    
    var sttEndpoint: String {
        return "\(apiBaseURL)/voice/stt"
    }
    
    var parseEndpoint: String {
        return "\(apiBaseURL)/voice/parse"
    }
    
    var healthEndpoint: String {
        return "\(apiBaseURL)/health"
    }
}
