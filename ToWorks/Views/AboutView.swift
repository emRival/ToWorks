//
//  AboutView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showCopied = false
    
    private let instagramURL = URL(string: "https://instagram.com/em_rival")!
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                    
                    Text(LocalizationManager.shared.localized("About"))
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, 44)
                }
                .padding()
                .background(Material.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App Icon & Branding
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange.opacity(0.2), .pink.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 56))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                            }
                            .shadow(color: .orange.opacity(0.2), radius: 20, y: 10)
                            
                            VStack(spacing: 8) {
                                Text("ToWorks")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                    Text("Version 1.0.0")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.top, 32)
                        
                        // Features Card
                        VStack(alignment: .leading, spacing: 16) {
                            Label {
                                Text("About This App")
                                    .font(.system(size: 15, weight: .bold))
                            } icon: {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            
                            Text("ToWorks - Focus & To-Do List is a modern productivity app designed to help you manage tasks efficiently with a smart calendar, voice commands, and detailed statistics.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineSpacing(5)
                            
                            Divider()
                            
                            // Feature list
                            VStack(spacing: 12) {
                                featureRow("calendar", "Smart Calendar", "Visual task planning with date indicators")
                                featureRow("mic.fill", "Voice Commands", "Add tasks hands-free with speech recognition")
                                featureRow("chart.bar.fill", "Statistics", "Track your productivity over time")
                                featureRow("bell.badge.fill", "Smart Reminders", "Get notified before, at, and after deadlines")
                                featureRow("globe", "Multi-Language", "Support for English, Indonesian, and Japanese")
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        
                        // Developer Card
                        VStack(spacing: 16) {
                            Text("DEVELOPER")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .kerning(1.5)
                            
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Button(action: {
                                UIApplication.shared.open(instagramURL)
                            }) {
                                VStack(spacing: 6) {
                                    Text("Muhammad Rival, S.Kom")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text("iOS Developer")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Button(action: {
                                UIApplication.shared.open(instagramURL)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "link")
                                        .font(.system(size: 12))
                                    Text("@em_rival")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        
                        // Tech Stack
                        VStack(alignment: .leading, spacing: 12) {
                            Label {
                                Text("Built With")
                                    .font(.system(size: 15, weight: .bold))
                            } icon: {
                                Image(systemName: "hammer.fill")
                                    .foregroundColor(.orange)
                            }
                            
                            HStack(spacing: 8) {
                                techBadge("SwiftUI", "swift", .orange)
                                techBadge("SwiftData", "cylinder.fill", .blue)
                                techBadge("Speech", "waveform", .green)
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        
                        // Copyright
                        VStack(spacing: 4) {
                            Text("Made with ❤️ in Indonesia")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("© 2026 ToWorks - Focus & To-Do List. All rights reserved.")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Helpers
    
    private func featureRow(_ icon: String, _ title: String, _ desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func techBadge(_ title: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    AboutView()
}
