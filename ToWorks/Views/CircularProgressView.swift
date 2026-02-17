//
//  CircularProgressView.swift
//  ToWorks
//
//  Created by RIVAL on 17/02/26.
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var color: Color = .blue
    let lineWidth: CGFloat = 20
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Ring
                Circle()
                    .stroke(
                        Color(.systemGray5),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                
                // Progress Ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.5, dampingFraction: 0.8), value: progress)
                
                // Content Inside Ring
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(LocalizationManager.shared.localized("Completion"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
            }
            .frame(width: 130, height: 130)
            .padding(10)
        }
    }
}

#Preview {
    CircularProgressView(progress: 0.75)
        .frame(width: 200, height: 200)
}
