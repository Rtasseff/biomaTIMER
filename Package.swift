// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "biomaTIMER",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "biomaTIMER", targets: ["biomaTIMER"])
    ],
    targets: [
        .target(
            name: "biomaTIMER",
            path: "biomaTIMER",
            sources: [
                "biomaTIMERApp.swift",
                "ContentView.swift",
                "Models/TimerModel.swift",
                "Services/TimerService.swift",
                "Services/PersistenceController.swift",
                "Services/BackgroundTaskService.swift",
                "Views/MainTimerView.swift",
                "Views/ProjectEditorView.swift",
                "Views/HistoryView.swift",
                "Views/SettingsView.swift",
                "Extensions/Date+Extensions.swift"
            ]
        )
    ]
)