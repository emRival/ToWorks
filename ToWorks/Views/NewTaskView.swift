//
//  NewTaskView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct NewTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var title = ""
    @State private var category = "Inbox"
    @State private var priority = "Medium"
    @State private var dueDate = Date()
    @State private var hasReminder = false
    
    private let categories = ["Inbox", "Work", "Personal", "Admin", "Health", "Study"]
    
    // Extra Features
    @State private var location = ""
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showFilePicker = false
    @State private var fileName: String?
    @State private var fileData: Data?
    @State private var notes = ""
    @State private var isImproving = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                    }
                    
                    Spacer()
                    
                    Text(LocalizationManager.shared.localized("Create New Task"))
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: {
                        guard !title.isEmpty || !notes.isEmpty else { return }
                        isImproving = true
                        HapticManager.shared.impact(style: .light)
                        
                        Task {
                            // Run improvements in parallel for speed
                            async let improvedTitle = AIManager.shared.improveText(title)
                            async let improvedNotes = AIManager.shared.improveText(notes)
                            
                            let newTitle = await improvedTitle
                            let newNotes = await improvedNotes
                            
                            DispatchQueue.main.async {
                                withAnimation {
                                    if !newTitle.isEmpty { title = newTitle }
                                    if !newNotes.isEmpty { notes = newNotes }
                                    isImproving = false
                                    HapticManager.shared.notification(type: .success)
                                }
                            }
                        }
                    }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                            .rotationEffect(.degrees(isImproving ? 360 : 0))
                            .animation(isImproving ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isImproving)
                        }
                    }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Material.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {

                        // Title Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.localized("Details"))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextField(LocalizationManager.shared.localized("What needs to be done?"), text: $title, axis: .vertical)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .padding(.vertical, 4)
                            
                            Divider()
                            
                            // Category Scroll
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(categories, id: \.self) { cat in
                                        CategoryChip(title: cat, icon: categoryIcon(cat), isSelected: category == cat) {
                                            category = cat
                                            HapticManager.shared.selection()
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        
                        // Settings Card
                        VStack(spacing: 0) {
                            // Date
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                DatePicker("", selection: $dueDate)
                                    .labelsHidden()
                            }
                            .padding(16)
                            
                            Divider().padding(.leading, 56)
                            
                            // Location
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                TextField(LocalizationManager.shared.localized("Add location..."), text: $location)
                            }
                            .padding(16)
                            
                            Divider().padding(.leading, 56)
                            
                            // Priority
                            HStack {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                Text("Priority")
                                Spacer()
                                Picker("Priority", selection: $priority) {
                                    Text("Low").tag("Low")
                                    Text("Medium").tag("Medium")
                                    Text("High").tag("High")
                                }
                                .labelsHidden()
                            }
                            .padding(16)
                            
                            Divider().padding(.leading, 56)
                            
                            // Reminder
                            Toggle(isOn: $hasReminder) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.purple)
                                        .frame(width: 24)
                                    Text("Remind me")
                                }
                            }
                            .padding(16)
                            .tint(.blue)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        
                        // Notes Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.localized("Notes"))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text(LocalizationManager.shared.localized("Add description..."))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                }
                                TextEditor(text: $notes)
                                    .frame(minHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        
                        // Attachments Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.localized("Attachments"))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Photo Picker
                                    PhotosPicker(selection: $selectedImageItem, matching: .images) {
                                        if let imageData, let uiImage = UIImage(data: imageData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            VStack {
                                                Image(systemName: "photo")
                                                    .font(.title2)
                                                Text("Photo")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                            }
                                            .foregroundColor(.blue)
                                            .frame(width: 80, height: 80)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(12)
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
                                        if let _ = fileData {
                                            VStack {
                                                Image(systemName: "doc.fill")
                                                    .font(.title2)
                                                Text("File")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                            }
                                            .foregroundColor(.green)
                                            .frame(width: 80, height: 80)
                                            .background(Color.green.opacity(0.1))
                                            .cornerRadius(12)
                                        } else {
                                            VStack {
                                                Image(systemName: "folder")
                                                    .font(.title2)
                                                Text("File")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                            }
                                            .foregroundColor(.orange)
                                            .frame(width: 80, height: 80)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
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
    
    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Inbox": return "tray.fill"
        case "Work": return "briefcase.fill"
        case "Personal": return "person.fill"
        case "Admin": return "folder.fill"
        case "Health": return "heart.fill"
        case "Study": return "book.fill"
        default: return "tag.fill"
        }
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
            // NotificationRecord history is now auto-saved by NotificationManager
            // when each notification fires (willPresent delegate).
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
            .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
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
