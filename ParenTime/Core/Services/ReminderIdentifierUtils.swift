//
//  ReminderIdentifierUtils.swift
//  ParenTime
//
//  Created for ParenTime MVP2
//

import Foundation

/// Utility for generating stable identifiers for reminders and notifications
struct ReminderIdentifierUtils {
    
    /// Generate a stable notification identifier for a reminder
    /// - Parameters:
    ///   - childId: The child's UUID
    ///   - templateId: The template ID
    ///   - dueDate: The due date of the reminder
    /// - Returns: A stable identifier string
    static func notificationIdentifier(childId: UUID, templateId: String, dueDate: Date) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: dueDate)
        return "reminder_\(childId.uuidString)_\(templateId)_\(dateString)"
    }
    
    /// Generate a stable occurrence identifier
    /// - Parameters:
    ///   - templateId: The template ID
    ///   - dueDate: The due date of the occurrence
    /// - Returns: A stable identifier string
    static func occurrenceIdentifier(templateId: String, dueDate: Date) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: dueDate)
        return "\(templateId)_\(dateString)"
    }
}
