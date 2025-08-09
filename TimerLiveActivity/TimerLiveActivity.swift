import ActivityKit
import Foundation

// TimerActivityAttributes used by the Live Activity. This must match the app target’s
// definition exactly (name and fields) so ActivityKit can encode/decode across processes.
struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var isRunning: Bool
        var activeProjectName: String?
        var activeProjectColor: String?
        var currentSessionTime: TimeInterval
        var dailyTotalTime: TimeInterval
    }
    
    var timerName: String
}