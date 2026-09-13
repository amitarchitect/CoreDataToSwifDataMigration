import Foundation
import SwiftData

/// Schema V1 representing the initial schema mapping exactly to the Core Data implementation.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Department.self, Employee.self, Address.self, Project.self]
    }
    
    @Model
    final class Department {
        @Attribute(.unique) var id: UUID
        var name: String
        var budget: Double
        
        @Relationship(deleteRule: .cascade, inverse: \Employee.department)
        var employees: [Employee]?
        
        init(id: UUID = UUID(), name: String, budget: Double) {
            self.id = id
            self.name = name
            self.budget = budget
        }
    }
    
    @Model
    final class Employee {
        @Attribute(.unique) var id: UUID
        var firstName: String
        var lastName: String
        var email: String  // V1: named 'email'
        var hireDate: Date
        var salary: Double
        var department: Department?
        
        @Relationship(deleteRule: .cascade, inverse: \Address.employee)
        var address: Address?
        
        @Relationship(inverse: \Project.employees)
        var projects: [Project]?
        
        init(id: UUID = UUID(), firstName: String, lastName: String, email: String, hireDate: Date, salary: Double) {
            self.id = id
            self.firstName = firstName
            self.lastName = lastName
            self.email = email
            self.hireDate = hireDate
            self.salary = salary
        }
    }
    
    @Model
    final class Address {
        @Attribute(.unique) var id: UUID
        var street: String
        var city: String
        var state: String
        var zipCode: String
        var country: String
        var employee: Employee?
        
        init(id: UUID = UUID(), street: String, city: String, state: String, zipCode: String, country: String) {
            self.id = id
            self.street = street
            self.city = city
            self.state = state
            self.zipCode = zipCode
            self.country = country
        }
    }
    
    @Model
    final class Project {
        @Attribute(.unique) var id: UUID
        var name: String
        var startDate: Date
        var deadline: Date?
        var isCompleted: Bool
        var employees: [Employee]?
        
        init(id: UUID = UUID(), name: String, startDate: Date, deadline: Date? = nil, isCompleted: Bool = false) {
            self.id = id
            self.name = name
            self.startDate = startDate
            self.deadline = deadline
            self.isCompleted = isCompleted
        }
    }
}
