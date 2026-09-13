import Foundation
import CoreData

@objc(AddressCD)
public class AddressCD: NSManagedObject {

    // MARK: - Fetch Request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AddressCD> {
        return NSFetchRequest<AddressCD>(entityName: "AddressCD")
    }

    // MARK: - Properties
    @NSManaged public var id: UUID
    @NSManaged public var street: String?
    @NSManaged public var city: String?
    @NSManaged public var state: String?
    @NSManaged public var zipCode: String?
    @NSManaged public var country: String?

    // MARK: - Relationships
    @NSManaged public var employee: EmployeeCD?

    // MARK: - Computed Properties
    /// Returns the formatted full address string.
    public var fullAddress: String {
        let components = [street, city, state, zipCode, country].compactMap { $0 }.filter { !$0.isEmpty }
        return components.joined(separator: ", ")
    }
}
