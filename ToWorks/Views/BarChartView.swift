//
//  BarChartView.swift
//  ToWorks
//
//  Created by RIVAL on 17/02/26.
//

import SwiftUI
import Charts

struct DailyData: Identifiable {
    let id = UUID()
    let day: String
    let value: Int
}

struct BarChartView: View {
    let data: [DailyData]
    var color: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.localized("Weekly Activity"))
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(data) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Tasks", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(8)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // Fallback for older iOS (Custom implementation)
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(data) { item in
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(colors: [.blue, .blue.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                                .frame(height: CGFloat(item.value) * 20 + 10) // Simple scaling
                            
                            Text(item.day)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    BarChartView(data: [
        DailyData(day: "Mon", value: 5),
        DailyData(day: "Tue", value: 8),
        DailyData(day: "Wed", value: 3),
        DailyData(day: "Thu", value: 7),
        DailyData(day: "Fri", value: 6),
        DailyData(day: "Sat", value: 2),
        DailyData(day: "Sun", value: 1)
    ])
    .padding()
    .background(Color(.systemGroupedBackground))
}
