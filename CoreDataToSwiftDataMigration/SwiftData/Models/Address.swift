import Foundation
import SwiftData

/// Represents a physical address for an employee.
@Model
final class Address {
    /// Unique identifier for the address.
    @Attribute(.unique) var id: UUID
    
    /// The street name and number.
    var street: String
    
    /// The city.
    var city: String
    
    /// The state or province.
    var state: String
    
    /// The postal or ZIP code.
    var zipCode: String
    
    /// The country.
    var country: String
    
    /// The employee associated with this address.
    var employee: Employee?
    
    /// Initializes a new Address.
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - street: Street name.
    ///   - city: City.
    ///   - state: State.
    ///   - zipCode: ZIP Code.
    ///   - country: Country.
    init(id: UUID = UUID(), street: String, city: String, state: String, zipCode: String, country: String) {
        self.id = id
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }
}
