import SwiftUI

struct MainTimerView: View {
    @EnvironmentObject var timerService: TimerService
    @State private var showingProjectEditor = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Text("Work Timer")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("\(timerService.getCurrentSessionTime().formattedDuration()) (\(timerService.getDailyTotal().formattedDuration()))")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(timerService.timerState.isRunning ? .primary : .secondary)
                    
                    Button(action: {
                        if timerService.timerState.isRunning {
                            timerService.stopWorkTimer()
                        } else {
                            timerService.startWorkTimer()
                        }
                    }) {
                        HStack {
                            Image(systemName: timerService.timerState.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            Text(timerService.timerState.isRunning ? "Stop" : "Start")
                        }
                        .font(.title2)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                    }
                    .accessibilityIdentifier(timerService.timerState.isRunning ? "Stop" : "Start")
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Projects")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: { showingProjectEditor = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                    
                    if timerService.projects.isEmpty {
                        Text("No projects yet. Tap + to add one.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(timerService.projects) { project in
                                    ProjectRowView(project: project)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("biomaTIMER")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingProjectEditor) {
            ProjectEditorView()
        }
    }
}

struct ProjectRowView: View {
    let project: ProjectData
    @EnvironmentObject var timerService: TimerService
    
    private var isRunning: Bool {
        timerService.projectTimers.first { $0.projectId == project.id }?.isRunning ?? false
    }
    
    private var currentSessionTime: TimeInterval {
        return timerService.getCurrentProjectSessionTime(project.id)
    }
    
    private var dailyTotalTime: TimeInterval {
        return timerService.getProjectDailyTotal(project.id)
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(project.color)
                .frame(width: 12, height: 12)
            
            Text(project.name)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(currentSessionTime.formattedDuration()) (\(dailyTotalTime.formattedDuration()))")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                
                if isRunning {
                    Text("• Running")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Button(action: {
                if isRunning {
                    timerService.stopProject(project.id)
                } else {
                    // Auto-start main timer if not running
                    if !timerService.timerState.isRunning {
                        timerService.startWorkTimer()
                    }
                    timerService.startProject(project.id)
                }
            }) {
                Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .foregroundColor(isRunning ? .orange : .blue)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    MainTimerView()
        .environmentObject(TimerService(context: PersistenceController.preview.container.viewContext))
}