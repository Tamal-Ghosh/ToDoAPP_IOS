import Foundation
import FirebaseFirestore

/// Handles all Firestore CRUD for the signed-in user's tasks.
/// Data path: users/{uid}/tasks/{taskId}
@MainActor
final class TaskViewModel: ObservableObject {
    @Published var tasks: [TodoTask] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var userId: String?

    private func collection(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("tasks")
    }

    // MARK: - Realtime listener

    func start(userId: String) {
        stop()
        self.userId = userId
        isLoading = true

        listener = collection(userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                let parsed = snapshot?.documents.compactMap { TodoTask(document: $0) } ?? []
                let message = error?.localizedDescription
                Task { @MainActor in
                    guard let self else { return }
                    if let message {
                        self.errorMessage = message
                    } else {
                        self.tasks = parsed
                    }
                    self.isLoading = false
                }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
        userId = nil
        tasks = []
        isLoading = false
    }

    // MARK: - Create

    func add(title: String, details: String) {
        guard let uid = userId else { return }
        let task = TodoTask(title: title, details: details)
        collection(uid).document(task.id).setData(task.dictionary) { [weak self] error in
            if let message = error?.localizedDescription {
                Task { @MainActor in self?.errorMessage = message }
            }
        }
    }

    // MARK: - Update

    func update(_ task: TodoTask) {
        guard let uid = userId else { return }
        let data: [String: Any] = [
            "title": task.title,
            "description": task.details,
            "isCompleted": task.isCompleted,
            "updatedAt": Timestamp(date: Date())
        ]
        collection(uid).document(task.id).updateData(data) { [weak self] error in
            if let message = error?.localizedDescription {
                Task { @MainActor in self?.errorMessage = message }
            }
        }
    }

    func toggleCompleted(_ task: TodoTask) {
        var changed = task
        changed.isCompleted.toggle()
        update(changed)
    }

    // MARK: - Delete

    func delete(_ task: TodoTask) {
        guard let uid = userId else { return }
        collection(uid).document(task.id).delete { [weak self] error in
            if let message = error?.localizedDescription {
                Task { @MainActor in self?.errorMessage = message }
            }
        }
    }
}
