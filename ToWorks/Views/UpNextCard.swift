//
//  UpNextCard.swift
//  ToWorks
//
//  Created by RIVAL on 17/02/26.
//

import SwiftUI

struct UpNextCard: View {
    let item: TodoItem
    var color: Color = .blue
    var onComplete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background Gradient
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "2E3A59"), Color(hex: "1F212A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Decorative Glow
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 150, height: 150)
                .blur(radius: 50)
                .offset(x: 40, y: -40)
            
            VStack(alignment: .leading, spacing: 20) {
                // Header Row
                HStack {
                    Text(LocalizationManager.shared.localized("UP NEXT"))
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(color)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    
                    if item.hasReminder {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Complete Button
                    Button(action: onComplete) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(item.isCompleted ? .green : .white.opacity(0.3))
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label {
                            Text(item.timestamp, style: .time)
                        } icon: {
                            Image(systemName: "clock.fill")
                        }
                        
                        if let loc = item.location, !loc.isEmpty {
                            Label {
                                Text(loc)
                            } icon: {
                                Image(systemName: "mappin.and.ellipse")
                            }
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                }
                
                // Footer (Chips)
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(categoryColor(for: item.category))
                            .frame(width: 8, height: 8)
                        Text(item.category)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                        Text(item.priority)
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(priorityColor(for: item.priority))
                }
                .foregroundColor(.white)
            }
            .padding(24)
        }
        .frame(height: 220)
        .shadow(color: Color.blue.opacity(0.15), radius: 15, x: 0, y: 10)
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Work": return .cyan
        case "Personal": return .orange
        case "Admin": return .purple
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
