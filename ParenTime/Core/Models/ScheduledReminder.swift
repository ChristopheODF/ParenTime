//
//  ScheduledReminder.swift
//  ParenTime
//
//  Created for ParenTime MVP2
//

import Foundation

/// Unified model for all scheduled reminders (catalog-based and user-created)
struct ScheduledReminder: Identifiable, Codable, Equatable {
    let id: UUID
    let childId: UUID
    let templateId: String? // nil for user-created reminders
    let title: String
    let category: SuggestionCategory
    let priority: SuggestionPriority
    let dueDate: Date
    let description: String?
    
    // State management
    var isActivated: Bool
    var isCompleted: Bool
    var completedAt: Date?
    
    init(
        id: UUID = UUID(),
        childId: UUID,
        templateId: String? = nil,
        title: String,
        category: SuggestionCategory,
        priority: SuggestionPriority,
        dueDate: Date,
        description: String? = nil,
        isActivated: Bool = false,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.childId = childId
        self.templateId = templateId
        self.title = title
        self.category = category
        self.priority = priority
        self.dueDate = dueDate
        self.description = description
        self.isActivated = isActivated
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
    
    /// Create a scheduled reminder from an upcoming event
    static func from(event: UpcomingEvent, childId: UUID) -> ScheduledReminder {
        return ScheduledReminder(
            childId: childId,
            templateId: event.templateId,
            title: event.title,
            category: event.category,
            priority: event.priority,
            dueDate: event.dueDate,
            description: event.description
        )
    }
    
    /// Check if reminder is overdue
    func isOverdue(at referenceDate: Date = Date()) -> Bool {
        return dueDate < referenceDate && !isCompleted
    }
    
    /// Get "late since" text for overdue reminders
    func lateSinceText(at referenceDate: Date = Date(), calendar: Calendar = .current) -> String? {
        guard isOverdue(at: referenceDate) else { return nil }
        
        let components = calendar.dateComponents([.day, .month], from: dueDate, to: referenceDate)
        
        if let months = components.month, months > 0 {
            return months == 1 ? "En retard depuis 1 mois" : "En retard depuis \(months) mois"
        } else if let days = components.day, days > 0 {
            return days == 1 ? "En retard depuis 1 jour" : "En retard depuis \(days) jours"
        }
        
        return "En retard"
    }
}

// MARK: - Helper Extensions

extension Array where Element == ScheduledReminder {
    /// Filter reminders by category and sort by due date
    func filtered(by category: SuggestionCategory) -> [ScheduledReminder] {
        return self
            .filter { $0.category == category }
            .sorted { $0.dueDate < $1.dueDate }
    }
}
