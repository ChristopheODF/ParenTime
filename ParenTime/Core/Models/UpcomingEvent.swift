//
//  UpcomingEvent.swift
//  ParenTime
//
//  Created for ParenTime MVP
//

import Foundation

/// Represents a dated event/reminder generated from a template based on child's age
struct UpcomingEvent: Identifiable, Equatable {
    let id: String
    let templateId: String
    let title: String
    let category: SuggestionCategory
    let priority: SuggestionPriority
    let dueDate: Date
    let description: String?
    
    init(
        id: String = UUID().uuidString,
        templateId: String,
        title: String,
        category: SuggestionCategory,
        priority: SuggestionPriority,
        dueDate: Date,
        description: String? = nil
    ) {
        self.id = id
        self.templateId = templateId
        self.title = title
        self.category = category
        self.priority = priority
        self.dueDate = dueDate
        self.description = description
    }
    
    /// Create an upcoming event from a template and due date
    static func from(template: DefaultSuggestionTemplate, dueDate: Date) -> UpcomingEvent {
        // Use stable identifier from utility
        let stableId = ReminderIdentifierUtils.occurrenceIdentifier(templateId: template.id, dueDate: dueDate)
        
        return UpcomingEvent(
            id: stableId,
            templateId: template.id,
            title: template.title,
            category: SuggestionCategory(rawValue: template.category) ?? .custom,
            priority: SuggestionPriority(rawValue: template.priority) ?? .info,
            dueDate: dueDate,
            description: template.description
        )
    }
}
