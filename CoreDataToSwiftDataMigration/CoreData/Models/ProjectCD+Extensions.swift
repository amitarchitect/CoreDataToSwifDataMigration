import Foundation
import CoreData

@objc(ProjectCD)
public class ProjectCD: NSManagedObject {

    // MARK: - Fetch Request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProjectCD> {
        return NSFetchRequest<ProjectCD>(entityName: "ProjectCD")
    }

    // MARK: - Properties
    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var deadline: Date?
    @NSManaged public var isCompleted: Bool

    // MARK: - Relationships
    @NSManaged public var employees: NSSet?

    // MARK: - Computed Properties
    /// Returns a sorted array of employees assigned to the project.
    public var employeesArray: [EmployeeCD] {
        let set = employees as? Set<EmployeeCD> ?? []
        return set.sorted { 
            ($0.lastName ?? "") < ($1.lastName ?? "")
        }
    }
}

// MARK: Generated accessors for employees
extension ProjectCD {
    @objc(addEmployeesObject:)
    @NSManaged public func addToEmployees(_ value: EmployeeCD)

    @objc(removeEmployeesObject:)
    @NSManaged public func removeFromEmployees(_ value: EmployeeCD)

    @objc(addEmployees:)
    @NSManaged public func addToEmployees(_ values: NSSet)

    @objc(removeEmployees:)
    @NSManaged public func removeFromEmployees(_ values: NSSet)
}
