//
//  DashboardItem.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation

/// Représente un item actif (suggestion ou rappel)
enum DashboardItem: Identifiable, Equatable {
    case suggestion(ReminderSuggestion)
    case reminder(ActiveReminder)
    
    var id: UUID {
        switch self {
        case .suggestion(let suggestion):
            return suggestion.id
        case .reminder(let reminder):
            return reminder.id
        }
    }
    
    var title: String {
        switch self {
        case .suggestion(let suggestion):
            return suggestion.title
        case .reminder(let reminder):
            return reminder.title
        }
    }
    
    var description: String {
        switch self {
        case .suggestion(let suggestion):
            return suggestion.description
        case .reminder(let reminder):
            return reminder.description
        }
    }
    
    /// Date de référence pour le tri (nil pour suggestions)
    var dueDate: Date? {
        switch self {
        case .suggestion:
            return nil
        case .reminder(let reminder):
            return reminder.dueDate
        }
    }
}
