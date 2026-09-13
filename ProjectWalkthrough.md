# 🔬 Deep Dive: Building a Core Data to SwiftData Migration System — Architecture & Code Walkthrough

*Ever wondered what a production-grade migration from Core Data to SwiftData actually looks like under the hood?*

In my [previous article](#), I covered the **why** and **what** of migrating to SwiftData. Now, let's roll up our sleeves and examine the **how** — a complete architectural deep dive into a real Employee Management System that demonstrates every moving part of the migration.

This article walks through the actual source code, explains the architecture with **HLD, SLD, and Sequence Diagrams**, and most importantly, shows you how the system handles **three timelines**: Before Migration (Core Data), During Migration, and After Migration (SwiftData + Future Schema Evolution).

📂 **Full source code:** [GitHub — CoreDataToSwiftDataMigration](https://github.com/anthropics/CoreDataToSwiftDataMigration)

---

## 📐 Project Architecture Overview

Before we dive into code, let's understand the system from the top down.

### High-Level Design (HLD)

The project is organized into **6 layers**, each with a clear responsibility. This separation allows the Core Data and SwiftData stacks to coexist during the transition period.

```mermaid
graph TB
    subgraph "🎨 Presentation Layer"
        App["CoreDataToSwiftDataMigrationApp"]
        CV["ContentView (TabView)"]
        DLV["DepartmentListView"]
        ELV["EmployeeListView"]
        EDV["EmployeeDetailView"]
        MSV["MigrationStatusView"]
    end

    subgraph "📦 SwiftData Layer (New)"
        MC["ModelContainer"]
        MCtx["ModelContext"]
        SD_Dept["@Model Department"]
        SD_Emp["@Model Employee"]
        SD_Proj["@Model Project"]
        SD_Addr["@Model Address"]
    end

    subgraph "🔄 Schema Versioning"
        SV1["SchemaV1 (email)"]
        SV2["SchemaV2 (emailAddress + phoneNumber)"]
        MP["EmployeeManagementMigrationPlan"]
    end

    subgraph "🔀 Migration Layer"
        Migrator["CoreDataToSwiftDataMigrator"]
        DTOs["Thread-Safe DTOs"]
    end

    subgraph "🗄️ Core Data Layer (Legacy)"
        CDS["CoreDataStack (Singleton)"]
        PC["NSPersistentContainer"]
        CD_Dept["DepartmentCD"]
        CD_Emp["EmployeeCD"]
        CD_Proj["ProjectCD"]
        CD_Addr["AddressCD"]
    end

    subgraph "🧪 Utilities"
        SDG["SampleDataGenerator"]
    end

    App --> MC
    App --> CV
    CV --> DLV
    CV --> MSV
    DLV --> ELV
    ELV --> EDV

    MC --> MCtx
    MC -.-> MP
    MP --> SV1
    MP --> SV2

    DLV --> |"@Query"| SD_Dept
    ELV --> |"@Query"| SD_Emp

    MSV --> Migrator
    Migrator --> |"Read"| CDS
    Migrator --> |"Write"| MCtx
    Migrator --> DTOs

    CDS --> PC
    PC --> CD_Dept
    PC --> CD_Emp
    PC --> CD_Proj
    PC --> CD_Addr

    SDG --> CDS

    style App fill:#4A90D9,color:#fff
    style Migrator fill:#E8873A,color:#fff
    style MC fill:#50C878,color:#fff
    style CDS fill:#CD5C5C,color:#fff
```

> **Key Insight:** The Migration Layer acts as a bridge between the two worlds. It reads from Core Data on its queue, converts to thread-safe DTOs, then writes to SwiftData on the main actor. The two persistence stacks **never directly interact**.

---

### System-Level Design (SLD) — Entity Relationships

The domain model contains **all three relationship types** found in real enterprise apps:

```mermaid
classDiagram
    direction LR

    class DepartmentCD {
        <<NSManagedObject>>
        +UUID id
        +String name
        +Double budget
        +NSSet? employees
    }

    class EmployeeCD {
        <<NSManagedObject>>
        +UUID id
        +String firstName
        +String lastName
        +String email
        +Date hireDate
        +Double salary
        +DepartmentCD? department
        +AddressCD? address
        +NSSet? projects
    }

    class AddressCD {
        <<NSManagedObject>>
        +UUID id
        +String street
        +String city
        +String state
        +String zipCode
        +String country
        +EmployeeCD? employee
    }

    class ProjectCD {
        <<NSManagedObject>>
        +UUID id
        +String name
        +Date startDate
        +Date? deadline
        +Bool isCompleted
        +NSSet? employees
    }

    DepartmentCD "1" --o "N" EmployeeCD : employees
    EmployeeCD "1" --o "1" AddressCD : address
    EmployeeCD "N" --o "M" ProjectCD : projects

    class Department {
        <<@Model>>
        +UUID id
        +String name
        +Double budget
        +Array~Employee~? employees
    }

    class Employee {
        <<@Model>>
        +UUID id
        +String firstName
        +String lastName
        +String emailAddress ⬅ renamed
        +String? phoneNumber ⬅ new
        +Date hireDate
        +Double salary
        +Department? department
        +Address? address
        +Array~Project~? projects
    }

    class Address {
        <<@Model>>
        +UUID id
        +String street
        +String city
        +String state
        +String zipCode
        +String country
        +Employee? employee
    }

    class Project {
        <<@Model>>
        +UUID id
        +String name
        +Date startDate
        +Date? deadline
        +Bool isCompleted
        +Array~Employee~? employees
    }

    Department "1" --o "N" Employee : employees
    Employee "1" --o "1" Address : address
    Employee "N" --o "M" Project : projects

    class CoreDataToSwiftDataMigrator {
        +MigrationState state
        -CoreDataStack coreDataStack
        -ModelContext modelContext
        +migrate() async throws
        +resetMigration()
        -fetchCoreDataEntities() async
    }

    CoreDataToSwiftDataMigrator ..> DepartmentCD : reads
    CoreDataToSwiftDataMigrator ..> EmployeeCD : reads
    CoreDataToSwiftDataMigrator ..> ProjectCD : reads
    CoreDataToSwiftDataMigrator ..> AddressCD : reads
    CoreDataToSwiftDataMigrator ..> Department : writes
    CoreDataToSwiftDataMigrator ..> Employee : writes
    CoreDataToSwiftDataMigrator ..> Project : writes
    CoreDataToSwiftDataMigrator ..> Address : writes
```

Notice the key differences between the **left (Core Data)** and **right (SwiftData)** sides:

| Aspect | Core Data | SwiftData |
|--------|-----------|-----------|
| Email field | `email: String` | `emailAddress: String` (renamed via `@Attribute(originalName:)`) |
| Phone | ❌ Not present | `phoneNumber: String?` (new in V2) |
| Relationships | `NSSet?` (untyped) | `[Employee]?` (typed arrays) |
| Definitions | `.xcdatamodeld` XML + NSManagedObject | `@Model` classes in pure Swift |

---

## ⏳ Timeline 1: BEFORE Migration — The Core Data World

### How the Core Data Stack Works

```mermaid
sequenceDiagram
    participant App as App Launch
    participant CDS as CoreDataStack
    participant PC as NSPersistentContainer
    participant DB as SQLite (.sqlite)
    participant View as SwiftUI View

    App->>CDS: CoreDataStack.shared
    CDS->>PC: NSPersistentContainer("EmployeeManagement")
    PC->>DB: loadPersistentStores()
    DB-->>PC: Store loaded ✅
    PC-->>CDS: viewContext ready

    Note over View: Using @FetchRequest or manual fetch
    View->>CDS: fetch(NSFetchRequest<EmployeeCD>)
    CDS->>PC: viewContext.fetch(request)
    PC->>DB: SQL SELECT
    DB-->>PC: NSManagedObjects
    PC-->>CDS: [EmployeeCD]
    CDS-->>View: Display data

    Note over View: Creating new record
    View->>CDS: NSEntityDescription.insertNewObject()
    CDS->>PC: viewContext.save()
    PC->>DB: SQL INSERT
    DB-->>PC: Saved ✅
```

**The Core Data Stack** (`CoreDataStack.swift`) is a classic singleton pattern:

```swift
public class CoreDataStack {
    public static let shared = CoreDataStack()
    
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "EmployeeManagement")
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}
```

**The Entity Definitions** live in an XML file (`EmployeeManagement.xcdatamodeld`), requiring:
- Manual `@objc(EmployeeCD)` class annotations
- `@NSManaged` property declarations
- Explicit relationship inverses
- String-based entity names (`"EmployeeCD"`) in fetch requests

> **Pain Point:** A single typo in an entity name (e.g., `"Employee"` instead of `"EmployeeCD"`) causes a **runtime crash**, not a compile-time error. We caught exactly this issue during our code review!

---

## 🔀 Timeline 2: DURING Migration — The Bridge

This is where the magic happens. The `CoreDataToSwiftDataMigrator` orchestrates a safe, tracked, one-time data transfer.

### Migration Sequence Diagram

```mermaid
sequenceDiagram
    participant UI as MigrationStatusView
    participant M as CoreDataToSwiftDataMigrator
    participant CD as CoreDataStack
    participant DTO as Thread-Safe DTOs
    participant SD as ModelContext (SwiftData)
    participant UDF as UserDefaults

    UI->>M: migrate()
    M->>UDF: needsMigration?
    UDF-->>M: true ✅
    M->>M: state = .inProgress(0%, "Preparing...")

    rect rgb(255, 240, 230)
        Note over M,CD: Phase 1: Extract from Core Data (on CD queue)
        M->>CD: context.perform { ... }
        CD->>CD: fetch("DepartmentCD")
        CD->>CD: fetch("ProjectCD")
        CD->>CD: fetch("EmployeeCD")
        CD->>CD: Extract relationship UUIDs
        CD-->>DTO: Convert to DTOs
        DTO-->>M: [DepartmentDTO], [ProjectDTO], [EmployeeDTO]
    end

    rect rgb(230, 255, 230)
        Note over M,SD: Phase 2: Write to SwiftData (on @MainActor)
        M->>M: state = .inProgress(55%, "Departments")
        M->>SD: insert(Department) for each DTO
        M->>M: Build departmentMap[UUID: Department]

        M->>M: state = .inProgress(65%, "Projects")
        M->>SD: insert(Project) for each DTO
        M->>M: Build projectMap[UUID: Project]

        M->>M: state = .inProgress(75%, "Employees")
        loop For each EmployeeDTO
            M->>SD: insert(Employee)
            M->>M: emp.department = departmentMap[deptId]
            M->>SD: insert(Address) if exists
            M->>M: emp.address = newAddress
            M->>M: emp.projects = lookup projectMap
        end
    end

    rect rgb(230, 230, 255)
        Note over M,SD: Phase 3: Finalize
        M->>M: state = .inProgress(90%, "Saving...")
        M->>SD: modelContext.save()
        SD-->>M: Saved ✅
        M->>UDF: set("migrationCompleted", true)
        M->>M: state = .completed(stats)
    end

    M-->>UI: Stats displayed ✅
```

### Why the DTO Pattern?

This is a critical architectural decision. You **cannot** access `NSManagedObject` properties on the main thread and `ModelContext` on a background thread. The solution:

```
┌─────────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Core Data Queue   │───▶│   DTOs (Structs) │───▶│   @MainActor Queue  │
│                     │    │   Thread-safe     │    │                     │
│ NSManagedObject     │    │ DepartmentDTO     │    │ @Model Department   │
│ (not thread-safe)   │    │ EmployeeDTO       │    │ @Model Employee     │
│                     │    │ ProjectDTO        │    │ @Model Project      │
│                     │    │ AddressDTO        │    │ @Model Address      │
└─────────────────────┘    └──────────────────┘    └─────────────────────┘
```

The DTO structs are simple value types with no thread-affinity:

```swift
private struct EmployeeDTO {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String           // Core Data field name
    let hireDate: Date
    let salary: Double
    let departmentId: UUID?     // Relationship → just the UUID
    let address: AddressDTO?    // Nested DTO for 1:1
    let projectIds: [UUID]      // M:N → array of UUIDs
}
```

### Relationship Reconstruction with UUID Maps

The trickiest part of migration is preserving relationships. Since Core Data and SwiftData objects live in different object graphs, we use **UUID-keyed dictionaries** as a bridge:

```swift
// Build maps during creation
var departmentMap: [UUID: Department] = [:]
var projectMap: [UUID: Project] = [:]

// When creating employees, resolve relationships via UUID lookup
if let deptId = dto.departmentId {
    emp.department = departmentMap[deptId]  // 1:N ✅
}
emp.address = Address(...)                  // 1:1 ✅
emp.projects = dto.projectIds.compactMap {  // M:N ✅
    projectMap[$0]
}
```

---

## ✨ Timeline 3: AFTER Migration — The SwiftData World

### How SwiftData Serves the UI

```mermaid
sequenceDiagram
    participant App as App Launch
    participant MC as ModelContainer
    participant MP as MigrationPlan
    participant MCtx as ModelContext
    participant DB as SQLite (default.store)
    participant View as DepartmentListView

    App->>MC: ModelContainer(for: schema, migrationPlan: ...)
    MC->>MP: Check schema version
    MP-->>MC: V2 (current) ✅
    MC->>DB: Open store
    DB-->>MC: Ready ✅
    MC->>MCtx: Create ModelContext

    Note over View: Using @Query (declarative)
    View->>MCtx: @Query var departments (automatic)
    MCtx->>DB: FetchDescriptor<Department>
    DB-->>MCtx: [Department] (typed!)
    MCtx-->>View: SwiftUI auto-updates ✅

    Note over View: Creating new record
    View->>MCtx: modelContext.insert(Department(...))
    MCtx->>DB: Auto-save
    DB-->>MCtx: Saved ✅
    MCtx-->>View: @Query auto-refreshes UI ✅
```

**The key difference:** No manual fetch requests. No string-typed entity names. No manual save calls. The `@Query` macro handles everything declaratively:

```swift
struct DepartmentListView: View {
    // This ONE line replaces ~15 lines of Core Data @FetchRequest setup
    @Query(sort: \Department.name) private var departments: [Department]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List(departments) { dept in
                NavigationLink(value: dept) {
                    VStack(alignment: .leading) {
                        Text(dept.name).font(.headline)
                        Text(dept.budget, format: .currency(code: "USD"))
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}
```

---

## 🔮 Timeline 4: FUTURE — Managing Schema Evolution

This is where SwiftData truly shines. When your schema evolves **after** the initial migration, you don't need to write a new migrator. You use `VersionedSchema` + `SchemaMigrationPlan`.

### Schema Evolution Flow

```mermaid
graph LR
    subgraph "V1 (Initial)"
        V1_E["Employee<br/>• email: String<br/>• (no phone)"]
    end

    subgraph "V2 (Current)"
        V2_E["Employee<br/>• emailAddress: String ⬅ renamed<br/>• phoneNumber: String? ⬅ new"]
    end

    subgraph "V3 (Future Example)"
        V3_E["Employee<br/>• emailAddress: String<br/>• phoneNumber: String?<br/>• emergencyContact: String? ⬅ new<br/>• employeeLevel: Int ⬅ new"]
    end

    V1_E -->|"Custom Migration<br/>@Attribute(originalName:)<br/>+ set default phoneNumber"| V2_E
    V2_E -->|"Lightweight Migration<br/>just add optional fields"| V3_E

    style V1_E fill:#CD5C5C,color:#fff
    style V2_E fill:#4A90D9,color:#fff
    style V3_E fill:#50C878,color:#fff
```

### How VersionedSchema Works

Each version snapshot captures the schema at a point in time:

```swift
// V1: Matches the original Core Data schema
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Department.self, Employee.self, Address.self, Project.self]
    }
    
    @Model final class Employee {
        var email: String       // ← Original field name
        // No phoneNumber field
    }
}

// V2: Current active schema
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Department.self, Employee.self, Address.self, Project.self]
    }
    // References the top-level @Model classes (latest version)
}
```

### The Migration Plan

```swift
enum EmployeeManagementMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Pre-migration: framework handles rename via @Attribute(originalName:)
        },
        didMigrate: { context in
            // Post-migration: set defaults for new fields
            let employees = try context.fetch(FetchDescriptor<Employee>())
            for employee in employees {
                if employee.phoneNumber == nil {
                    employee.phoneNumber = "000-000-0000"
                }
            }
            try context.save()
        }
    )
}
```

### Future Migration Sequence

```mermaid
sequenceDiagram
    participant App as App Launch
    participant MC as ModelContainer
    participant MP as MigrationPlan
    participant DB as SQLite Store

    App->>MC: ModelContainer(migrationPlan: ...)
    MC->>DB: Read current schema version
    DB-->>MC: Version 1.0.0

    MC->>MP: Need migration?
    MP-->>MC: Yes: V1 → V2

    rect rgb(255, 245, 230)
        Note over MC,DB: Stage: migrateV1toV2 (Custom)
        MC->>MP: willMigrate(context)
        Note right of MP: Framework renames email → emailAddress<br/>via @Attribute(originalName: "email")
        MC->>DB: Apply schema changes
        MC->>MP: didMigrate(context)
        MP->>DB: Set phoneNumber defaults
        MP->>DB: context.save()
    end

    MC->>DB: Update version → 2.0.0
    DB-->>MC: Migration complete ✅
    MC-->>App: ModelContainer ready

    Note over App: Future: Adding V3
    Note over App: 1. Create SchemaV3 enum
    Note over App: 2. Add migrateV2toV3 stage
    Note over App: 3. Update schemas array
    Note over App: SwiftData handles the chain:<br/>V1 → V2 → V3 automatically
```

> **🎯 Key Takeaway:** When adding V3 in the future, you only need three things:
> 1. Create a `SchemaV3` enum
> 2. Add a `migrateV2toV3` stage (lightweight or custom)
> 3. Append both to the migration plan's arrays
>
> SwiftData **automatically chains** migrations: a user on V1 will migrate V1→V2→V3 sequentially.

---

## 🗂️ Complete Project Structure

```
CoreDataToSwiftDataMigration/
│
├── 📱 App/
│   └── CoreDataToSwiftDataMigrationApp.swift    ← ModelContainer + MigrationPlan setup
│
├── 🗄️ CoreData/ (Legacy)
│   ├── CoreDataStack.swift                       ← NSPersistentContainer singleton
│   ├── EmployeeManagement.xcdatamodeld/          ← XML schema definition
│   └── Models/
│       ├── DepartmentCD+Extensions.swift         ← NSManagedObject subclass
│       ├── EmployeeCD+Extensions.swift
│       ├── ProjectCD+Extensions.swift
│       └── AddressCD+Extensions.swift
│
├── 📦 SwiftData/ (Modern)
│   ├── Models/
│   │   ├── Department.swift                      ← @Model, 1:N cascade
│   │   ├── Employee.swift                        ← @Model, @Attribute(originalName:)
│   │   ├── Project.swift                         ← @Model, M:N relationship
│   │   └── Address.swift                         ← @Model, 1:1 relationship
│   └── Schema/
│       ├── SchemaV1.swift                        ← VersionedSchema (initial)
│       ├── SchemaV2.swift                        ← VersionedSchema (current)
│       └── MigrationPlan.swift                   ← SchemaMigrationPlan
│
├── 🔀 Migration/
│   └── CoreDataToSwiftDataMigrator.swift         ← DTO pattern, @Observable
│
├── 🎨 Views/
│   ├── ContentView.swift                         ← TabView
│   ├── DepartmentListView.swift                  ← @Query, CRUD
│   ├── EmployeeListView.swift                    ← Search, navigation
│   ├── EmployeeDetailView.swift                  ← @Bindable, relationships
│   └── MigrationStatusView.swift                 ← Progress tracking
│
└── 🧪 Utilities/
    └── SampleDataGenerator.swift                 ← Test data in Core Data
```

---

## 🧬 Before vs After — Side-by-Side Code Comparison

### Defining a Model

```swift
// ❌ BEFORE: Core Data (3 files needed)
// File 1: .xcdatamodeld (XML visual editor)
// File 2: NSManagedObject subclass
@objc(EmployeeCD)
public class EmployeeCD: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var firstName: String
    @NSManaged public var lastName: String
    @NSManaged public var email: String
    @NSManaged public var department: DepartmentCD?
    @NSManaged public var address: AddressCD?
    @NSManaged public var projects: NSSet?  // Untyped!
}
// File 3: Extension with computed properties & fetchRequest()
```

```swift
// ✅ AFTER: SwiftData (1 file, complete)
@Model
final class Employee {
    @Attribute(.unique) var id: UUID
    var firstName: String
    var lastName: String
    @Attribute(originalName: "email")
    var emailAddress: String                           // Renamed!
    var phoneNumber: String?                           // New!
    var department: Department?
    @Relationship(deleteRule: .cascade, inverse: \Address.employee)
    var address: Address?
    @Relationship(inverse: \Project.employees)
    var projects: [Project]? = []                      // Typed!
}
```

### Fetching Data in SwiftUI

```swift
// ❌ BEFORE: Core Data
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \DepartmentCD.name, ascending: true)],
    animation: .default
)
private var departments: FetchedResults<DepartmentCD>
```

```swift
// ✅ AFTER: SwiftData
@Query(sort: \Department.name)
private var departments: [Department]
```

### Creating a New Record

```swift
// ❌ BEFORE: Core Data
let dept = NSEntityDescription.insertNewObject(forEntityName: "DepartmentCD", into: context)
dept.setValue(UUID(), forKey: "id")         // String-typed key! 💀
dept.setValue("Engineering", forKey: "name")
dept.setValue(1500000.0, forKey: "budget")
try context.save()
```

```swift
// ✅ AFTER: SwiftData
let dept = Department(name: "Engineering", budget: 1_500_000.0)
modelContext.insert(dept)
// Auto-saves! No manual save needed
```

---

## 📊 Migration State Machine

The migrator uses a state machine to track progress, which the UI observes via `@Observable`:

```mermaid
stateDiagram-v2
    [*] --> NotStarted

    NotStarted --> InProgress : migrate() called
    InProgress --> InProgress : progress updates<br/>(0%→55%→65%→75%→90%)
    InProgress --> Completed : save() succeeds
    InProgress --> Failed : error thrown

    Completed --> [*]
    Failed --> NotStarted : resetMigration()

    note right of InProgress
        Tracks:
        • progress (0.0 → 1.0)
        • currentEntity ("Departments", "Employees"...)
    end note

    note right of Completed
        Stores:
        • departmentsMigrated
        • employeesMigrated
        • projectsMigrated
        • addressesMigrated
        • duration
    end note
```

---

## ⚡ Key Architectural Decisions & Lessons Learned

### 1. Thread Safety via DTOs, Not Direct Object Passing

❌ **Wrong:** Passing `NSManagedObject` to `@MainActor` context
✅ **Right:** Convert to value-type DTOs on Core Data's queue, then create `@Model` objects on main actor

### 2. UUID-Based Relationship Mapping

❌ **Wrong:** Trying to look up objects by Core Data `NSManagedObjectID`
✅ **Right:** Every entity has a `UUID id` — use `[UUID: SwiftDataModel]` dictionaries to reconstruct the object graph

### 3. UserDefaults Guard for One-Time Migration

The migration checks `UserDefaults` before running, ensuring it only executes once:

```swift
var needsMigration: Bool {
    !UserDefaults.standard.bool(forKey: "CoreDataToSwiftDataMigrationCompleted")
}
```

### 4. `@Attribute(originalName:)` for Field Renames

Instead of writing complex data transformation code, SwiftData handles field renames declaratively:

```swift
@Attribute(originalName: "email")
var emailAddress: String  // SwiftData knows "email" → "emailAddress"
```

### 5. Custom Migration for Default Values

New non-optional fields need defaults for existing records. The `didMigrate` closure handles this:

```swift
didMigrate: { context in
    let employees = try context.fetch(FetchDescriptor<Employee>())
    for employee in employees {
        if employee.phoneNumber == nil {
            employee.phoneNumber = "000-000-0000"
        }
    }
    try context.save()
}
```

---

## 🎬 Summary — The Three Timelines

| Timeline | Stack | Relationships | Schema Changes | Type Safety |
|----------|-------|---------------|----------------|-------------|
| **Before** (Core Data) | NSPersistentContainer + xcdatamodeld | NSSet (untyped), manual inverse | NSMappingModel (XML) | Runtime ❌ |
| **During** (Migration) | Both stacks + Migrator + DTOs | UUID-based mapping dictionaries | N/A (one-time transfer) | DTO contracts ⚠️ |
| **After** (SwiftData) | ModelContainer + @Model | Typed arrays, auto-inverse | VersionedSchema + SchemaMigrationPlan | Compile-time ✅ |
| **Future** (Schema V3+) | Same ModelContainer | Same typed approach | Add schema + stage → auto-chains | Compile-time ✅ |

---

## 🚀 Try It Yourself

1. Clone the repo
2. Open `CoreDataToSwiftDataMigration.xcodeproj` in Xcode 15+
3. Run on iOS 17+ Simulator
4. Go to **Migration tab** → **Generate Sample Core Data** → **Start Migration**
5. Switch to **Departments tab** — you'll see all migrated data with relationships intact!

📂 **Source code:** [GitHub — CoreDataToSwiftDataMigration](https://github.com/anthropics/CoreDataToSwiftDataMigration)

---

*Found this deep dive useful? Share it with your iOS team and follow me for more architecture-level content on Swift, SwiftUI, and system design!*

#iOSDevelopment #SwiftData #CoreData #SoftwareArchitecture #SystemDesign #SwiftUI #MobileDevelopment #Apple #TechDeepDive
