import Foundation
import FirebaseFirestore

/// A single to-do item. Stored in Firestore at users/{uid}/tasks/{taskId}.
struct TodoTask: Identifiable, Equatable {
    var id: String
    var title: String
    var details: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        details: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Builds a task from a Firestore document. Returns nil if the title is missing.
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let title = data["title"] as? String else { return nil }
        self.id = document.documentID
        self.title = title
        self.details = data["description"] as? String ?? ""
        self.isCompleted = data["isCompleted"] as? Bool ?? false
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    }

    /// Firestore representation.
    var dictionary: [String: Any] {
        [
            "title": title,
            "description": details,
            "isCompleted": isCompleted,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
}
