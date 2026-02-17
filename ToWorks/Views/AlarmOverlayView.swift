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
    
    init(taskID: String, onDismiss: @escaping () -> Void) {
        self.taskID = taskID
        self.onDismiss = onDismiss
        
        // Clean ID (remove suffixes)
        let cleanIDString = taskID.replacingOccurrences(of: "_before", with: "")
                                  .replacingOccurrences(of: "_after", with: "")
                                  .replacingOccurrences(of: "_minus", with: "")
                                  .replacingOccurrences(of: "_plus", with: "")
                                  
        // Query to find the specific task
        let id = UUID(uuidString: cleanIDString) ?? UUID()
        _tasks = Query(filter: #Predicate<TodoItem> { $0.id == id })
    }
    
    var body: some View {
        ZStack {
            // Dark Background
            Color.black.ignoresSafeArea()
            
            // Gradient Pulsing Background
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 300, height: 300)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.5 : 0.2)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            
            if let task = tasks.first {
                VStack(spacing: 50) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .symbolEffect(.bounce.byLayer, options: .repeating)
                        
                        Text("TASK REMINDER")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(2)
                        
                        Text(task.title)
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if !task.notes.isEmpty {
                            Text(task.notes)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal)
                        }
                        
                        Text(task.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 40) {
                        // SNOOZE / REJECT
                        Button {
                            snoozeTask()
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 70, height: 70)
                                        .shadow(color: .red.opacity(0.4), radius: 10)
                                    Image(systemName: "bell.slash.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                                Text("Snooze")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // COMPLETE / ACCEPT
                        Button {
                            completeTask(task)
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 70, height: 70)
                                        .shadow(color: .green.opacity(0.4), radius: 10)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 30, weight: .heavy))
                                        .foregroundColor(.white)
                                }
                                Text("Complete")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.bottom, 60)
                }
            } else {
                // Task not found (maybe deleted)
                VStack {
                    Text("Task not found")
                        .foregroundColor(.white)
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }
            }
        }
        .onAppear {
            isPulsing = true
            startAlarmLoop()
        }
        .onDisappear {
            stopAlarmLoop()
        }
    }
    
    private func startAlarmLoop() {
        // Play immediately
        playSound()
        // Loop every 2 seconds
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
        feedbackGenerator.notificationOccurred(.error) // Stronger feedback
    }
    
    private func snoozeTask() {
        // Schedule new notification for 5 min later
        // Use NotificationManager for this
        // We handle logic manually here since we are in the app
        let snoozeDate = Date().addingTimeInterval(5 * 60)
        
        if let task = tasks.first {
            NotificationManager.shared.scheduleNotification(
                id: task.id.uuidString, // Reuse ID to overwrite
                title: "💤 Snoozed: \(task.title)",
                body: "This task was snoozed for 5 minutes.",
                date: snoozeDate
            )
        }
        onDismiss()
    }
    
    private func completeTask(_ task: TodoItem) {
        withAnimation {
            task.isCompleted = true
            NotificationManager.shared.cancelAllTaskNotifications(taskId: task.id.uuidString)
            // Save context? SwiftData autosaves usually, but explicit save handles edge cases
            try? modelContext.save()
        }
        onDismiss()
    }
}
