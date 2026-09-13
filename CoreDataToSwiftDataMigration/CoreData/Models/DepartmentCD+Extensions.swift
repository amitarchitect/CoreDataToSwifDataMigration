import Foundation
import CoreData

@objc(DepartmentCD)
public class DepartmentCD: NSManagedObject {

    // MARK: - Fetch Request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DepartmentCD> {
        return NSFetchRequest<DepartmentCD>(entityName: "DepartmentCD")
    }

    // MARK: - Properties
    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var budget: Double

    // MARK: - Relationships
    @NSManaged public var employees: NSSet?

    // MARK: - Computed Properties
    /// Returns a sorted array of employees belonging to the department.
    public var employeesArray: [EmployeeCD] {
        let set = employees as? Set<EmployeeCD> ?? []
        return set.sorted { 
            ($0.lastName ?? "") < ($1.lastName ?? "")
        }
    }
}

// MARK: Generated accessors for employees
extension DepartmentCD {
    @objc(addEmployeesObject:)
    @NSManaged public func addToEmployees(_ value: EmployeeCD)

    @objc(removeEmployeesObject:)
    @NSManaged public func removeFromEmployees(_ value: EmployeeCD)

    @objc(addEmployees:)
    @NSManaged public func addToEmployees(_ values: NSSet)

    @objc(removeEmployees:)
    @NSManaged public func removeFromEmployees(_ values: NSSet)
}
