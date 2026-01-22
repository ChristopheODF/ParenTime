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
    private static let defaultSuggestionsFileName = "default_suggestions"
    
    private let calendar: Calendar
    private let referenceDate: Date
    private let templates: [DefaultSuggestionTemplate]
    
    /// Initialise le moteur de suggestions
    /// - Parameters:
    ///   - calendar: Calendrier à utiliser pour les calculs d'âge (par défaut: .current)
    ///   - referenceDate: Date de référence pour calculer l'âge (par défaut: Date())
    ///   - templates: Templates to use (defaults to loading from JSON)
    init(calendar: Calendar = .current, referenceDate: Date = Date(), templates: [DefaultSuggestionTemplate]? = nil) {
        self.calendar = calendar
        self.referenceDate = referenceDate
        self.templates = templates ?? Self.loadTemplates()
    }
    
    /// Load templates from JSON file
    private static func loadTemplates() -> [DefaultSuggestionTemplate] {
        guard let url = Bundle.main.url(forResource: defaultSuggestionsFileName, withExtension: "json") else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode([DefaultSuggestionTemplate].self, from: data)
        } catch {
            // In production, use proper logging (e.g., os_log)
            // For MVP, return empty array
            return []
        }
    }
    
    /// Génère des suggestions de rappels pour un enfant donné
    /// - Parameter child: L'enfant pour lequel générer des suggestions
    /// - Returns: Liste de suggestions applicables
    func suggestions(for child: Child) -> [ReminderSuggestion] {
        return templates
            .filter { $0.isApplicable(to: child, at: referenceDate, calendar: calendar) }
            .map { ReminderSuggestion.from(template: $0) }
            .sorted { suggestion1, suggestion2 in
                // Sort by priority: required > recommended > info
                let priorityOrder: [SuggestionPriority: Int] = [
                    .required: 0,
                    .recommended: 1,
                    .info: 2
                ]
                let order1 = priorityOrder[suggestion1.priority] ?? 3
                let order2 = priorityOrder[suggestion2.priority] ?? 3
                return order1 < order2
            }
    }
}
