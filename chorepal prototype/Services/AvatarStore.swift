import Foundation

enum AvatarStore {
    private static let parentKey = "parentAvatarName"
    
    static func getParentAvatarName() -> String? {
        UserDefaults.standard.string(forKey: parentKey)
    }
    
    static func setParentAvatarName(_ name: String) {
        UserDefaults.standard.set(name, forKey: parentKey)
    }
    
    static func getChildAvatarName(childId: UUID) -> String? {
        UserDefaults.standard.string(forKey: key(for: childId))
    }
    
    static func setChildAvatarName(_ name: String, for childId: UUID) {
        UserDefaults.standard.set(name, forKey: key(for: childId))
    }
    
    private static func key(for childId: UUID) -> String {
        "childAvatar_\(childId.uuidString)"
    }
}


