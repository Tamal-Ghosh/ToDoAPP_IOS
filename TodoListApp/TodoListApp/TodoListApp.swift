import SwiftUI
import FirebaseCore

@main
struct TodoListApp: App {
    @StateObject private var auth: AuthViewModel
    @StateObject private var taskVM: TaskViewModel

    init() {
        // Reads GoogleService-Info.plist from the app bundle.
        FirebaseApp.configure()
        _auth = StateObject(wrappedValue: AuthViewModel())
        _taskVM = StateObject(wrappedValue: TaskViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(taskVM)
        }
    }
}
