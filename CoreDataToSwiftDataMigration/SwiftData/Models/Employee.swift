import Foundation
import SwiftData

/// Represents an employee in the system.
/// Contains the V2 schema updates: emailAddress and phoneNumber.
@Model
final class Employee {
    /// A unique identifier for the employee.
    @Attribute(.unique) var id: UUID
    
    /// The first name of the employee.
    var firstName: String
    
    /// The last name of the employee.
    var lastName: String
    
    /// The email address of the employee. Renamed from 'email' in V2.
    @Attribute(originalName: "email")
    var emailAddress: String
    
    /// The phone number of the employee. New in V2 schema.
    var phoneNumber: String?
    
    /// The date the employee was hired.
    var hireDate: Date
    
    /// The current salary of the employee.
    var salary: Double
    
    /// The department the employee belongs to.
    var department: Department?
    
    /// The address of the employee.
    /// Cascade delete: deleting an employee deletes their address.
    @Relationship(deleteRule: .cascade, inverse: \Address.employee)
    var address: Address?
    
    /// The projects the employee is assigned to.
    @Relationship(inverse: \Project.employees)
    var projects: [Project]? = []
    
    /// Computed property for the full name.
    @Transient
    var fullName: String { "\(firstName) \(lastName)" }
    
    /// Initializes a new Employee.
    /// - Parameters:
    ///   - id: Unique identifier, defaults to a new UUID.
    ///   - firstName: First name.
    ///   - lastName: Last name.
    ///   - emailAddress: Email address.
    ///   - phoneNumber: Phone number (optional).
    ///   - hireDate: Date of hire.
    ///   - salary: Current salary.
    init(id: UUID = UUID(), firstName: String, lastName: String, emailAddress: String, phoneNumber: String? = nil, hireDate: Date, salary: Double) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.emailAddress = emailAddress
        self.phoneNumber = phoneNumber
        self.hireDate = hireDate
        self.salary = salary
    }
}
