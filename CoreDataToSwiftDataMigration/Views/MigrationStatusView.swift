import SwiftUI
import SwiftData

// MARK: - MigrationStatusView

/// A view that manages and displays the Core Data to SwiftData migration process.
///
/// This view provides:
/// - A visual status indicator for the migration state
/// - Controls to generate sample Core Data, start migration, and reset
/// - A progress bar with current entity information during migration
/// - Migration statistics after completion
/// - Error display with retry capability on failure
struct MigrationStatusView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var migrator: CoreDataToSwiftDataMigrator?
    
    var body: some View {
        List {
            // MARK: - Status Display
            Section {
                VStack(spacing: 20) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(statusColor)
                        .symbolEffect(.pulse, isActive: currentMigrator?.state.isInProgress ?? false)
                    
                    Text(statusText)
                        .font(.title2.bold())
                    
                    // Progress bar during migration
                    if let migrator = migrator, case let .inProgress(progress, currentEntity) = migrator.state {
                        VStack(spacing: 8) {
                            ProgressView(value: progress, total: 1.0)
                                .progressViewStyle(.linear)
                                .tint(.orange)
                            
                            Text("Migrating: \(currentEntity)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            // MARK: - Migration Statistics
            if let migrator = migrator, case let .completed(stats) = migrator.state {
                Section("Migration Results") {
                    LabeledContent("Departments", value: "\(stats.departmentsMigrated)")
                    LabeledContent("Employees", value: "\(stats.employeesMigrated)")
                    LabeledContent("Projects", value: "\(stats.projectsMigrated)")
                    LabeledContent("Addresses", value: "\(stats.addressesMigrated)")
                    LabeledContent("Duration", value: String(format: "%.2f seconds", stats.duration))
                }
            }
            
            // MARK: - Error Display
            if let migrator = migrator, case let .failed(errorMessage) = migrator.state {
                Section("Error Details") {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            // MARK: - Actions
            Section("Actions") {
                // Generate sample Core Data
                Button {
                    SampleDataGenerator.generateSampleData(in: CoreDataStack.shared.viewContext)
                } label: {
                    Label("Generate Sample Core Data", systemImage: "plus.circle.fill")
                }
                .disabled(currentMigrator?.state.isInProgress ?? false)
                
                // Start Migration
                Button {
                    Task {
                        let m = ensureMigrator()
                        try? await m.migrate()
                    }
                } label: {
                    Label("Start Migration", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(currentMigrator?.state.isInProgress ?? false)
                
                // Reset Migration
                Button(role: .destructive) {
                    ensureMigrator().resetMigration()
                } label: {
                    Label("Reset Migration", systemImage: "arrow.counterclockwise")
                }
                .disabled(currentMigrator?.state.isInProgress ?? false)
            }
        }
        .navigationTitle("Migration")
    }
    
    // MARK: - Helpers
    
    /// Returns the current migrator, or nil if not yet created.
    private var currentMigrator: CoreDataToSwiftDataMigrator? {
        migrator
    }
    
    /// Ensures a migrator instance exists, creating one if needed.
    @discardableResult
    private func ensureMigrator() -> CoreDataToSwiftDataMigrator {
        if let existing = migrator {
            return existing
        }
        let newMigrator = CoreDataToSwiftDataMigrator(
            coreDataStack: CoreDataStack.shared,
            modelContext: modelContext
        )
        migrator = newMigrator
        return newMigrator
    }
    
    // MARK: - Status Properties
    
    private var statusIcon: String {
        guard let migrator = migrator else { return "tray.and.arrow.down" }
        switch migrator.state {
        case .notStarted:
            return "tray.and.arrow.down"
        case .inProgress:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.seal.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        guard let migrator = migrator else { return .blue }
        switch migrator.state {
        case .notStarted:
            return .blue
        case .inProgress:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var statusText: String {
        guard let migrator = migrator else { return "Ready to Migrate" }
        switch migrator.state {
        case .notStarted:
            return "Ready to Migrate"
        case .inProgress:
            return "Migrating Data..."
        case .completed:
            return "Migration Complete ✅"
        case .failed:
            return "Migration Failed ❌"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MigrationStatusView()
    }
    .modelContainer(for: [Department.self, Employee.self, Project.self, Address.self])
}
