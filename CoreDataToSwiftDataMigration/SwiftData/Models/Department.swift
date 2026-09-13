import Foundation
import SwiftData

/// Represents a department within the organization.
/// Employees belong to exactly one department.
@Model
final class Department {
    /// A unique identifier for the department.
    @Attribute(.unique) var id: UUID
    
    /// The name of the department (e.g., "Engineering").
    var name: String
    
    /// The allocated budget for the department.
    var budget: Double
    
    /// The employees belonging to this department.
    /// Uses cascade delete rule: deleting a department deletes all its employees.
    @Relationship(deleteRule: .cascade, inverse: \Employee.department)
    var employees: [Employee]? = []
    
    /// Initializes a new Department.
    /// - Parameters:
    ///   - id: Unique identifier, defaults to a new UUID.
    ///   - name: The name of the department.
    ///   - budget: The budget allocated.
    init(id: UUID = UUID(), name: String, budget: Double) {
        self.id = id
        self.name = name
        self.budget = budget
    }
}
