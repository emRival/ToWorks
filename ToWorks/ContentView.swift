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
    @EnvironmentObject var localizationManager: LocalizationManager
    
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
            // Main Content
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack { DashboardView() }
                case 1:
                    NavigationStack { CalendarView() }
                case 2:
                    NavigationStack { StatsView() }
                case 3:
                    NavigationStack { SettingsView() }
                default:
                    NavigationStack { DashboardView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
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
                    .zIndex(1)
            }
            
            // Custom Tab Bar & FAB
            VStack(spacing: 0) {
                Spacer()
                
                ZStack(alignment: .bottom) {
                    // Floating Tab Bar
                    CustomTabBar(selectedTab: $selectedTab, accentColor: appAccentColor, onFabTap: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            fabExpanded.toggle()
                        }
                    })
                    
                    // FAB Actions (When Expanded)
                    if fabExpanded {
                        VStack(spacing: 16) {
                            // Voice Command
                            Button {
                                withAnimation { fabExpanded = false }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    showVoiceCommand = true
                                }
                            } label: {
                                actionButtonLabel(text: LocalizationManager.shared.localized("Voice"), icon: "mic.fill", color: .indigo)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
                            
                            // New Task
                            Button {
                                withAnimation { fabExpanded = false }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    showNewTaskSheet = true
                                }
                            } label: {
                                actionButtonLabel(text: LocalizationManager.shared.localized("New Task"), icon: "pencil.line", color: appAccentColor)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
                        }
                        .padding(.bottom, 80) // Push up above the FAB
                        .zIndex(3)
                    }
                    
                    // Main FAB Button (Centered on Tab Bar)
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            fabExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
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
                            .shadow(color: (fabExpanded ? Color.red : appAccentColor).opacity(0.4), radius: 10, y: 5)
                            .rotationEffect(.degrees(fabExpanded ? 45 : 0))
                    }
                    .offset(y: -28) // Pull up to float above tab bar
                    .zIndex(4)
                }
            }
            .ignoresSafeArea(.keyboard)
            .zIndex(2)
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
    
    // Helper View for FAB Actions
    private func actionButtonLabel(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(color))
                .shadow(color: color.opacity(0.4), radius: 8, y: 4)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
