import Foundation
import SwiftData

/// The migration plan for transitioning between schema versions.
enum EmployeeManagementMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    // MARK: - Migration Stages
    
    /// Custom migration stage from V1 to V2.
    /// This handles setting the new `phoneNumber` property defaults for existing employees,
    /// while `email` to `emailAddress` is handled by the framework using `@Attribute(originalName:)`.
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Pre-migration logic could go here if needed.
            // In this case, fetching V1 employees doesn't strictly require alteration
            // before the migration since SwiftData handles lightweight attribute renames.
            let employees = try context.fetch(FetchDescriptor<SchemaV1.Employee>())
            for _ in employees {
                // Perform any preprocessing for each employee here if required
            }
            try context.save()
        },
        didMigrate: { context in
            // Post-migration logic: set defaults for the newly added phoneNumber property
            let newEmployees = try context.fetch(FetchDescriptor<Employee>())
            for employee in newEmployees {
                if employee.phoneNumber == nil {
                    // Set a default value for legacy records
                    employee.phoneNumber = "000-000-0000"
                }
            }
            try context.save()
        }
    )
}
