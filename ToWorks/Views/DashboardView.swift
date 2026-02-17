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
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedDate = Date()
    @State private var showNotifications = false
    @AppStorage("userName") private var userName = "User"

    
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
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                // Optimize: Filter once
                let todayTasks = items.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentDateString)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                            
                            Text("Welcome, \(userName)")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showNotifications = true }) {
                            ZStack {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .padding(12)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
                                
                                if unreadCount > 0 {
                                    Text("\(unreadCount)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Color.orange)
                                        .clipShape(Circle())
                                        .offset(x: 10, y: -10)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2).offset(x: 10, y: -10))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            
                            // Weekly Calendar Strip
                            WeeklyCalendarStrip(selectedDate: $selectedDate)
                            
                            // Up Next Hero Card
                            VStack(alignment: .leading, spacing: 16) {
                                // Logic moved inline/helper
                                if let item = getUpNext(from: todayTasks) {
                                    NavigationLink(destination: TaskDetailView(item: item)) {
                                        UpNextCard(item: item)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    EmptyTasksView()
                                }
                            }
                            
                            // Upcoming List
                            VStack(alignment: .leading, spacing: 18) {
                                HStack {
                                    Text(LocalizationManager.shared.localized("Upcoming Tasks"))
                                        .font(.system(size: 20, weight: .heavy))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(todayTasks.count) \(LocalizationManager.shared.localized("Total"))")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                }
                                
                                ForEach(todayTasks) { item in
                                    NavigationLink(destination: TaskDetailView(item: item)) {
                                        TaskRow(item: item)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotifications) {
                NotificationListView()
            }

        }
    }
    
    // Helper for Up Next logic
    private func getUpNext(from tasks: [TodoItem]) -> TodoItem? {
        if let incomplete = tasks.first(where: { !$0.isCompleted }) {
            return incomplete
        }
        return tasks.last
    }
}

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.orange.opacity(0.3))
            
            Text(LocalizationManager.shared.localized("All caught up!"))
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(LocalizationManager.shared.localized("Enjoy your free time or add a new task to get started."))
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white.opacity(0.5))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Components

struct WeeklyCalendarStrip: View {
    @Binding var selectedDate: Date
    
    // Generate next 7 days instead of 5
    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(date)
            }
        }
        return dates
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(days, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = date
                        }
                        HapticManager.shared.selection()
                    }) {
                        VStack(spacing: 8) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                            
                            Text(date.formatted(.dateTime.day()))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(isSelected ? .white : .primary)
                            
                            if isToday && !isSelected {
                                Circle().fill(Color.orange).frame(width: 4, height: 4)
                            } else if isSelected {
                                Capsule().fill(Color.white).frame(width: 12, height: 3)
                            } else {
                                Spacer().frame(height: 3)
                            }
                        }
                        .frame(width: 58, height: 86)
                        .background(
                            isSelected ? 
                            AnyView(LinearGradient(gradient: Gradient(colors: [Color(hex: "5E5CE6"), Color(hex: "342EAD")]), startPoint: .top, endPoint: .bottom)) : 
                            AnyView(Color(.secondarySystemGroupedBackground))
                        )
                        .cornerRadius(20)
                        .shadow(color: isSelected ? Color(hex: "5E5CE6").opacity(0.4) : Color.black.opacity(0.04), radius: 4, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 4) // Add padding to avoid clipping shadow
            .padding(.vertical, 4)
        }
    }
}

struct UpNextCard: View {
    let item: TodoItem
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Background
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "1F212A"), Color(hex: "342EAD")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Decorative Glow
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 50, y: -50)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(LocalizationManager.shared.localized("UP NEXT"))
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(item.hasReminder ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    
                    if item.hasReminder {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                    
                    if item.imageData != nil || item.fileData != nil {
                        Image(systemName: "paperclip")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            item.isCompleted.toggle()
                        }
                        if item.isCompleted {
                            HapticManager.shared.notification(type: .success)
                        } else {
                            HapticManager.shared.impact(style: .light)
                        }
                    }) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "arrow.up.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(item.isCompleted ? Color.green : Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                        Text(item.timestamp, style: .time)
                            .font(.system(size: 14, weight: .semibold))
                        
                        if let loc = item.location, !loc.isEmpty {
                            Spacer().frame(width: 8)
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 12))
                            Text(loc)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(categoryColor(for: item.category))
                            .frame(width: 8, height: 8)
                        Text(item.category)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                        Text(item.priority)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(28)
        }
        .shadow(color: Color(hex: "1F212A").opacity(0.35), radius: 10, x: 0, y: 8)
    }
    
    func categoryColor(for category: String) -> Color {
        switch category {
        case "Work": return .blue
        case "Personal": return .orange
        case "Admin": return .purple
        default: return .gray
        }
    }
}


struct TaskRow: View {
    let item: TodoItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Icon (Checkbox)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    item.isCompleted.toggle()
                }
                if item.isCompleted {
                    HapticManager.shared.notification(type: .success)
                } else {
                    HapticManager.shared.impact(style: .light)
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(item.isCompleted ? categoryColor(for: item.category) : categoryColor(for: item.category).opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if item.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(categoryColor(for: item.category))
                            .font(.system(size: 24))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .strikethrough(item.isCompleted)
                
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Text(item.category)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(categoryColor(for: item.category))
                    
                    if let loc = item.location, !loc.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.5))
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                        Text(loc)
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    
                    if item.hasReminder {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                    
                    if item.imageData != nil || item.fileData != nil {
                        Image(systemName: "paperclip")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.timestamp, style: .time)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.black.opacity(0.02), lineWidth: 1)
        )
    }
    
    func categoryColor(for category: String) -> Color {
        switch category {
        case "Work": return .blue
        case "Personal": return .orange
        case "Admin": return .purple
        default: return .gray
        }
    }
}


        
        #Preview {
            DashboardView()
        }

