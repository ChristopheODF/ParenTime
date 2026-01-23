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
    
    /// Génère des événements à venir avec dates d'échéance pour un enfant (toutes les occurrences)
    /// - Parameters:
    ///   - child: L'enfant pour lequel générer des événements
    ///   - maxMonthsInFuture: Horizon maximum en mois (nil = pas de limite)
    /// - Returns: Liste d'événements à venir
    func upcomingEvents(for child: Child, maxMonthsInFuture: Int? = nil) -> [UpcomingEvent] {
        var events: [UpcomingEvent] = []
        
        let maxDate: Date?
        if let maxMonths = maxMonthsInFuture {
            maxDate = calendar.date(byAdding: .month, value: maxMonths, to: referenceDate)
        } else {
            maxDate = nil
        }
        
        for template in templates {
            // Generate events from schedule if present
            if let schedule = template.schedule {
                let templateEvents = generateEvents(from: template, schedule: schedule, child: child, maxDate: maxDate)
                events.append(contentsOf: templateEvents)
            }
        }
        
        // Sort by priority, then by date, then by title
        return events.sorted { event1, event2 in
            // First by priority: required > recommended > info
            let priorityOrder: [SuggestionPriority: Int] = [
                .required: 0,
                .recommended: 1,
                .info: 2
            ]
            let order1 = priorityOrder[event1.priority] ?? 3
            let order2 = priorityOrder[event2.priority] ?? 3
            
            if order1 != order2 {
                return order1 < order2
            }
            
            // Then by due date (earliest first)
            if event1.dueDate != event2.dueDate {
                return event1.dueDate < event2.dueDate
            }
            
            // Finally by title (alphabetical)
            return event1.title < event2.title
        }
    }
    
    /// Génère des événements à venir pour un enfant, en ne gardant que la prochaine occurrence par templateId
    /// - Parameters:
    ///   - child: L'enfant pour lequel générer des événements
    ///   - maxMonthsInFuture: Horizon maximum en mois (nil = pas de limite)
    ///   - includeOverdue: Si true, inclut les occurrences en retard
    /// - Returns: Liste d'événements à venir (un seul par templateId)
    func nextOccurrencePerTemplate(for child: Child, maxMonthsInFuture: Int? = nil, includeOverdue: Bool = false) -> [UpcomingEvent] {
        let allEvents = upcomingEvents(for: child, maxMonthsInFuture: maxMonthsInFuture)
        
        // Group events by templateId
        var eventsByTemplate: [String: [UpcomingEvent]] = [:]
        for event in allEvents {
            if eventsByTemplate[event.templateId] == nil {
                eventsByTemplate[event.templateId] = []
            }
            eventsByTemplate[event.templateId]?.append(event)
        }
        
        // For each template, keep only the next occurrence (earliest date >= now)
        var nextOccurrences: [UpcomingEvent] = []
        for (_, events) in eventsByTemplate {
            // Sort by date
            let sortedEvents = events.sorted { $0.dueDate < $1.dueDate }
            
            // Find the first event that is in the future (or now)
            if let nextEvent = sortedEvents.first(where: { $0.dueDate >= referenceDate }) {
                nextOccurrences.append(nextEvent)
            } else if includeOverdue, let lastEvent = sortedEvents.last {
                // If includeOverdue and no future events, include the most recent past event
                nextOccurrences.append(lastEvent)
            }
        }
        
        // Sort by priority, then by date, then by title
        return nextOccurrences.sorted { event1, event2 in
            // First by priority: required > recommended > info
            let priorityOrder: [SuggestionPriority: Int] = [
                .required: 0,
                .recommended: 1,
                .info: 2
            ]
            let order1 = priorityOrder[event1.priority] ?? 3
            let order2 = priorityOrder[event2.priority] ?? 3
            
            if order1 != order2 {
                return order1 < order2
            }
            
            // Then by due date (earliest first)
            if event1.dueDate != event2.dueDate {
                return event1.dueDate < event2.dueDate
            }
            
            // Finally by title (alphabetical)
            return event1.title < event2.title
        }
    }
    
    /// Get overdue events (past due date, required priority only)
    /// - Parameter child: L'enfant pour lequel chercher les retards
    /// - Returns: Liste d'événements en retard
    func overdueEvents(for child: Child) -> [UpcomingEvent] {
        var overdueEvents: [UpcomingEvent] = []
        
        for template in templates {
            // Only check templates with schedule and required priority
            guard let schedule = template.schedule,
                  SuggestionPriority(rawValue: template.priority) == .required else {
                continue
            }
            
            let templateEvents = generateEvents(from: template, schedule: schedule, child: child, maxDate: nil)
            
            // Filter to only past events
            let pastEvents = templateEvents.filter { $0.dueDate < referenceDate }
            
            // Add all past required events as overdue
            overdueEvents.append(contentsOf: pastEvents)
        }
        
        // Sort by priority (all required here), then by date (oldest first), then by title
        return overdueEvents.sorted { event1, event2 in
            // By due date (oldest first for overdue items)
            if event1.dueDate != event2.dueDate {
                return event1.dueDate < event2.dueDate
            }
            
            // Finally by title (alphabetical)
            return event1.title < event2.title
        }
    }
    
    /// Generate events from a template's schedule
    private func generateEvents(from template: DefaultSuggestionTemplate, schedule: DefaultSuggestionTemplate.Schedule, child: Child, maxDate: Date?) -> [UpcomingEvent] {
        var events: [UpcomingEvent] = []
        
        // Generate events from dueAgeMonths
        if let dueAgeMonths = schedule.dueAgeMonths {
            for ageMonths in dueAgeMonths {
                if let dueDate = calendar.date(byAdding: .month, value: ageMonths, to: child.birthDate) {
                    // For upcomingEvents: only include if in the future and within max date if specified
                    // For overdueEvents: include past events too (maxDate will be nil)
                    if maxDate != nil {
                        // For upcoming events with maxDate, only future events
                        if dueDate >= referenceDate {
                            if let maxDate = maxDate {
                                if dueDate <= maxDate {
                                    events.append(UpcomingEvent.from(template: template, dueDate: dueDate))
                                }
                            } else {
                                events.append(UpcomingEvent.from(template: template, dueDate: dueDate))
                            }
                        }
                    } else {
                        // No maxDate means we want all events (for overdue detection)
                        events.append(UpcomingEvent.from(template: template, dueDate: dueDate))
                    }
                }
            }
        }
        
        // Generate event from dueAgeMonthsRange (use middle of range)
        if let range = schedule.dueAgeMonthsRange {
            // Use middle of range with integer division (truncates for odd ranges)
            let middleMonth = (range.min + range.max) / 2
            if let dueDate = calendar.date(byAdding: .month, value: middleMonth, to: child.birthDate) {
                // For upcomingEvents: only include if in the future and within max date if specified
                // For overdueEvents: include past events too (maxDate will be nil)
                if maxDate != nil {
                    // For upcoming events with maxDate, only future events
                    if dueDate >= referenceDate {
                        if let maxDate = maxDate {
                            if dueDate <= maxDate {
                                events.append(UpcomingEvent.from(template: template, dueDate: dueDate))
                            }
                        } else {
                            events.append(UpcomingEvent.from(template: template, dueDate: dueDate))
                        }
                    }
                } else {
                    // No maxDate means we want all events (for overdue detection)
                    events.append(UpcomingEvent.from(template: template, dueDate: dueDate))
                }
            }
        }
        
        return events
    }
}
