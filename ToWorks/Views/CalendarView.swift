//
//  CalendarView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Query(sort: \TodoItem.timestamp, order: .forward) private var items: [TodoItem]
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showCompleted = true
    @FocusState private var isSearchFocused: Bool
    
    private let calendar = Calendar.current
    private let daySymbols = Calendar.current.shortWeekdaySymbols
    
    // MARK: - Computed
    
    private var filteredItems: [TodoItem] {
        let dayItems = items.filter {
            calendar.isDate($0.timestamp, inSameDayAs: selectedDate)
        }
        let searched: [TodoItem]
        if searchText.isEmpty {
            searched = dayItems
        } else {
            searched = dayItems.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.location?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        return showCompleted ? searched : searched.filter { !$0.isCompleted }
    }
    
    /// Cache: set of day-start Dates that have tasks
    private var taskDaySet: Set<Date> {
        var set = Set<Date>()
        for item in items {
            if let start = calendar.dateInterval(of: .day, for: item.timestamp)?.start {
                set.insert(start)
            }
        }
        return set
    }
    
    /// Cache: set of day-start Dates that have high-priority tasks
    private var highPriorityDaySet: Set<Date> {
        var set = Set<Date>()
        for item in items where item.priority == "High" {
            if let start = calendar.dateInterval(of: .day, for: item.timestamp)?.start {
                set.insert(start)
            }
        }
        return set
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.backgroundLight.ignoresSafeArea()
                    .onTapGesture {
                        dismissSearch()
                    }
                
                VStack(spacing: 0) {
                    // Header
                    headerArea(safeTop: geo.safeAreaInsets.top)
                    
                    // Scrollable content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            calendarCard
                            agendaSection
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 100)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func headerArea(safeTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            if isSearching {
                // Search bar
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("Search tasks...", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFocused)
                            .submitLabel(.done)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                    
                    Button("Cancel") {
                        dismissSearch()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 20)
                .padding(.top, safeTop + 8)
                .padding(.bottom, 10)
                .background(Color.backgroundLight)
                .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                // Regular header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(displayedMonth, format: .dateTime.month(.wide).year())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.accentColor.opacity(0.85))
                            .textCase(.uppercase)
                            .kerning(1.1)
                        Text(LocalizationManager.shared.localized("Calendar"))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Button {
                            isSearching = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                isSearchFocused = true
                            }
                        } label: {
                            headerIcon("magnifyingglass")
                        }
                        
                        Menu {
                            Button {
                                withAnimation {
                                    selectedDate = Date()
                                    displayedMonth = Date()
                                }
                            } label: {
                                Label("Go to Today", systemImage: "calendar.badge.clock")
                            }
                            Button {
                                showCompleted.toggle()
                            } label: {
                                Label(showCompleted ? "Hide Completed" : "Show Completed",
                                      systemImage: showCompleted ? "eye.slash" : "eye")
                            }
                        } label: {
                            headerIcon("ellipsis")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, safeTop + 16)
                .padding(.bottom, 16)
                .background(Material.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isSearching)
        .zIndex(10)
    }
    
    private func headerIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary.opacity(0.75))
            .frame(width: 36, height: 36)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
    
    // MARK: - Calendar Card (100% SwiftUI)
    
    private var calendarCard: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            // Weekday labels
            HStack(spacing: 0) {
                ForEach(daySymbols, id: \.self) { sym in
                    Text(sym.prefix(2).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.6))
                        .kerning(0.5)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
            
            // Day grid
            let days = generateDaysForMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { day in
                    if let day = day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Day Cell
    
    private func dayCell(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let dayStart = calendar.dateInterval(of: .day, for: date)?.start
        let hasTask = dayStart.map { taskDaySet.contains($0) } ?? false
        let isHighPriority = dayStart.map { highPriorityDaySet.contains($0) } ?? false
        let isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday || isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(
                        isSelected ? .white :
                        isToday ? .accentColor :
                        isCurrentMonth ? .primary : .secondary.opacity(0.4)
                    )
                    .frame(width: 34, height: 34)
                    .background(
                        Group {
                            if isSelected {
                                Circle().fill(Color.accentColor)
                            } else if isToday {
                                Circle().stroke(Color.accentColor, lineWidth: 1.5)
                            }
                        }
                    )
                
                // Dot indicator
                Circle()
                    .fill(
                        hasTask
                            ? (isHighPriority ? Color.red : Color.accentColor)
                            : Color.clear
                    )
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
        .frame(height: 44)
    }
    
    // MARK: - Agenda Section
    
    private var agendaSection: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Agenda")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.abbreviated))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                    Text("\(filteredItems.count) Tasks")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            
            // Tasks
            if filteredItems.isEmpty {
                emptyState
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { idx, item in
                        NavigationLink(destination: TaskDetailView(item: item)) {
                            taskRow(item, isLast: idx == filteredItems.count - 1)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
    
    // MARK: - Task Row
    
    private func taskRow(_ item: TodoItem, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Time
            VStack(spacing: 3) {
                Text(item.timestamp, format: .dateTime.hour().minute())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 60)
            
            // Card
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(2)
                            .strikethrough(item.isCompleted)
                            .foregroundColor(item.isCompleted ? .secondary : .primary)
                        
                        if let loc = item.location, !loc.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 9))
                                Text(loc)
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer(minLength: 4)
                    
                    Text(item.category.prefix(3).uppercased())
                        .font(.system(size: 8, weight: .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(catColor(item.category).opacity(0.15))
                        .foregroundColor(catColor(item.category))
                        .cornerRadius(4)
                }
                
                HStack(spacing: 4) {
                    if item.isCompleted {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                    } else {
                        Label(item.priority, systemImage: "flag.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(prioColor(item.priority))
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(catColor(item.category))
                    .frame(width: 3),
                alignment: .leading
            )
            .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(.gray.opacity(0.25))
                .padding(.top, 20)
            Text("No tasks for this day")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Tap + to add a new task")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - Calendar Helpers
    
    private func generateDaysForMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }
        
        let firstDay = monthInterval.start
        let weekday = calendar.component(.weekday, from: firstDay)
        // Offset: how many blank cells before day 1
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: firstDay) {
                days.append(date)
            }
        }
        
        // Pad trailing to fill the last row
        let remainder = days.count % 7
        if remainder > 0 {
            days.append(contentsOf: Array(repeating: nil as Date?, count: 7 - remainder))
        }
        
        return days
    }
    
    private func changeMonth(by value: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
                displayedMonth = newMonth
            }
        }
    }
    
    private func dismissSearch() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isSearching = false
            searchText = ""
            isSearchFocused = false
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
    
    private func catColor(_ c: String) -> Color {
        switch c {
        case "Work": return .blue
        case "Personal": return .orange
        case "Admin": return .purple
        default: return .gray
        }
    }
    
    private func prioColor(_ p: String) -> Color {
        switch p {
        case "High": return .red
        case "Medium": return .orange
        default: return .blue
        }
    }
}

// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CalendarView()
            .modelContainer(for: TodoItem.self, inMemory: true)
    }
}
