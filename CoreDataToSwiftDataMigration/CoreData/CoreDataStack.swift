import Foundation
import CoreData

/// Singleton class for managing the Core Data stack.
public class CoreDataStack {
    
    // MARK: - Shared Instance
    
    /// The singleton instance of the Core Data stack.
    public static let shared = CoreDataStack()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    /// The persistent container for the application. This implementation
    /// creates and returns a container, having loaded the store for the
    /// application to it.
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "EmployeeManagement")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        // Automatically merge changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    /// The main view context associated with the main queue.
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Saving support
    
    /// Saves the main view context if there are any pending changes.
    public func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Performs a fetch request and returns the results.
    public func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    /// Deletes a specific managed object.
    public func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        saveContext()
    }
    
    /// Clears all data for a specific entity name.
    public func clearData(for entityName: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(batchDeleteRequest)
            saveContext()
        } catch {
            print("Batch delete error: \(error)")
        }
    }
}
