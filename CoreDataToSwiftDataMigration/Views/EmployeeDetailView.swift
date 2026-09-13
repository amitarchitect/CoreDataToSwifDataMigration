import SwiftUI
import SwiftData

struct EmployeeDetailView: View {
    @Bindable var employee: Employee
    
    var body: some View {
        List {
            Section("Personal Info") {
                LabeledContent("First Name", value: employee.firstName)
                LabeledContent("Last Name", value: employee.lastName)
                LabeledContent("Email", value: employee.emailAddress)
                if let phone = employee.phoneNumber {
                    LabeledContent("Phone", value: phone)
                }
            }
            
            Section("Employment") {
                LabeledContent("Department", value: employee.department?.name ?? "None")
                LabeledContent("Hire Date", value: employee.hireDate.formatted(.dateTime.year().month().day()))
                LabeledContent("Salary", value: employee.salary, format: .currency(code: "USD"))
            }
            
            if let address = employee.address {
                Section("Address") {
                    Text(address.street)
                    Text("\(address.city), \(address.state) \(address.zipCode)")
                    Text(address.country)
                }
            }
            
            Section("Projects") {
                if let projects = employee.projects, !projects.isEmpty {
                    ForEach(projects) { project in
                        HStack {
                            Text(project.name)
                            Spacer()
                            if project.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } else {
                    Text("No projects assigned")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(employee.fullName)
    }
}
