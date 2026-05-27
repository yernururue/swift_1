import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var items: [TodoItem]

    @State private var showingAddSheet = false
    @State private var newTaskTitle = ""

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Нет задач",
                        systemImage: "checklist",
                        description: Text("Нажмите +, чтобы добавить первую задачу")
                    )
                } else {
                    List {
                        ForEach(items) { item in
                            TodoRow(item: item)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteItem(item)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation {
                                            item.isCompleted.toggle()
                                        }
                                    } label: {
                                        Label(
                                            item.isCompleted ? "Вернуть" : "Готово",
                                            systemImage: item.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(item.isCompleted ? .orange : .green)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Мои задачи")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addTaskSheet
            }
        }
    }

    // MARK: - Add Task Sheet

    private var addTaskSheet: some View {
        NavigationStack {
            Form {
                Section("Новая задача") {
                    TextField("Что нужно сделать?", text: $newTaskTitle)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle("Добавить")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismissAddSheet()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        addItem()
                    }
                    .bold()
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
    }

    // MARK: - Actions

    private func addItem() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newItem = TodoItem(title: trimmed)
        modelContext.insert(newItem)
        dismissAddSheet()
    }

    private func deleteItem(_ item: TodoItem) {
        modelContext.delete(item)
    }

    private func dismissAddSheet() {
        newTaskTitle = ""
        showingAddSheet = false
    }
}

// MARK: - Preview

#Preview("With Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoItem.self, configurations: config)

    let sampleItems = [
        TodoItem(title: "Купить продукты"),
        TodoItem(title: "Написать отчёт"),
        TodoItem(title: "Позвонить врачу"),
    ]
    // Mark one as completed for visual variety
    sampleItems[1].isCompleted = true

    for item in sampleItems {
        container.mainContext.insert(item)
    }

    return ContentView()
        .modelContainer(container)
}

#Preview("Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoItem.self, configurations: config)

    return ContentView()
        .modelContainer(container)
}
