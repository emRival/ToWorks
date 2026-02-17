//
//  StatsView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \TodoItem.timestamp, order: .forward) private var allItems: [TodoItem]
    @State private var selectedPeriod = "Week"
    @State private var animateCharts = false
    @EnvironmentObject var localizationManager: LocalizationManager
    
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
    
    private var overdueCount: Int {
        allItems.filter { !$0.isCompleted && $0.timestamp < Date() }.count
    }
    
    // Weekly activity data for BarChart
    private var weeklyData: [DailyData] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] // Weekday index 1-7 (Sun-Sat)
        
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let count = allItems.filter { cal.isDate($0.timestamp, inSameDayAs: date) }.count
            let weekdayIndex = cal.component(.weekday, from: date) // 1-7
            let label = dayLabels[weekdayIndex - 1]
            return DailyData(day: label, value: count)
        }
    }
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizationManager.shared.localized("PERFORMANCE"))
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(accentColor.opacity(0.8))
                                .kerning(1.1)
                            Text(LocalizationManager.shared.localized("Insights"))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(periods, id: \.self) { p in
                                Text(LocalizationManager.shared.localized(p)).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .background(Material.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 8)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            
                            // 1. Completion Rate (Full Width)
                            // 1. Completion Rate (Full Width)
                            HStack(spacing: 20) {
                                CircularProgressView(progress: animateCharts ? completionRate : 0, color: accentColor)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(localizationManager.localized("Great Job!"))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .layoutPriority(1)
                                    
                                    let periodLower = localizationManager.localized(selectedPeriod.lowercased())
                                    Text(String(format: localizationManager.localized("You have completed %d%% of your tasks this %@."), Int(completionRate * 100), periodLower))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineLimit(3)
                                        .minimumScaleFactor(0.5) // Allow text to shrink if needed
                                }
                                Spacer(minLength: 0)
                            } // HStack
                            .padding(20)
                            .background(Color.cardBackground)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                            
                            // 2. Metrics Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                StatGenericCard(
                                    title: LocalizationManager.shared.localized("Total Done"),
                                    value: "\(completedItems.count)",
                                    icon: "checkmark.circle.fill",
                                    color: accentColor // Apply Accent
                                )
                                
                                StatGenericCard(
                                    title: LocalizationManager.shared.localized("Pending"),
                                    value: "\(pendingItems.count)",
                                    icon: "clock.fill",
                                    color: .orange // Pending often keeps orange/red semantic, but could use accent secondary? keeping orange for semantic distinction
                                )
                            }
                            
                            // 3. Weekly Activity Chart (Full Width)
                            BarChartView(data: weeklyData, color: accentColor)
                            
                            // 4. Overdue (Full Width)
                            if overdueCount > 0 {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.red)
                                        .padding(12)
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(LocalizationManager.shared.localized("Attention Needed"))
                                            .font(.headline)
                                        Text(String(format: LocalizationManager.shared.localized("You have %d overdue tasks."), overdueCount))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding(20)
                                .background(Color.cardBackground)
                                .cornerRadius(24)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
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
    }
}

#Preview {
    StatsView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
