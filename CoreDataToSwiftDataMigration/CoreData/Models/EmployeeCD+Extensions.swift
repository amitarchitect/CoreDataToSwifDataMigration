import Foundation
import CoreData

@objc(EmployeeCD)
public class EmployeeCD: NSManagedObject {

    // MARK: - Fetch Request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmployeeCD> {
        return NSFetchRequest<EmployeeCD>(entityName: "EmployeeCD")
    }

    // MARK: - Properties
    @NSManaged public var id: UUID
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var email: String?
    @NSManaged public var hireDate: Date?
    @NSManaged public var salary: Double

    // MARK: - Relationships
    @NSManaged public var department: DepartmentCD?
    @NSManaged public var address: AddressCD?
    @NSManaged public var projects: NSSet?

    // MARK: - Computed Properties
    
    /// Returns the full name of the employee.
    public var fullName: String {
        return [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
    
    /// Returns a sorted array of projects associated with the employee.
    public var projectsArray: [ProjectCD] {
        let set = projects as? Set<ProjectCD> ?? []
        return set.sorted { 
            ($0.name ?? "") < ($1.name ?? "")
        }
    }
}

// MARK: Generated accessors for projects
extension EmployeeCD {
    @objc(addProjectsObject:)
    @NSManaged public func addToProjects(_ value: ProjectCD)

    @objc(removeProjectsObject:)
    @NSManaged public func removeFromProjects(_ value: ProjectCD)

    @objc(addProjects:)
    @NSManaged public func addToProjects(_ values: NSSet)

    @objc(removeProjects:)
    @NSManaged public func removeFromProjects(_ values: NSSet)
}
