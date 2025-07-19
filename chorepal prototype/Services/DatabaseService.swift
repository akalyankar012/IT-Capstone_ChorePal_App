import Foundation

// Database structure for our mock data
struct Database: Codable {
    var parents: [Parent]
    var children: [Child]
}

// Simple service to demonstrate database structure
class DatabaseService {
    static let shared = DatabaseService()
    private var database: Database?
    
    private init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        // This is just for demonstration purposes
        let parentId = UUID()
        let childId = UUID()
        
        let sampleData = Database(
            parents: [
                Parent(phoneNumber: "5551234567", 
                      password: "demo123")
            ],
            children: [
                Child(name: "Alice Doe",
                     pin: "1234",
                     parentId: parentId)
            ]
        )
        self.database = sampleData
    }
    
    // Helper method to get children
    func getChildren() -> [Child] {
        return database?.children ?? []
    }
    
    // Helper method to update points
    func updatePoints(for childId: UUID, newPoints: Int) {
        guard var db = database else { return }
        if let index = db.children.firstIndex(where: { $0.id == childId }) {
            db.children[index].points = newPoints
            database = db
        }
    }
    
    // MARK: - Parent Authentication
    func authenticateParent(phoneNumber: String, password: String) -> Parent? {
        return database?.parents.first { $0.phoneNumber == phoneNumber && $0.password == password }
    }
    
    // MARK: - Get Children for Parent
    func getChildren(forParentId parentId: UUID) -> [Child] {
        return database?.children.filter { $0.parentId == parentId } ?? []
    }
    
    // MARK: - Update Child Points
    func updateChildPoints(childId: UUID, newPoints: Int) -> Bool {
        guard var db = database else { return false }
        
        if let index = db.children.firstIndex(where: { $0.id == childId }) {
            db.children[index].points = newPoints
            database = db
            return true
        }
        return false
    }
    
    // MARK: - Child Authentication
    func authenticateChild(pin: String) -> Child? {
        return database?.children.first { $0.pin == pin }
    }
} 