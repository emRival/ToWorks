//
//  CalendarStripView.swift
//  ToWorks
//
//  Created by RIVAL on 17/02/26.
//

import SwiftUI

struct CalendarStripView: View {
    @Binding var selectedDate: Date
    var accentColor: Color = .blue
    
    // Generate next 14 days
    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dates: [Date] = []
        for i in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(date)
            }
        }
        return dates
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
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
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                                .textCase(.uppercase)
                            
                            Text(date.formatted(.dateTime.day()))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isSelected ? .white : .primary)
                            
                            // Visual Indicator
                            if isSelected {
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: 16, height: 3)
                            } else if isToday {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 4, height: 4)
                            } else {
                                Spacer().frame(height: 3)
                            }
                        }
                        .frame(width: 68, height: 90)
                        .background(
                            ZStack {
                                if isSelected {
                                    LinearGradient(
                                        colors: [accentColor, accentColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    Color(.secondarySystemGroupedBackground)
                                }
                            }
                        )
                        .cornerRadius(24)
                        .shadow(
                            color: isSelected ? accentColor.opacity(0.3) : Color.black.opacity(0.03),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: 4
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(isSelected ? 0.2 : 0), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
        CalendarStripView(selectedDate: .constant(Date()))
    }
}
