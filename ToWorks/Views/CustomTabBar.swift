//
//  CustomTabBar.swift
//  ToWorks
//
//  Created by RIVAL on 17/02/26.
//

import SwiftUI

enum Tab: Int, CaseIterable {
    case home = 0
    case calendar = 1
    case stats = 2
    case settings = 3
    
    var icon: String {
        switch self {
        case .home: return "square.grid.2x2.fill"
        case .calendar: return "calendar"
        case .stats: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    var titleKey: String {
        switch self {
        case .home: return "Home"
        case .calendar: return "Calendar"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }
    
    var title: String {
        LocalizationManager.shared.localized(titleKey)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var accentColor: Color = .blue
    var onFabTap: () -> Void
    
    // Animation namespace for the sliding effect
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Tabs
            ForEach(Tab.allCases.prefix(2), id: \.self) { tab in
                TabButton(tab: tab, selectedTab: $selectedTab, accentColor: accentColor, animation: animation)
            }
            
            // Center FAB Space (Visual Only, FAB is in ContentView)
            Spacer()
                .frame(width: 60)
            
            // Right Tabs
            ForEach(Tab.allCases.suffix(2), id: \.self) { tab in
                TabButton(tab: tab, selectedTab: $selectedTab, accentColor: accentColor, animation: animation)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Color.white.opacity(0.15)
            }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
            .shadow(color: Color.white.opacity(0.4), radius: 1, x: 0, y: -1) // Top highlight
        )
        .padding(.horizontal, 24)
    }
}

struct TabButton: View {
    let tab: Tab
    @Binding var selectedTab: Int
    var accentColor: Color = .blue
    var animation: Namespace.ID
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab.rawValue
                HapticManager.shared.selection()
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: selectedTab == tab.rawValue ? .bold : .medium))
                    .symbolEffect(.bounce, value: selectedTab == tab.rawValue)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTab == tab.rawValue ? accentColor : .gray.opacity(0.8))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(0), accentColor: .blue, onFabTap: {})
        }
    }
}
