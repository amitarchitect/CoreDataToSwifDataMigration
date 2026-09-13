import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DepartmentListView()
            }
            .tabItem {
                Label("Departments", systemImage: "building.2")
            }

            NavigationStack {
                MigrationStatusView()
            }
            .tabItem {
                Label("Migration", systemImage: "arrow.triangle.2.circlepath")
            }
            
            NavigationStack {
                Text("About Settings")
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    ContentView()
}
