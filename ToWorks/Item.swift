//
//  Item.swift
//  ToWorks
//
//  Created by RIVAL on 16/02/26.
//

import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var notes: String
    var timestamp: Date
    var isCompleted: Bool
    var priority: String // "Low", "Medium", "High"
    var category: String // "Work", "Personal", "Admin", etc.
    var hasReminder: Bool
    
    // New Features
    var location: String?
    @Attribute(.externalStorage) var imageData: Data?
    var fileName: String?
    @Attribute(.externalStorage) var fileData: Data?
    
    init(title: String, notes: String = "", timestamp: Date = Date(), priority: String = "Medium", category: String = "Inbox", hasReminder: Bool = false, location: String? = nil, imageData: Data? = nil, fileName: String? = nil, fileData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.timestamp = timestamp
        self.isCompleted = false
        self.priority = priority
        self.category = category
        self.hasReminder = hasReminder
        self.location = location
        self.imageData = imageData
        self.fileName = fileName
        self.fileData = fileData
    }
}
