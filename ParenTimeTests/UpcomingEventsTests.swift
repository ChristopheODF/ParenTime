//
//  UpcomingEventsTests.swift
//  ParenTimeTests
//
//  Created for ParenTime MVP
//

import Foundation
import Testing
@testable import ParenTime

@Suite("Upcoming Events Tests")
struct UpcomingEventsTests {
    
    // Helper to create a child with a specific age in months
    private func createChild(monthsOld: Int, calendar: Calendar = .current, referenceDate: Date) -> Child {
        let birthDate = calendar.date(byAdding: .month, value: -monthsOld, to: referenceDate)!
        return Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
    }
    
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
            ),
            // ROR 2nd dose at 16-18 months range
            DefaultSuggestionTemplate(
                id: "ror_2",
                title: "ROR - 2ème dose",
                category: "vaccines",
                priority: "recommended",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: nil,
                    maxAge: nil,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: "Rappel ROR",
                schedule: DefaultSuggestionTemplate.Schedule(
                    dueAgeMonths: nil,
                    dueAgeMonthsRange: DefaultSuggestionTemplate.ScheduleRange(min: 16, max: 18)
                )
            ),
            // HPV without schedule (year-based)
            DefaultSuggestionTemplate(
                id: "hpv_vaccination",
                title: "Vaccination HPV",
                category: "vaccines",
                priority: "recommended",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: 11,
                    maxAge: 14,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00",
                description: "Papillomavirus",
                schedule: nil
            )
        ]
    }
    
    // MARK: - Event Generation Tests
    
    @Test("Newborn should have all future vaccine events generated")
    func testNewbornVaccineEvents() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        
        // Should have events for: DTP (2, 4, 11 months), ROR 1 (12 months), ROR 2 (17 months middle of 16-18)
        #expect(events.count == 5)
        
        // Check DTP events exist
        let dtpEvents = events.filter { $0.templateId == "dtp_series" }
        #expect(dtpEvents.count == 3)
        
        // Check ROR events
        let ror1Events = events.filter { $0.templateId == "ror_1" }
        #expect(ror1Events.count == 1)
        
        let ror2Events = events.filter { $0.templateId == "ror_2" }
        #expect(ror2Events.count == 1)
    }
    
    @Test("Events should be in the future only")
    func testOnlyFutureEvents() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        
        // Child is 5 months old
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        
        // Should NOT include DTP at 2 and 4 months (in the past)
        // Should include DTP at 11 months, ROR at 12 and 17 months
        #expect(events.count == 3)
        
        // Verify all events are in the future
        for event in events {
            #expect(event.dueDate >= referenceDate)
        }
    }
    
    @Test("Events respect maxMonthsInFuture limit")
    func testMaxMonthsInFutureLimit() {
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
        let eventsIn6Months = engine.upcomingEvents(for: child, maxMonthsInFuture: 6)
        
        // Should only have DTP at 2 and 4 months
        #expect(eventsIn6Months.count == 2)
        
        // Only events within 12 months
        let eventsIn12Months = engine.upcomingEvents(for: child, maxMonthsInFuture: 12)
        
        // Should have DTP (2, 4, 11 months) and ROR 1 (12 months)
        #expect(eventsIn12Months.count == 4)
    }
    
    // MARK: - Sorting Tests
    
    @Test("Events should be sorted by priority first")
    func testSortingByPriority() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        
        // First event should be required priority (DTP at 2 months)
        #expect(events.first?.priority == .required)
        
        // Count required vs recommended
        let requiredCount = events.filter { $0.priority == .required }.count
        let recommendedCount = events.filter { $0.priority == .recommended }.count
        
        #expect(requiredCount == 4) // DTP (3) + ROR 1 (1)
        #expect(recommendedCount == 1) // ROR 2
        
        // All required should come before recommended
        var seenRecommended = false
        for event in events {
            if event.priority == .recommended {
                seenRecommended = true
            }
            if seenRecommended {
                #expect(event.priority != .required, "Required should not come after recommended")
            }
        }
    }
    
    @Test("Events with same priority should be sorted by date")
    func testSortingByDateWithinSamePriority() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        
        // Get all required priority events
        let requiredEvents = events.filter { $0.priority == .required }
        
        // They should be sorted by date
        for i in 0..<(requiredEvents.count - 1) {
            #expect(requiredEvents[i].dueDate <= requiredEvents[i + 1].dueDate)
        }
    }
    
    @Test("Events with same priority and date should be sorted alphabetically")
    func testSortingAlphabetically() {
        // Create templates with same due date but different titles
        let templates = [
            DefaultSuggestionTemplate(
                id: "vaccine_z",
                title: "Vaccin Z",
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
                )
            ),
            DefaultSuggestionTemplate(
                id: "vaccine_a",
                title: "Vaccin A",
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
                )
            )
        ]
        
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: templates
        )
        
        let events = engine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        
        #expect(events.count == 2)
        #expect(events[0].title == "Vaccin A")
        #expect(events[1].title == "Vaccin Z")
    }
    
    // MARK: - Due Date Calculation Tests
    
    @Test("Due dates should be calculated correctly from birth date")
    func testDueDateCalculation() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        
        // Find DTP event at 2 months (first DTP event)
        let dtpEvents = events.filter { $0.templateId == "dtp_series" }
        let dtp2Months = dtpEvents.first
        #expect(dtp2Months != nil)
        
        if let event = dtp2Months {
            // Due date should be approximately 2 months after birth date
            let expectedDate = calendar.date(byAdding: .month, value: 2, to: birthDate)!
            #expect(calendar.isDate(event.dueDate, equalTo: expectedDate, toGranularity: .day))
        }
    }
    
    @Test("Range-based schedules should use middle of range for due date")
    func testRangeBasedDueDate() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        
        // Find ROR 2 event (16-18 months range)
        let ror2 = events.first { $0.templateId == "ror_2" }
        #expect(ror2 != nil)
        
        if let event = ror2 {
            // Due date should be at 17 months (middle of 16-18)
            let expectedDate = calendar.date(byAdding: .month, value: 17, to: birthDate)!
            #expect(calendar.isDate(event.dueDate, equalTo: expectedDate, toGranularity: .day))
        }
    }
    
    // MARK: - Category Filtering Tests
    
    @Test("Can filter events by category")
    func testCategoryFiltering() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let allEvents = engine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        let vaccineEvents = allEvents.filter { $0.category == .vaccines }
        
        // All events should be vaccines in this test
        #expect(vaccineEvents.count == allEvents.count)
        
        // Verify all are vaccines
        for event in vaccineEvents {
            #expect(event.category == .vaccines)
        }
    }
    
    // MARK: - Edge Cases
    
    @Test("Templates without schedule should not generate events")
    func testNoScheduleNoEvents() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2014, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: createVaccineTemplates()
        )
        
        let events = engine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        
        // HPV has no schedule, should not generate any events
        let hpvEvents = events.filter { $0.templateId == "hpv_vaccination" }
        #expect(hpvEvents.isEmpty)
    }
    
    @Test("Empty templates should return empty events")
    func testEmptyTemplates() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(
            calendar: calendar,
            referenceDate: referenceDate,
            templates: []
        )
        
        let events = engine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        #expect(events.isEmpty)
    }
}
