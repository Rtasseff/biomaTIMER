import Foundation
import ActivityKit
import UIKit

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
    
    func startLiveActivity(timerState: TimerState, activeProjectName: String?, activeProjectColor: String?, currentSessionTime: TimeInterval, dailyTotalTime: TimeInterval) {
        // If we already have an active Live Activity, update it instead
        if currentActivity != nil {
            updateLiveActivity(timerState: timerState, activeProjectName: activeProjectName, activeProjectColor: activeProjectColor, currentSessionTime: currentSessionTime, dailyTotalTime: dailyTotalTime)
            return
        }
        
        let authInfo = ActivityAuthorizationInfo()
        print("Live Activities enabled: \(authInfo.areActivitiesEnabled)")
        print("Live Activities frequency enabled: \(authInfo.frequentPushesEnabled)")
        
        guard authInfo.areActivitiesEnabled else { 
            print("Live Activities are not enabled - check iOS Settings > biomaTIMER > Live Activities")
            return 
        }
        
        let attributes = TimerActivityAttributes(timerName: "Work Timer")
        let contentState = TimerActivityAttributes.ContentState(
            startTime: timerState.startTime ?? Date(),
            isRunning: timerState.isRunning,
            activeProjectName: activeProjectName,
            activeProjectColor: activeProjectColor,
            currentSessionTime: currentSessionTime,
            dailyTotalTime: dailyTotalTime
        )
        
        do {
            // Set stale date to 30 seconds to encourage more frequent updates
            let staleDate = Date().addingTimeInterval(30)
            let content = ActivityContent(state: contentState, staleDate: staleDate)
            currentActivity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("Live Activity started successfully")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateLiveActivity(timerState: TimerState, activeProjectName: String?, activeProjectColor: String?, currentSessionTime: TimeInterval, dailyTotalTime: TimeInterval) {
        guard let activity = currentActivity else { return }
        
        let contentState = TimerActivityAttributes.ContentState(
            startTime: timerState.startTime ?? Date(),
            isRunning: timerState.isRunning,
            activeProjectName: activeProjectName,
            activeProjectColor: activeProjectColor,
            currentSessionTime: currentSessionTime,
            dailyTotalTime: dailyTotalTime
        )
        
        Task {
            // Set stale date to 30 seconds to encourage more frequent updates
            let staleDate = Date().addingTimeInterval(30)
            let content = ActivityContent(state: contentState, staleDate: staleDate)
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