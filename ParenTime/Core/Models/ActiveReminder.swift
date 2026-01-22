//
//  ActiveReminder.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation

/// Type de rappel actif
enum ActiveReminderType: String, Codable, Equatable {
    case vaccine = "vaccine"
    case treatment = "treatment"
    case appointment = "appointment"
    case custom = "custom"
}

/// Rappel actif avec une date d'échéance
/// Pour le MVP, il s'agit d'un modèle placeholder
/// qui peut être étendu avec une persistance plus tard
struct ActiveReminder: Identifiable, Equatable {
    let id: UUID
    let type: ActiveReminderType
    let title: String
    let description: String
    let dueDate: Date
    
    init(
        id: UUID = UUID(),
        type: ActiveReminderType,
        title: String,
        description: String,
        dueDate: Date
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.dueDate = dueDate
    }
}
