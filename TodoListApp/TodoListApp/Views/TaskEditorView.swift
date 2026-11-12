import SwiftUI

struct TaskEditorView: View {
    enum Mode: Identifiable {
        case add
        case edit(TodoTask)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let task): return task.id
            }
        }
    }

    let mode: Mode

    @EnvironmentObject private var taskVM: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String
    @State private var isCompleted: Bool

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _title = State(initialValue: "")
            _details = State(initialValue: "")
            _isCompleted = State(initialValue: false)
        case .edit(let task):
            _title = State(initialValue: task.title)
            _details = State(initialValue: task.details)
            _isCompleted = State(initialValue: task.isCompleted)
        }
    }

    private var editingTask: TodoTask? {
        if case .edit(let task) = mode { return task }
        return nil
    }

    private var isEditing: Bool { editingTask != nil }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    section("Title") {
                        TextField("e.g. Finish lab report", text: $title)
                    }

                    section("Description") {
                        ZStack(alignment: .topLeading) {
                            if details.isEmpty {
                                Text("Add details (optional)")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                            TextEditor(text: $details)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 140)
                        }
                    }

                    if isEditing {
                        HStack {
                            Label("Mark as completed", systemImage: "checkmark.circle")
                            Spacer()
                            Toggle("", isOn: $isCompleted)
                                .labelsHidden()
                        }
                        .padding(14)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button(isEditing ? "Save Changes" : "Add Task") {
                        save()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(trimmedTitle.isEmpty)
                    .padding(.top, 6)

                    if let task = editingTask {
                        Button(role: .destructive) {
                            taskVM.delete(task)
                            dismiss()
                        } label: {
                            Label("Delete task", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func save() {
        let cleanDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        if var task = editingTask {
            task.title = trimmedTitle
            task.details = cleanDetails
            task.isCompleted = isCompleted
            taskVM.update(task)
        } else {
            taskVM.add(title: trimmedTitle, details: cleanDetails)
        }
        dismiss()
    }
}
