//
//  OnboardingView.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    
    @State private var inputName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAnimating = false
    @State private var showIcon = false
    
    var body: some View {
        ZStack {
            // Consistent App Background
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Animated Icon
                if showIcon {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .symbolEffect(.bounce, value: isAnimating)
                        .padding(.bottom, 20)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Welcome Text
                VStack(spacing: 8) {
                    Text(LocalizationManager.shared.localized("Welcome to ToWorks"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(LocalizationManager.shared.localized("Let's get productive. First, what should we call you?"))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
                
                // Input Section (Card Style)
                VStack(alignment: .leading, spacing: 16) {
                    Text(LocalizationManager.shared.localized("YOUR NAME"))
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.secondary)
                        .tracking(1)
                    
                    TextField(LocalizationManager.shared.localized("Enter your first name"), text: $inputName)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .submitLabel(.done)
                        .onSubmit {
                            submit()
                        }
                    
                    if showError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Floating Action Button Style
                Button(action: submit) {
                    HStack {
                        Text(LocalizationManager.shared.localized("Get Started"))
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .shadow(color: Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                showIcon = true
                isAnimating = true
            }
        }
    }
    
    private func submit() {
        let trimmed = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation: Not empty
        guard !trimmed.isEmpty else {
            showError(msg: "Please enter your name.")
            return
        }
        
        // Validation: 1 word only
        let components = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count > 1 {
            showError(msg: "Please enter only your first name (one word).")
            return
        }
        
        // Success
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation {
            userName = trimmed
            hasOnboarded = true
        }
    }
    
    private func showError(msg: String) {
        withAnimation {
            errorMessage = msg
            showError = true
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

#Preview {
    OnboardingView()
}
