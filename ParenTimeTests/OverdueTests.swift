//
//  OverdueTests.swift
//  ParenTimeTests
//
//  Created for ParenTime MVP2
//

import Foundation
import Testing
@testable import ParenTime

@Suite("Overdue Events Tests")
struct OverdueTests {
    
    private func createVaccineTemplates() -> [DefaultSuggestionTemplate] {
        return [
            // DTP series at 2, 4, 11 months (required)
            DefaultSuggestionTemplate(
                id: "dtp_series",
                title: "DTP - Série complète",
                category: "vaccines",
                priority: "required",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: "Diphtérie, Tétanos, Poliomyélite",
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: [2, 4, 11],
                    dueAgeMonthsRange: nil
                )
            ),
            // Rotavirus (recommended, should not be included in overdue)
            DefaultSuggestionTemplate(
                id: "rotavirus_1",
                title: "Rotavirus - 1ère dose",
                category: "vaccines",
                priority: "recommended",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: "Gastro-entérites",
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: [2],
                    dueAgeMonthsRange: nil
                )
            )
        ]
    }
    
    @Test("Should detect overdue required vaccines")
    func testOverdueDetection() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        
        // Child is 5 months old (DTP at 2 and 4 months are overdue)
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let overdueEvents = engine.overdueEvents(for: child)
        
        // Should have 2 overdue events: DTP at 2 and 4 months
        #expect(overdueEvents.count == 2)
        
        // All should be DTP (required)
        for event in overdueEvents {
            #expect(event.templateId == "dtp_series")
            #expect(event.priority == .required)
            #expect(event.dueDate < referenceDate)
        }
    }
    
    @Test("Should not include recommended vaccines in overdue")
    func testOnlyRequiredOverdue() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        
        // Child is 5 months old (Rotavirus at 2 months is past but should not be overdue)
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let overdueEvents = engine.overdueEvents(for: child)
        
        // Should not include rotavirus (recommended)
        let rotavirusEvents = overdueEvents.filter { $0.templateId == "rotavirus_1" }
        #expect(rotavirusEvents.isEmpty)
    }
    
    @Test("Should return empty when no overdue events")
    func testNoOverdueEvents() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        
        // Newborn (no overdue events)
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let overdueEvents = engine.overdueEvents(for: child)
        
        #expect(overdueEvents.isEmpty)
    }
    
    @Test("Should sort overdue events by date (oldest first)")
    func testOverdueSorting() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 12, day: 1))!
        
        // Child is 11 months old (all DTP doses are overdue)
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let overdueEvents = engine.overdueEvents(for: child)
        
        // Should have 3 overdue events
        #expect(overdueEvents.count == 3)
        
        // Should be sorted by date (oldest first)
        for i in 0..<(overdueEvents.count - 1) {
            #expect(overdueEvents[i].dueDate <= overdueEvents[i + 1].dueDate)
        }
        
        // First should be 2 months, then 4 months, then 11 months
        let expectedMonths = [2, 4, 11]
        for (index, expectedMonth) in expectedMonths.enumerated() {
            let expectedDate = calendar.date(byAdding: .month, value: expectedMonth, to: birthDate)!
            #expect(calendar.isDate(overdueEvents[index].dueDate, equalTo: expectedDate, toGranularity: .day))
        }
    }
}

@Suite("ScheduledReminder Overdue Tests")
struct ScheduledReminderOverdueTests {
    
    @Test("Should correctly detect overdue reminders")
    func testIsOverdue() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let pastDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let futureDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
        
        let childId = UUID()
        
        // Past, not completed = overdue
        let overdueReminder = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: pastDate,
            isCompleted: false
        )
        #expect(overdueReminder.isOverdue(at: referenceDate))
        
        // Past but completed = not overdue
        let completedReminder = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: pastDate,
            isCompleted: true
        )
        #expect(!completedReminder.isOverdue(at: referenceDate))
        
        // Future = not overdue
        let futureReminder = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: futureDate,
            isCompleted: false
        )
        #expect(!futureReminder.isOverdue(at: referenceDate))
    }
    
    @Test("Should generate correct late since text")
    func testLateSinceText() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let childId = UUID()
        
        // 1 day late
        let oneDayLate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 31))!
        let reminder1 = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: oneDayLate,
            isCompleted: false
        )
        #expect(reminder1.lateSinceText(at: referenceDate, calendar: calendar) == "En retard depuis 1 jour")
        
        // 5 days late
        let fiveDaysLate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 27))!
        let reminder2 = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: fiveDaysLate,
            isCompleted: false
        )
        #expect(reminder2.lateSinceText(at: referenceDate, calendar: calendar) == "En retard depuis 5 jours")
        
        // 1 month late
        let oneMonthLate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let reminder3 = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: oneMonthLate,
            isCompleted: false
        )
        #expect(reminder3.lateSinceText(at: referenceDate, calendar: calendar) == "En retard depuis 1 mois")
        
        // 3 months late
        let threeMonthsLate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let reminder4 = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: threeMonthsLate,
            isCompleted: false
        )
        #expect(reminder4.lateSinceText(at: referenceDate, calendar: calendar) == "En retard depuis 3 mois")
        
        // Not late
        let futureDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
        let futureReminder = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: futureDate,
            isCompleted: false
        )
        #expect(futureReminder.lateSinceText(at: referenceDate, calendar: calendar) == nil)
    }
}
