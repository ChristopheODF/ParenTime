//
//  NextOccurrenceTests.swift
//  ParenTimeTests
//
//  Created for ParenTime MVP2
//

import Foundation
import Testing
@testable import ParenTime

@Suite("Next Occurrence Per Template Tests")
struct NextOccurrenceTests {
    
    // Helper to create test templates with schedules
    private func createVaccineTemplates() -> [DefaultSuggestionTemplate] {
        return [
            // DTP series at 2, 4, 11 months
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
            // ROR at 12 months
            DefaultSuggestionTemplate(
                id: "ror_1",
                title: "ROR - 1ère dose",
                category: "vaccines",
                priority: "required",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: "Rougeole, Oreillons, Rubéole",
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: [12],
                    dueAgeMonthsRange: nil
                )
            )
        ]
    }
    
    @Test("Should return only next occurrence per template")
    func testNextOccurrencePerTemplate() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: nil)
        
        // Should have 2 events: DTP at 2 months (first occurrence) and ROR at 12 months
        #expect(events.count == 2)
        
        // DTP should only show first occurrence (2 months)
        let dtpEvents = events.filter { $0.templateId == "dtp_series" }
        #expect(dtpEvents.count == 1)
        
        // Verify it's the 2-month occurrence (earliest)
        if let dtpEvent = dtpEvents.first {
            let expectedDate = calendar.date(byAdding: .month, value: 2, to: birthDate)!
            #expect(calendar.isDate(dtpEvent.dueDate, equalTo: expectedDate, toGranularity: .day))
        }
    }
    
    @Test("Should return only future occurrence when some are past")
    func testNextOccurrenceWhenSomePast() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        
        // Child is 5 months old (DTP at 2 and 4 months are past)
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: nil)
        
        // Should have 2 events: DTP at 11 months (next occurrence) and ROR at 12 months
        #expect(events.count == 2)
        
        // DTP should only show 11-month occurrence (next future one)
        let dtpEvents = events.filter { $0.templateId == "dtp_series" }
        #expect(dtpEvents.count == 1)
        
        if let dtpEvent = dtpEvents.first {
            let expectedDate = calendar.date(byAdding: .month, value: 11, to: birthDate)!
            #expect(calendar.isDate(dtpEvent.dueDate, equalTo: expectedDate, toGranularity: .day))
        }
    }
    
    @Test("Should not return any occurrence if all are past and includeOverdue is false")
    func testNoOccurrenceWhenAllPast() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!
        
        // Child is 11 months old (all DTP and ROR are past)
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: nil, includeOverdue: false)
        
        // ROR at 12 months is still in the future (barely)
        #expect(events.count == 1)
        #expect(events.first?.templateId == "ror_1")
    }
    
    @Test("Should include most recent past occurrence when includeOverdue is true")
    func testIncludeOverdue() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2027, month: 6, day: 1))!
        
        // Child is 1.5 years old (all occurrences are past)
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: nil, includeOverdue: true)
        
        // Should have 2 events: DTP at 11 months (most recent) and ROR at 12 months
        #expect(events.count == 2)
        
        // DTP should show 11-month occurrence (most recent)
        let dtpEvents = events.filter { $0.templateId == "dtp_series" }
        #expect(dtpEvents.count == 1)
        
        if let dtpEvent = dtpEvents.first {
            let expectedDate = calendar.date(byAdding: .month, value: 11, to: birthDate)!
            #expect(calendar.isDate(dtpEvent.dueDate, equalTo: expectedDate, toGranularity: .day))
        }
    }
    
    @Test("Should respect maxMonthsInFuture")
    func testMaxMonthsInFutureWithNextOccurrence() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        // Only events within 6 months
        let eventsIn6Months = engine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: 6)
        
        // Should only have DTP at 2 months (first occurrence within 6 months)
        #expect(eventsIn6Months.count == 1)
        #expect(eventsIn6Months.first?.templateId == "dtp_series")
    }
}
