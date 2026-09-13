import Foundation
import SwiftData

/// Schema V2 representing the updated schema with the new 'phoneNumber' field
/// and 'emailAddress' renamed from 'email'. Uses the top-level active models.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Department.self, Employee.self, Address.self, Project.self]
    }
}
