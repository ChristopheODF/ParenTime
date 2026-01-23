//
//  RemindersStore.swift
//  ParenTime
//
//  Created for ParenTime MVP2
//

import Foundation

/// Protocol for managing scheduled reminders persistence
protocol RemindersStore {
    /// Fetch all reminders for a specific child
    func fetchReminders(forChild childId: UUID) async throws -> [ScheduledReminder]
    
    /// Fetch all reminders across all children
    func fetchAllReminders() async throws -> [ScheduledReminder]
    
    /// Add or update a reminder
    func saveReminder(_ reminder: ScheduledReminder) async throws
    
    /// Delete a reminder
    func deleteReminder(id: UUID) async throws
    
    /// Update activation state for a reminder
    func updateActivation(id: UUID, isActivated: Bool) async throws
    
    /// Mark a reminder as completed
    func markCompleted(id: UUID, completedAt: Date) async throws
}
