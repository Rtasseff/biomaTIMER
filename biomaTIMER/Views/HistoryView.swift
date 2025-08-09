import SwiftUI
import CoreData

struct HistoryView: View {
    @EnvironmentObject var timerService: TimerService
    @Environment(\.managedObjectContext) private var context
    @State private var selectedPeriod: TimePeriod = .day
    
    enum TimePeriod: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Picker("Time Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 20) {
                        workTimeSummary
                        
                        if !timerService.projects.isEmpty {
                            projectTimeSummary
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var workTimeSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Work Time")
                .font(.headline)
            
            HStack {
                Text("Total:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(getWorkTime().formattedDuration())
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var projectTimeSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Breakdown")
                .font(.headline)
            
            ForEach(timerService.projects) { project in
                let projectTime = getProjectTime(project.id)
                let workTime = getWorkTime()
                let percentage = workTime > 0 ? (projectTime / workTime) * 100 : 0
                
                HStack {
                    Circle()
                        .fill(project.color)
                        .frame(width: 10, height: 10)
                    
                    Text(project.name)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(projectTime.formattedDuration())
                            .font(.system(.body, design: .monospaced))
                        
                        Text(String(format: "%.1f%%", percentage))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func getWorkTime() -> TimeInterval {
        let (startDate, endDate) = getDateRange()
        
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "isWorkTime == YES AND startTime >= %@ AND startTime < %@ AND endTime != nil",
            startDate as NSDate,
            endDate as NSDate
        )
        
        guard let entries = try? context.fetch(request) else { return 0 }
        
        return entries.reduce(0) { total, entry in
            guard let start = entry.startTime, let end = entry.endTime else { return total }
            return total + end.timeIntervalSince(start)
        }
    }
    
    private func getProjectTime(_ projectId: UUID) -> TimeInterval {
        let (startDate, endDate) = getDateRange()
        
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "project.id == %@ AND startTime >= %@ AND startTime < %@ AND endTime != nil",
            projectId as CVarArg,
            startDate as NSDate,
            endDate as NSDate
        )
        
        guard let entries = try? context.fetch(request) else { return 0 }
        
        return entries.reduce(0) { total, entry in
            guard let start = entry.startTime, let end = entry.endTime else { return total }
            return total + end.timeIntervalSince(start)
        }
    }
    
    private func getDateRange() -> (Date, Date) {
        let now = Date()
        switch selectedPeriod {
        case .day:
            return (now.startOfDay(), now.endOfDay())
        case .week:
            return (now.startOfWeek(), now.endOfWeek())
        case .month:
            return (now.startOfMonth(), now.endOfMonth())
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(TimerService(context: PersistenceController.preview.container.viewContext))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}