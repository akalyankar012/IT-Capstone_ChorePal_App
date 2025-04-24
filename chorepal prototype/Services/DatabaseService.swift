import Foundation

// Models for our database entities
struct Parent: Codable {
    var id: String
    var email: String
    var password: String
    var name: String
    var children: [String]
}

struct Child: Codable {
    var id: String
    var name: String
    var pin: String
    var points: Int
    var parentId: String
}

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
        let sampleData = Database(
            parents: [
                Parent(id: "p1", 
                      email: "parent@example.com",
                      password: "demo123",
                      name: "John Doe",
                      children: ["c1"])
            ],
            children: [
                Child(id: "c1",
                     name: "Alice Doe",
                     pin: "1234",
                     points: 100,
                     parentId: "p1")
            ]
        )
        self.database = sampleData
    }
    
    // Helper method to get children
    func getChildren() -> [Child] {
        return database?.children ?? []
    }
    
    // Helper method to update points
    func updatePoints(for childId: String, newPoints: Int) {
        guard var db = database else { return }
        if let index = db.children.firstIndex(where: { $0.id == childId }) {
            db.children[index].points = newPoints
            database = db
        }
    }
    
    // MARK: - Parent Authentication
    func authenticateParent(email: String, password: String) -> Parent? {
        return database?.parents.first { $0.email == email && $0.password == password }
    }
    
    // MARK: - Get Children for Parent
    func getChildren(forParentId parentId: String) -> [Child] {
        return database?.children.filter { $0.parentId == parentId } ?? []
    }
    
    // MARK: - Update Child Points
    func updateChildPoints(childId: String, newPoints: Int) -> Bool {
        guard var db = database else { return false }
        
        if let index = db.children.firstIndex(where: { $0.id == childId }) {
            db.children[index].points = newPoints
            database = db
            return true
        }
        return false
    }
    
    // MARK: - Child Authentication
    func authenticateChild(id: String, pin: String) -> Child? {
        return database?.children.first { $0.id == id && $0.pin == pin }
    }
} 