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
    @EnvironmentObject var localizationManager: LocalizationManager
    @AppStorage("accentColorChoice") private var accentColorChoice = "Blue"
    
    private var accentColor: Color {
        switch accentColorChoice {
        case "Purple": return .purple
        case "Orange": return .orange
        case "Green": return .green
        case "Red": return .red
        case "Pink": return .pink
        default: return .blue
        }
    }
    
    var body: some View {
        ZStack {
            Color.backgroundLight.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header — Liquid Glass
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
                    
                    Text(LocalizationManager.shared.localized("Task Details"))
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
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
                .background(Material.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.localized("TASK TITLE"))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextField(LocalizationManager.shared.localized("Enter title..."), text: $item.title, axis: .vertical)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .padding(.vertical, 4)
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        
                        // Status & Priority Grid
                        HStack(spacing: 16) {
                            // Status Card
                            Button(action: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    item.isCompleted.toggle()
                                }
                                if item.isCompleted {
                                    HapticManager.shared.notification(type: .success)
                                } else {
                                    HapticManager.shared.impact(style: .light)
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(item.isCompleted ? .green : .secondary)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.isCompleted ? LocalizationManager.shared.localized("Completed") : LocalizationManager.shared.localized("Pending"))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(item.isCompleted ? .green : .primary)
                                        
                                        Text(LocalizationManager.shared.localized("STATUS"))
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 130)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Priority Card
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: "flag.fill")
                                    .font(.title2)
                                    .foregroundColor(priorityColor(item.priority))
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Picker(LocalizationManager.shared.localized("Priority"), selection: $item.priority) {
                                        Text(LocalizationManager.shared.localized("Low")).tag("Low")
                                        Text(LocalizationManager.shared.localized("Medium")).tag("Medium")
                                        Text(LocalizationManager.shared.localized("High")).tag("High")
                                    }
                                    .labelsHidden()
                                    .accentColor(priorityColor(item.priority))
                                    
                                    Text(LocalizationManager.shared.localized("PRIORITY"))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 130)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                        
                        // Details Card (Date, Reminder, Location)
                        VStack(spacing: 0) {
                            // Date Row
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(LocalizationManager.shared.localized("Due Date"))
                                    .fontWeight(.medium)
                                Spacer()
                                DatePicker("", selection: $item.timestamp, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .onChange(of: item.timestamp) { _, _ in updateNotifications() }
                            }
                            .padding(16)
                            
                            Divider().padding(.leading, 56)
                            
                            // Reminder Row
                            Toggle(isOn: $item.hasReminder) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.orange)
                                        .frame(width: 24)
                                    Text(LocalizationManager.shared.localized("Remind Me"))
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(16)
                            .onChange(of: item.hasReminder) { _, _ in updateNotifications() }
                            
                            if item.hasReminder {
                                Divider().padding(.leading, 56)
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.purple)
                                        .frame(width: 24)
                                    Text(LocalizationManager.shared.localized("Reminder Time"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(LocalizationManager.shared.localized("At time of event"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                            }

                            Divider().padding(.leading, 56)
                            
                            // Location Row
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                TextField(LocalizationManager.shared.localized("Add Location"), text: bindingLocation)
                                    .fontWeight(.medium)
                            }
                            .padding(16)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        
                        // Category Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.localized("CATEGORY"))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(["Inbox", "Work", "Personal", "Admin"], id: \.self) { cat in
                                        Button(action: { 
                                            withAnimation(.spring(response: 0.3)) {
                                                item.category = cat
                                            }
                                            HapticManager.shared.selection()
                                        }) {
                                            HStack(spacing: 6) {
                                                if item.category == cat {
                                                    Image(systemName: "checkmark")
                                                        .font(.caption)
                                                }
                                                Text(cat)
                                                    .fontWeight(.semibold)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(item.category == cat ? accentColor : Color(.tertiarySystemGroupedBackground))
                                            .foregroundColor(item.category == cat ? .white : .primary)
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        
                        // Attachments & Notes
                        VStack(alignment: .leading, spacing: 20) {
                            // Attachments
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizationManager.shared.localized("ATTACHMENTS"))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                if item.imageData == nil && item.fileData == nil {
                                    Button(action: {
                                        // TODO: Implement attachment picker
                                        HapticManager.shared.notification(type: .warning)
                                    }) {
                                        HStack {
                                            Image(systemName: "plus")
                                            Text(LocalizationManager.shared.localized("Add Attachment"))
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5])))
                                    }
                                } else {
                                    HStack(spacing: 12) {
                                        if let data = item.imageData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(12)
                                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                        }
                                        
                                        if let name = item.fileName {
                                            HStack {
                                                Image(systemName: "doc.fill")
                                                    .foregroundColor(.blue)
                                                Text(name)
                                                    .lineLimit(1)
                                            }
                                            .padding()
                                            .background(Color(.tertiarySystemGroupedBackground))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Notes
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizationManager.shared.localized("NOTES"))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                ZStack(alignment: .topLeading) {
                                    if item.notes.isEmpty {
                                        Text(LocalizationManager.shared.localized("Add notes here..."))
                                            .foregroundColor(.secondary)
                                            .padding(.top, 8)
                                            .padding(.leading, 5)
                                    }
                                    TextEditor(text: $item.notes)
                                        .frame(minHeight: 100)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        
                        // Delete Button (Standardized)
                        Button(role: .destructive, action: deleteItem) {
                            HStack {
                                Image(systemName: "trash")
                                Text(LocalizationManager.shared.localized("Delete Task"))
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                        }
                        .padding(.top, 20)
                    }
                    .padding(20)
                    .padding(.bottom, 40)
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

// Helpers for Preview
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

extension TaskDetailView {
    private func priorityColor(_ priority: String) -> Color {
        switch priority {
        case "High": return .red
        case "Medium": return .orange
        case "Low": return .green
        default: return .gray
        }
    }
    
    private var bindingLocation: Binding<String> {
        Binding(
            get: { item.location ?? "" },
            set: { item.location = $0 }
        )
    }
}
