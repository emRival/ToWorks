//
//  DashboardView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \TodoItem.timestamp, order: .forward) private var items: [TodoItem]
    @Query(sort: \NotificationRecord.timestamp, order: .reverse) private var notifications: [NotificationRecord]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedDate = Date()
    @State private var showNotifications = false
    @AppStorage("userName") private var userName = "User"
    @State private var searchText = ""
    @AppStorage("accentColorChoice") private var accentColorChoice = "Blue"
    
    private var accentColor: Color {
        switch accentColorChoice {
        case "Blue": return .blue
        case "Purple": return .purple
        case "Orange": return .orange
        case "Green": return .green
        case "Red": return .red
        case "Pink": return .pink
        default: return .blue
        }
    }
    
    private var filteredItems: [TodoItem] {
        items.filter {
            Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) &&
            (searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText))
        }
    }

    private var upNextItem: TodoItem? {
        // Filter tasks for the selected day
        let todayItems = items.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
        
        // Strategy: 
        // 1. Find the earliest task that is NOT completed. 
        //    This captures both "Upcoming" and "Overdue" tasks.
        if let incomplete = todayItems.first(where: { !$0.isCompleted }) {
            return incomplete
        }
        
        // 2. If all tasks for today are completed, show the very last one of the day as a summary
        return todayItems.last
    }
    
    private var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return LocalizationManager.shared.localized("Good Morning,")
        case 12..<18: return LocalizationManager.shared.localized("Good Afternoon,")
        default: return LocalizationManager.shared.localized("Good Evening,")
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header (Welcome)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(timeGreeting)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(userName)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showNotifications = true }) {
                            ZStack {
                            Circle()
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .frame(width: 48, height: 48)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "bell.badge")
                                    .font(.system(size: 20))
                                    .foregroundColor(.primary)
                                
                                if unreadCount > 0 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 6, y: -6)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField(LocalizationManager.shared.localized("Search for task..."), text: $searchText)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground).opacity(0.8))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            
                            // Weekly Calendar Strip
                            CalendarStripView(selectedDate: $selectedDate, accentColor: accentColor)
                            
                            // Up Next Hero Card
                            VStack(alignment: .leading, spacing: 16) {
                                if let next = upNextItem {
                                    NavigationLink(destination: TaskDetailView(item: next)) {
                                        UpNextCard(item: next, color: accentColor) {
                                            toggleCompletion(for: next)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    if filteredItems.isEmpty {
                                        EmptyTasksView()
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Upcoming List
                            VStack(alignment: .leading, spacing: 18) {
                                HStack {
                                    // Localized Header
                                    Text(LocalizationManager.shared.localized("Upcoming Tasks"))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    NavigationLink(destination: CalendarView()) {
                                        Text(LocalizationManager.shared.localized("See All"))
                                            .font(.headline)
                                            .foregroundColor(accentColor)
                                    }
                                }
                                .padding(.horizontal, 24)
                                
                                LazyVStack(spacing: 12) {
                                    // Make sure items are sorted by time (although query does it, explicit is safer)
                                    let sortedItems = filteredItems.sorted { $0.timestamp < $1.timestamp }
                                    
                                    ForEach(sortedItems) { item in
                                        if item.id != upNextItem?.id {
                                            NavigationLink(destination: TaskDetailView(item: item)) {
                                                TaskRow(item: item) {
                                                    toggleCompletion(for: item)
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .contextMenu {
                                                Button {
                                                    toggleCompletion(for: item)
                                                } label: {
                                                    Label(item.isCompleted ? "Mark Incomplete" : "Mark Complete", systemImage: item.isCompleted ? "circle" : "checkmark.circle")
                                                }
                                                
                                                Button(role: .destructive) {
                                                    withAnimation {
                                                        modelContext.delete(item)
                                                        HapticManager.shared.notification(type: .warning)
                                                    }
                                                } label: {
                                                    Label(LocalizationManager.shared.localized("Delete"), systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showNotifications) {
                NotificationListView()
            }
        }
        .tint(accentColor) // Apply Accent Color to Navigation
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func toggleCompletion(for item: TodoItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            item.isCompleted.toggle()
        }
        if item.isCompleted {
            HapticManager.shared.notification(type: .success)
        } else {
            HapticManager.shared.impact(style: .light)
        }
    }
}

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.blue.opacity(0.3))
                .padding(20)
                .background(Circle().fill(Color.blue.opacity(0.1)))
            
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.localized("All caught up!"))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(LocalizationManager.shared.localized("Enjoy your free time or add a new task to get started."))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    DashboardView()
}
