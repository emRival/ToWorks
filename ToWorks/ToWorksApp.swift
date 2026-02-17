//
//  ToWorksApp.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData

@main
struct ToWorksApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var notificationManager = NotificationManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TodoItem.self,
            NotificationRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Ensure Application Support directory exists (Fix for Simulator Sandbox issues)
        if let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
             try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        }
        
        // Request Notification Permissions on Launch
        NotificationManager.shared.requestAuthorization()
        
        // Give NotificationManager access to SwiftData so it can auto-save history
        NotificationManager.shared.modelContainer = sharedModelContainer
    }

    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasOnboarded {
                    ContentView()
                } else {
                    OnboardingView()
                }
                
                // Alarm Overlay
                if let alarmID = notificationManager.activeAlarmID {
                    AlarmOverlayView(taskID: alarmID) {
                        notificationManager.activeAlarmID = nil
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(100)
                }
            }
            .animation(.spring, value: notificationManager.activeAlarmID)
            .animation(.default, value: hasOnboarded)
            .environmentObject(localizationManager) // Inject Global Localization
        }
        .modelContainer(sharedModelContainer)
    }
}
