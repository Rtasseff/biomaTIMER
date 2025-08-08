# biomaTIMER

A minimalist iPhone app for tracking work time and project-specific effort throughout the day. Built with SwiftUI, Core Data, and ActivityKit.

## Features

- **Work Timer**: Simple start/stop/reset functionality like a stopwatch
- **Project Timers**: Track time on specific projects with custom colors
- **Live Activities**: Timer display on lock screen via Dynamic Island
- **Local Storage**: All data stored locally using Core Data
- **History**: Daily/weekly/monthly time reports
- **CSV Export**: Export data via iOS Share Sheet
- **Battery Optimized**: Minimal background processing

## Architecture

- **SwiftUI**: Modern iOS UI framework
- **Core Data**: Local data persistence
- **Combine**: Reactive state management
- **ActivityKit**: Live Activities for lock screen display
- **MVVM Pattern**: Clean separation of concerns

## Project Structure

```
biomaTIMER/
├── Models/           # Data models and Core Data entities
├── Views/           # SwiftUI views
├── Services/        # Business logic and data services
├── Extensions/      # Utility extensions
└── LiveActivity/    # Lock screen Live Activity widget
```

## Key Components

- **TimerService**: Central state management for all timers
- **PersistenceController**: Core Data stack configuration
- **BackgroundTaskService**: Handles Live Activities and background tasks
- **MainTimerView**: Primary interface with work timer and project list
- **HistoryView**: Time tracking reports and analytics
- **SettingsView**: Data export and reset functionality

## Requirements

- iOS 17.5+
- Xcode 15.4+
- Swift 5.10+

## Usage

1. Tap "Start" to begin tracking work time
2. Add projects with the "+" button
3. Start project timers to track specific work
4. View reports in the History tab
5. Export data as CSV from Settings

The app automatically creates Live Activities when timers are running, showing current time on the lock screen and Dynamic Island.

## Testing

The app includes comprehensive unit tests for business logic and UI tests for critical user flows. All tests validate timer functionality, data persistence, and user interactions.