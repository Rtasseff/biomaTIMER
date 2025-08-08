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
    }
    
    func startWorkTimer() {
        guard !timerState.isRunning else { return }
        
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
        
        endCurrentTimeEntry()
        backgroundService.endLiveActivity()
    }
    
    func resetWorkTimer() {
        stopWorkTimer()
        timerState.totalSeconds = 0
    }
    
    func startProject(_ projectId: UUID) {
        if !timerState.isRunning {
            startWorkTimer()
        }
        
        stopAllProjectTimers()
        
        if let index = projectTimers.firstIndex(where: { $0.projectId == projectId }) {
            projectTimers[index].isRunning = true
            projectTimers[index].startTime = Date()
        } else {
            let newTimer = ProjectTimer(projectId: projectId, isRunning: true, startTime: Date())
            projectTimers.append(newTimer)
        }
        
        timerState.activeProject = projectId
        createTimeEntry(isWorkTime: false, projectId: projectId)
        updateLiveActivity()
    }
    
    func stopProject(_ projectId: UUID) {
        if let index = projectTimers.firstIndex(where: { $0.projectId == projectId }) {
            projectTimers[index].isRunning = false
        }
        
        if timerState.activeProject == projectId {
            timerState.activeProject = nil
        }
        
        endCurrentTimeEntry()
    }
    
    private func stopAllProjectTimers() {
        for index in projectTimers.indices {
            projectTimers[index].isRunning = false
        }
        timerState.activeProject = nil
        endCurrentTimeEntry()
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
        guard timerState.isRunning, let startTime = timerState.startTime else { return }
        
        let now = Date()
        timerState.totalSeconds = now.timeIntervalSince(startTime)
        
        for index in projectTimers.indices {
            if projectTimers[index].isRunning, let projectStartTime = projectTimers[index].startTime {
                projectTimers[index].totalSeconds = now.timeIntervalSince(projectStartTime)
            }
        }
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
        
        try? context.save()
    }
    
    private func endCurrentTimeEntry() {
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        request.predicate = NSPredicate(format: "endTime == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeEntry.startTime, ascending: false)]
        
        if let entries = try? context.fetch(request) {
            for entry in entries {
                entry.endTime = Date()
            }
            try? context.save()
        }
    }
    
    func addProject(name: String, colorHex: String = "#007AFF") {
        let project = Project(context: context)
        project.id = UUID()
        project.name = name
        project.colorHex = colorHex
        project.createdAt = Date()
        
        try? context.save()
        loadProjects()
    }
    
    func deleteProject(_ projectId: UUID) {
        let request: NSFetchRequest<Project> = Project.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", projectId as CVarArg)
        
        if let project = try? context.fetch(request).first {
            context.delete(project)
            try? context.save()
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
                    createdAt: createdAt
                )
                return projectData
            }
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
                activeProjectColor: activeProjectColor
            )
        } else {
            backgroundService.endLiveActivity()
        }
    }
}