import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        user = Auth.auth().currentUser
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
            }
        }
    }

    func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    func signIn(email: String, password: String) async {
        clearMessages()
        isLoading = true
        defer { isLoading = false }
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func signUp(name: String, email: String, password: String) async {
        clearMessages()
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let change = result.user.createProfileChangeRequest()
                change.displayName = trimmed
                try? await change.commitChanges()
            }
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func resetPassword(email: String) async {
        clearMessages()
        isLoading = true
        defer { isLoading = false }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            infoMessage = "Password reset email sent. Check your inbox."
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func signOut() {
        clearMessages()
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        // Raw Firebase Auth error codes (stable across SDK versions).
        guard nsError.domain == "FIRAuthErrorDomain" else {
            return error.localizedDescription
        }
        switch nsError.code {
        case 17008: // invalid email
            return "That email address looks invalid."
        case 17009, 17004: // wrong password / invalid credential
            return "Incorrect email or password."
        case 17011: // user not found
            return "No account found for this email."
        case 17007: // email already in use
            return "An account with this email already exists."
        case 17026: // weak password
            return "Password is too weak. Use at least 6 characters."
        case 17020: // network error
            return "Network error. Check your internet connection."
        case 17010: // too many requests
            return "Too many attempts. Please try again later."
        default:
            return error.localizedDescription
        }
    }
}
