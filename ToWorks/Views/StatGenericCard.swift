//
//  StatGenericCard.swift
//  ToWorks
//
//  Created by RIVAL on 17/02/26.
//

import SwiftUI

struct StatGenericCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .padding(10)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 130)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
