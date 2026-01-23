//
//  UserDefaultsRemindersStoreTests.swift
//  ParenTimeTests
//
//  Created for ParenTime MVP2
//

import Foundation
import Testing
@testable import ParenTime

@Suite("UserDefaults Reminders Store Tests")
struct UserDefaultsRemindersStoreTests {
    
    // Use a unique suite name for each test to ensure isolation
    private func createStore() -> UserDefaultsRemindersStore {
        let suiteName = "test_\(UUID().uuidString)"
        return UserDefaultsRemindersStore(suiteName: suiteName)
    }
    
    @Test("Should save and fetch reminders")
    func testSaveAndFetch() async throws {
        let store = createStore()
        let childId = UUID()
        
        let reminder = ScheduledReminder(
            childId: childId,
            templateId: "test_template",
            title: "Test Reminder",
            category: .vaccines,
            priority: .required,
            dueDate: Date(),
            description: "Test description"
        )
        
        try await store.saveReminder(reminder)
        let reminders = try await store.fetchReminders(forChild: childId)
        
        #expect(reminders.count == 1)
        #expect(reminders[0].id == reminder.id)
        #expect(reminders[0].title == "Test Reminder")
        #expect(reminders[0].category == .vaccines)
    }
    
    @Test("Should update existing reminder")
    func testUpdateReminder() async throws {
        let store = createStore()
        let childId = UUID()
        
        var reminder = ScheduledReminder(
            childId: childId,
            title: "Original Title",
            category: .vaccines,
            priority: .required,
            dueDate: Date()
        )
        
        try await store.saveReminder(reminder)
        
        // Update reminder
        reminder.isActivated = true
        try await store.saveReminder(reminder)
        
        let reminders = try await store.fetchReminders(forChild: childId)
        
        #expect(reminders.count == 1)
        #expect(reminders[0].isActivated == true)
    }
    
    @Test("Should delete reminder")
    func testDeleteReminder() async throws {
        let store = createStore()
        let childId = UUID()
        
        let reminder = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: Date()
        )
        
        try await store.saveReminder(reminder)
        try await store.deleteReminder(id: reminder.id)
        
        let reminders = try await store.fetchReminders(forChild: childId)
        #expect(reminders.isEmpty)
    }
    
    @Test("Should update activation state")
    func testUpdateActivation() async throws {
        let store = createStore()
        let childId = UUID()
        
        let reminder = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: Date(),
            isActivated: false
        )
        
        try await store.saveReminder(reminder)
        try await store.updateActivation(id: reminder.id, isActivated: true)
        
        let reminders = try await store.fetchReminders(forChild: childId)
        #expect(reminders[0].isActivated == true)
    }
    
    @Test("Should mark reminder as completed")
    func testMarkCompleted() async throws {
        let store = createStore()
        let childId = UUID()
        
        let reminder = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: Date(),
            isCompleted: false
        )
        
        try await store.saveReminder(reminder)
        
        let completedAt = Date()
        try await store.markCompleted(id: reminder.id, completedAt: completedAt)
        
        let reminders = try await store.fetchReminders(forChild: childId)
        #expect(reminders[0].isCompleted == true)
        #expect(reminders[0].completedAt != nil)
    }
    
    @Test("Should filter by child")
    func testFilterByChild() async throws {
        let store = createStore()
        let child1Id = UUID()
        let child2Id = UUID()
        
        let reminder1 = ScheduledReminder(
            childId: child1Id,
            title: "Child 1 Reminder",
            category: .vaccines,
            priority: .required,
            dueDate: Date()
        )
        
        let reminder2 = ScheduledReminder(
            childId: child2Id,
            title: "Child 2 Reminder",
            category: .vaccines,
            priority: .required,
            dueDate: Date()
        )
        
        try await store.saveReminder(reminder1)
        try await store.saveReminder(reminder2)
        
        let child1Reminders = try await store.fetchReminders(forChild: child1Id)
        let child2Reminders = try await store.fetchReminders(forChild: child2Id)
        
        #expect(child1Reminders.count == 1)
        #expect(child1Reminders[0].title == "Child 1 Reminder")
        
        #expect(child2Reminders.count == 1)
        #expect(child2Reminders[0].title == "Child 2 Reminder")
    }
    
    @Test("Should fetch all reminders")
    func testFetchAllReminders() async throws {
        let store = createStore()
        let child1Id = UUID()
        let child2Id = UUID()
        
        let reminder1 = ScheduledReminder(
            childId: child1Id,
            title: "Reminder 1",
            category: .vaccines,
            priority: .required,
            dueDate: Date()
        )
        
        let reminder2 = ScheduledReminder(
            childId: child2Id,
            title: "Reminder 2",
            category: .vaccines,
            priority: .required,
            dueDate: Date()
        )
        
        try await store.saveReminder(reminder1)
        try await store.saveReminder(reminder2)
        
        let allReminders = try await store.fetchAllReminders()
        #expect(allReminders.count == 2)
    }
    
    @Test("Should handle empty store")
    func testEmptyStore() async throws {
        let store = createStore()
        let childId = UUID()
        
        let reminders = try await store.fetchReminders(forChild: childId)
        #expect(reminders.isEmpty)
    }
    
    @Test("Should persist data across instances")
    func testPersistence() async throws {
        let suiteName = "test_persistence_\(UUID().uuidString)"
        let store1 = UserDefaultsRemindersStore(suiteName: suiteName)
        
        let childId = UUID()
        let reminder = ScheduledReminder(
            childId: childId,
            title: "Persisted Reminder",
            category: .vaccines,
            priority: .required,
            dueDate: Date()
        )
        
        try await store1.saveReminder(reminder)
        
        // Create a new store instance with the same suite name
        let store2 = UserDefaultsRemindersStore(suiteName: suiteName)
        let reminders = try await store2.fetchReminders(forChild: childId)
        
        #expect(reminders.count == 1)
        #expect(reminders[0].title == "Persisted Reminder")
    }
    
    @Test("Should encode and decode dates correctly")
    func testDateEncoding() async throws {
        let store = createStore()
        let childId = UUID()
        
        let calendar = Calendar.current
        let dueDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 9, minute: 0))!
        let completedAt = calendar.date(from: DateComponents(year: 2026, month: 6, day: 16, hour: 10, minute: 30))!
        
        let reminder = ScheduledReminder(
            childId: childId,
            title: "Test",
            category: .vaccines,
            priority: .required,
            dueDate: dueDate,
            isCompleted: true,
            completedAt: completedAt
        )
        
        try await store.saveReminder(reminder)
        let reminders = try await store.fetchReminders(forChild: childId)
        
        #expect(reminders[0].dueDate.timeIntervalSince1970 == dueDate.timeIntervalSince1970)
        #expect(reminders[0].completedAt?.timeIntervalSince1970 == completedAt.timeIntervalSince1970)
    }
}
