import SwiftUI
import CoreData

struct SettingsView: View {
    @EnvironmentObject var timerService: TimerService
    @Environment(\.managedObjectContext) private var context
    @State private var showingExportSheet = false
    @State private var showingResetAlert = false
    @State private var showingDeleteProjectAlert = false
    @State private var projectToDelete: ProjectData?
    
    var body: some View {
        NavigationView {
            List {
                Section("Data Export") {
                    Button(action: { showingExportSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export to CSV")
                        }
                    }
                }
                
                Section("Data Management") {
                    Button(action: { showingResetAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset All Data")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("Projects") {
                    ForEach(timerService.projects) { project in
                        HStack {
                            Circle()
                                .fill(project.color)
                                .frame(width: 12, height: 12)
                            
                            Text(project.name)
                            
                            Spacer()
                            
                            // Don't show delete button for lunch timer
                            if !project.isLunchTimer {
                                Button(action: {
                                    projectToDelete = project
                                    showingDeleteProjectAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all timer data and projects. This action cannot be undone.")
        }
        .alert("Delete Project", isPresented: $showingDeleteProjectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let project = projectToDelete {
                    timerService.deleteProject(project.id)
                    projectToDelete = nil
                }
            }
        } message: {
            if let project = projectToDelete {
                Text("Are you sure you want to delete '\(project.name)'? This will also delete all associated time entries.")
            }
        }
    }
    
    private func resetAllData() {
        let projectRequest: NSFetchRequest<NSFetchRequestResult> = Project.fetchRequest()
        let timeEntryRequest: NSFetchRequest<NSFetchRequestResult> = TimeEntry.fetchRequest()
        
        let deleteProjects = NSBatchDeleteRequest(fetchRequest: projectRequest)
        let deleteTimeEntries = NSBatchDeleteRequest(fetchRequest: timeEntryRequest)
        
        do {
            try context.execute(deleteTimeEntries)
            try context.execute(deleteProjects)
            try context.save()
        } catch {
            print("Failed to reset data: \(error)")
        }
        
        // Clear service state and refresh
        timerService.timerState = TimerState()
        timerService.projectTimers.removeAll()
        timerService.projects.removeAll()
        // Reload from Core Data (should be empty now)
        // Using an internal method would be better; here we nudge via public surface
        // by calling add/remove no-ops would be awkward; instead rely on a small delay.
        DispatchQueue.main.async {
            // Trigger a refresh
            // The service will reload projects on next app launch; do a manual pull:
            // There's no public reload, so we can start/stop timer to ensure live activity ends.
            timerService.resetWorkTimer()
        }
    }
}

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @State private var exportData: String = ""
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export your timer data as CSV")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Button("Generate CSV") {
                    generateCSV()
                    showingShareSheet = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [exportData])
        }
    }
    
    private func generateCSV() {
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeEntry.startTime, ascending: true)]
        
        guard let entries = try? context.fetch(request) else {
            exportData = "No data to export"
            return
        }
        
        var csv = "Date,Start Time,End Time,Duration (minutes),Project,Type\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .medium
        
        for entry in entries {
            guard let startTime = entry.startTime else { continue }
            
            let date = formatter.string(from: startTime)
            let start = timeFormatter.string(from: startTime)
            let end = entry.endTime != nil ? timeFormatter.string(from: entry.endTime!) : "Running"
            let duration = entry.endTime != nil ? String(format: "%.1f", entry.endTime!.timeIntervalSince(startTime) / 60) : "0"
            let project = entry.project?.name ?? ""
            let type = entry.isWorkTime ? "Work" : "Project"
            
            csv += "\(date),\(start),\(end),\(duration),\(project),\(type)\n"
        }
        
        exportData = csv
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environmentObject(TimerService(context: PersistenceController.preview.container.viewContext))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}