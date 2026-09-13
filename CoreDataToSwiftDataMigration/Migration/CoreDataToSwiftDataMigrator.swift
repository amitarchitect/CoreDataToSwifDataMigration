import Foundation
import CoreData
import SwiftData

// MARK: - CoreDataToSwiftDataMigrator

/// Handles the one-time migration of data from Core Data to SwiftData.
///
/// This class reads all entities from the Core Data store and creates
/// equivalent SwiftData model objects, preserving all relationships
/// (1:1, 1:N, and M:N).
///
/// ## Usage
/// ```swift
/// let migrator = CoreDataToSwiftDataMigrator(
///     coreDataStack: CoreDataStack.shared,
///     modelContext: modelContext
/// )
/// try await migrator.migrate()
/// ```
///
/// ## Migration Strategy
/// 1. Fetch all Core Data entities on a background context
/// 2. Convert to intermediate structs (DTOs) to avoid thread-safety issues
/// 3. Create SwiftData @Model objects on the main actor
/// 4. Re-link all relationships using UUID-based mapping dictionaries
/// 5. Save and mark migration as completed
@Observable
class CoreDataToSwiftDataMigrator {
    
    // MARK: - Types
    
    /// Represents the current state of the migration process.
    enum MigrationState: Equatable {
        case notStarted
        case inProgress(progress: Double, currentEntity: String)
        case completed(stats: MigrationStats)
        case failed(errorMessage: String)
        
        static func == (lhs: MigrationState, rhs: MigrationState) -> Bool {
            switch (lhs, rhs) {
            case (.notStarted, .notStarted):
                return true
            case let (.inProgress(p1, e1), .inProgress(p2, e2)):
                return p1 == p2 && e1 == e2
            case let (.completed(s1), .completed(s2)):
                return s1 == s2
            case let (.failed(e1), .failed(e2)):
                return e1 == e2
            default:
                return false
            }
        }
        
        /// Convenience check for whether migration is currently running.
        var isInProgress: Bool {
            if case .inProgress = self { return true }
            return false
        }
    }
    
    /// Statistics collected during the migration process.
    struct MigrationStats: Equatable {
        let departmentsMigrated: Int
        let employeesMigrated: Int
        let projectsMigrated: Int
        let addressesMigrated: Int
        let duration: TimeInterval
    }
    
    // MARK: - Intermediate DTOs (Thread-Safe Data Transfer)
    
    /// Lightweight struct for transferring Department data across threads.
    private struct DepartmentDTO {
        let id: UUID
        let name: String
        let budget: Double
    }
    
    /// Lightweight struct for transferring Project data across threads.
    private struct ProjectDTO {
        let id: UUID
        let name: String
        let startDate: Date
        let deadline: Date?
        let isCompleted: Bool
    }
    
    /// Lightweight struct for transferring Address data across threads.
    private struct AddressDTO {
        let id: UUID
        let street: String
        let city: String
        let state: String
        let zipCode: String
        let country: String
    }
    
    /// Lightweight struct for transferring Employee data across threads.
    private struct EmployeeDTO {
        let id: UUID
        let firstName: String
        let lastName: String
        let email: String
        let hireDate: Date
        let salary: Double
        let departmentId: UUID?
        let address: AddressDTO?
        let projectIds: [UUID]
    }
    
    // MARK: - Properties
    
    /// The current state of the migration process. Observable by SwiftUI views.
    private(set) var state: MigrationState = .notStarted
    
    /// The Core Data stack to read legacy data from.
    private let coreDataStack: CoreDataStack
    
    /// The SwiftData model context to write migrated data to.
    private let modelContext: ModelContext
    
    /// UserDefaults key to track whether migration has been completed.
    private static let migrationCompletedKey = "CoreDataToSwiftDataMigrationCompleted"
    
    /// Whether the app still needs to migrate data from Core Data.
    var needsMigration: Bool {
        !UserDefaults.standard.bool(forKey: Self.migrationCompletedKey)
    }
    
    // MARK: - Initialization
    
    /// Creates a new migrator instance.
    /// - Parameters:
    ///   - coreDataStack: The Core Data stack containing the legacy data.
    ///   - modelContext: The SwiftData context to write migrated data into.
    init(coreDataStack: CoreDataStack, modelContext: ModelContext) {
        self.coreDataStack = coreDataStack
        self.modelContext = modelContext
    }
    
    // MARK: - Migration Execution
    
    /// Performs the full migration from Core Data to SwiftData.
    ///
    /// This method:
    /// 1. Fetches all Core Data entities on the Core Data context's queue
    /// 2. Converts them to thread-safe DTOs
    /// 3. Creates SwiftData model objects on the main actor
    /// 4. Rebuilds all relationships using UUID-based lookups
    /// 5. Saves the SwiftData context
    /// 6. Marks the migration as completed in UserDefaults
    ///
    /// - Throws: An error if the fetch or save operations fail.
    @MainActor
    func migrate() async throws {
        guard needsMigration else { return }
        
        let startTime = Date()
        state = .inProgress(progress: 0.0, currentEntity: "Preparing...")
        
        do {
            // Step 1: Extract all data from Core Data as thread-safe DTOs
            let (departmentDTOs, projectDTOs, employeeDTOs) = try await fetchCoreDataEntities()
            
            // Step 2: Create SwiftData objects on the main actor
            state = .inProgress(progress: 0.5, currentEntity: "Creating SwiftData objects...")
            
            // Maps to preserve relationships using UUIDs
            var departmentMap: [UUID: Department] = [:]
            var projectMap: [UUID: Project] = [:]
            var addressCount = 0
            
            // 2a. Migrate Departments
            state = .inProgress(progress: 0.55, currentEntity: "Departments")
            for dto in departmentDTOs {
                let dept = Department(id: dto.id, name: dto.name, budget: dto.budget)
                modelContext.insert(dept)
                departmentMap[dto.id] = dept
            }
            
            // 2b. Migrate Projects
            state = .inProgress(progress: 0.65, currentEntity: "Projects")
            for dto in projectDTOs {
                let proj = Project(
                    id: dto.id,
                    name: dto.name,
                    startDate: dto.startDate,
                    deadline: dto.deadline,
                    isCompleted: dto.isCompleted
                )
                modelContext.insert(proj)
                projectMap[dto.id] = proj
            }
            
            // 2c. Migrate Employees, Addresses, and Relationships
            state = .inProgress(progress: 0.75, currentEntity: "Employees & Addresses")
            for dto in employeeDTOs {
                // Create Employee (using V2 model: emailAddress, phoneNumber)
                let emp = Employee(
                    id: dto.id,
                    firstName: dto.firstName,
                    lastName: dto.lastName,
                    emailAddress: dto.email,
                    phoneNumber: nil,   // Core Data V1 doesn't have phone numbers
                    hireDate: dto.hireDate,
                    salary: dto.salary
                )
                modelContext.insert(emp)
                
                // Link Department (1:N relationship)
                if let deptId = dto.departmentId {
                    emp.department = departmentMap[deptId]
                }
                
                // Create and link Address (1:1 relationship)
                if let addrDTO = dto.address {
                    let addr = Address(
                        id: addrDTO.id,
                        street: addrDTO.street,
                        city: addrDTO.city,
                        state: addrDTO.state,
                        zipCode: addrDTO.zipCode,
                        country: addrDTO.country
                    )
                    modelContext.insert(addr)
                    emp.address = addr
                    addressCount += 1
                }
                
                // Link Projects (M:N relationship)
                var linkedProjects: [Project] = []
                for projId in dto.projectIds {
                    if let proj = projectMap[projId] {
                        linkedProjects.append(proj)
                    }
                }
                emp.projects = linkedProjects
            }
            
            // Step 3: Save SwiftData context
            state = .inProgress(progress: 0.9, currentEntity: "Saving...")
            try modelContext.save()
            
            // Step 4: Mark migration as completed
            UserDefaults.standard.set(true, forKey: Self.migrationCompletedKey)
            
            let stats = MigrationStats(
                departmentsMigrated: departmentDTOs.count,
                employeesMigrated: employeeDTOs.count,
                projectsMigrated: projectDTOs.count,
                addressesMigrated: addressCount,
                duration: Date().timeIntervalSince(startTime)
            )
            state = .completed(stats: stats)
            
        } catch {
            state = .failed(errorMessage: error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Core Data Fetching (Background Thread)
    
    /// Fetches all entities from Core Data and converts them to thread-safe DTOs.
    ///
    /// This runs on Core Data's context queue via `perform` to ensure thread safety,
    /// then returns the lightweight DTOs back to the caller.
    private func fetchCoreDataEntities() async throws -> ([DepartmentDTO], [ProjectDTO], [EmployeeDTO]) {
        let context = coreDataStack.viewContext
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Fetch Departments
                    let deptFetch = NSFetchRequest<NSManagedObject>(entityName: "DepartmentCD")
                    let cdDepartments = try context.fetch(deptFetch)
                    let departmentDTOs: [DepartmentDTO] = cdDepartments.compactMap { cdDept in
                        guard let id = cdDept.value(forKey: "id") as? UUID,
                              let name = cdDept.value(forKey: "name") as? String,
                              let budget = cdDept.value(forKey: "budget") as? Double else { return nil }
                        return DepartmentDTO(id: id, name: name, budget: budget)
                    }
                    
                    // Fetch Projects
                    let projFetch = NSFetchRequest<NSManagedObject>(entityName: "ProjectCD")
                    let cdProjects = try context.fetch(projFetch)
                    let projectDTOs: [ProjectDTO] = cdProjects.compactMap { cdProj in
                        guard let id = cdProj.value(forKey: "id") as? UUID,
                              let name = cdProj.value(forKey: "name") as? String,
                              let startDate = cdProj.value(forKey: "startDate") as? Date,
                              let isCompleted = cdProj.value(forKey: "isCompleted") as? Bool else { return nil }
                        let deadline = cdProj.value(forKey: "deadline") as? Date
                        return ProjectDTO(id: id, name: name, startDate: startDate, deadline: deadline, isCompleted: isCompleted)
                    }
                    
                    // Fetch Employees with relationships
                    let empFetch = NSFetchRequest<NSManagedObject>(entityName: "EmployeeCD")
                    let cdEmployees = try context.fetch(empFetch)
                    let employeeDTOs: [EmployeeDTO] = cdEmployees.compactMap { cdEmp in
                        guard let id = cdEmp.value(forKey: "id") as? UUID,
                              let firstName = cdEmp.value(forKey: "firstName") as? String,
                              let lastName = cdEmp.value(forKey: "lastName") as? String,
                              let email = cdEmp.value(forKey: "email") as? String,
                              let hireDate = cdEmp.value(forKey: "hireDate") as? Date,
                              let salary = cdEmp.value(forKey: "salary") as? Double else { return nil }
                        
                        // Extract department relationship (UUID only)
                        let departmentId: UUID? = {
                            guard let cdDept = cdEmp.value(forKey: "department") as? NSManagedObject,
                                  let deptId = cdDept.value(forKey: "id") as? UUID else { return nil }
                            return deptId
                        }()
                        
                        // Extract address data (with safe defaults for nil fields)
                        let addressDTO: AddressDTO? = {
                            guard let cdAddr = cdEmp.value(forKey: "address") as? NSManagedObject,
                                  let addrId = cdAddr.value(forKey: "id") as? UUID else { return nil }
                            return AddressDTO(
                                id: addrId,
                                street: (cdAddr.value(forKey: "street") as? String) ?? "",
                                city: (cdAddr.value(forKey: "city") as? String) ?? "",
                                state: (cdAddr.value(forKey: "state") as? String) ?? "",
                                zipCode: (cdAddr.value(forKey: "zipCode") as? String) ?? "",
                                country: (cdAddr.value(forKey: "country") as? String) ?? ""
                            )
                        }()
                        
                        // Extract project relationship UUIDs (M:N)
                        let projectIds: [UUID] = {
                            guard let projSet = cdEmp.value(forKey: "projects") as? NSSet else { return [] }
                            return projSet.compactMap { projObj in
                                (projObj as? NSManagedObject)?.value(forKey: "id") as? UUID
                            }
                        }()
                        
                        return EmployeeDTO(
                            id: id,
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            hireDate: hireDate,
                            salary: salary,
                            departmentId: departmentId,
                            address: addressDTO,
                            projectIds: projectIds
                        )
                    }
                    
                    continuation.resume(returning: (departmentDTOs, projectDTOs, employeeDTOs))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Utilities
    
    /// Resets the migration status, allowing it to run again.
    /// Used primarily for testing or re-migration scenarios.
    func resetMigration() {
        UserDefaults.standard.set(false, forKey: Self.migrationCompletedKey)
        state = .notStarted
    }
}
