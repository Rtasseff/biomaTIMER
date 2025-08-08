import Foundation
import UIKit
import ActivityKit

class BackgroundTaskService: ObservableObject {
    static let shared = BackgroundTaskService()
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var currentActivity: Activity<TimerActivityAttributes>?
    
    init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        startBackgroundTask()
    }
    
    @objc private func appWillEnterForeground() {
        endBackgroundTask()
    }
    
    private func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "TimerPersistence") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    func startLiveActivity(timerState: TimerState, activeProjectName: String?, activeProjectColor: String?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = TimerActivityAttributes(timerName: "Work Timer")
        let contentState = TimerActivityAttributes.ContentState(
            startTime: timerState.startTime ?? Date(),
            isRunning: timerState.isRunning,
            activeProjectName: activeProjectName,
            activeProjectColor: activeProjectColor
        )
        
        do {
            let content = ActivityContent(state: contentState, staleDate: nil)
            currentActivity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateLiveActivity(timerState: TimerState, activeProjectName: String?, activeProjectColor: String?) {
        guard let activity = currentActivity else { return }
        
        let contentState = TimerActivityAttributes.ContentState(
            startTime: timerState.startTime ?? Date(),
            isRunning: timerState.isRunning,
            activeProjectName: activeProjectName,
            activeProjectColor: activeProjectColor
        )
        
        Task {
            let content = ActivityContent(state: contentState, staleDate: nil)
            await activity.update(content)
        }
    }
    
    func endLiveActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}