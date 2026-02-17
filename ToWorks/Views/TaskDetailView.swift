//
//  TaskDetailView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var item: TodoItem
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            Color.backgroundLight.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    Text("Task Details")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        // Delete or Edit action
                        deleteItem()
                    }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TITLE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextField("Task Title", text: $item.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                        
                        // Status & Priority
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("STATUS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { 
                                    item.isCompleted.toggle()
                                    if item.isCompleted {
                                        HapticManager.shared.notification(type: .success)
                                    } else {
                                        HapticManager.shared.impact(style: .light)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.isCompleted ? .green : .secondary)
                                        Text(item.isCompleted ? "Completed" : "Pending")
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PRIORITY")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                Picker("Priority", selection: $item.priority) {
                                    Text("Low").tag("Low")
                                    Text("Medium").tag("Medium")
                                    Text("High").tag("High")
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Reminder Toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("REMINDER")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            Toggle(isOn: $item.hasReminder) {
                                Label("Enable Notifications", systemImage: item.hasReminder ? "bell.fill" : "bell.slash")
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .tint(.blue)
                            .onChange(of: item.hasReminder) { oldValue, newValue in
                                updateNotifications()
                            }
                        }
                        
                        // Date & Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DUE DATE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            DatePicker("Select Date", selection: $item.timestamp)
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .onChange(of: item.timestamp) { oldValue, newValue in
                                    updateNotifications()
                                }
                        }
                        
                        // Location display
                        if let loc = item.location, !loc.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("LOCATION")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.red)
                                    Text(loc)
                                        .font(.subheadline)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Category selection ... (keeping existing)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORY")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(["Inbox", "Work", "Personal", "Admin"], id: \.self) { cat in
                                        Button(action: { item.category = cat }) {
                                            Text(cat)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                .background(item.category == cat ? Color.blue : Color(.secondarySystemGroupedBackground))
                                                .foregroundColor(item.category == cat ? .white : .primary)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Attachments display
                        if item.imageData != nil || item.fileData != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ATTACHMENTS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    if let data = item.imageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(8)
                                    }
                                    
                                    if let name = item.fileName {
                                        HStack {
                                            Image(systemName: "doc.fill")
                                            Text(name)
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $item.notes)
                                .frame(height: 120)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .navigationBarHidden(true)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func updateNotifications() {
        // Cancel existing (including legacy suffixes to be safe)
        NotificationManager.shared.cancelNotification(ids: [
            item.id.uuidString,
            "\(item.id.uuidString)_before",
            "\(item.id.uuidString)_after",
            "\(item.id.uuidString)_minus",
            "\(item.id.uuidString)_plus"
        ])
        
        // Reschedule if needed
        if item.hasReminder {
            NotificationManager.shared.scheduleTaskNotifications(
                taskId: item.id.uuidString,
                title: item.title,
                dueDate: item.timestamp
            )
        }
    }
    
    private func deleteItem() {
        HapticManager.shared.notification(type: .warning)
        modelContext.delete(item)
        dismiss()
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TodoItem.self, configurations: config)
        let item = TodoItem(title: "Test Task", timestamp: Date(), priority: "High")
        return TaskDetailView(item: item)
            .modelContainer(container)
    } catch {
       return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
