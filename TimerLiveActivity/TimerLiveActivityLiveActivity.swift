import ActivityKit
import WidgetKit
import SwiftUI

struct TimerLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen/banner UI
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.blue)
                    Text("biomaTIMER")
                        .font(.headline)
                    Spacer()
                    if context.state.isRunning {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if context.state.isRunning {
                            Text(timerInterval: context.state.startTime...Date.distantFuture, countsDown: false)
                                .font(.title2)
                                .fontWeight(.bold)
                                .fontDesign(.monospaced)
                                .multilineTextAlignment(.center)
                                .monospacedDigit()
                        } else {
                            Text(context.state.currentSessionTime.formattedDuration())
                                .font(.title2)
                                .fontWeight(.bold)
                                .fontDesign(.monospaced)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Daily Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(context.state.dailyTotalTime.formattedDuration())
                            .font(.title2)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                    }
                }
                
                if let projectName = context.state.activeProjectName {
                    HStack {
                        Circle()
                            .fill(Color(hex: context.state.activeProjectColor ?? "#007AFF"))
                            .frame(width: 8, height: 8)
                        Text(projectName)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Session")
                            .font(.caption2)
                        if context.state.isRunning {
                            Text(timerInterval: context.state.startTime...Date.distantFuture, countsDown: false)
                                .font(.title3)
                                .fontWeight(.bold)
                                .fontDesign(.monospaced)
                                .multilineTextAlignment(.center)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                        } else {
                            Text(context.state.currentSessionTime.formattedDuration())
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("Daily")
                            .font(.caption2)
                        Text(context.state.dailyTotalTime.formattedDuration())
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    if let projectName = context.state.activeProjectName {
                        HStack {
                            Circle()
                                .fill(Color(hex: context.state.activeProjectColor ?? "#007AFF"))
                                .frame(width: 6, height: 6)
                            Text(projectName)
                                .font(.caption2)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isRunning ? "play.circle.fill" : "pause.circle.fill")
                    .foregroundColor(context.state.isRunning ? .green : .orange)
            } compactTrailing: {
                Text(context.state.dailyTotalTime.formattedDuration())
                    .font(.caption2)
                    .fontWeight(.bold)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension TimeInterval {
    func formattedDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}