import SwiftUI

struct AuthView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case login = "Login"
        case signUp = "Sign Up"
        var id: String { rawValue }
    }

    @EnvironmentObject private var auth: AuthViewModel

    @State private var mode: Mode = .login
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showReset = false
    @State private var resetEmail = ""

    private var isSignUp: Bool { mode == .signUp }

    private var isValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passwordOK = password.count >= 6
        if isSignUp {
            return emailOK && passwordOK && password == confirmPassword
        }
        return emailOK && passwordOK
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()

            Theme.gradient
                .frame(height: 320)
                .clipShape(BottomRounded(radius: 36))
                .ignoresSafeArea(edges: .top)

            ScrollView {
                VStack(spacing: 24) {
                    header
                    formCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("Reset password", isPresented: $showReset) {
            TextField("Email", text: $resetEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            Button("Send link") {
                Task { await auth.resetPassword(email: resetEmail.trimmed) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We will email you a link to reset your password.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "checklist")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 78, height: 78)
                .background(Circle().fill(Color.white))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)

            Text("Todo List")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.white)

            Text(isSignUp ? "Create an account to sync your tasks" : "Welcome back! Sign in to continue")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 36)
        .padding(.bottom, 4)
    }

    // MARK: - Form card

    private var formCard: some View {
        VStack(spacing: 18) {
            modeSwitcher

            VStack(spacing: 12) {
                if isSignUp {
                    field(systemImage: "person") {
                        TextField("Full name", text: $name)
                            .textContentType(.name)
                    }
                }

                field(systemImage: "envelope") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                field(systemImage: "lock") {
                    Group {
                        if showPassword {
                            TextField("Password (min 6 characters)", text: $password)
                        } else {
                            SecureField("Password (min 6 characters)", text: $password)
                        }
                    }
                    .textContentType(isSignUp ? .newPassword : .password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if isSignUp {
                    field(systemImage: "lock.rotation") {
                        SecureField("Confirm password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Passwords do not match.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if let error = auth.errorMessage {
                banner(error, systemImage: "exclamationmark.triangle.fill", color: .red)
            }
            if let info = auth.infoMessage {
                banner(info, systemImage: "checkmark.circle.fill", color: .green)
            }

            Button {
                Task {
                    if isSignUp {
                        await auth.signUp(name: name, email: email.trimmed, password: password)
                    } else {
                        await auth.signIn(email: email.trimmed, password: password)
                    }
                }
            } label: {
                if auth.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(isSignUp ? "Create Account" : "Login")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isValid || auth.isLoading)

            if !isSignUp {
                Button("Forgot password?") {
                    resetEmail = email
                    showReset = true
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }

    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(Mode.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = item }
                    auth.clearMessages()
                } label: {
                    Text(item.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(mode == item ? Color.white : Color.secondary)
                        .background {
                            if mode == item {
                                Capsule().fill(Theme.gradient)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color(.tertiarySystemFill)))
    }

    // MARK: - Helpers

    private func field<Content: View>(
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func banner(_ text: String, systemImage: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
            Text(text)
                .font(.footnote)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(color)
        .padding(12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
