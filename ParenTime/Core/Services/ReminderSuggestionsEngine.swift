//
//  ReminderSuggestionsEngine.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation

/// Service pour générer des suggestions de rappels basées sur l'âge de l'enfant
/// Cette implémentation est pure et testable (pas de side effects)
struct ReminderSuggestionsEngine {
    private let calendar: Calendar
    private let referenceDate: Date
    
    /// Initialise le moteur de suggestions
    /// - Parameters:
    ///   - calendar: Calendrier à utiliser pour les calculs d'âge (par défaut: .current)
    ///   - referenceDate: Date de référence pour calculer l'âge (par défaut: Date())
    init(calendar: Calendar = .current, referenceDate: Date = Date()) {
        self.calendar = calendar
        self.referenceDate = referenceDate
    }
    
    /// Génère des suggestions de rappels pour un enfant donné
    /// - Parameter child: L'enfant pour lequel générer des suggestions
    /// - Returns: Liste de suggestions applicables
    func suggestions(for child: Child) -> [ReminderSuggestion] {
        guard let age = child.age(at: referenceDate, calendar: calendar) else {
            return []
        }
        
        var suggestions: [ReminderSuggestion] = []
        
        // HPV vaccination suggestion for ages 11-14
        if ReminderSuggestion.hpvVaccination.ageRange.contains(age) {
            suggestions.append(.hpvVaccination)
        }
        
        return suggestions
    }
}
