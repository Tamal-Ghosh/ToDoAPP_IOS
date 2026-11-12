import SwiftUI

struct TaskListView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case completed = "Done"
        var id: String { rawValue }
    }

    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var taskVM: TaskViewModel

    @State private var searchText = ""
    @State private var filter: Filter = .all
    @State private var editorMode: TaskEditorView.Mode?
    @State private var showSignOutConfirm = false

    // MARK: - Derived data

    private var completedCount: Int {
        taskVM.tasks.filter { $0.isCompleted }.count
    }

    private var remainingCount: Int {
        taskVM.tasks.count - completedCount
    }

    private var progress: Double {
        taskVM.tasks.isEmpty ? 0 : Double(completedCount) / Double(taskVM.tasks.count)
    }

    private var firstName: String {
        if let name = auth.user?.displayName, !name.isEmpty {
            return name.components(separatedBy: " ").first ?? name
        }
        return auth.user?.email?.components(separatedBy: "@").first ?? "there"
    }

    private var filteredTasks: [TodoTask] {
        taskVM.tasks.filter { task in
            let matchesFilter: Bool
            switch filter {
            case .all: matchesFilter = true
            case .active: matchesFilter = !task.isCompleted
            case .completed: matchesFilter = task.isCompleted
            }
            guard matchesFilter else { return false }
            guard !searchText.isEmpty else { return true }
            return task.title.localizedCaseInsensitiveContains(searchText)
                || task.details.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func count(for filter: Filter) -> Int {
        switch filter {
        case .all: return taskVM.tasks.count
        case .active: return remainingCount
        case .completed: return completedCount
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 14) {
                    headerCard
                    searchField
                    filterChips
                    content
                }
                .padding(.top, 8)

                addButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editorMode) { mode in
                TaskEditorView(mode: mode)
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog("Sign out of your account?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { auth.signOut() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK", role: .cancel) { taskVM.errorMessage = nil }
            } message: {
                Text(taskVM.errorMessage ?? "")
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(firstName)")
                        .font(.title2.bold())
                    Text(taskVM.tasks.isEmpty
                         ? "Add your first task to get started"
                         : "\(remainingCount) task\(remainingCount == 1 ? "" : "s") left to do")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                Spacer()

                Menu {
                    if let email = auth.user?.email {
                        Text(email)
                    }
                    Button("Sign Out", role: .destructive) {
                        showSignOutConfirm = true
                    }
                } label: {
                    Text(String(firstName.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color.white))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("\(completedCount)/\(taskVM.tasks.count) completed")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.9))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.25))
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geo.size.width * progress)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 8)
            }
        }
        .foregroundStyle(Color.white)
        .padding(20)
        .background(Theme.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Theme.accent.opacity(0.3), radius: 14, y: 8)
        .padding(.horizontal, 16)
    }

    // MARK: - Search and filters

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search tasks", text: $searchText)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(Filter.allCases) { item in
                let selected = filter == item
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { filter = item }
                } label: {
                    HStack(spacing: 6) {
                        Text(item.rawValue)
                        Text("\(count(for: item))")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(selected ? Color.white.opacity(0.25) : Color(.tertiarySystemFill))
                            )
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(selected ? Color.white : Color.primary)
                    .background(
                        Capsule().fill(selected ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Theme.card))
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if taskVM.isLoading {
            Spacer()
            ProgressView("Loading tasks...")
            Spacer()
        } else if filteredTasks.isEmpty {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: taskVM.tasks.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent.opacity(0.7))
                Text(taskVM.tasks.isEmpty ? "No tasks yet" : "No matching tasks")
                    .font(.headline)
                Text(taskVM.tasks.isEmpty ? "Tap the + button to add your first task." : "Try a different search or filter.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
        } else {
            List {
                ForEach(filteredTasks) { task in
                    TaskRowView(task: task) {
                        taskVM.toggleCompleted(task)
                    }
                    .onTapGesture { editorMode = .edit(task) }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            taskVM.delete(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editorMode = .edit(task)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Theme.accent)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }
        }
    }

    // MARK: - Floating add button

    private var addButton: some View {
        Button {
            editorMode = .add
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Theme.gradient))
                .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 6)
        }
        .padding(.trailing, 22)
        .padding(.bottom, 18)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { taskVM.errorMessage != nil },
            set: { if !$0 { taskVM.errorMessage = nil } }
        )
    }
}
