# biomaTIMER · Application Design Document (Semi-Formal)

---

## 1. Purpose

**biomaTIMER** is a minimalist iPhone app designed to track work time and project-specific effort throughout the day. It is as simple to use as the iOS stopwatch but includes additional functionality for tracking time spent on named projects. The app is visually clean, fast to interact with, and respects the user’s focus and time. It stores data locally and offers lightweight export and history views — no accounts, no sync, no distractions.

---

## 2. Key Features

### 🔹 Main Work Timer
- Start/stop/reset the timer like a stopwatch.
- Displays total time worked for the current day.
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
| **State Management** | Combine |
| **Storage** | Core Data or Codable + file-based storage (tbd based on prototyping) |
| **Export** | Codable → CSV writer → iOS ShareSheet |
| **Lock Screen / Live Activity** | WidgetKit + ActivityKit |
| **Data Retention** | On-device only (no sync, no cloud) |
| **Target Device** | iPhone only (no iPad, no macOS) |

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

## 7. Battery Optimization

To avoid draining battery unnecessarily:

- **Use system clocks** (e.g. `Date()` + `Timer`) rather than continuous loops for counting time.
- **Avoid frequent background work**:
  - Leverage background task scheduler only when app enters background to mark timestamps.
  - Update UI when app is in the foreground or visible (via SwiftUI state).
- **Live Activity** (via ActivityKit) is battery-optimized by Apple but should:
  - Be used only when the main work timer is running.
  - Expire when not needed (automatically or explicitly).
- **Project timer toggling** should not trigger heavy computation or frequent disk writes — batch persist at safe intervals or state changes.

