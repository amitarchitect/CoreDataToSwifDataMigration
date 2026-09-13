import Foundation
import CoreData

// MARK: - SampleDataGenerator

/// Utility class for generating realistic sample data in Core Data
/// to test the migration process to SwiftData.
///
/// Creates departments, employees with addresses, and projects
/// with many-to-many relationships between employees and projects.
class SampleDataGenerator {
    
    /// Generates a complete set of sample data in the provided Core Data context.
    ///
    /// Creates:
    /// - 4 departments (Engineering, Marketing, Sales, Human Resources)
    /// - 15 employees across all departments
    /// - 5 projects with employee assignments (M:N)
    /// - 1 address per employee (1:1)
    ///
    /// - Parameter context: The NSManagedObjectContext to insert objects into.
    static func generateSampleData(in context: NSManagedObjectContext) {
        
        // MARK: - Departments
        
        let departmentData: [(name: String, budget: Double)] = [
            ("Engineering", 1_500_000.0),
            ("Marketing", 500_000.0),
            ("Sales", 800_000.0),
            ("Human Resources", 300_000.0)
        ]
        
        var deptObjects: [NSManagedObject] = []
        
        for dept in departmentData {
            let deptObj = NSEntityDescription.insertNewObject(forEntityName: "DepartmentCD", into: context)
            deptObj.setValue(UUID(), forKey: "id")
            deptObj.setValue(dept.name, forKey: "name")
            deptObj.setValue(dept.budget, forKey: "budget")
            deptObjects.append(deptObj)
        }
        
        // MARK: - Employees & Addresses
        
        let employeeData: [(first: String, last: String, email: String, salary: Double, deptIndex: Int)] = [
            ("Alice", "Johnson", "alice.johnson@company.com", 125_000, 0),
            ("Bob", "Smith", "bob.smith@company.com", 115_000, 0),
            ("Carol", "Williams", "carol.williams@company.com", 130_000, 0),
            ("David", "Brown", "david.brown@company.com", 118_000, 0),
            ("Emma", "Davis", "emma.davis@company.com", 95_000, 1),
            ("Frank", "Miller", "frank.miller@company.com", 88_000, 1),
            ("Grace", "Wilson", "grace.wilson@company.com", 92_000, 1),
            ("Henry", "Moore", "henry.moore@company.com", 105_000, 2),
            ("Irene", "Taylor", "irene.taylor@company.com", 98_000, 2),
            ("Jack", "Anderson", "jack.anderson@company.com", 102_000, 2),
            ("Karen", "Thomas", "karen.thomas@company.com", 110_000, 2),
            ("Leo", "Jackson", "leo.jackson@company.com", 85_000, 3),
            ("Mia", "White", "mia.white@company.com", 82_000, 3),
            ("Noah", "Harris", "noah.harris@company.com", 90_000, 0),
            ("Olivia", "Martin", "olivia.martin@company.com", 78_000, 1)
        ]
        
        let addressData: [(street: String, city: String, state: String, zip: String, country: String)] = [
            ("123 Oak Street", "San Francisco", "CA", "94102", "USA"),
            ("456 Elm Avenue", "San Jose", "CA", "95110", "USA"),
            ("789 Pine Road", "Palo Alto", "CA", "94301", "USA"),
            ("101 Maple Drive", "Mountain View", "CA", "94040", "USA"),
            ("202 Cedar Lane", "Cupertino", "CA", "95014", "USA"),
            ("303 Birch Court", "Sunnyvale", "CA", "94085", "USA"),
            ("404 Walnut Way", "Santa Clara", "CA", "95050", "USA"),
            ("505 Spruce Street", "Redwood City", "CA", "94061", "USA"),
            ("606 Ash Boulevard", "Menlo Park", "CA", "94025", "USA"),
            ("707 Willow Place", "Foster City", "CA", "94404", "USA"),
            ("808 Poplar Terrace", "San Mateo", "CA", "94401", "USA"),
            ("909 Cherry Circle", "Fremont", "CA", "94536", "USA"),
            ("111 Magnolia Way", "Oakland", "CA", "94607", "USA"),
            ("222 Sequoia Drive", "Berkeley", "CA", "94704", "USA"),
            ("333 Redwood Lane", "Hayward", "CA", "94541", "USA")
        ]
        
        var empObjects: [NSManagedObject] = []
        
        for (index, emp) in employeeData.enumerated() {
            // Create employee
            let empObj = NSEntityDescription.insertNewObject(forEntityName: "EmployeeCD", into: context)
            empObj.setValue(UUID(), forKey: "id")
            empObj.setValue(emp.first, forKey: "firstName")
            empObj.setValue(emp.last, forKey: "lastName")
            empObj.setValue(emp.email, forKey: "email")
            empObj.setValue(Date().addingTimeInterval(-Double.random(in: 86400...31536000)), forKey: "hireDate")
            empObj.setValue(emp.salary, forKey: "salary")
            
            // Assign to department (1:N)
            empObj.setValue(deptObjects[emp.deptIndex], forKey: "department")
            
            // Create and link address (1:1)
            let addr = addressData[index]
            let addrObj = NSEntityDescription.insertNewObject(forEntityName: "AddressCD", into: context)
            addrObj.setValue(UUID(), forKey: "id")
            addrObj.setValue(addr.street, forKey: "street")
            addrObj.setValue(addr.city, forKey: "city")
            addrObj.setValue(addr.state, forKey: "state")
            addrObj.setValue(addr.zip, forKey: "zipCode")
            addrObj.setValue(addr.country, forKey: "country")
            
            empObj.setValue(addrObj, forKey: "address")
            addrObj.setValue(empObj, forKey: "employee")
            
            empObjects.append(empObj)
        }
        
        // MARK: - Projects
        
        let projectData: [(name: String, isCompleted: Bool)] = [
            ("iOS App Redesign", false),
            ("Cloud Migration", false),
            ("Q4 Marketing Campaign", true),
            ("Employee Portal", false),
            ("Data Analytics Dashboard", true)
        ]
        
        var projObjects: [NSManagedObject] = []
        
        for proj in projectData {
            let projObj = NSEntityDescription.insertNewObject(forEntityName: "ProjectCD", into: context)
            projObj.setValue(UUID(), forKey: "id")
            projObj.setValue(proj.name, forKey: "name")
            projObj.setValue(Date().addingTimeInterval(-Double.random(in: 86400...15768000)), forKey: "startDate")
            projObj.setValue(proj.isCompleted ? nil : Date().addingTimeInterval(Double.random(in: 2592000...15768000)), forKey: "deadline")
            projObj.setValue(proj.isCompleted, forKey: "isCompleted")
            projObjects.append(projObj)
        }
        
        // MARK: - Project Assignments (M:N)
        
        // Assign employees to projects to demonstrate many-to-many relationships
        let assignments: [(empIndices: [Int], projIndex: Int)] = [
            ([0, 1, 2, 13], 0),     // iOS App Redesign: Engineering team
            ([0, 3, 7, 8], 1),       // Cloud Migration: Cross-functional
            ([4, 5, 6, 14], 2),      // Q4 Marketing Campaign: Marketing team
            ([11, 12, 9], 3),        // Employee Portal: HR + Sales
            ([2, 3, 10, 7], 4)       // Data Analytics Dashboard: Mixed
        ]
        
        for assignment in assignments {
            let projObj = projObjects[assignment.projIndex]
            let empSet = NSMutableSet()
            for empIndex in assignment.empIndices {
                empSet.add(empObjects[empIndex])
            }
            projObj.setValue(empSet, forKey: "employees")
            
            // Also set the inverse for each employee
            for empIndex in assignment.empIndices {
                let empObj = empObjects[empIndex]
                let existingProjects = (empObj.value(forKey: "projects") as? NSMutableSet) ?? NSMutableSet()
                existingProjects.add(projObj)
                empObj.setValue(existingProjects, forKey: "projects")
            }
        }
        
        // MARK: - Save
        
        do {
            try context.save()
            print("✅ Successfully generated sample Core Data with \(employeeData.count) employees, \(departmentData.count) departments, and \(projectData.count) projects.")
        } catch {
            print("❌ Failed to save sample data: \(error)")
        }
    }
}
