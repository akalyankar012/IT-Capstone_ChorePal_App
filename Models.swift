import SwiftUI

public struct Chore: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let points: Int
    public var isCompleted: Bool
    public let dateCreated: Date
    public let dueDate: Date
    
    public init(title: String, description: String, points: Int, isCompleted: Bool, dateCreated: Date, dueDate: Date) {
        self.title = title
        self.description = description
        self.points = points
        self.isCompleted = isCompleted
        self.dateCreated = dateCreated
        self.dueDate = dueDate
    }
    
    public static func == (lhs: Chore, rhs: Chore) -> Bool {
        lhs.id == rhs.id
    }
}

public enum UserRole {
    case parent
    case child
} 
