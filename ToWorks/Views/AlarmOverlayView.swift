//
//  AlarmOverlayView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData
import AudioToolbox

struct AlarmOverlayView: View {
    let taskID: String
    var onDismiss: () -> Void
    
    @Query private var tasks: [TodoItem]
    @Environment(\.modelContext) private var modelContext
    @State private var isPulsing = false
    @State private var soundTimer: Timer?
    @State private var feedbackGenerator = UINotificationFeedbackGenerator()
    @State private var ringScale: CGFloat = 1.0
    @State private var timeText = ""
    
    init(taskID: String, onDismiss: @escaping () -> Void) {
        self.taskID = taskID
        self.onDismiss = onDismiss
        
        let cleanIDString = taskID.replacingOccurrences(of: "_before", with: "")
                                  .replacingOccurrences(of: "_after", with: "")
                                  .replacingOccurrences(of: "_minus", with: "")
                                  .replacingOccurrences(of: "_plus", with: "")
                                  
        let id = UUID(uuidString: cleanIDString) ?? UUID()
        _tasks = Query(filter: #Predicate<TodoItem> { $0.id == id })
    }
    
    var body: some View {
        ZStack {
            // Deep dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.orange.opacity(0.3), .pink.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: CGFloat(180 + index * 80), height: CGFloat(180 + index * 80))
                    .scaleEffect(isPulsing ? 1.15 : 0.95)
                    .opacity(isPulsing ? 0.15 : 0.4)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3),
                        value: isPulsing
                    )
            }
            
            if let task = tasks.first {
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Current time
                    Text(timeText)
                        .font(.system(size: 60, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    Spacer().frame(height: 40)
                    
                    // Alarm icon with pulse ring
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .scaleEffect(ringScale)
                        
                        Circle()
                            .fill(Color.orange.opacity(0.08))
                            .frame(width: 140, height: 140)
                            .scaleEffect(ringScale * 0.9)
                        
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                            )
                            .symbolEffect(.bounce.byLayer, options: .repeating)
                    }
                    
                    Spacer().frame(height: 32)
                    
                    // Task info
                    VStack(spacing: 12) {
                        Text("TASK REMINDER")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .kerning(3)
                        
                        Text(task.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 32)
                        
                        if !task.notes.isEmpty {
                            Text(task.notes)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 40)
                        }
                        
                        // Due time badge
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                            Text(task.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(20)
                        .padding(.top, 4)
                        
                        // Category & Priority
                        if !task.category.isEmpty {
                            HStack(spacing: 8) {
                                Label(task.category, systemImage: "tag.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("·")
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Label(task.priority, systemImage: "flag.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(priorityColor(task.priority).opacity(0.8))
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Complete Button (primary)
                        Button {
                            completeTask(task)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .heavy))
                                Text("Mark Complete")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(18)
                            .shadow(color: .green.opacity(0.4), radius: 12, y: 6)
                        }
                        
                        // Snooze Button (secondary)
                        Button {
                            snoozeTask()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Snooze 5 Min")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        }
                        
                        // Dismiss
                        Button {
                            stopAlarmLoop()
                            onDismiss()
                        } label: {
                            Text("Dismiss")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            } else {
                // Task not found
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Task not found")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .onAppear {
            isPulsing = true
            startAlarmLoop()
            updateTime()
            // Update time every second
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateTime()
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                ringScale = 1.2
            }
        }
        .onDisappear {
            stopAlarmLoop()
        }
    }
    
    // MARK: - Helpers
    
    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeText = formatter.string(from: Date())
    }
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority {
        case "High": return .red
        case "Medium": return .orange
        default: return .green
        }
    }
    
    private func startAlarmLoop() {
        playSound()
        soundTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            playSound()
        }
    }
    
    private func stopAlarmLoop() {
        soundTimer?.invalidate()
        soundTimer = nil
    }
    
    private func playSound() {
        let soundName = UserDefaults.standard.string(forKey: "selectedRingtone") ?? "Radar"
        let soundID = Ringtone.getSoundID(for: soundName)
        
        AudioServicesPlaySystemSound(soundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        feedbackGenerator.notificationOccurred(.error)
    }
    
    private func snoozeTask() {
        let snoozeDate = Date().addingTimeInterval(5 * 60)
        
        if let task = tasks.first {
            NotificationManager.shared.scheduleNotification(
                id: task.id.uuidString,
                title: "💤 Snoozed: \(task.title)",
                body: "This task was snoozed for 5 minutes.",
                date: snoozeDate
            )
        }
        stopAlarmLoop()
        onDismiss()
    }
    
    private func completeTask(_ task: TodoItem) {
        withAnimation {
            task.isCompleted = true
            NotificationManager.shared.cancelAllTaskNotifications(taskId: task.id.uuidString)
            try? modelContext.save()
        }
        stopAlarmLoop()
        onDismiss()
    }
}
