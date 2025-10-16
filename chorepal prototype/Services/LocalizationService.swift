import Foundation

final class LocalizationService: ObservableObject {
    func localizedString(for key: String) -> String {
        // Minimal stub: return a prettified version of the key
        return key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}


