//
//  StatsView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \TodoItem.timestamp, order: .forward) private var allItems: [TodoItem]
    @State private var selectedPeriod = "Week"
    @State private var animateCharts = false
    
    private let periods = ["Week", "Month", "All"]
    
    // MARK: - Computed Stats
    
    private var filteredItems: [TodoItem] {
        let cal = Calendar.current
        let now = Date()
        switch selectedPeriod {
        case "Week":
            let start = cal.date(byAdding: .day, value: -7, to: now) ?? now
            return allItems.filter { $0.timestamp >= start }
        case "Month":
            let start = cal.date(byAdding: .month, value: -1, to: now) ?? now
            return allItems.filter { $0.timestamp >= start }
        default:
            return allItems
        }
    }
    
    private var completedItems: [TodoItem] {
        filteredItems.filter { $0.isCompleted }
    }
    
    private var pendingItems: [TodoItem] {
        filteredItems.filter { !$0.isCompleted }
    }
    
    private var completionRate: Double {
        guard !filteredItems.isEmpty else { return 0 }
        return Double(completedItems.count) / Double(filteredItems.count)
    }
    
    // Tasks per category
    private var categoryBreakdown: [(String, Int, Color)] {
        let categories = Dictionary(grouping: filteredItems, by: { $0.category })
        return categories.map { ($0.key, $0.value.count, categoryColor(for: $0.key)) }
            .sorted { $0.1 > $1.1 }
    }
    
    // Tasks per priority
    private var priorityBreakdown: [(String, Int, Color)] {
        let groups = Dictionary(grouping: filteredItems, by: { $0.priority })
        let order = ["High", "Medium", "Low"]
        return order.compactMap { p in
            guard let count = groups[p]?.count else { return nil }
            return (p, count, priorityColor(for: p))
        }
    }
    
    // Weekly activity data (tasks created per day for last 7 days)
    private var weeklyData: [(String, Int, Bool)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
        
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let count = allItems.filter { cal.isDate($0.timestamp, inSameDayAs: date) }.count
            let weekday = cal.component(.weekday, from: date)
            let isToday = offset == 0
            return (dayLabels[weekday - 1], count, isToday)
        }
    }
    
    // Streak: consecutive days with at least 1 completed task
    private var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        let today = cal.startOfDay(for: Date())
        
        for offset in 0..<365 {
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let hasCompleted = allItems.contains { $0.isCompleted && cal.isDate($0.timestamp, inSameDayAs: date) }
            if hasCompleted {
                streak += 1
            } else if offset > 0 {
                break
            }
        }
        return streak
    }
    
    // Overdue
    private var overdueCount: Int {
        allItems.filter { !$0.isCompleted && $0.timestamp < Date() }.count
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("PERFORMANCE")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.accentColor.opacity(0.85))
                            .kerning(1.1)
                        Text("Productivity Insights")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Period Picker
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(periods, id: \.self) { p in
                            Text(p).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        
                        // MARK: - Top Row: Completion + Streak
                        HStack(spacing: 12) {
                            // Completion Ring
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.12), lineWidth: 10)
                                    Circle()
                                        .trim(from: 0, to: animateCharts ? completionRate : 0)
                                        .stroke(
                                            completionRate >= 0.7 ? Color.green :
                                            completionRate >= 0.4 ? Color.orange : Color.red,
                                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                        )
                                        .rotationEffect(.degrees(-90))
                                        .animation(.easeOut(duration: 1.0), value: animateCharts)
                                    
                                    VStack(spacing: 2) {
                                        Text("\(Int(completionRate * 100))%")
                                            .font(.system(size: 22, weight: .black, design: .rounded))
                                        Text("\(completedItems.count)/\(filteredItems.count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(width: 90, height: 90)
                                
                                Text("COMPLETION")
                                    .font(.system(size: 9, weight: .heavy))
                                    .kerning(0.8)
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
                            
                            // Stats Stack
                            VStack(spacing: 10) {
                                statMiniCard(
                                    icon: "flame.fill",
                                    color: .orange,
                                    value: "\(currentStreak)",
                                    label: "DAY STREAK"
                                )
                                
                                statMiniCard(
                                    icon: "exclamationmark.triangle.fill",
                                    color: .red,
                                    value: "\(overdueCount)",
                                    label: "OVERDUE"
                                )
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // MARK: - Quick Numbers
                        HStack(spacing: 12) {
                            quickStatCard(value: "\(filteredItems.count)", label: "Total", icon: "list.bullet", color: .blue)
                            quickStatCard(value: "\(completedItems.count)", label: "Done", icon: "checkmark.circle.fill", color: .green)
                            quickStatCard(value: "\(pendingItems.count)", label: "Pending", icon: "clock.fill", color: .orange)
                        }
                        
                        // MARK: - Weekly Activity
                        VStack(alignment: .leading, spacing: 14) {
                            Text("WEEKLY ACTIVITY")
                                .font(.system(size: 11, weight: .heavy))
                                .kerning(0.8)
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .bottom, spacing: 8) {
                                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, data in
                                    let (label, count, isToday) = data
                                    let maxCount = max(weeklyData.map { $0.1 }.max() ?? 1, 1)
                                    let height = max(CGFloat(count) / CGFloat(maxCount) * 80, 6)
                                    
                                    VStack(spacing: 6) {
                                        Text("\(count)")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.secondary)
                                        
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                isToday
                                                ? LinearGradient(colors: [.blue, .indigo], startPoint: .bottom, endPoint: .top)
                                                : LinearGradient(colors: [.gray.opacity(0.2), .gray.opacity(0.15)], startPoint: .bottom, endPoint: .top)
                                            )
                                            .frame(height: animateCharts ? height : 6)
                                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.05), value: animateCharts)
                                        
                                        Text(label)
                                            .font(.system(size: 10, weight: .heavy))
                                            .foregroundColor(isToday ? .blue : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 120)
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
                        
                        // MARK: - Category Breakdown
                        if !categoryBreakdown.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("BY CATEGORY")
                                    .font(.system(size: 11, weight: .heavy))
                                    .kerning(0.8)
                                    .foregroundColor(.secondary)
                                
                                ForEach(categoryBreakdown, id: \.0) { name, count, color in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 10, height: 10)
                                        
                                        Text(name)
                                            .font(.system(size: 14, weight: .bold))
                                        
                                        Spacer()
                                        
                                        // Bar
                                        GeometryReader { geo in
                                            let maxCount = categoryBreakdown.first?.1 ?? 1
                                            let width = max(CGFloat(count) / CGFloat(maxCount) * geo.size.width, 20)
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(color.opacity(0.2))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(color)
                                                        .frame(width: animateCharts ? width : 0),
                                                    alignment: .leading
                                                )
                                                .animation(.easeOut(duration: 0.8), value: animateCharts)
                                        }
                                        .frame(width: 100, height: 8)
                                        
                                        Text("\(count)")
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundColor(.primary)
                                            .frame(width: 28, alignment: .trailing)
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
                        }
                        
                        // MARK: - Priority Breakdown
                        if !priorityBreakdown.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("BY PRIORITY")
                                    .font(.system(size: 11, weight: .heavy))
                                    .kerning(0.8)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    ForEach(priorityBreakdown, id: \.0) { name, count, color in
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .stroke(color.opacity(0.2), lineWidth: 6)
                                                    .frame(width: 50, height: 50)
                                                Circle()
                                                    .trim(from: 0, to: animateCharts ? (filteredItems.isEmpty ? 0 : CGFloat(count) / CGFloat(filteredItems.count)) : 0)
                                                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                                    .frame(width: 50, height: 50)
                                                    .rotationEffect(.degrees(-90))
                                                    .animation(.easeOut(duration: 0.8), value: animateCharts)
                                                
                                                Text("\(count)")
                                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                            }
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: "flag.fill")
                                                    .font(.system(size: 8))
                                                Text(name)
                                                    .font(.system(size: 10, weight: .heavy))
                                            }
                                            .foregroundColor(color)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateCharts = true
            }
        }
        .onChange(of: selectedPeriod) { _, _ in
            animateCharts = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateCharts = true
            }
        }
    }
    
    // MARK: - Mini Components
    
    private func statMiniCard(icon: String, color: Color, value: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                Text(label)
                    .font(.system(size: 8, weight: .heavy))
                    .kerning(0.5)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
    
    private func quickStatCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
            
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(.secondary)
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
    
    // MARK: - Helpers
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Work": return .blue
        case "Personal": return .orange
        case "Admin": return .purple
        case "Health": return .green
        case "Study": return .cyan
        default: return .gray
        }
    }
    
    private func priorityColor(for priority: String) -> Color {
        switch priority {
        case "High": return .red
        case "Medium": return .orange
        case "Low": return .green
        default: return .gray
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
