import SwiftUI

struct TaskRowView: View {
    let task: TodoTask
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onToggle) {
                ZStack {
                    if task.isCompleted {
                        Circle().fill(Theme.gradient)
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.white)
                    } else {
                        Circle().strokeBorder(Color(.systemGray3), lineWidth: 2)
                    }
                }
                .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)

                if !task.details.isEmpty {
                    Text(task.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Label(
                    task.createdAt.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "clock"
                )
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        .contentShape(Rectangle())
    }
}
