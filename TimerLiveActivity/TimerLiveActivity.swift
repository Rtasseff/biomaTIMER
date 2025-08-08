import ActivityKit
import WidgetKit
import SwiftUI

struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var isRunning: Bool
        var activeProjectName: String?
        var activeProjectColor: String?
    }
    
    var timerName: String
}

struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("biomaTIMER")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let projectName = context.state.activeProjectName {
                        HStack {
                            Circle()
                                .fill(Color(hex: context.state.activeProjectColor ?? "#007AFF"))
                                .frame(width: 8, height: 8)
                            Text(projectName)
                                .font(.caption2)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(timerText(from: context.state.startTime, isRunning: context.state.isRunning))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            } compactLeading: {
                Image(systemName: context.state.isRunning ? "timer" : "pause.circle")
                    .foregroundColor(context.state.isRunning ? .green : .orange)
            } compactTrailing: {
                Text(timerText(from: context.state.startTime, isRunning: context.state.isRunning))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.state.isRunning ? "timer" : "pause.circle")
                    .foregroundColor(context.state.isRunning ? .green : .orange)
            }
        }
    }
    
    private func timerText(from startTime: Date, isRunning: Bool) -> String {
        guard isRunning else { return "00:00" }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed) % 3600 / 60
        let seconds = Int(elapsed) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct TimerLiveActivityView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("biomaTIMER")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: context.state.isRunning ? "timer" : "pause.circle")
                    .foregroundColor(context.state.isRunning ? .green : .orange)
            }
            
            Text(timerText(from: context.state.startTime, isRunning: context.state.isRunning))
                .font(.title)
                .fontWeight(.bold)
                .monospacedDigit()
            
            if let projectName = context.state.activeProjectName {
                HStack {
                    Circle()
                        .fill(Color(hex: context.state.activeProjectColor ?? "#007AFF"))
                        .frame(width: 6, height: 6)
                    Text(projectName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func timerText(from startTime: Date, isRunning: Bool) -> String {
        guard isRunning else { return "00:00" }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed) % 3600 / 60
        let seconds = Int(elapsed) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}