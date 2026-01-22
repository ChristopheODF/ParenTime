//
//  DashboardPrioritizer.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation

/// Service pour prioriser et organiser les items du dashboard
struct DashboardPrioritizer {
    private let referenceDate: Date
    
    init(referenceDate: Date = Date()) {
        self.referenceDate = referenceDate
    }
    
    /// Organise les items en sections "À faire maintenant" et "À venir"
    /// - Parameters:
    ///   - items: Liste complète des items (suggestions + rappels)
    ///   - maxNow: Nombre maximum d'items dans "À faire maintenant" (défaut: 3)
    ///   - maxUpcoming: Nombre maximum d'items dans "À venir" (défaut: 3)
    /// - Returns: Tuple avec les items "maintenant" et "à venir"
    func prioritize(
        items: [DashboardItem],
        maxNow: Int = 3,
        maxUpcoming: Int = 3
    ) -> (now: [DashboardItem], upcoming: [DashboardItem]) {
        // Séparer suggestions et rappels
        let suggestions = items.compactMap { item -> ReminderSuggestion? in
            if case .suggestion(let suggestion) = item {
                return suggestion
            }
            return nil
        }
        
        let reminders = items.compactMap { item -> ActiveReminder? in
            if case .reminder(let reminder) = item {
                return reminder
            }
            return nil
        }
        
        // Calculer les items "maintenant"
        // Suggestions actives (dans la fenêtre d'âge) vont dans "maintenant"
        let nowSuggestions = suggestions.map { DashboardItem.suggestion($0) }
        
        // Rappels avec date d'échéance dans les 7 prochains jours vont dans "maintenant"
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: referenceDate)!
        let urgentReminders = reminders
            .filter { $0.dueDate <= sevenDaysFromNow }
            .sorted { $0.dueDate < $1.dueDate }
            .map { DashboardItem.reminder($0) }
        
        // Combiner et limiter à maxNow
        let nowItems = (urgentReminders + nowSuggestions).prefix(maxNow)
        
        // Calculer les items "à venir"
        // Rappels avec date d'échéance après 7 jours
        let upcomingReminders = reminders
            .filter { $0.dueDate > sevenDaysFromNow }
            .sorted { $0.dueDate < $1.dueDate }
            .map { DashboardItem.reminder($0) }
            .prefix(maxUpcoming)
        
        return (now: Array(nowItems), upcoming: Array(upcomingReminders))
    }
}
