import SwiftUI

// MARK: - Main Tab View

/// Root view wrapping the existing Tasks tab and the new Background Engine tab.
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Existing Todo Tasks
            ContentView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(0)

            // Tab 2: Background Engine
            BackgroundEngineView()
                .tabItem {
                    Label("Studio", systemImage: "photo.artframe")
                }
                .tag(1)
        }
        .tint(Color(red: 0.48, green: 0.18, blue: 1.0))
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
