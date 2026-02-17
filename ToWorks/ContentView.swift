//
//  ContentView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showNewTaskSheet = false
    @State private var showVoiceCommand = false
    @State private var fabExpanded = false
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Global settings — applied at root level
    @AppStorage("appearance") private var appearance = "System"
    @AppStorage("accentColorChoice") private var accentColorChoice = "Blue"
    
    private var colorScheme: ColorScheme? {
        switch appearance {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }
    
    private var appAccentColor: Color {
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
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    DashboardView()
                }
                .tag(0)
                .tabItem {
                    Label(LocalizationManager.shared.localized("Home"), systemImage: "square.grid.2x2")
                }
                
                NavigationStack {
                    CalendarView()
                }
                .tag(1)
                .tabItem {
                    Label(LocalizationManager.shared.localized("Calendar"), systemImage: "calendar")
                }
                
                NavigationStack {
                    StatsView()
                }
                .tag(2)
                .tabItem {
                    Label(LocalizationManager.shared.localized("Stats"), systemImage: "chart.bar")
                }
                
                NavigationStack {
                    SettingsView()
                }
                .tag(3)
                .tabItem {
                    Label(LocalizationManager.shared.localized("Settings"), systemImage: "gearshape")
                }
            }
            .tint(appAccentColor)
            
            // Dim overlay when FAB expanded
            if fabExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            fabExpanded = false
                        }
                    }
                    .transition(.opacity)
            }
            
            // FAB Stack
            VStack(spacing: 12) {
                if fabExpanded {
                        // Voice Command
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            fabExpanded = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showVoiceCommand = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(LocalizationManager.shared.localized("Voice"))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "mic.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .indigo],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
                    
                    // New Task
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            fabExpanded = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showNewTaskSheet = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(LocalizationManager.shared.localized("New Task"))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "pencil.line")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(appAccentColor)
                        )
                        .shadow(color: appAccentColor.opacity(0.3), radius: 8, y: 4)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
                }
                
                // Main FAB button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        fabExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle().fill(
                                LinearGradient(
                                    colors: fabExpanded ? [.red.opacity(0.9), .orange] : [appAccentColor, appAccentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .shadow(color: (fabExpanded ? Color.red : appAccentColor).opacity(0.3), radius: 12, y: 5)
                        .rotationEffect(.degrees(fabExpanded ? 45 : 0))
                }
            }
            .padding(.bottom, 60)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: fabExpanded)
        }
        .sheet(isPresented: $showNewTaskSheet) {
            NewTaskView()
                .tint(appAccentColor)
        }
        .sheet(isPresented: $showVoiceCommand) {
            VoiceCommandView()
        }
        .tint(appAccentColor)
        .preferredColorScheme(colorScheme)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}

