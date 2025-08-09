import ActivityKit
import Foundation

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