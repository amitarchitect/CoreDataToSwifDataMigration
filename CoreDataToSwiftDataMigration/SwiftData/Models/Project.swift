import Foundation
import SwiftData

/// Represents a project that employees can be assigned to.
@Model
final class Project {
    /// Unique identifier for the project.
    @Attribute(.unique) var id: UUID
    
    /// Name of the project.
    var name: String
    
    /// The start date of the project.
    var startDate: Date
    
    /// The optional deadline for the project.
    var deadline: Date?
    
    /// Indicates whether the project is completed.
    var isCompleted: Bool
    
    /// The employees assigned to this project.
    var employees: [Employee]? = []
    
    /// Initializes a new Project.
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - name: Project name.
    ///   - startDate: Start date.
    ///   - deadline: Deadline date (optional).
    ///   - isCompleted: Completion status.
    init(id: UUID = UUID(), name: String, startDate: Date, deadline: Date? = nil, isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.deadline = deadline
        self.isCompleted = isCompleted
    }
}
