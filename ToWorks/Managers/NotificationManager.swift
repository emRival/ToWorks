//
//  NotificationManager.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import UserNotifications
import Combine
import AudioToolbox

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var settings: UNNotificationSettings?
    @Published var isAuthorized = false
    @Published var activeAlarmID: String? = nil
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupCategories()
        getSettings()
    }
    
    private func setupCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Complete",
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 5 Min",
            options: .destructive
        )
        
        let category = UNNotificationCategory(
            identifier: "TASK_ALARM",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            if granted {
                print("✅ Notification permission granted")
                self.getSettings()
            } else if let error = error {
                print("❌ Notification permission denied: \(error.localizedDescription)")
            }
        }
    }
    
    func getSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.settings = settings
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Schedule a local notification with sound
    func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if soundEnabled {
            let ringtone = UserDefaults.standard.string(forKey: "selectedRingtone") ?? "Radar"
            // Use custom sound file. iOS plays default if file not found.
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(ringtone).caf"))
        } else {
            content.sound = nil
        }
        content.badge = 1
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = "TASK_ALARM"
        
        let trigger: UNNotificationTrigger
        let timeInterval = date.timeIntervalSinceNow
        
        if timeInterval <= 1 {
            // Schedule for ~1 second from now (immediate)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        } else {
            // Schedule for exact date/time
            let triggerDate = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        }
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Notification Error: \(error.localizedDescription)")
            } else {
                print("🔔 Scheduled: \"\(title)\" @ \(date.formatted(.dateTime.hour().minute().day().month()))")
            }
        }
    }
    
    /// Schedule the full set of notifications for a task (before + at time + after)
    func scheduleTaskNotifications(taskId: String, title: String, dueDate: Date) {
        let reminderMinutes = UserDefaults.standard.integer(forKey: "reminderMinutes")
        let actualMinutes = reminderMinutes > 0 ? reminderMinutes : 5 // default 5 min
        
        // 1. Reminder BEFORE due date
        if let beforeDate = Calendar.current.date(byAdding: .minute, value: -actualMinutes, to: dueDate) {
            if beforeDate > Date() {
                scheduleNotification(
                    id: "\(taskId)_before",
                    title: "⏰ Upcoming: \(title)",
                    body: "Starting in \(actualMinutes) minutes!",
                    date: beforeDate
                )
            }
        }
        
        // 2. At exact due time
        scheduleNotification(
            id: taskId,
            title: "🔔 Reminder: \(title)",
            body: "Your task is due now!",
            date: dueDate
        )
        
        // 3. Follow-up AFTER due date
        if let afterDate = Calendar.current.date(byAdding: .minute, value: actualMinutes, to: dueDate) {
            scheduleNotification(
                id: "\(taskId)_after",
                title: "📋 Follow up: \(title)",
                body: "Did you complete this task?",
                date: afterDate
            )
        }
    }
    
    func cancelNotification(ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    func cancelAllTaskNotifications(taskId: String) {
        cancelNotification(ids: [taskId, "\(taskId)_before", "\(taskId)_after"])
    }
    
    /// Debug: list all pending notifications
    func listPending() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📬 Pending notifications: \(requests.count)")
            for r in requests {
                print("   - \(r.identifier): \(r.content.title)")
            }
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Show notification even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner + sound + badge even while app is open
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    // Handle notification tap & actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let fullID = response.notification.request.identifier
        // Strip suffixes to get true Task ID
        // Strip suffixes to get true Task ID
        let id = fullID.replacingOccurrences(of: "_before", with: "")
                       .replacingOccurrences(of: "_after", with: "")
                       .replacingOccurrences(of: "_minus", with: "")
                       .replacingOccurrences(of: "_plus", with: "")
        
        // Check for specific actions
        switch response.actionIdentifier {
        case "COMPLETE_ACTION":
            // We can't easily mark complete here without ModelContext access.
            // Instead, we'll launch the app and let the view handle it via activeAlarmID
            print("✅ Complete Action Tapped")
            DispatchQueue.main.async {
                self.activeAlarmID = id
            }
            
        case "SNOOZE_ACTION":
            print("Ez Snooze Action Tapped")
            // Reschedule for 5 min later
            if response.notification.request.content.userInfo["originalDate"] is Date {
                // If we have original date, add 5 min to NOW, or original?
                // Simpler: 5 min from NOW
                let newDate = Date().addingTimeInterval(5 * 60)
                let content = response.notification.request.content
                scheduleNotification(id: id, title: content.title, body: content.body, date: newDate)
            } else {
                 // Fallback snooze
                 let newDate = Date().addingTimeInterval(5 * 60)
                 let content = response.notification.request.content
                 scheduleNotification(id: id, title: content.title, body: content.body, date: newDate)
            }
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification -> Open Alarm View
            print("📲 User tapped notification: \(id)")
            DispatchQueue.main.async {
                self.activeAlarmID = id
            }
            
        default:
            break
        }
        
        completionHandler()
    }
}
