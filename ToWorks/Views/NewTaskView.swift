//
//  NewTaskView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct NewTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    
    @State private var title = ""
    @State private var category = "Inbox"
    @State private var priority = "Medium"
    @State private var dueDate = Date()
    @State private var hasReminder = false
    
    // Extra Features
    @State private var location = ""
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showFilePicker = false
    @State private var fileName: String?
    @State private var fileData: Data?
    @State private var notes = ""
    
    var body: some View {
        ZStack {
            Color(hex: "F8F9FE").ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                    }
                    
                    Spacer()
                    
                    Text(LocalizationManager.shared.localized("Create New Task"))
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Category Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.localized("CATEGORY"))
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            HStack(spacing: 12) {
                                CategoryChip(title: LocalizationManager.shared.localized("Inbox"), icon: "tray.fill", isSelected: category == "Inbox") { category = "Inbox" }
                                CategoryChip(title: LocalizationManager.shared.localized("Work"), icon: "briefcase.fill", isSelected: category == "Work") { category = "Work" }
                                CategoryChip(title: LocalizationManager.shared.localized("Personal"), icon: "person.fill", isSelected: category == "Personal") { category = "Personal" }
                            }
                        }
                        
                        // Input Area
                        VStack(alignment: .leading, spacing: 16) {
                            TextField(LocalizationManager.shared.localized("What needs to be done?"), text: $title, axis: .vertical)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .padding(24)
                                .background(Color.white)
                                .cornerRadius(24)
                                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        }
                        
                        // Settings Row
                        VStack(alignment: .leading, spacing: 20) {
                            // Location Input
                            VStack(alignment: .leading, spacing: 12) {
                                Label(LocalizationManager.shared.localized("Location"), systemImage: "mappin.and.ellipse")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                TextField(LocalizationManager.shared.localized("Add address or place..."), text: $location)
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05), lineWidth: 1))
                            }
                            
                            HStack {
                                Label(LocalizationManager.shared.localized("Due Date"), systemImage: "calendar")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                DatePicker("", selection: $dueDate)
                                    .labelsHidden()
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(20)
                            
                            HStack {
                                Label(LocalizationManager.shared.localized("Priority"), systemImage: "flag.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Picker("", selection: $priority) {
                                    Text(LocalizationManager.shared.localized("Low")).tag("Low")
                                    Text(LocalizationManager.shared.localized("Medium")).tag("Medium")
                                    Text(LocalizationManager.shared.localized("High")).tag("High")
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(20)
                            
                            Toggle(isOn: $hasReminder) {
                                Label(LocalizationManager.shared.localized("Set Reminder"), systemImage: "bell.fill")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(20)
                            .tint(.blue)
                        }
                        
                        // Attachments Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizationManager.shared.localized("ATTACHMENTS"))
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            HStack(spacing: 16) {
                                // Image Picker
                                PhotosPicker(selection: $selectedImageItem, matching: .images) {
                                    VStack(spacing: 8) {
                                        if let imageData, let uiImage = UIImage(data: imageData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            Image(systemName: "photo.on.rectangle")
                                                .font(.system(size: 24))
                                                .foregroundColor(.blue)
                                                .frame(width: 80, height: 80)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(12)
                                        }
                                        Text(LocalizationManager.shared.localized("Image"))
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                    }
                                }
                                .onChange(of: selectedImageItem) { _, newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                            imageData = data
                                        }
                                    }
                                }
                                
                                // File Picker
                                Button(action: { showFilePicker = true }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: fileData != nil ? "doc.fill" : "doc.badge.plus")
                                            .font(.system(size: 24))
                                            .foregroundColor(fileData != nil ? .green : .blue)
                                            .frame(width: 80, height: 80)
                                            .background(fileData != nil ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                                            .cornerRadius(12)
                                        
                                        Text(fileName ?? LocalizationManager.shared.localized("File"))
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 80)
                                }
                            }
                        }
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.localized("NOTES"))
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(24)
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Bottom Button
                Button(action: {
                    hideKeyboard()
                    addTask()
                }) {
                    HStack {
                        Text(LocalizationManager.shared.localized("Create Task"))
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(24)
                    .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(24)
                }
            } // End of Main VStack
        } // End of ZStack
        .onTapGesture {
            hideKeyboard()
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                fileName = url.lastPathComponent
                fileData = try? Data(contentsOf: url)
            case .failure(let error):
                print("Error picking file: \(error.localizedDescription)")
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func addTask() {
        let newItem = TodoItem(
            title: title,
            notes: notes,
            timestamp: dueDate,
            priority: priority,
            category: category,
            hasReminder: hasReminder,
            location: location.isEmpty ? nil : location,
            imageData: imageData,
            fileName: fileName,
            fileData: fileData
        )
        modelContext.insert(newItem)
        
        // Schedule Notifications if needed
        if hasReminder {
            NotificationManager.shared.scheduleTaskNotifications(
                taskId: newItem.id.uuidString,
                title: title,
                dueDate: dueDate
            )
            
            // Save records for notification history
            let reminderMinutes = UserDefaults.standard.integer(forKey: "reminderMinutes")
            let mins = reminderMinutes > 0 ? reminderMinutes : 5
            
            if let beforeDate = Calendar.current.date(byAdding: .minute, value: -mins, to: dueDate), beforeDate > Date() {
                modelContext.insert(NotificationRecord(title: "⏰ Upcoming: \(title)", body: "Starting in \(mins) minutes!", timestamp: beforeDate))
            }
            modelContext.insert(NotificationRecord(title: "🔔 Reminder: \(title)", body: "Your task is due now!", timestamp: dueDate))
            if let afterDate = Calendar.current.date(byAdding: .minute, value: mins, to: dueDate) {
                modelContext.insert(NotificationRecord(title: "📋 Follow up: \(title)", body: "Did you complete this task?", timestamp: afterDate))
            }
        }
        
        dismiss()
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color.white)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(15)
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuggestionChip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    NewTaskView()
}
