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
}

/// Suggestion de rappel basée sur l'âge de l'enfant
struct ReminderSuggestion: Identifiable, Equatable {
    let id: UUID
    let type: ReminderSuggestionType
    let title: String
    let description: String
    let ageRange: ClosedRange<Int>
    
    init(
        id: UUID = UUID(),
        type: ReminderSuggestionType,
        title: String,
        description: String,
        ageRange: ClosedRange<Int>
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.ageRange = ageRange
    }
}

// Predefined suggestions
extension ReminderSuggestion {
    /// HPV vaccination suggestion for children aged 11-14
    static let hpvVaccination = ReminderSuggestion(
        type: .hpvVaccination,
        title: "Vaccination HPV",
        description: "La vaccination contre le papillomavirus (HPV) est recommandée entre 11 et 14 ans pour prévenir certains cancers.",
        ageRange: 11...14
    )
}
