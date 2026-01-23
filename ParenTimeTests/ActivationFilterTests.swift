//
//  ActivationFilterTests.swift
//  ParenTimeTests
//
//  Created for ParenTime MVP2
//

import Foundation
import Testing
@testable import ParenTime

@Suite("Activation Filter Tests")
struct ActivationFilterTests {
    
    /// Helper to filter events by activation state
    private func filterByActivation(events: [UpcomingEvent], reminders: [ScheduledReminder]) -> [UpcomingEvent] {
        return events.filter { event in
            if let reminder = reminders.first(where: { $0.templateId == event.templateId && !$0.isCompleted }) {
                return reminder.isActivated
            }
            return false
        }
    }
    
    @Test("Should filter upcoming events to only show activated reminders")
    func testFilterActivatedReminders() {
        let calendar = Calendar.current
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        // Create test events
        let dueDate1 = calendar.date(byAdding: .month, value: 2, to: birthDate)!
        let dueDate2 = calendar.date(byAdding: .month, value: 4, to: birthDate)!
        
        let event1 = UpcomingEvent(
            templateId: "vaccine_1",
            title: "Vaccine 1",
            category: .vaccines,
            priority: .required,
            dueDate: dueDate1
        )
        
        let event2 = UpcomingEvent(
            templateId: "vaccine_2",
            title: "Vaccine 2",
            category: .vaccines,
            priority: .required,
            dueDate: dueDate2
        )
        
        // Create scheduled reminders - only vaccine_1 is activated
        let reminder1 = ScheduledReminder(
            childId: child.id,
            templateId: "vaccine_1",
            title: "Vaccine 1",
            category: .vaccines,
            priority: .required,
            dueDate: dueDate1,
            isActivated: true,
            isCompleted: false
        )
        
        let reminder2 = ScheduledReminder(
            childId: child.id,
            templateId: "vaccine_2",
            title: "Vaccine 2",
            category: .vaccines,
            priority: .required,
            dueDate: dueDate2,
            isActivated: false,
            isCompleted: false
        )
        
        let scheduledReminders = [reminder1, reminder2]
        let allEvents = [event1, event2]
        
        // Filter events using helper
        let filteredEvents = filterByActivation(events: allEvents, reminders: scheduledReminders)
        
        // Should only have event1 (activated)
        #expect(filteredEvents.count == 1)
        #expect(filteredEvents.first?.templateId == "vaccine_1")
    }
    
    @Test("Should not show events without any reminder")
    func testNoReminderNoDisplay() {
        let calendar = Calendar.current
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let dueDate = calendar.date(byAdding: .month, value: 2, to: birthDate)!
        
        let event = UpcomingEvent(
            templateId: "vaccine_1",
            title: "Vaccine 1",
            category: .vaccines,
            priority: .required,
            dueDate: dueDate
        )
        
        // No scheduled reminders
        let scheduledReminders: [ScheduledReminder] = []
        let allEvents = [event]
        
        // Filter events using helper
        let filteredEvents = filterByActivation(events: allEvents, reminders: scheduledReminders)
        
        // Should be empty (no reminder = not shown)
        #expect(filteredEvents.isEmpty)
    }
    
    @Test("Should not show completed reminders even if activated")
    func testCompletedNotShown() {
        let calendar = Calendar.current
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let dueDate = calendar.date(byAdding: .month, value: 2, to: birthDate)!
        
        let event = UpcomingEvent(
            templateId: "vaccine_1",
            title: "Vaccine 1",
            category: .vaccines,
            priority: .required,
            dueDate: dueDate
        )
        
        // Reminder is activated but completed
        let reminder = ScheduledReminder(
            childId: child.id,
            templateId: "vaccine_1",
            title: "Vaccine 1",
            category: .vaccines,
            priority: .required,
            dueDate: dueDate,
            isActivated: true,
            isCompleted: true
        )
        
        let scheduledReminders = [reminder]
        let allEvents = [event]
        
        // Filter events using helper
        let filteredEvents = filterByActivation(events: allEvents, reminders: scheduledReminders)
        
        // Should be empty (completed = not shown)
        #expect(filteredEvents.isEmpty)
    }
}

@Suite("Stable ID Tests")
struct StableIDTests {
    
    @Test("Should generate stable IDs for occurrences")
    func testStableOccurrenceIDs() {
        let calendar = Calendar.current
        let dueDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        
        let template = DefaultSuggestionTemplate(
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
            schedule: nil
        )
        
        // Create two events with same template and due date
        let event1 = UpcomingEvent.from(template: template, dueDate: dueDate)
        let event2 = UpcomingEvent.from(template: template, dueDate: dueDate)
        
        // IDs should be identical (stable)
        #expect(event1.id == event2.id)
        
        // ID should contain template ID and date
        #expect(event1.id.contains("dtp_series"))
        #expect(event1.id.contains("2026-03-01"))
    }
    
    @Test("Should generate different IDs for different dates")
    func testDifferentDatesGenerateDifferentIDs() {
        let calendar = Calendar.current
        let dueDate1 = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let dueDate2 = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        
        let template = DefaultSuggestionTemplate(
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
            schedule: nil
        )
        
        let event1 = UpcomingEvent.from(template: template, dueDate: dueDate1)
        let event2 = UpcomingEvent.from(template: template, dueDate: dueDate2)
        
        // IDs should be different (different dates)
        #expect(event1.id != event2.id)
    }
}
