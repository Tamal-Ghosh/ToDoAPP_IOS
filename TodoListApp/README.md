# Todo List – iOS (SwiftUI + Firebase)

Simple professional Todo app for the Mobile Computing Lab.

**Features**
- Firebase Authentication (email/password): sign up, login, logout, password reset
- Firestore database: each user's tasks live at `users/{uid}/tasks/{taskId}`
- Task has a **title** and a **description**
- CRUD: create, read (realtime), update (edit / mark done), delete (swipe)
- Search, All / Active / Done filter, completed counter

**Requirements:** macOS with Xcode 15+, iOS 16+ target, a Firebase account.

## Folder structure

```
TodoListApp/
├── TodoListApp.xcodeproj
├── firestore.rules               # security rules (paste into Firebase console)
└── TodoListApp/
    ├── TodoListApp.swift         # @main, FirebaseApp.configure()
    ├── Models/TodoTask.swift
    ├── ViewModels/AuthViewModel.swift
    ├── ViewModels/TaskViewModel.swift   # Firestore CRUD + realtime listener
    ├── Views/RootView.swift
    ├── Views/AuthView.swift
    ├── Views/TaskListView.swift
    ├── Views/TaskRowView.swift
    ├── Views/TaskEditorView.swift
    └── Assets.xcassets
```

## Connect to Firebase (step by step)

1. Open `TodoListApp.xcodeproj` in Xcode. Wait for **Swift Package Manager** to download `firebase-ios-sdk` (bottom status bar; first time takes a few minutes).
2. Select the project > target **TodoListApp** > **Signing & Capabilities** > choose your **Team**.
   Also decide the **Bundle Identifier** (default `com.bipro.TodoListApp`). Change it to something unique, e.g. `com.yourname.TodoListApp`.
3. Go to https://console.firebase.google.com > your project > **Add app** > **iOS**.
   - Enter the **exact same Bundle ID** as in Xcode.
   - Download **GoogleService-Info.plist**.
4. Drag `GoogleService-Info.plist` into Xcode under the `TodoListApp` folder (tick **Copy items if needed** and the **TodoListApp** target). Skip the "add SDK / initialization code" steps in the console, this project already has them.
5. Firebase console > **Build > Authentication > Get started > Sign-in method** > enable **Email/Password**.
6. Firebase console > **Build > Firestore Database > Create database** (start in production mode, pick the nearest region).
7. Firestore > **Rules** tab > paste the contents of `firestore.rules` > **Publish**.
8. Run on a simulator (iPhone 15 / 16) with **Cmd + R**. Sign up, add tasks, and see them appear in Firestore under `users/<uid>/tasks`.

## Troubleshooting

| Problem | Fix |
|---|---|
| `The default Firebase app has not been configured` / crash on launch | `GoogleService-Info.plist` is missing from the target. Re-add it (step 4). |
| `Missing or insufficient permissions` | Publish the rules from `firestore.rules` (step 7). |
| Auth error "operation not allowed" | Enable Email/Password in Authentication (step 5). |
| Packages fail to resolve | File > Packages > Reset Package Caches, then Resolve Package Versions. |
| Signing error | Select your Team in Signing & Capabilities, use a unique Bundle ID. |

## If the .xcodeproj does not open

Create it manually (2 minutes): Xcode > New Project > iOS App > Interface **SwiftUI**, Language **Swift**, name `TodoListApp`. Delete the default `ContentView.swift` and `TodoListAppApp.swift`, drag in the `Models`, `ViewModels`, `Views` folders and `TodoListApp.swift` from this zip. Then File > Add Package Dependencies > `https://github.com/firebase/firebase-ios-sdk` > add **FirebaseAuth** and **FirebaseFirestore**. Continue from step 3 above.
