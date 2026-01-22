//
//  DashboardPrioritizerTests.swift
//  ParenTimeTests
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation
import Testing
@testable import ParenTime

@Suite("DashboardPrioritizer Tests")
struct DashboardPrioritizerTests {
    
    // Helper to create reference date
    private func createDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
    
    @Test("Empty items should return empty now and upcoming")
    func testEmptyItems() {
        let referenceDate = createDate(2026, 1, 22)
        let prioritizer = DashboardPrioritizer(referenceDate: referenceDate)
        
        let result = prioritizer.prioritize(items: [])
        
        #expect(result.now.isEmpty)
        #expect(result.upcoming.isEmpty)
    }
    
    @Test("Suggestions should appear in now section")
    func testSuggestionsInNow() {
        let referenceDate = createDate(2026, 1, 22)
        let prioritizer = DashboardPrioritizer(referenceDate: referenceDate)
        
        let suggestion = ReminderSuggestion.hpvVaccination
        let items = [DashboardItem.suggestion(suggestion)]
        
        let result = prioritizer.prioritize(items: items)
        
        #expect(result.now.count == 1)
        #expect(result.upcoming.isEmpty)
    }
    
    @Test("Urgent reminders (within 7 days) should appear in now section")
    func testUrgentRemindersInNow() {
        let referenceDate = createDate(2026, 1, 22)
        let prioritizer = DashboardPrioritizer(referenceDate: referenceDate)
        
        // Create reminders for tomorrow and in 5 days
        let tomorrow = createDate(2026, 1, 23)
        let in5Days = createDate(2026, 1, 27)
        
        let reminder1 = ActiveReminder(
            type: .vaccine,
            title: "Rappel 1",
            description: "Test",
            dueDate: tomorrow
        )
        let reminder2 = ActiveReminder(
            type: .vaccine,
            title: "Rappel 2",
            description: "Test",
            dueDate: in5Days
        )
        
        let items = [
            DashboardItem.reminder(reminder1),
            DashboardItem.reminder(reminder2)
        ]
        
        let result = prioritizer.prioritize(items: items)
        
        #expect(result.now.count == 2)
        #expect(result.upcoming.isEmpty)
    }
    
    @Test("Non-urgent reminders (after 7 days) should appear in upcoming section")
    func testNonUrgentRemindersInUpcoming() {
        let referenceDate = createDate(2026, 1, 22)
        let prioritizer = DashboardPrioritizer(referenceDate: referenceDate)
        
        // Create reminders for 10 days and 15 days from now
        let in10Days = createDate(2026, 2, 1)
        let in15Days = createDate(2026, 2, 6)
        
        let reminder1 = ActiveReminder(
            type: .vaccine,
            title: "Rappel 1",
            description: "Test",
            dueDate: in10Days
        )
        let reminder2 = ActiveReminder(
            type: .vaccine,
            title: "Rappel 2",
            description: "Test",
            dueDate: in15Days
        )
        
        let items = [
            DashboardItem.reminder(reminder1),
            DashboardItem.reminder(reminder2)
        ]
        
        let result = prioritizer.prioritize(items: items)
        
        #expect(result.now.isEmpty)
        #expect(result.upcoming.count == 2)
    }
    
    @Test("Mix of suggestions and reminders should be prioritized correctly")
    func testMixedItems() {
        let referenceDate = createDate(2026, 1, 22)
        let prioritizer = DashboardPrioritizer(referenceDate: referenceDate)
        
        let suggestion = ReminderSuggestion.hpvVaccination
        let urgentReminder = ActiveReminder(
            type: .vaccine,
            title: "Urgent",
            description: "Test",
            dueDate: createDate(2026, 1, 25)
        )
        let upcomingReminder = ActiveReminder(
            type: .vaccine,
            title: "Upcoming",
            description: "Test",
            dueDate: createDate(2026, 2, 5)
        )
        
        let items = [
            DashboardItem.suggestion(suggestion),
            DashboardItem.reminder(urgentReminder),
            DashboardItem.reminder(upcomingReminder)
        ]
        
        let result = prioritizer.prioritize(items: items)
        
        #expect(result.now.count == 2) // urgent reminder + suggestion
        #expect(result.upcoming.count == 1) // upcoming reminder
    }
    
    @Test("Now items should be limited to maxNow")
    func testMaxNowLimit() {
        let referenceDate = createDate(2026, 1, 22)
        let prioritizer = DashboardPrioritizer(referenceDate: referenceDate)
        
        // Create 5 urgent reminders
        let items = (0..<5).map { i in
            DashboardItem.reminder(ActiveReminder(
                type: .vaccine,
                title: "Rappel \(i)",
                description: "Test",
                dueDate: createDate(2026, 1, 23 + i)
            ))
        }
        
        let result = prioritizer.prioritize(items: items, maxNow: 3)
        
        #expect(result.now.count == 3)
    }
    
    @Test("Upcoming items should be limited to maxUpcoming")
    func testMaxUpcomingLimit() {
        let referenceDate = createDate(2026, 1, 22)
        let prioritizer = DashboardPrioritizer(referenceDate: referenceDate)
        
        // Create 5 non-urgent reminders
        let items = (0..<5).map { i in
            DashboardItem.reminder(ActiveReminder(
                type: .vaccine,
                title: "Rappel \(i)",
                description: "Test",
                dueDate: createDate(2026, 2, 1 + i)
            ))
        }
        
        let result = prioritizer.prioritize(items: items, maxUpcoming: 3)
        
        #expect(result.upcoming.count == 3)
    }
    
    @Test("Urgent reminders should be sorted by due date")
    func testUrgentRemindersSorted() {
        let referenceDate = createDate(2026, 1, 22)
        let prioritizer = DashboardPrioritizer(referenceDate: referenceDate)
        
        let reminder1 = ActiveReminder(
            type: .vaccine,
            title: "Later",
            description: "Test",
            dueDate: createDate(2026, 1, 27)
        )
        let reminder2 = ActiveReminder(
            type: .vaccine,
            title: "Sooner",
            description: "Test",
            dueDate: createDate(2026, 1, 23)
        )
        
        let items = [
            DashboardItem.reminder(reminder1),
            DashboardItem.reminder(reminder2)
        ]
        
        let result = prioritizer.prioritize(items: items)
        
        #expect(result.now.count == 2)
        // First item should be the sooner one
        if case .reminder(let firstReminder) = result.now[0] {
            #expect(firstReminder.title == "Sooner")
        }
    }
}
