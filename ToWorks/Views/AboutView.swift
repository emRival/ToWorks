//
//  AboutView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
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
                    
                    Text("About")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, 44) // Balance the back button
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App Icon & Info
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill") // Placeholder until AppIcon is ready
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                            
                            VStack(spacing: 4) {
                                Text("ToWorks")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                
                                Text("Version 1.0.0")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What is ToWorks?")
                                .font(.headline)
                            
                            Text("ToWorks is a modern productivity application designed to help you manage tasks efficiently. It features a smart calendar, voice command integration for quick task entry, and detailed productivity statistics to keep you on track.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        // Author Info
                        VStack(spacing: 16) {
                            Text("Designed & Developed by")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .kerning(1)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("Muhammad Rival, S.Kom")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Lead Developer")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        // Copyright
                        Text("© 2026 ToWorks. All rights reserved.")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.top, 20)
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    AboutView()
}
