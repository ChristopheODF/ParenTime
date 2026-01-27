//
//  SeriesGroupingTests.swift
//  ParenTimeTests
//
//  Created for ParenTime MVP2
//

import Foundation
import Testing
@testable import ParenTime

@Suite("Series Grouping Tests")
struct SeriesGroupingTests {
    
    // Helper to create test templates with seriesId
    private func createSeriesTemplates() -> [DefaultSuggestionTemplate] {
        return [
            // DTP series with seriesId
            DefaultSuggestionTemplate(
                id: "dtp_coqueluche_1",
                title: "DTP et Coqueluche - 1ère dose",
                category: "vaccines",
                priority: "required",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: "Vaccination à 2 mois",
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: [2],
                    dueAgeMonthsRange: nil
                ),
                seriesId: "dtp_coqueluche"
            ),
            DefaultSuggestionTemplate(
                id: "dtp_coqueluche_2",
                title: "DTP et Coqueluche - 2ème dose",
                category: "vaccines",
                priority: "required",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: "Vaccination à 4 mois",
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: [4],
                    dueAgeMonthsRange: nil
                ),
                seriesId: "dtp_coqueluche"
            ),
            DefaultSuggestionTemplate(
                id: "dtp_coqueluche_3",
                title: "DTP et Coqueluche - 3ème dose",
                category: "vaccines",
                priority: "required",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: "Vaccination à 11 mois",
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: [11],
                    dueAgeMonthsRange: nil
                ),
                seriesId: "dtp_coqueluche"
            ),
            // ROR series with seriesId
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
                description: "Vaccination à 12 mois",
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: [12],
                    dueAgeMonthsRange: nil
                ),
                seriesId: "ror"
            ),
            DefaultSuggestionTemplate(
                id: "ror_2",
                title: "ROR - 2ème dose",
                category: "vaccines",
                priority: "required",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: "Vaccination entre 16 et 18 mois",
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: nil,
                    dueAgeMonthsRange: DefaultSuggestionTemplate.ScheduleRange(min: 16, max: 18)
                ),
                seriesId: "ror"
            ),
            // Single vaccine without seriesId
            DefaultSuggestionTemplate(
                id: "bcg_vaccination",
                title: "BCG",
                category: "vaccines",
                priority: "recommended",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: "Vaccination à la naissance",
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: [0],
                    dueAgeMonthsRange: nil
                ),
                seriesId: nil
            )
        ]
    }
    
    @Test("Should group by seriesId and return only next occurrence per series")
    func testGroupingBySeriesId() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createSeriesTemplates()
        )
        
        let events = engine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: nil)
        
        // Should have 3 events total:
        // - DTP series: only the first dose (2 months)
        // - ROR series: only the first dose (12 months)
        // - BCG: single vaccine (0 months)
        #expect(events.count == 3)
        
        // Check DTP series - should only have first occurrence
        let dtpEvents = events.filter { $0.seriesId == "dtp_coqueluche" }
        #expect(dtpEvents.count == 1)
        
        if let dtpEvent = dtpEvents.first {
            #expect(dtpEvent.templateId == "dtp_coqueluche_1")
            let expectedDate = calendar.date(byAdding: .month, value: 2, to: birthDate)!
            #expect(calendar.isDate(dtpEvent.dueDate, equalTo: expectedDate, toGranularity: .day))
        }
        
        // Check ROR series - should only have first occurrence
        let rorEvents = events.filter { $0.seriesId == "ror" }
        #expect(rorEvents.count == 1)
        
        if let rorEvent = rorEvents.first {
            #expect(rorEvent.templateId == "ror_1")
            let expectedDate = calendar.date(byAdding: .month, value: 12, to: birthDate)!
            #expect(calendar.isDate(rorEvent.dueDate, equalTo: expectedDate, toGranularity: .day))
        }
        
        // Check BCG - single vaccine without seriesId
        let bcgEvents = events.filter { $0.templateId == "bcg_vaccination" }
        #expect(bcgEvents.count == 1)
    }
    
    @Test("Should return next future occurrence when some doses are past")
    func testNextOccurrenceWhenSomeDosesPast() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        
        // Child is 5 months old (DTP at 2 and 4 months are past)
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createSeriesTemplates()
        )
        
        let events = engine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: nil)
        
        // Check DTP series - should show third dose (11 months) as next occurrence
        let dtpEvents = events.filter { $0.seriesId == "dtp_coqueluche" }
        #expect(dtpEvents.count == 1)
        
        if let dtpEvent = dtpEvents.first {
            #expect(dtpEvent.templateId == "dtp_coqueluche_3")
            let expectedDate = calendar.date(byAdding: .month, value: 11, to: birthDate)!
            #expect(calendar.isDate(dtpEvent.dueDate, equalTo: expectedDate, toGranularity: .day))
        }
    }
    
    @Test("Templates without seriesId should still work independently")
    func testTemplatesWithoutSeriesId() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        // Create templates without seriesId (old behavior)
        let templatesWithoutSeries = [
            DefaultSuggestionTemplate(
                id: "vaccine_a_2m",
                title: "Vaccine A - 2 months",
                category: "vaccines",
                priority: "required",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: nil,
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: [2],
                    dueAgeMonthsRange: nil
                ),
                seriesId: nil
            ),
            DefaultSuggestionTemplate(
                id: "vaccine_b_2m",
                title: "Vaccine B - 2 months",
                category: "vaccines",
                priority: "required",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: nil,
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: [2],
                    dueAgeMonthsRange: nil
                ),
                seriesId: nil
            )
        ]
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: templatesWithoutSeries
        )
        
        let events = engine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: nil)
        
        // Should have 2 events - one for each template (no grouping)
        #expect(events.count == 2)
    }
    
    @Test("UpcomingEvent should preserve seriesId from template")
    func testUpcomingEventPreservesSeriesId() {
        let template = DefaultSuggestionTemplate(
            id: "test_id",
            title: "Test Vaccine",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: nil,
            schedule: nil,
            seriesId: "test_series"
        )
        
        let dueDate = Date()
        let event = UpcomingEvent.from(template: template, dueDate: dueDate)
        
        #expect(event.seriesId == "test_series")
        #expect(event.templateId == "test_id")
    }
}
