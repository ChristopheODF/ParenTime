//
//  ReminderSuggestion.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation

/// Type de suggestion de rappel
enum ReminderSuggestionType: String, Codable, Equatable {
    case hpvVaccination = "hpv_vaccination"
    case mandatoryVaccines = "mandatory_vaccines_0_2"
    case meningococcusB = "meningococcus_b_2025"
}

/// Category of suggestion
enum SuggestionCategory: String, Codable, Equatable {
    case vaccines
    case appointments
    case medications
    case custom
}

/// Priority level of suggestion
enum SuggestionPriority: String, Codable, Equatable {
    case required
    case recommended
    case info
}

/// Suggestion de rappel basée sur l'âge de l'enfant
struct ReminderSuggestion: Identifiable, Equatable {
    let id: String
    let templateId: String
    let title: String
    let category: SuggestionCategory
    let priority: SuggestionPriority
    let description: String?
    
    init(
        id: String = UUID().uuidString,
        templateId: String,
        title: String,
        category: SuggestionCategory,
        priority: SuggestionPriority,
        description: String? = nil
    ) {
        self.id = id
        self.templateId = templateId
        self.title = title
        self.category = category
        self.priority = priority
        self.description = description
    }
    
    /// Create a suggestion from a template
    static func from(template: DefaultSuggestionTemplate) -> ReminderSuggestion {
        return ReminderSuggestion(
            id: UUID().uuidString,
            templateId: template.id,
            title: template.title,
            category: SuggestionCategory(rawValue: template.category) ?? .custom,
            priority: SuggestionPriority(rawValue: template.priority) ?? .info,
            description: template.description
        )
    }
}

