//
//  TaskRow.swift
//  ToWorks
//
//  Created by RIVAL on 17/02/26.
//

import SwiftUI

struct TaskRow: View {
    let item: TodoItem
    var onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkbox
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .stroke(item.isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if item.isCompleted {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted)
                
                HStack(spacing: 8) {
                    Text(item.category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(categoryColor(for: item.category))
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .lineLimit(1)
                    }
                    
                    if item.hasReminder {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time
            Text(item.timestamp, style: .time)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Work": return .blue
        case "Personal": return .orange
        case "Admin": return .purple
        default: return .gray
        }
    }
}
