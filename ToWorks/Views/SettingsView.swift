//
//  SettingsView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData
import UserNotifications
import AudioToolbox

struct SettingsView: View {
    @Query(sort: \TodoItem.timestamp) private var allItems: [TodoItem]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Appearance
    @AppStorage("appearance") private var appearance = "System"
    @AppStorage("accentColorChoice") private var accentColorChoice = "Blue"
    @AppStorage("userName") private var userName = "User"
    
    // Notifications
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderMinutes") private var reminderMinutes = 5
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("selectedRingtone") private var selectedRingtone = "Radar"
    @AppStorage("voiceLanguage") private var voiceLanguage = "Auto"
    
    // Task Defaults
    @AppStorage("defaultCategory") private var defaultCategory = "Inbox"
    @AppStorage("defaultPriority") private var defaultPriority = "Medium"
    
    // Data
    @State private var showDeleteAlert = false
    @State private var showDeleteCompletedAlert = false
    @State private var showResetAlert = false
    @State private var deletedCount = 0
    @State private var showDeletionBanner = false
    
    private let categories = ["Inbox", "Work", "Personal", "Admin", "Health", "Study"]
    private let priorities = ["Low", "Medium", "High"]
    private let appearances = ["System", "Light", "Dark"]
    private let accentColors = ["Blue", "Purple", "Orange", "Green", "Red", "Pink"]
    private let reminderOptions = [0, 5, 10, 15, 30, 60]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(LocalizationManager.shared.localized("PREFERENCES"))
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.accentColor.opacity(0.85))
                            .kerning(1.1)
                        Text(LocalizationManager.shared.localized("Settings"))
                            .font(.system(size: 26, weight: .black, design: .rounded))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                List {
                    // MARK: - Profile
                    Section {
                        HStack {
                            settingIcon("person.fill", color: .blue)
                            TextField("Name", text: $userName)
                        }
                    } header: {
                        sectionHeader("Profile")
                    }

                    // MARK: - Appearance
                    Section {
                        // Theme
                        HStack {
                            settingIcon("paintbrush.fill", color: .purple)
                            Picker("Theme", selection: $appearance) {
                                ForEach(appearances, id: \.self) { a in
                                    Text(a).tag(a)
                                }
                            }
                        }
                        
                        // Accent Color
                        HStack {
                            settingIcon("paintpalette.fill", color: accentColorValue)
                            Picker("Accent Color", selection: $accentColorChoice) {
                                ForEach(accentColors, id: \.self) { c in
                                    HStack {
                                        Circle().fill(colorFor(c)).frame(width: 12, height: 12)
                                        Text(c)
                                    }.tag(c)
                                }
                            }
                        }
                    } header: {
                        sectionHeader(LocalizationManager.shared.localized("Appearance"))
                    }
                    
                    // MARK: - Notifications
                    Section {
                        HStack {
                            settingIcon("bell.fill", color: .orange)
                            Toggle(LocalizationManager.shared.localized("Enable Notifications"), isOn: $notificationsEnabled)
                        }
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.requestAuthorization()
                            }
                        }
                        
                        if notificationsEnabled {
                            HStack {
                                settingIcon("clock.fill", color: .blue)
                                Picker(LocalizationManager.shared.localized("Remind Before"), selection: $reminderMinutes) {
                                    Text("At time").tag(0)
                                    Text("5 min").tag(5)
                                    Text("10 min").tag(10)
                                    Text("15 min").tag(15)
                                    Text("30 min").tag(30)
                                    Text("1 hour").tag(60)
                                }
                            }
                            
                            HStack {
                                settingIcon("speaker.wave.2.fill", color: .cyan)
                                Toggle(LocalizationManager.shared.localized("Sound"), isOn: $soundEnabled)
                            }
                            
                            if soundEnabled {
                                HStack {
                                    settingIcon("music.note", color: .pink)
                                    Picker("Ringtone", selection: $selectedRingtone) {
                                        ForEach(Ringtone.all, id: \.id) { ringtone in
                                            Text(ringtone.name).tag(ringtone.id)
                                        }
                                    }
                                }
                            }
                            
                            HStack {
                                settingIcon("mic.fill", color: .purple)
                                Picker(LocalizationManager.shared.localized("Voice Language"), selection: $voiceLanguage) {
                                    ForEach(VoiceLanguage.allLanguages) { lang in
                                        Text("\(lang.flag) \(lang.name)").tag(lang.id)
                                    }
                                }
                            }
                        }
                    } header: {
                        sectionHeader(LocalizationManager.shared.localized("Notifications"))
                    }
                    
                    // MARK: - Task Defaults
                    Section {
                        HStack {
                            settingIcon("folder.fill", color: .blue)
                            Picker(LocalizationManager.shared.localized("Default Category"), selection: $defaultCategory) {
                                ForEach(categories, id: \.self) { c in
                                    Text(c).tag(c)
                                }
                            }
                        }
                        
                        HStack {
                            settingIcon("flag.fill", color: .orange)
                            Picker(LocalizationManager.shared.localized("Default Priority"), selection: $defaultPriority) {
                                ForEach(priorities, id: \.self) { p in
                                    Text(p).tag(p)
                                }
                            }
                        }
                    } header: {
                        sectionHeader(LocalizationManager.shared.localized("Task Defaults"))
                    }
                    
                    // MARK: - Data Management
                    Section {
                        // Summary
                        HStack {
                            settingIcon("chart.bar.fill", color: .green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizationManager.shared.localized("Tasks Summary"))
                                    .font(.system(size: 15, weight: .semibold))
                                Text("\(allItems.count) total · \(allItems.filter { $0.isCompleted }.count) completed · \(allItems.filter { !$0.isCompleted }.count) pending")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Delete completed
                        Button {
                            showDeleteCompletedAlert = true
                        } label: {
                            HStack {
                                settingIcon("checkmark.circle.fill", color: .orange)
                                Text(LocalizationManager.shared.localized("Delete Completed Tasks"))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(allItems.filter { $0.isCompleted }.count)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Delete all
                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                settingIcon("trash.fill", color: .red)
                                Text(LocalizationManager.shared.localized("Delete All Tasks"))
                                    .foregroundColor(.red)
                            }
                        }
                    } header: {
                        sectionHeader(LocalizationManager.shared.localized("Data Management"))
                    }
                    
                    // MARK: - About
                    Section {
                        NavigationLink(destination: AboutView()) {
                            HStack {
                                settingIcon("info.circle.fill", color: .blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LocalizationManager.shared.localized("About ToWorks"))
                                        .font(.system(size: 15, weight: .bold))
                                    Text(LocalizationManager.shared.localized("Version, Author & Info"))
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        sectionHeader(LocalizationManager.shared.localized("About"))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            
            // Deletion banner
            if showDeletionBanner {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(deletedCount) tasks deleted")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.85))
                    .cornerRadius(14)
                    .shadow(radius: 10)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: voiceLanguage) { _, _ in
            LocalizationManager.shared.languageDidChange()
        }
        .alert("Delete All Tasks?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllTasks()
            }
        } message: {
            Text("This will permanently delete all \(allItems.count) tasks. This cannot be undone.")
        }
        .alert("Delete Completed Tasks?", isPresented: $showDeleteCompletedAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCompletedTasks()
            }
        } message: {
            let count = allItems.filter { $0.isCompleted }.count
            Text("This will permanently delete \(count) completed tasks.")
        }
    }
    
    // MARK: - Actions
    
    private func deleteAllTasks() {
        let count = allItems.count
        for item in allItems {
            NotificationManager.shared.cancelNotification(ids: [item.id.uuidString, "\(item.id.uuidString)_before"])
            modelContext.delete(item)
        }
        showBanner(count: count)
    }
    
    private func deleteCompletedTasks() {
        let completed = allItems.filter { $0.isCompleted }
        let count = completed.count
        for item in completed {
            NotificationManager.shared.cancelNotification(ids: [item.id.uuidString])
            modelContext.delete(item)
        }
        showBanner(count: count)
    }
    
    private func showBanner(count: Int) {
        deletedCount = count
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showDeletionBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showDeletionBanner = false
            }
        }
    }
    
    // MARK: - Helpers
    
    private var colorScheme: ColorScheme? {
        switch appearance {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }
    
    private var accentColorValue: Color {
        colorFor(accentColorChoice)
    }
    
    private func colorFor(_ name: String) -> Color {
        switch name {
        case "Blue": return .blue
        case "Purple": return .purple
        case "Orange": return .orange
        case "Green": return .green
        case "Red": return .red
        case "Pink": return .pink
        default: return .blue
        }
    }
    
    private func settingIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(color)
            .frame(width: 32, height: 32)
            .background(color.opacity(0.12))
            .cornerRadius(8)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .heavy))
            .kerning(0.8)
            .foregroundColor(.secondary)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}

// Model for Ringtone Selection
struct Ringtone: Identifiable, Hashable {
    let id: String
    let name: String
    let systemSoundID: SystemSoundID
    
    static let all: [Ringtone] = [
        Ringtone(id: "Radar", name: "Radar (Default)", systemSoundID: 1005),
        Ringtone(id: "Apex", name: "Apex", systemSoundID: 1001),
        Ringtone(id: "Beacon", name: "Beacon", systemSoundID: 1002),
        Ringtone(id: "Bulletin", name: "Bulletin", systemSoundID: 1003),
        Ringtone(id: "Chime", name: "Chime", systemSoundID: 1000),
        Ringtone(id: "Circuit", name: "Circuit", systemSoundID: 1004),
        Ringtone(id: "Cosmic", name: "Cosmic", systemSoundID: 1006),
        Ringtone(id: "Crystals", name: "Crystals", systemSoundID: 1007),
        Ringtone(id: "Hillside", name: "Hillside", systemSoundID: 1008),
        Ringtone(id: "Illuminate", name: "Illuminate", systemSoundID: 1009),
        Ringtone(id: "Night Owl", name: "Night Owl", systemSoundID: 1010),
        Ringtone(id: "Playtime", name: "Playtime", systemSoundID: 1011),
        Ringtone(id: "Presto", name: "Presto", systemSoundID: 1012),
        Ringtone(id: "Radar2", name: "Radar 2", systemSoundID: 1013),
        Ringtone(id: "Radiate", name: "Radiate", systemSoundID: 1014),
        Ringtone(id: "Ripples", name: "Ripples", systemSoundID: 1015),
        Ringtone(id: "Sencha", name: "Sencha", systemSoundID: 1016),
        Ringtone(id: "Signal", name: "Signal", systemSoundID: 1017),
        Ringtone(id: "Silk", name: "Silk", systemSoundID: 1018),
        Ringtone(id: "Slow Rise", name: "Slow Rise", systemSoundID: 1019),
        Ringtone(id: "Sparkle", name: "Sparkle", systemSoundID: 1020),
        Ringtone(id: "Summit", name: "Summit", systemSoundID: 1021),
        Ringtone(id: "Twinkle", name: "Twinkle", systemSoundID: 1022),
        Ringtone(id: "Uplift", name: "Uplift", systemSoundID: 1023),
        Ringtone(id: "Waves", name: "Waves", systemSoundID: 1024)
    ]
    
    static func getSoundID(for name: String) -> SystemSoundID {
        return all.first(where: { $0.id == name })?.systemSoundID ?? 1005
    }
}
