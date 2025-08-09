import Foundation
import SwiftUI

struct TimerState: Equatable {
    var isRunning: Bool = false
    var startTime: Date?
    var totalSeconds: TimeInterval = 0
    var activeProject: UUID?
}

struct ProjectTimer: Identifiable, Equatable {
    let id = UUID()
    var projectId: UUID
    var isRunning: Bool = false
    var startTime: Date?
    var totalSeconds: TimeInterval = 0
    
    static func == (lhs: ProjectTimer, rhs: ProjectTimer) -> Bool {
        lhs.id == rhs.id && lhs.projectId == rhs.projectId && lhs.isRunning == rhs.isRunning
    }
}

struct ProjectData: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    var isLunchTimer: Bool
    
    init(name: String, colorHex: String = "#007AFF", isLunchTimer: Bool = false) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
        self.isLunchTimer = isLunchTimer
    }
    
    init(id: UUID, name: String, colorHex: String, createdAt: Date, isLunchTimer: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.isLunchTimer = isLunchTimer
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}