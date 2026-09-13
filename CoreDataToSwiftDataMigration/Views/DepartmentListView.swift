import SwiftUI
import SwiftData

struct DepartmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Department.name) private var departments: [Department]
    
    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newBudget: Double = 0.0

    var body: some View {
        List {
            ForEach(departments) { department in
                NavigationLink(destination: EmployeeListView(department: department)) {
                    VStack(alignment: .leading) {
                        Text(department.name)
                            .font(.headline)
                        HStack {
                            Text(department.budget, format: .currency(code: "USD"))
                            Spacer()
                            Text("\(department.employees?.count ?? 0) employees")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle("Departments")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Department", systemImage: "plus")
                }
            }
        }
        .overlay {
            if departments.isEmpty {
                ContentUnavailableView("No Departments", systemImage: "building.2", description: Text("Add a new department to get started."))
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                Form {
                    TextField("Name", text: $newName)
                    TextField("Budget", value: $newBudget, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
                .navigationTitle("New Department")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newItem = Department(name: newName, budget: newBudget)
                            modelContext.insert(newItem)
                            newName = ""
                            newBudget = 0.0
                            showingAddSheet = false
                        }
                        .disabled(newName.isEmpty)
                    }
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(departments[index])
            }
        }
    }
}
