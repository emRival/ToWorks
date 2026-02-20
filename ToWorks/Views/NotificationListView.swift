//
//  NotificationListView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData

struct NotificationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query(sort: \NotificationRecord.timestamp, order: .reverse) var notifications: [NotificationRecord]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text(LocalizationManager.shared.localized("History"))) {
                    if notifications.isEmpty {
                        Text(LocalizationManager.shared.localized("No notifications yet"))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(notifications) { notification in
                            HStack(alignment: .top, spacing: 12) {
                                // Icon based on content (simple heuristic)
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: notification.title.lowercased().contains("test") ? "bell.badge.fill" : "calendar.badge.clock")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(notification.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text(notification.body)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                    Text(notification.timestamp, style: .time)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .onDelete(perform: deleteNotifications)
                    }
                }
                
                Section {
                    #if DEBUG
                    Button(action: addTestNotification) {
                        Label(LocalizationManager.shared.localized("Test System Notification"), systemImage: "bell.badge.fill")
                    }
                    #endif
                    
                    if !notifications.isEmpty {
                        Button(role: .destructive, action: clearAll) {
                            Label(LocalizationManager.shared.localized("Clear All History"), systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.localized("Notifications"))
            .navigationBarItems(trailing: Button(LocalizationManager.shared.localized("Done")) {
                dismiss()
            })
            .onAppear {
                markAllAsRead()
            }
        }
    }
    
    private func markAllAsRead() {
        for notification in notifications {
            notification.isRead = true
        }
    }
    
    private func addTestNotification() {
        let title = "Test Notification"
        let body = "This is a test notification from ToWorks - Focus & To-Do List."
        let date = Date()
        
        NotificationManager.shared.scheduleNotification(
            id: UUID().uuidString,
            title: title,
            body: body,
            date: date
        )
        
        let record = NotificationRecord(title: title, body: body, timestamp: date)
        modelContext.insert(record)
    }
    
    private func deleteNotifications(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(notifications[index])
        }
    }
    
    private func clearAll() {
        for notification in notifications {
            modelContext.delete(notification)
        }
    }
}
