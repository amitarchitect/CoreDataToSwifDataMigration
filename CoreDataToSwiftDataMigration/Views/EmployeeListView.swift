import SwiftUI
import SwiftData

struct EmployeeListView: View {
    let department: Department
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    @State private var newFirstName = ""
    @State private var newLastName = ""
    @State private var newEmail = ""
    @State private var newSalary = 0.0
    
    var employees: [Employee] {
        let all = department.employees ?? []
        if searchText.isEmpty {
            return all.sorted { $0.firstName < $1.firstName }
        } else {
            return all.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.firstName < $1.firstName }
        }
    }

    var body: some View {
        List {
            ForEach(employees) { employee in
                NavigationLink(destination: EmployeeDetailView(employee: employee)) {
                    VStack(alignment: .leading) {
                        Text(employee.fullName)
                            .font(.headline)
                        Text(employee.emailAddress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Hired: \(employee.hireDate.formatted(.dateTime.year().month().day()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle(department.name)
        .searchable(text: $searchText, prompt: "Search employees")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Employee", systemImage: "person.badge.plus")
                }
            }
        }
        .overlay {
            if employees.isEmpty {
                ContentUnavailableView("No Employees", systemImage: "person.3", description: Text("No employees in this department."))
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                Form {
                    TextField("First Name", text: $newFirstName)
                    TextField("Last Name", text: $newLastName)
                    TextField("Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Salary", value: $newSalary, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
                .navigationTitle("New Employee")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newItem = Employee(
                                firstName: newFirstName,
                                lastName: newLastName,
                                emailAddress: newEmail,
                                hireDate: Date(),
                                salary: newSalary
                            )
                            newItem.department = department
                            modelContext.insert(newItem)
                            showingAddSheet = false
                        }
                        .disabled(newFirstName.isEmpty || newLastName.isEmpty || newEmail.isEmpty)
                    }
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let employee = employees[index]
                modelContext.delete(employee)
            }
        }
    }
}
