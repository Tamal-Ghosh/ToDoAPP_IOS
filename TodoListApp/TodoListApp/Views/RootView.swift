import SwiftUI
import UIKit

// MARK: - Theme (shared colors and styles used by all screens)

enum Theme {
    static let accent = Color(red: 0.31, green: 0.27, blue: 0.90)
    static let accentLight = Color(red: 0.55, green: 0.36, blue: 0.96)

    static let gradient = LinearGradient(
        colors: [accent, accentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
}

/// Rectangle with only the bottom corners rounded (used by the header).
struct BottomRounded: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.gradient)
                    .opacity(isEnabled ? 1 : 0.45)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Root

struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var taskVM: TaskViewModel

    var body: some View {
        Group {
            if auth.user != nil {
                TaskListView()
            } else {
                AuthView()
            }
        }
        .tint(Theme.accent)
        .animation(.easeInOut, value: auth.user?.uid)
        .onAppear {
            if let uid = auth.user?.uid {
                taskVM.start(userId: uid)
            }
        }
        .onChange(of: auth.user?.uid) { newValue in
            if let uid = newValue {
                taskVM.start(userId: uid)
            } else {
                taskVM.stop()
            }
        }
    }
}
