//
//  NotificationRecord.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import Foundation
import SwiftData

@Model
final class NotificationRecord {
    var id: UUID
    var title: String
    var body: String
    var timestamp: Date
    var isRead: Bool
    
    init(title: String, body: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.timestamp = timestamp
        self.isRead = false
    }
}
