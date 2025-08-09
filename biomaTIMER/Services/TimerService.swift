import Foundation
import Combine
import CoreData

class TimerService: ObservableObject {
    @Published var timerState = TimerState()
    @Published var projectTimers: [ProjectTimer] = []
    @Published var projects: [ProjectData] = []
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext
    private let backgroundService = BackgroundTaskService.shared
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadProjects()
        createLunchTimerIfNeeded()
    }
    
    func startWorkTimer() {
        guard !timerState.isRunning else { return }
        
        // Stop lunch timer if it's running (mutual exclusivity)
        stopLunchTimerIfRunning()
        
        timerState.isRunning = true
        timerState.startTime = Date()
        
        createTimeEntry(isWorkTime: true)
        startUITimer()
        updateLiveActivity()
    }
    
    func stopWorkTimer() {
        timerState.isRunning = false
        stopAllProjectTimers()
        stopUITimer()
        
        // End any open project entries first, then the work entry.
        endOpenProjectEntries()
        endOpenWorkEntries()
        backgroundService.endLiveActivity()
    }
    
    func resetWorkTimer() {
        stopWorkTimer()
        timerState.totalSeconds = 0
    }
    
    func startProject(_ projectId: UUID) {
        // Check if this is the lunch timer
        let isLunchTimer = isProjectLunchTimer(projectId)
        
        if isLunchTimer {
            // For lunch timer: stop work timer if running (mutual exclusivity)
            if timerState.isRunning {
                timerState.isRunning = false
                stopUITimer()
                endOpenWorkEntries()
            }
        } else {
            // For regular projects: start work timer if not running
            if !timerState.isRunning {
                startWorkTimer()
            }
        }
        
        // Stop other projects and close any open project entries before starting a new one.
        stopAllProjectTimers()
        endOpenProjectEntries()
        
        if let index = projectTimers.firstIndex(where: { $0.projectId == projectId }) {
            projectTimers[index].isRunning = true
            projectTimers[index].startTime = Date()
        } else {
            let newTimer = ProjectTimer(projectId: projectId, isRunning: true, startTime: Date())
            projectTimers.append(newTimer)
        }
        
        timerState.activeProject = projectId
        createTimeEntry(isWorkTime: false, projectId: projectId)
        
        // Start UI timer for lunch timer since work timer won't be running
        if isLunchTimer {
            startUITimer()
        }
        
        updateLiveActivity()
    }
    
    func stopProject(_ projectId: UUID) {
        if let index = projectTimers.firstIndex(where: { $0.projectId == projectId }) {
            projectTimers[index].isRunning = false
        }
        
        if timerState.activeProject == projectId {
            timerState.activeProject = nil
        }
        
        // If this is the lunch timer and work timer isn't running, stop UI timer
        if isProjectLunchTimer(projectId) && !timerState.isRunning {
            stopUITimer()
        }
        
        // Only end the open project entry for this project.
        endOpenProjectEntries(projectId: projectId)
        updateLiveActivity()
    }
    
    private func stopAllProjectTimers() {
        for index in projectTimers.indices {
            projectTimers[index].isRunning = false
        }
        timerState.activeProject = nil
        // Do not end work entries here; only close project entries when switching.
    }
    
    private func startUITimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimers()
        }
        
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopUITimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimers() {
        let now = Date()
        
        // Update work timer if running
        if timerState.isRunning, let startTime = timerState.startTime {
            timerState.totalSeconds = now.timeIntervalSince(startTime)
        }
        
        // Update all project timers (including lunch timer)
        for index in projectTimers.indices {
            if projectTimers[index].isRunning, let projectStartTime = projectTimers[index].startTime {
                projectTimers[index].totalSeconds = now.timeIntervalSince(projectStartTime)
            }
        }
        updateLiveActivity()
    }
    
    func getDailyTotal() -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        // Only include main work time entries to avoid double-counting project time.
        request.predicate = NSPredicate(format: "isWorkTime == YES AND startTime >= %@ AND startTime < %@", today as NSDate, tomorrow as NSDate)
        
        do {
            let entries = try context.fetch(request)
            let completedTime = entries.reduce(into: 0) { total, entry in
                if let startTime = entry.startTime, let endTime = entry.endTime {
                    total += endTime.timeIntervalSince(startTime)
                }
            }
            
            // Add current session time for today only, if timer is running.
            let currentSession = clampedCurrentWorkSessionSince(today: today)
            return completedTime + currentSession
        } catch {
            print("Error fetching daily total: \(error)")
            return clampedCurrentWorkSessionSince(today: today)
        }
    }
    
    private func clampedCurrentWorkSessionSince(today: Date) -> TimeInterval {
        guard timerState.isRunning, let startTime = timerState.startTime else { return 0 }
        let start = max(startTime, today)
        return Date().timeIntervalSince(start)
    }
    
    func getCurrentSessionTime() -> TimeInterval {
        guard timerState.isRunning, let startTime = timerState.startTime else {
            return 0
        }
        return Date().timeIntervalSince(startTime)
    }
    
    func getProjectDailyTotal(_ projectId: UUID) -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@ AND project.id == %@", 
                                       today as NSDate, tomorrow as NSDate, projectId as NSUUID)
        
        do {
            let entries = try context.fetch(request)
            let completedTime = entries.reduce(into: 0) { total, entry in
                if let startTime = entry.startTime, let endTime = entry.endTime {
                    total += endTime.timeIntervalSince(startTime)
                }
            }
            
            // Add today's portion of the current project session, if running.
            if let projectTimer = projectTimers.first(where: { $0.projectId == projectId }),
               projectTimer.isRunning, let startTime = projectTimer.startTime {
                let start = max(startTime, today)
                let currentSession = Date().timeIntervalSince(start)
                return completedTime + currentSession
            }
            
            return completedTime
        } catch {
            print("Error fetching project daily total: \(error)")
            return 0
        }
    }
    
    func getCurrentProjectSessionTime(_ projectId: UUID) -> TimeInterval {
        guard let projectTimer = projectTimers.first(where: { $0.projectId == projectId }),
              projectTimer.isRunning, let startTime = projectTimer.startTime else {
            return 0
        }
        return Date().timeIntervalSince(startTime)
    }
    
    private func createTimeEntry(isWorkTime: Bool, projectId: UUID? = nil) {
        let entry = TimeEntry(context: context)
        entry.id = UUID()
        entry.startTime = Date()
        entry.isWorkTime = isWorkTime
        
        if let projectId = projectId {
            let request: NSFetchRequest<Project> = Project.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", projectId as CVarArg)
            
            if let project = try? context.fetch(request).first {
                entry.project = project
            }
        }
        
        do { try context.save() } catch { print("Failed to save new time entry: \(error)") }
    }
    
    // End only the open work entry (if any).
    private func endOpenWorkEntries() {
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        request.predicate = NSPredicate(format: "endTime == nil AND isWorkTime == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeEntry.startTime, ascending: false)]
        
        if let entries = try? context.fetch(request) {
            for entry in entries { entry.endTime = Date() }
            do { try context.save() } catch { print("Failed to end work entries: \(error)") }
        }
    }
    
    // End open project entries, optionally scoped to a specific project.
    private func endOpenProjectEntries(projectId: UUID? = nil) {
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        if let pid = projectId {
            request.predicate = NSPredicate(format: "endTime == nil AND isWorkTime == NO AND project.id == %@", pid as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "endTime == nil AND isWorkTime == NO")
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeEntry.startTime, ascending: false)]
        
        if let entries = try? context.fetch(request) {
            for entry in entries { entry.endTime = Date() }
            do { try context.save() } catch { print("Failed to end project entries: \(error)") }
        }
    }
    
    func addProject(name: String, colorHex: String = "#007AFF") {
        let project = Project(context: context)
        project.id = UUID()
        project.name = name
        project.colorHex = colorHex
        project.createdAt = Date()
        project.isLunchTimer = false // Regular projects are never lunch timers
        
        do { try context.save() } catch { print("Failed to save project: \(error)") }
        loadProjects()
    }
    
    func deleteProject(_ projectId: UUID) {
        // Prevent deletion of the lunch timer
        if isProjectLunchTimer(projectId) {
            print("Cannot delete lunch timer")
            return
        }
        
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", projectId as CVarArg)
        
        if let project = try? context.fetch(request).first {
            context.delete(project)
            do { try context.save() } catch { print("Failed to delete project: \(error)") }
            loadProjects()
            
            projectTimers.removeAll { $0.projectId == projectId }
            if timerState.activeProject == projectId {
                timerState.activeProject = nil
            }
        }
    }
    
    private func loadProjects() {
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Project.createdAt, ascending: true)]
        
        if let coreDataProjects = try? context.fetch(request) {
            projects = coreDataProjects.compactMap { project in
                guard let id = project.id,
                      let name = project.name,
                      let createdAt = project.createdAt else { return nil }
                
                let projectData = ProjectData(
                    id: id,
                    name: name,
                    colorHex: project.colorHex ?? "#007AFF",
                    createdAt: createdAt,
                    isLunchTimer: project.isLunchTimer
                )
                return projectData
            }
            
            // Sort projects to show lunch timer first, then by creation date
            projects.sort { first, second in
                if first.isLunchTimer && !second.isLunchTimer {
                    return true
                } else if !first.isLunchTimer && second.isLunchTimer {
                    return false
                } else {
                    return first.createdAt < second.createdAt
                }
            }
        }
    }
    
    private func createLunchTimerIfNeeded() {
        // Check if lunch timer already exists
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        request.predicate = NSPredicate(format: "isLunchTimer == YES")
        
        if let existingLunchProjects = try? context.fetch(request), existingLunchProjects.isEmpty {
            // Create the lunch timer project
            let lunchProject = Project(context: context)
            lunchProject.id = UUID()
            lunchProject.name = "Lunch"
            lunchProject.colorHex = "#FF0000" // Red color
            lunchProject.createdAt = Date()
            lunchProject.isLunchTimer = true
            
            do {
                try context.save()
                loadProjects() // Reload to update the UI
            } catch {
                print("Failed to create lunch timer: \(error)")
            }
        }
    }
    
    private func isProjectLunchTimer(_ projectId: UUID) -> Bool {
        return projects.first(where: { $0.id == projectId })?.isLunchTimer ?? false
    }
    
    private func stopLunchTimerIfRunning() {
        if let lunchProject = projects.first(where: { $0.isLunchTimer }),
           let lunchTimer = projectTimers.first(where: { $0.projectId == lunchProject.id }),
           lunchTimer.isRunning {
            stopProject(lunchProject.id)
        }
    }
    
    func getTodayWorkTime() -> TimeInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        request.predicate = NSPredicate(format: "isWorkTime == YES AND startTime >= %@ AND startTime < %@ AND endTime != nil", startOfDay as NSDate, endOfDay as NSDate)
        
        if let entries = try? context.fetch(request) {
            return entries.reduce(0) { total, entry in
                guard let start = entry.startTime, let end = entry.endTime else { return total }
                return total + end.timeIntervalSince(start)
            }
        }
        
        return 0
    }
    
    func getTodayProjectTime(_ projectId: UUID) -> TimeInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        request.predicate = NSPredicate(format: "project.id == %@ AND startTime >= %@ AND startTime < %@ AND endTime != nil", projectId as CVarArg, startOfDay as NSDate, endOfDay as NSDate)
        
        if let entries = try? context.fetch(request) {
            return entries.reduce(0) { total, entry in
                guard let start = entry.startTime, let end = entry.endTime else { return total }
                return total + end.timeIntervalSince(start)
            }
        }
        
        return 0
    }
    
    private func updateLiveActivity() {
        var activeProjectName: String?
        var activeProjectColor: String?
        
        if let activeProjectId = timerState.activeProject,
           let project = projects.first(where: { $0.id == activeProjectId }) {
            activeProjectName = project.name
            activeProjectColor = project.colorHex
        }
        
        if timerState.isRunning {
            backgroundService.startLiveActivity(
                timerState: timerState,
                activeProjectName: activeProjectName,
                activeProjectColor: activeProjectColor,
                currentSessionTime: getCurrentSessionTime(),
                dailyTotalTime: getDailyTotal()
            )
        } else {
            backgroundService.endLiveActivity()
        }
    }
}