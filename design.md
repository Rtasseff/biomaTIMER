# biomaTIMER · Application Design Document (Semi-Formal)

---

## 1. Purpose

**biomaTIMER** is a minimalist iPhone app designed to track work time and project-specific effort throughout the day. It is as simple to use as the iOS stopwatch but includes additional functionality for tracking time spent on named projects. The app is visually clean, fast to interact with, and respects the user’s focus and time. It stores data locally and offers lightweight export and history views — no accounts, no sync, no distractions.

---

## 2. Key Features

### 🔹 Main Work Timer
- Start/stop/reset the timer like a stopwatch.
- Displays total time worked for the current day prominently on main screen.
- Timer display shows current session time with daily total in parentheses: "0:05:30 (2:45:15)".
- Daily total persists across timer pauses/restarts and appears on lock screen.
- Timer clearly indicates whether it’s running (e.g., through color or animation).
- Timer auto-starts if a user initiates a project timer.

### 🔹 Project Timers
- Each project has a name and a color dot (default: blue).
- Only one project timer can be active at a time.
- Starting a project timer stops the previous one.
- Project timers can only run if the main work timer is active; starting one auto-activates the main timer if needed.

### 🔹 Lock Screen & Live Activity
- Persistent lock screen display when main timer is running.
- Uses Live Activities (via Dynamic Island/lock screen area).
- Shows:
  - Current work timer
  - Active project (if any)

### 🔹 Daily View (Main Screen)
- Work timer at top, with:
  - Start/Stop button
  - Total time display for the day
- Below: list of projects with:
  - Project name
  - Color dot
  - Start/Stop toggle
  - Project time for the day

### 🔹 History View
- Displays totals for:
  - Day
  - Week
  - Month
- Shows:
  - Main work time
  - Per-project time
  - Relative time per project (as % of main work time)

### 🔹 Data Control
- Data stored only on the device.
- CSV export using the iOS Share Sheet (AirDrop, iCloud Drive, etc.).
- Option to:
  - Reset all history
  - Reset individual timers
  - Delete a project (removes associated data)

---

## 3. App Views

| View | Contents |
|------|----------|
| **Main Timer View** | Stopwatch-style interface for work and project timers |
| **Project Editor** | Add/edit/delete projects with name and color |
| **History View** | Aggregated daily/weekly/monthly time reports |
| **Settings** | Export data, reset data, delete projects |

---

## 4. Style Guide

- **Design philosophy**: Spartan, functional, fast — no excess chrome.
- **Colors**: Light mode only. Muted UI with accent colors per project.
- **Typography**: San Francisco UI font, large timer numerals, readable labels.
- **Buttons/icons**: SF Symbols, minimal sizing, no skeuomorphism.
- **Animations**: Subtle — timer state transitions, color fades for project switches.
- **Layout**: SwiftUI-native responsive layout with vertical scrolling project list.

---

## 5. Technical Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | SwiftUI |
| **State Management** | Combine + ObservableObject |
| **Storage** | Core Data with entities: TimeEntry, Project |
| **Export** | CSV writer → iOS ShareSheet |
| **Lock Screen / Live Activity** | WidgetKit + ActivityKit with Widget Extension target |
| **Data Retention** | On-device only (no sync, no cloud) |
| **Target Device** | iPhone only (iOS 17.5+) |
| **Architecture** | MVVM with TimerService as central state manager |

---

## 6. Constraints & Exclusions

- No iCloud or cross-device syncing.
- No user accounts or login.
- No notifications or reminders.
- No recurring or scheduled timers.
- Export is manual only via Share Sheet.
- Only 1 project timer active at a time.
- No background syncing or server backend.

---

## 7. Technical Implementation Details

### 🔹 Project Structure
```
biomaTIMER/
├── biomaTIMER.xcodeproj/          # Xcode project with main app + Widget Extension targets
├── biomaTIMER/                    # Main app target
│   ├── biomaTIMERApp.swift        # App entry point with Core Data setup
│   ├── ContentView.swift          # Tab view container (Main, History, Settings)
│   ├── Info.plist                 # NSSupportsLiveActivities = YES
│   ├── biomaTIMER.entitlements    # App group: group.com.rtasseff.biomaTIMER
│   ├── Models/
│   │   ├── TimerModel.swift       # Data models (TimerState, ProjectData, ProjectTimer)
│   │   └── TimerActivityAttributes.swift  # Live Activity attributes & content state
│   ├── Views/
│   │   ├── MainTimerView.swift    # Main timer + project list UI
│   │   ├── ProjectEditorView.swift # Add/edit projects
│   │   ├── HistoryView.swift      # Daily/weekly/monthly reports
│   │   └── SettingsView.swift     # Export, reset, project management
│   ├── Services/
│   │   ├── TimerService.swift     # Central state management
│   │   ├── PersistenceController.swift # Core Data setup
│   │   └── BackgroundTaskService.swift # Live Activities + background tasks
│   ├── Extensions/
│   │   └── Date+Extensions.swift  # Time formatting utilities
│   └── DataModel.xcdatamodeld/    # Core Data entities (Project, TimeEntry)
└── TimerLiveActivity/             # Widget Extension target
    ├── Info.plist                 # Widget extension configuration
    ├── TimerLiveActivity.entitlements # App group: group.com.rtasseff.biomaTIMER
    ├── TimerLiveActivityBundle.swift   # Widget bundle entry point
    └── TimerLiveActivityLiveActivity.swift # Live Activity UI implementation
```

### 🔹 Core Data Schema
```swift
// Project Entity
- id: UUID (Primary Key)
- name: String
- colorHex: String (default: "#007AFF") 
- createdAt: Date
- timeEntries: [TimeEntry] (One-to-Many relationship)

// TimeEntry Entity  
- id: UUID (Primary Key)
- startTime: Date
- endTime: Date? (nil while timer running)
- isWorkTime: Bool (true for main timer, false for project timer)
- project: Project? (Many-to-One relationship, nil for main timer entries)
```

### 🔹 Key Service Methods
```swift
// TimerService.swift - Central state manager
class TimerService: ObservableObject {
    @Published var timerState: TimerState
    @Published var projectTimers: [ProjectTimer]
    @Published var projects: [ProjectData]
    
    // Main timer controls
    func startWorkTimer()
    func stopWorkTimer() 
    func resetWorkTimer()
    
    // Project timer controls
    func startProject(_ projectId: UUID)  // Auto-starts main timer if needed
    func stopProject(_ projectId: UUID)
    
    // Daily total calculations
    func getDailyTotal() -> TimeInterval
    func getProjectDailyTotal(_ projectId: UUID) -> TimeInterval
    func getCurrentSessionTime() -> TimeInterval
    func getCurrentProjectSessionTime(_ projectId: UUID) -> TimeInterval
}
```

### 🔹 Live Activities Implementation
```swift
// TimerActivityAttributes.swift - Shared between main app and Widget Extension
struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var isRunning: Bool
        var activeProjectName: String?
        var activeProjectColor: String?
        var currentSessionTime: TimeInterval    // Current session time
        var dailyTotalTime: TimeInterval        // Total time for the day
    }
    var timerName: String
}

// BackgroundTaskService.swift - Live Activity management
func startLiveActivity(timerState:, activeProjectName:, activeProjectColor:, currentSessionTime:, dailyTotalTime:)
func updateLiveActivity(...) // Updates existing activity
func endLiveActivity() // Ends activity when timer stops
```

### 🔹 Widget Extension Target Configuration
- **Target Name**: TimerLiveActivity  
- **Bundle ID**: com.rtasseff.biomaTIMER.TimerLiveActivity
- **Product Type**: com.apple.product-type.app-extension
- **Frameworks**: WidgetKit.framework, SwiftUI.framework
- **Dependencies**: Main app target dependency with embed extension
- **Entitlements**: App group shared with main app

### 🔹 Daily Total Display Format
- **Main Timer**: "0:05:30 (2:45:15)" - session time (daily total)
- **Project Timers**: "0:02:15 (1:30:45)" - project session (project daily total)
- **Lock Screen**: Shows both main timer session/daily and active project info

### 🔹 App Permissions & Settings
- **Info.plist Keys**: 
  - NSSupportsLiveActivities: YES
  - NSSupportsLiveActivitiesFrequentUpdates: YES  
  - UIBackgroundModes: ["background-processing"]
- **iOS Settings**: User must enable Live Activities in Settings > biomaTIMER

### 🔹 Xcode Project Setup
1. Create main iOS app target with Core Data
2. Add Widget Extension target with "Include Live Activity" option
3. Share TimerActivityAttributes.swift between both targets
4. Configure app group entitlements for both targets  
5. Set proper bundle identifiers and dependencies
6. Add Widget Extension as embedded extension in main app

### 🔹 Critical Implementation Requirements

#### Daily Total Calculation Logic
```swift
// Fetches all TimeEntry records for today and sums completed durations + current session
func getDailyTotal() -> TimeInterval {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
    
    let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
    request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", today as NSDate, tomorrow as NSDate)
    
    let entries = try context.fetch(request)
    let completedTime = entries.reduce(into: 0) { total, entry in
        if let startTime = entry.startTime, let endTime = entry.endTime {
            total += endTime.timeIntervalSince(startTime)
        }
    }
    return completedTime + getCurrentSessionTime()
}
```

#### Project Timer Auto-Start Logic
```swift
// In ProjectRowView button action:
if !timerService.timerState.isRunning {
    timerService.startWorkTimer()  // Auto-start main timer
}
timerService.startProject(project.id)
```

#### Live Activity Management
```swift
// Called every second when timer running and on state changes
private func updateLiveActivity() {
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
```

#### Widget Extension Display Structure
```swift
// Lock screen Live Activity shows:
// - "biomaTIMER" header with running indicator
// - Session time (large, bold) and "Daily: X:XX:XX" (smaller)
// - Active project name with color dot if applicable
// Dynamic Island shows compact/expanded views with same data
```

#### Core Data Persistence Pattern
```swift
// Create TimeEntry when timer starts (endTime = nil)
// Update TimeEntry.endTime when timer stops
// Query today's entries: startTime >= startOfDay AND startTime < tomorrow
// Sum (endTime - startTime) for completed entries + current session if running
```

### 🔹 Known Issues & Workarounds
- **Live Activities in Simulator**: Don't work reliably, test on physical device
- **"Attaching" during Xcode install**: Expected behavior with Widget Extension targets  
- **SpringBoard errors**: Normal in simulator, ignore for development
- **Notifications instead of Live Activities**: Simulator limitation, works on device

---

## 8. Battery Optimization

To avoid draining battery unnecessarily:

- **Use system clocks** (e.g. `Date()` + `Timer`) rather than continuous loops for counting time.
- **Avoid frequent background work**:
  - Leverage background task scheduler only when app enters background to mark timestamps.
  - Update UI when app is in the foreground or visible (via SwiftUI state).
- **Live Activity** (via ActivityKit) is battery-optimized by Apple but should:
  - Be used only when the main work timer is running.
  - Expire when not needed (automatically or explicitly).
- **Project timer toggling** should not trigger heavy computation or frequent disk writes — batch persist at safe intervals or state changes.

