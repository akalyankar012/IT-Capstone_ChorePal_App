import Foundation
import Combine
import Firebase
import FirebaseFirestore

class ChoreService: ObservableObject {
    @Published var chores: [Chore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOffline = false
    
    private let db = Firestore.firestore()
    
    // Cache for offline support
    private var cachedChores: [Chore] = []
    private var lastSyncTime: Date?
    
    // Real-time listener
    private var choresListener: ListenerRegistration?
    
    init() {
        // Load data immediately on init
        Task {
            await loadChoresFromFirestore()
        }
        
        // Also listen for authentication events to reload
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadDataOnAuthentication),
            name: .userAuthenticated,
            object: nil
        )
    }
    
    @objc private func loadDataOnAuthentication() {
        Task {
            await loadChoresFromFirestore()
        }
    }
    
    private func loadSampleData() {
        chores = Chore.sampleChores
    }
    
    // MARK: - CRUD Operations
    
    func addChore(_ chore: Chore) {
        chores.append(chore)
        
        // Save to Firestore
        Task {
            await saveChoreToFirestore(chore)
            
            // Send notification to assigned child if chore is assigned
            if let childId = chore.assignedToChildId {
                let notificationService = NotificationService()
                await notificationService.createNotification(
                    userId: childId,
                    type: .taskCreated,
                    title: "New Task Assigned! 📋",
                    message: "You have a new task: \"\(chore.title)\" worth \(chore.points) points",
                    choreId: chore.id
                )
                print("✅ Notification sent to child \(childId) for new chore: \(chore.title)")
            }
        }
    }
    
    private func saveChoreToFirestore(_ chore: Chore) async {
        await saveChoreToFirestoreWithRetry(chore)
    }
    
    func updateChore(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index] = chore
            
            // Update in Firestore
            Task {
                await updateChoreInFirestore(chore)
            }
        }
    }
    
    private func updateChoreInFirestore(_ chore: Chore) async {
        await updateChoreInFirestoreWithRetry(chore)
    }
    
    func deleteChore(_ chore: Chore) {
        chores.removeAll { $0.id == chore.id }
        
        // Delete from Firestore
        Task {
            await deleteChoreFromFirestore(chore)
        }
    }
    
    private func deleteChoreFromFirestore(_ chore: Chore) async {
        do {
            try await db.collection("chores").document(chore.id.uuidString).delete()
            print("✅ Chore deleted from Firestore: \(chore.title)")
            
        } catch {
            print("❌ Error deleting chore from Firestore: \(error)")
        }
    }
    
    func toggleChoreCompletion(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index].isCompleted.toggle()
            
            // Update completion status in Firestore
            Task {
                await updateChoreCompletionInFirestore(chore.id, isCompleted: chores[index].isCompleted)
            }
        }
    }
    
    private func updateChoreCompletionInFirestore(_ choreId: UUID, isCompleted: Bool) async {
        do {
            try await db.collection("chores").document(choreId.uuidString).updateData([
                "isCompleted": isCompleted,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            print("✅ Chore completion updated in Firestore: \(isCompleted)")
            
        } catch {
            print("❌ Error updating chore completion in Firestore: \(error)")
        }
    }
    
    // MARK: - Child Assignment
    
    func assignChoreToChild(_ chore: Chore, childId: UUID) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index].assignedToChildId = childId
            
            // Update assignment in Firestore
            Task {
                await updateChoreAssignmentInFirestore(chore.id, childId: childId)
            }
        }
    }
    
    func unassignChore(_ chore: Chore) {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index].assignedToChildId = nil
            
            // Update assignment in Firestore
            Task {
                await updateChoreAssignmentInFirestore(chore.id, childId: nil)
            }
        }
    }
    
    private func updateChoreAssignmentInFirestore(_ choreId: UUID, childId: UUID?) async {
        do {
            try await db.collection("chores").document(choreId.uuidString).updateData([
                "assignedToChildId": childId?.uuidString,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            print("✅ Chore assignment updated in Firestore: \(childId?.uuidString ?? "unassigned")")
            
        } catch {
            print("❌ Error updating chore assignment in Firestore: \(error)")
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
            // Include chores assigned to any of the parent's children
            if let assignedChildId = chore.assignedToChildId {
                return childrenIds.contains(assignedChildId)
            }
            // Also include unassigned chores
            return true
        }
    }
    
    // MARK: - Load Chores from Firestore
    
    func loadChoresFromFirestore() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let snapshot = try await db.collection("chores").getDocuments()
            
            await MainActor.run {
                var loadedChores: [Chore] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    
                    if let title = data["title"] as? String,
                       let description = data["description"] as? String,
                       let points = data["points"] as? Int,
                       let isCompleted = data["isCompleted"] as? Bool,
                       let isRequired = data["isRequired"] as? Bool {
                        
                        // Handle dueDate - it might be stored as Timestamp
                        var dueDate = Date()
                        if let timestamp = data["dueDate"] as? Timestamp {
                            dueDate = timestamp.dateValue()
                            print("🗓️ Loaded dueDate from Timestamp: \(dueDate)")
                        } else if let date = data["dueDate"] as? Date {
                            dueDate = date
                            print("🗓️ Loaded dueDate from Date: \(dueDate)")
                        }
                        
                        // Handle createdAt - it might be stored as Timestamp
                        var createdAt = Date()
                        if let timestamp = data["createdAt"] as? Timestamp {
                            createdAt = timestamp.dateValue()
                        } else if let date = data["createdAt"] as? Date {
                            createdAt = date
                        }
                        
                        let choreId = UUID(uuidString: document.documentID) ?? UUID()
                        let assignedToChildId = (data["assignedToChildId"] as? String).flatMap { UUID(uuidString: $0) }
                        
                        // Load photo proof fields
                        let requiresPhotoProof = data["requiresPhotoProof"] as? Bool ?? true
                        let photoProofStatus: PhotoProofStatus? = (data["photoProofStatus"] as? String).flatMap { PhotoProofStatus(rawValue: $0) }
                        let parentFeedback = data["parentFeedback"] as? String
                        
                        let chore = Chore(
                            id: choreId,
                            title: title,
                            description: description,
                            points: points,
                            dueDate: dueDate,
                            isCompleted: isCompleted,
                            isRequired: isRequired,
                            assignedToChildId: assignedToChildId,
                            createdAt: createdAt,
                            requiresPhotoProof: requiresPhotoProof,
                            photoProofStatus: photoProofStatus,
                            parentFeedback: parentFeedback
                        )
                        
                        loadedChores.append(chore)
                    }
                }
                
                self.chores = loadedChores
                self.isLoading = false
                print("✅ Loaded \(loadedChores.count) chores from Firestore")
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load chores: \(error.localizedDescription)"
                print("❌ Error loading chores from Firestore: \(error)")
            }
        }
    }
    
    // Load chores for a specific child
    func loadChoresForChild(_ childId: UUID) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let snapshot = try await db.collection("chores")
                .whereField("assignedToChildId", isEqualTo: childId.uuidString)
                .getDocuments()
            
            await MainActor.run {
                var loadedChores: [Chore] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    
                    if let title = data["title"] as? String,
                       let description = data["description"] as? String,
                       let points = data["points"] as? Int,
                       let isCompleted = data["isCompleted"] as? Bool,
                       let isRequired = data["isRequired"] as? Bool {
                        
                        // Handle dueDate - it might be stored as Timestamp
                        var dueDate = Date()
                        if let timestamp = data["dueDate"] as? Timestamp {
                            dueDate = timestamp.dateValue()
                            print("🗓️ Loaded dueDate from Timestamp: \(dueDate)")
                        } else if let date = data["dueDate"] as? Date {
                            dueDate = date
                            print("🗓️ Loaded dueDate from Date: \(dueDate)")
                        }
                        
                        // Handle createdAt - it might be stored as Timestamp
                        var createdAt = Date()
                        if let timestamp = data["createdAt"] as? Timestamp {
                            createdAt = timestamp.dateValue()
                        } else if let date = data["createdAt"] as? Date {
                            createdAt = date
                        }
                        
                        let choreId = UUID(uuidString: document.documentID) ?? UUID()
                        
                        // Load photo proof fields
                        let requiresPhotoProof = data["requiresPhotoProof"] as? Bool ?? true
                        let photoProofStatus: PhotoProofStatus? = (data["photoProofStatus"] as? String).flatMap { PhotoProofStatus(rawValue: $0) }
                        let parentFeedback = data["parentFeedback"] as? String
                        
                        let chore = Chore(
                            id: choreId,
                            title: title,
                            description: description,
                            points: points,
                            dueDate: dueDate,
                            isCompleted: isCompleted,
                            isRequired: isRequired,
                            assignedToChildId: childId,
                            createdAt: createdAt,
                            requiresPhotoProof: requiresPhotoProof,
                            photoProofStatus: photoProofStatus,
                            parentFeedback: parentFeedback
                        )
                        
                        loadedChores.append(chore)
                    }
                }
                
                self.chores = loadedChores
                self.isLoading = false
                print("✅ Loaded \(loadedChores.count) chores for child \(childId) from Firestore")
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load chores: \(error.localizedDescription)"
                print("❌ Error loading chores for child from Firestore: \(error)")
            }
        }
    }
    
    // MARK: - Statistics
    
    func getTotalChores() -> Int {
        return chores.count
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
    
    // MARK: - Caching & Offline Support
    
    private func cacheChores(_ chores: [Chore]) {
        cachedChores = chores
        lastSyncTime = Date()
        saveToUserDefaults(chores)
    }
    
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cachedChores"),
           let decodedChores = try? JSONDecoder().decode([Chore].self, from: data) {
            cachedChores = decodedChores
            chores = decodedChores
            print("📱 Loaded \(decodedChores.count) chores from cache")
        }
    }
    
    private func saveToUserDefaults(_ chores: [Chore]) {
        if let encoded = try? JSONEncoder().encode(chores) {
            UserDefaults.standard.set(encoded, forKey: "cachedChores")
        }
    }
    
    // MARK: - Real-time Listeners
    
    func setupRealTimeListener() {
        choresListener = db.collection("chores")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error listening for chores changes: \(error)")
                        self?.isOffline = true
                        return
                    }
                    
                    self?.isOffline = false
                    guard let documents = snapshot?.documents else { return }
                    
                    var loadedChores: [Chore] = []
                    for document in documents {
                        if let chore = self?.parseChoreFromDocument(document) {
                            loadedChores.append(chore)
                        }
                    }
                    
                    self?.chores = loadedChores
                    self?.cacheChores(loadedChores)
                    print("🔄 Real-time chores update: \(loadedChores.count) chores")
                }
            }
    }
    
    private func parseChoreFromDocument(_ document: DocumentSnapshot) -> Chore? {
        let data = document.data() ?? [:]
        
        guard let title = data["title"] as? String,
              let description = data["description"] as? String,
              let points = data["points"] as? Int,
              let isCompleted = data["isCompleted"] as? Bool,
              let isRequired = data["isRequired"] as? Bool else {
            return nil
        }
        
        // Handle dueDate - it might be stored as Timestamp
        var dueDate = Date()
        if let timestamp = data["dueDate"] as? Timestamp {
            dueDate = timestamp.dateValue()
        } else if let date = data["dueDate"] as? Date {
            dueDate = date
        }
        
        // Handle createdAt - it might be stored as Timestamp
        var createdAt = Date()
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let date = data["createdAt"] as? Date {
            createdAt = date
        }
        
        let choreId = UUID(uuidString: document.documentID) ?? UUID()
        let assignedToChildId = (data["assignedToChildId"] as? String).flatMap { UUID(uuidString: $0) }
        
        // Load photo proof fields
        let requiresPhotoProof = data["requiresPhotoProof"] as? Bool ?? true
        let photoProofStatus: PhotoProofStatus? = (data["photoProofStatus"] as? String).flatMap { PhotoProofStatus(rawValue: $0) }
        let parentFeedback = data["parentFeedback"] as? String
        
        return Chore(
            id: choreId,
            title: title,
            description: description,
            points: points,
            dueDate: dueDate,
            isCompleted: isCompleted,
            isRequired: isRequired,
            assignedToChildId: assignedToChildId,
            createdAt: createdAt,
            requiresPhotoProof: requiresPhotoProof,
            photoProofStatus: photoProofStatus,
            parentFeedback: parentFeedback
        )
    }
    
    func cleanupListener() {
        choresListener?.remove()
        choresListener = nil
    }
    
    // MARK: - Optimized Data Loading
    
    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?
    private var hasMoreData = true
    
    func loadChoresWithPagination() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            var query = db.collection("chores")
                .order(by: "createdAt", descending: true)
                .limit(to: pageSize)
            
            if let lastDoc = lastDocument {
                query = query.start(afterDocument: lastDoc)
            }
            
            let snapshot = try await query.getDocuments()
            
            await MainActor.run {
                let newChores = snapshot.documents.compactMap { parseChoreFromDocument($0) }
                
                if lastDocument == nil {
                    // First page
                    self.chores = newChores
                } else {
                    // Subsequent pages
                    self.chores.append(contentsOf: newChores)
                }
                
                self.lastDocument = snapshot.documents.last
                self.hasMoreData = snapshot.documents.count == self.pageSize
                self.isLoading = false
                
                print("📄 Loaded \(newChores.count) chores (page)")
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load chores: \(error.localizedDescription)"
                print("❌ Error loading chores with pagination: \(error)")
            }
        }
    }
    
    func loadMoreChoresIfNeeded() async {
        guard hasMoreData && !isLoading else { return }
        await loadChoresWithPagination()
    }
    
    func refreshChores() async {
        lastDocument = nil
        hasMoreData = true
        await loadChoresWithPagination()
    }
    
    // MARK: - Error Handling & Retry Logic
    
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    private func saveChoreToFirestoreWithRetry(_ chore: Chore, retryCount: Int = 0) async {
        do {
            var choreData: [String: Any] = [
                "title": chore.title,
                "description": chore.description,
                "points": chore.points,
                "dueDate": Timestamp(date: chore.dueDate),
                "isCompleted": chore.isCompleted,
                "isRequired": chore.isRequired,
                "assignedToChildId": chore.assignedToChildId?.uuidString ?? NSNull(),
                "requiresPhotoProof": chore.requiresPhotoProof,
                "createdAt": Timestamp(date: chore.createdAt),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            // Add photo proof fields if present
            if let photoProofStatus = chore.photoProofStatus {
                choreData["photoProofStatus"] = photoProofStatus.rawValue
            }
            if let parentFeedback = chore.parentFeedback {
                choreData["parentFeedback"] = parentFeedback
            }
            
            try await db.collection("chores").document(chore.id.uuidString).setData(choreData)
            print("✅ Chore saved to Firestore: \(chore.title)")
            
        } catch {
            print("❌ Error saving chore to Firestore: \(error)")
            
            if retryCount < maxRetries {
                print("🔄 Retrying save operation (attempt \(retryCount + 1)/\(maxRetries))")
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                await saveChoreToFirestoreWithRetry(chore, retryCount: retryCount + 1)
            } else {
                print("❌ Max retries reached for saving chore: \(chore.title)")
                await MainActor.run {
                    self.errorMessage = "Failed to save chore after \(maxRetries) attempts"
                }
            }
        }
    }
    
    private func updateChoreInFirestoreWithRetry(_ chore: Chore, retryCount: Int = 0) async {
        do {
            var choreData: [String: Any] = [
                "title": chore.title,
                "description": chore.description,
                "points": chore.points,
                "dueDate": chore.dueDate,
                "isCompleted": chore.isCompleted,
                "isRequired": chore.isRequired,
                "assignedToChildId": chore.assignedToChildId?.uuidString ?? NSNull(),
                "requiresPhotoProof": chore.requiresPhotoProof,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            // Add photo proof fields if present
            if let photoProofStatus = chore.photoProofStatus {
                choreData["photoProofStatus"] = photoProofStatus.rawValue
            }
            if let parentFeedback = chore.parentFeedback {
                choreData["parentFeedback"] = parentFeedback
            }
            
            try await db.collection("chores").document(chore.id.uuidString).updateData(choreData)
            print("✅ Chore updated in Firestore: \(chore.title) (photoStatus: \(chore.photoProofStatus?.rawValue ?? "none"))")
            
        } catch {
            print("❌ Error updating chore in Firestore: \(error)")
            
            if retryCount < maxRetries {
                print("🔄 Retrying update operation (attempt \(retryCount + 1)/\(maxRetries))")
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                await updateChoreInFirestoreWithRetry(chore, retryCount: retryCount + 1)
            } else {
                print("❌ Max retries reached for updating chore: \(chore.title)")
                await MainActor.run {
                    self.errorMessage = "Failed to update chore after \(maxRetries) attempts"
                }
            }
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