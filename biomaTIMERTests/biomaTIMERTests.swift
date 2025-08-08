import XCTest
import CoreData
@testable import biomaTIMER

final class biomaTIMERTests: XCTestCase {
    var timerService: TimerService!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        let persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        timerService = TimerService(context: context)
    }
    
    override func tearDownWithError() throws {
        timerService = nil
        context = nil
    }
    
    func testTimerStateInitialization() throws {
        XCTAssertFalse(timerService.timerState.isRunning)
        XCTAssertNil(timerService.timerState.startTime)
        XCTAssertEqual(timerService.timerState.totalSeconds, 0)
        XCTAssertNil(timerService.timerState.activeProject)
    }
    
    func testWorkTimerStartStop() throws {
        timerService.startWorkTimer()
        
        XCTAssertTrue(timerService.timerState.isRunning)
        XCTAssertNotNil(timerService.timerState.startTime)
        
        timerService.stopWorkTimer()
        
        XCTAssertFalse(timerService.timerState.isRunning)
    }
    
    func testWorkTimerReset() throws {
        timerService.startWorkTimer()
        timerService.timerState.totalSeconds = 100
        
        timerService.resetWorkTimer()
        
        XCTAssertFalse(timerService.timerState.isRunning)
        XCTAssertEqual(timerService.timerState.totalSeconds, 0)
    }
    
    func testProjectCreation() throws {
        let projectName = "Test Project"
        let projectColor = "#FF0000"
        
        timerService.addProject(name: projectName, colorHex: projectColor)
        
        XCTAssertEqual(timerService.projects.count, 1)
        XCTAssertEqual(timerService.projects.first?.name, projectName)
    }
    
    func testProjectDeletion() throws {
        timerService.addProject(name: "Test Project")
        let projectId = timerService.projects.first!.id
        
        timerService.deleteProject(projectId)
        
        XCTAssertEqual(timerService.projects.count, 0)
    }
    
    func testProjectTimerStartStop() throws {
        timerService.addProject(name: "Test Project")
        let projectId = timerService.projects.first!.id
        
        timerService.startProject(projectId)
        
        XCTAssertTrue(timerService.timerState.isRunning)
        XCTAssertEqual(timerService.timerState.activeProject, projectId)
        
        let projectTimer = timerService.projectTimers.first { $0.projectId == projectId }
        XCTAssertNotNil(projectTimer)
        XCTAssertTrue(projectTimer!.isRunning)
        
        timerService.stopProject(projectId)
        
        let updatedProjectTimer = timerService.projectTimers.first { $0.projectId == projectId }
        XCTAssertFalse(updatedProjectTimer!.isRunning)
    }
    
    func testOnlyOneProjectTimerActive() throws {
        timerService.addProject(name: "Project 1")
        timerService.addProject(name: "Project 2")
        
        let project1Id = timerService.projects[0].id
        let project2Id = timerService.projects[1].id
        
        timerService.startProject(project1Id)
        timerService.startProject(project2Id)
        
        let project1Timer = timerService.projectTimers.first { $0.projectId == project1Id }
        let project2Timer = timerService.projectTimers.first { $0.projectId == project2Id }
        
        XCTAssertFalse(project1Timer?.isRunning ?? true)
        XCTAssertTrue(project2Timer?.isRunning ?? false)
        XCTAssertEqual(timerService.timerState.activeProject, project2Id)
    }
    
    func testTimeEntryCreation() throws {
        timerService.startWorkTimer()
        
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        let entries = try context.fetch(request)
        
        XCTAssertEqual(entries.count, 1)
        XCTAssertTrue(entries.first!.isWorkTime)
        XCTAssertNotNil(entries.first!.startTime)
        XCTAssertNil(entries.first!.endTime)
    }
    
    func testTimeEntryCompletion() throws {
        timerService.startWorkTimer()
        timerService.stopWorkTimer()
        
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        let entries = try context.fetch(request)
        
        XCTAssertEqual(entries.count, 1)
        XCTAssertNotNil(entries.first!.endTime)
    }
    
    func testDateExtensions() throws {
        let date = Date()
        
        XCTAssertNotNil(date.startOfDay())
        XCTAssertNotNil(date.endOfDay())
        XCTAssertNotNil(date.startOfWeek())
        XCTAssertNotNil(date.endOfWeek())
        XCTAssertNotNil(date.startOfMonth())
        XCTAssertNotNil(date.endOfMonth())
    }
    
    func testTimeIntervalFormatting() throws {
        let duration: TimeInterval = 3661 // 1 hour, 1 minute, 1 second
        let formatted = duration.formattedDuration()
        
        XCTAssertEqual(formatted, "1:01:01")
        
        let shortDuration: TimeInterval = 61 // 1 minute, 1 second
        let shortFormatted = shortDuration.formattedDuration()
        
        XCTAssertEqual(shortFormatted, "1:01")
    }
    
    func testColorHexConversion() throws {
        let blueColor = Color(hex: "#007AFF")
        let redColor = Color(hex: "#FF0000")
        
        XCTAssertNotNil(blueColor)
        XCTAssertNotNil(redColor)
    }
}