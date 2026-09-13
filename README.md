# 🚀 CoreData → SwiftData Migration

<div align="center">

**A production-ready example project demonstrating a complete, enterprise-grade migration from Core Data to SwiftData — including all relationship types, schema versioning, and future migration management.**

[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift&logoColor=white)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-15.0%2B-blue?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![SwiftData](https://img.shields.io/badge/Framework-SwiftData-purple?logo=apple&logoColor=white)](https://developer.apple.com/documentation/swiftdata)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

[📖 Articles](#-documentation--articles) · [🏗️ Architecture](#-architecture) · [⚡ Quick Start](#-quick-start) · [📂 Project Structure](#-project-structure) · [🔬 Deep Dive](Article/ProjectWalkthrough.md)

</div>

---

## 📌 What is This?

This project is a **complete, runnable iOS app** that demonstrates migrating an **Employee Management System** from Core Data to SwiftData. It is designed as a learning resource and reference implementation for iOS engineers tackling real-world legacy migrations.

The app covers every challenge you'll face in production:
- ✅ Migrating **1:1, 1:N, and M:N** relationships
- ✅ Thread-safe migration using the **DTO pattern**
- ✅ **Schema versioning** with `VersionedSchema` (V1 → V2)
- ✅ **Custom migration stages** with `SchemaMigrationPlan`
- ✅ Field **rename** (`email` → `emailAddress`) via `@Attribute(originalName:)`
- ✅ Adding **new optional fields** (`phoneNumber`) with defaults for existing records
- ✅ Live **migration progress tracking** with `@Observable`
- ✅ Full **SwiftUI** integration with `@Query` and `@Environment(\.modelContext)`

---

## 🏗️ Architecture

The project is organized into **6 independent layers**:

```
┌──────────────────────────────────────────────────────────────────┐
│                     🎨 Presentation Layer                         │
│   ContentView  ·  DepartmentListView  ·  EmployeeListView        │
│   EmployeeDetailView  ·  MigrationStatusView                     │
└───────────────────────────┬──────────────────────────────────────┘
                            │
          ┌─────────────────┴──────────────────┐
          │                                    │
┌─────────▼──────────┐              ┌──────────▼─────────┐
│  🗄️ Core Data       │              │  📦 SwiftData       │
│  (Legacy Stack)    │              │  (Modern Stack)    │
│                    │              │                    │
│  CoreDataStack     │              │  ModelContainer    │
│  NSPersistentCont. │              │  ModelContext       │
│  DepartmentCD      │              │  @Model Department │
│  EmployeeCD        │              │  @Model Employee   │
│  ProjectCD         │              │  @Model Project    │
│  AddressCD         │              │  @Model Address    │
└─────────┬──────────┘              └──────────┬─────────┘
          │                                    │
          └─────────────┬──────────────────────┘
                        │
            ┌───────────▼────────────┐
            │  🔀 Migration Layer     │
            │  CoreDataToSwiftData   │
            │  Migrator (DTO pattern)│
            └───────────┬────────────┘
                        │
            ┌───────────▼────────────┐
            │  🔄 Schema Versioning   │
            │  SchemaV1 → SchemaV2   │
            │  MigrationPlan         │
            └────────────────────────┘
```

### Domain Model — Relationship Types

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ Department  │ 1──────N │  Employee   │ 1──────1 │   Address   │
│─────────────│         │─────────────│         │─────────────│
│ id: UUID    │         │ id: UUID    │         │ id: UUID    │
│ name        │         │ firstName   │         │ street      │
│ budget      │         │ lastName    │         │ city        │
└─────────────┘         │ emailAddr.  │         │ state       │
                        │ phoneNumber │         │ zipCode     │
                        │ hireDate    │         │ country     │
┌─────────────┐         │ salary      │         └─────────────┘
│   Project   │ N──────M │             │
│─────────────│         └─────────────┘
│ id: UUID    │
│ name        │
│ startDate   │
│ deadline?   │
│ isCompleted │
└─────────────┘
```

---

## ⚡ Quick Start

### Requirements
| Tool | Version |
|------|---------|
| Xcode | 15.0+ |
| iOS Simulator / Device | iOS 17.0+ |
| macOS (host) | 13.0+ |
| Swift | 5.9+ |

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/CoreDataToSwiftDataMigration.git

# Open in Xcode
open CoreDataToSwiftDataMigration.xcodeproj
```

### Running the App

1. Select an **iOS 17+ simulator** (e.g., iPhone 16)
2. Press **⌘R** to build and run
3. Navigate to the **Migration** tab (⇄ icon)
4. Tap **"Generate Sample Core Data"** — creates 4 departments, 15 employees, 5 projects with M:N assignments
5. Tap **"Start Migration"** — watch the progress bar as data migrates
6. Navigate to the **Departments** tab to see all migrated data

> [!NOTE]
> On first launch, no data exists in either store. The "Generate Sample Core Data" button populates the **Core Data** store so you can test the migration.

---

## 📂 Project Structure

```
CoreDataToSwiftDataMigration/
│
├── 📱 App/
│   └── CoreDataToSwiftDataMigrationApp.swift   # @main, ModelContainer setup
│
├── 🗄️ CoreData/                                 # Legacy persistence layer
│   ├── CoreDataStack.swift                      # NSPersistentContainer singleton
│   ├── EmployeeManagement.xcdatamodeld/         # Core Data XML model
│   └── Models/
│       ├── DepartmentCD+Extensions.swift        # NSManagedObject + @NSManaged
│       ├── EmployeeCD+Extensions.swift
│       ├── ProjectCD+Extensions.swift
│       └── AddressCD+Extensions.swift
│
├── 📦 SwiftData/                                # Modern persistence layer
│   ├── Models/
│   │   ├── Department.swift                     # @Model · 1:N cascade
│   │   ├── Employee.swift                       # @Model · @Attribute(originalName:)
│   │   ├── Project.swift                        # @Model · M:N
│   │   └── Address.swift                        # @Model · 1:1
│   └── Schema/
│       ├── SchemaV1.swift                       # VersionedSchema 1.0.0
│       ├── SchemaV2.swift                       # VersionedSchema 2.0.0
│       └── MigrationPlan.swift                  # SchemaMigrationPlan
│
├── 🔀 Migration/
│   └── CoreDataToSwiftDataMigrator.swift        # DTO pattern · @Observable
│
├── 🎨 Views/
│   ├── ContentView.swift                        # TabView shell
│   ├── DepartmentListView.swift                 # @Query · CRUD · swipe-to-delete
│   ├── EmployeeListView.swift                   # Filtered list · search
│   ├── EmployeeDetailView.swift                 # @Bindable · relationships
│   └── MigrationStatusView.swift               # Progress · stats · controls
│
├── 🧪 Utilities/
│   └── SampleDataGenerator.swift               # Seed Core Data for testing
│
├── Article/
│   ├── Article.md                              # LinkedIn article (Part 1)
│   └── ProjectWalkthrough.md                   # Deep-dive article (Part 2)
│
└── project.yml                                  # XcodeGen spec
```

---

## 🔄 Schema Versioning

One of the most powerful features demonstrated in this project is **how to manage schema changes after migrating to SwiftData**.

### Schema History

| Version | Changes | Migration Type |
|---------|---------|---------------|
| **V1** | Initial schema — matches Core Data exactly | — |
| **V2** | Renamed `email` → `emailAddress` · Added `phoneNumber: String?` | Custom |

### How It Works

```swift
// 1. Define a snapshot for each schema version
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    // @Model classes with 'email' field
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    // References current top-level @Model classes
}

// 2. Create a migration plan
enum EmployeeManagementMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]          // Order matters!
    }
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
}

// 3. SwiftData runs this automatically on next app launch
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self,
    willMigrate: nil,
    didMigrate: { context in
        // Set defaults for new 'phoneNumber' field
        let employees = try context.fetch(FetchDescriptor<Employee>())
        for employee in employees where employee.phoneNumber == nil {
            employee.phoneNumber = "000-000-0000"
        }
        try context.save()
    }
)
```

### Adding a Future V3

When your next release needs schema changes, simply:

1. Create `SchemaV3.swift` conforming to `VersionedSchema`
2. Add a `migrateV2toV3` stage
3. Append both to `MigrationPlan.swift`

SwiftData **automatically chains**: users on V1 migrate V1→V2→V3 in one app launch.

---

## 🔀 Migration Deep Dive

### The DTO Pattern (Thread Safety)

The migrator uses a **Data Transfer Object** pattern to safely move data between the Core Data queue and SwiftData's `@MainActor` context:

```
Core Data Queue          │  Thread Boundary  │  @MainActor
─────────────────────    │                   │  ────────────────────
NSManagedObject          │                   │  @Model objects
(not Sendable)           │    ─────────►     │  (main thread only)
                         │    DTOs           │
                         │   (Structs ✅)    │
```

### Migration State Machine

```
[notStarted] ──► [inProgress: 0%]
                      │
                      ├──► [inProgress: 55%] — Departments
                      ├──► [inProgress: 65%] — Projects
                      ├──► [inProgress: 75%] — Employees & Addresses
                      ├──► [inProgress: 90%] — Saving
                      │
                      ├── success ──► [completed(stats)]
                      └── failure ──► [failed(error)] ──► resetMigration() ──► [notStarted]
```

---

## 🧠 Key Concepts

### Relationship Mapping

| Type | Core Data | SwiftData | Example |
|------|-----------|-----------|---------|
| **1:1** | `@NSManaged var address: AddressCD?` | `@Relationship(deleteRule: .cascade, inverse: \Address.employee) var address: Address?` | Employee ↔ Address |
| **1:N** | `@NSManaged var employees: NSSet?` | `@Relationship(deleteRule: .cascade, inverse: \Employee.department) var employees: [Employee]?` | Department → Employees |
| **M:N** | `@NSManaged var projects: NSSet?` | `@Relationship(inverse: \Project.employees) var projects: [Project]?` | Employee ↔ Projects |

### Fetching: Before vs After

```swift
// ❌ Core Data — verbose, stringly-typed
let request = NSFetchRequest<DepartmentCD>(entityName: "DepartmentCD")
request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
let departments = try context.fetch(request)

// ✅ SwiftData — declarative, type-safe
@Query(sort: \Department.name) private var departments: [Department]
```

### Field Rename Without Data Loss

```swift
// The old field was "email" in Core Data / SchemaV1
// SwiftData handles the column rename automatically
@Attribute(originalName: "email")
var emailAddress: String
```

---

## 📊 Sample Data

The `SampleDataGenerator` creates a realistic dataset in Core Data for testing:

| Entity | Count | Notes |
|--------|-------|-------|
| Departments | 4 | Engineering, Marketing, Sales, HR |
| Employees | 15 | Distributed across departments, real names |
| Addresses | 15 | 1-per-employee, SF Bay Area locations |
| Projects | 5 | Mix of completed and active |
| Assignments | ~18 | M:N links between employees and projects |

---

## 📖 Articles

This project is accompanied by two in-depth articles:

| Article | Description |
|---------|-------------|
| [Part 1 — The Migration Guide](Article/Article.md) | Why migrate, SwiftData vs Core Data comparison, HLD/SLD diagrams, step-by-step migration strategy |
| [Part 2 — Project Deep Dive](Article/ProjectWalkthrough.md) | Architecture walkthrough, sequence diagrams for all 4 timelines, state machine, before/after code comparisons |

---

## 🤝 Contributing

Contributions are welcome! If you find a bug or want to add a concept:

1. Fork the repository
2. Create your branch: `git checkout -b feature/add-cloudkit-sync`
3. Commit your changes: `git commit -m 'Add CloudKit sync example'`
4. Push to the branch: `git push origin feature/add-cloudkit-sync`
5. Open a Pull Request

Please open an **Issue** first to discuss major changes.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Amit Mishra**

- LinkedIn: [Connect with me](https://linkedin.com/in/YOUR_PROFILE)
- GitHub: [@YOUR_USERNAME](https://github.com/YOUR_USERNAME)

---

<div align="center">

⭐ **If this project helped you, please consider giving it a star!** ⭐

*Built with ❤️ using Swift, SwiftData, and Core Data*

</div>
