import Foundation
import Combine

class ChoreService: ObservableObject {
    @Published var chores: [Chore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Load sample data for testing
        loadSampleData()
    }
    
    private func loadSampleData() {
        chores = Chore.sampleChores
    }
    
    // MARK: - CRUD Operations
    
    func addChore(_ chore: Chore) {
        chores.append(chore)
    }
    
    func updateChore(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index] = chore
        }
    }
    
    func deleteChore(_ chore: Chore) {
        chores.removeAll { $0.id == chore.id }
    }
    
    func toggleChoreCompletion(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index].isCompleted.toggle()
        }
    }
    
    // MARK: - Child Assignment
    
    func assignChoreToChild(_ chore: Chore, childId: UUID) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index].assignedToChildId = childId
        }
    }
    
    func unassignChore(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index].assignedToChildId = nil
        }
    }
    
    // MARK: - Queries
    
    func getChoresForChild(_ childId: UUID) -> [Chore] {
        return chores.filter { $0.assignedToChildId == childId }
    }
    
    func getUnassignedChores() -> [Chore] {
        return chores.filter { $0.assignedToChildId == nil }
    }
    
    func getChoresForParent(childrenIds: [UUID]) -> [Chore] {
        return chores.filter { chore in
            // Show chores assigned to any of the parent's children
            if let assignedChildId = chore.assignedToChildId {
                return childrenIds.contains(assignedChildId)
            }
            // Also show unassigned chores so parent can assign them
            return true
        }
    }
    
    func getCompletedChores() -> [Chore] {
        return chores.filter { $0.isCompleted }
    }
    
    func getActiveChores() -> [Chore] {
        return chores.filter { !$0.isCompleted }
    }
    
    func getOverdueChores() -> [Chore] {
        let now = Date()
        return chores.filter { !$0.isCompleted && $0.dueDate < now }
    }
    
    func getChoresDueToday() -> [Chore] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return chores.filter { chore in
            let choreDate = calendar.startOfDay(for: chore.dueDate)
            return choreDate >= today && choreDate < tomorrow
        }
    }
    
    // MARK: - Statistics
    
    func getTotalChores() -> Int {
        return chores.count
    }
    
    func getCompletedChoresCount() -> Int {
        return getCompletedChores().count
    }
    
    func getActiveChoresCount() -> Int {
        return getActiveChores().count
    }
    
    func getOverdueChoresCount() -> Int {
        return getOverdueChores().count
    }
    
    func getTotalPoints() -> Int {
        return chores.reduce(0) { $0 + $1.points }
    }
    
    func getCompletedPoints() -> Int {
        return getCompletedChores().reduce(0) { $0 + $1.points }
    }
    
    // MARK: - Validation
    
    func validateChore(_ chore: Chore) -> Bool {
        return !chore.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !chore.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               chore.points > 0 &&
               chore.points <= 100
    }
    
    // MARK: - Search and Filter
    
    func searchChores(query: String) -> [Chore] {
        if query.isEmpty {
            return chores
        }
        
        return chores.filter { chore in
            chore.title.localizedCaseInsensitiveContains(query) ||
            chore.description.localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterChores(by status: ChoreStatus) -> [Chore] {
        switch status {
        case .all:
            return chores
        case .active:
            return getActiveChores()
        case .completed:
            return getCompletedChores()
        case .overdue:
            return getOverdueChores()
        case .dueToday:
            return getChoresDueToday()
        }
    }
}

// MARK: - Supporting Types

enum ChoreStatus {
    case all
    case active
    case completed
    case overdue
    case dueToday
    
    var title: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .completed: return "Completed"
        case .overdue: return "Overdue"
        case .dueToday: return "Due Today"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .active: return "clock"
        case .completed: return "checkmark.circle"
        case .overdue: return "exclamationmark.triangle"
        case .dueToday: return "calendar"
        }
    }
} 