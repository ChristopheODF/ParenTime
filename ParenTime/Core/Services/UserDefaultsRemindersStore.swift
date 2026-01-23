//
//  UserDefaultsRemindersStore.swift
//  ParenTime
//
//  Created for ParenTime MVP2
//

import Foundation

/// UserDefaults-based implementation of RemindersStore
/// Uses a dedicated suite name for isolation and testing
actor UserDefaultsRemindersStore: RemindersStore {
    private let userDefaults: UserDefaults
    private let remindersKey = "scheduled_reminders"
    
    init(suiteName: String? = nil) {
        if let suiteName = suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.userDefaults = .standard
        }
    }
    
    // MARK: - RemindersStore Protocol
    
    func fetchReminders(forChild childId: UUID) async throws -> [ScheduledReminder] {
        let allReminders = try await fetchAllReminders()
        return allReminders.filter { $0.childId == childId }
    }
    
    func fetchAllReminders() async throws -> [ScheduledReminder] {
        let data = await MainActor.run {
            userDefaults.data(forKey: remindersKey)
        }
        
        guard let data = data else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([ScheduledReminder].self, from: data)
        } catch {
            // If decode fails, return empty and log error
            print("Error decoding reminders: \(error)")
            return []
        }
    }
    
    func saveReminder(_ reminder: ScheduledReminder) async throws {
        var reminders = try await fetchAllReminders()
        
        // Remove existing reminder with same ID if present
        reminders.removeAll { $0.id == reminder.id }
        
        // Add the new/updated reminder
        reminders.append(reminder)
        
        // Save to UserDefaults
        try await saveAllReminders(reminders)
    }
    
    func deleteReminder(id: UUID) async throws {
        var reminders = try await fetchAllReminders()
        reminders.removeAll { $0.id == id }
        try await saveAllReminders(reminders)
    }
    
    func updateActivation(id: UUID, isActivated: Bool) async throws {
        var reminders = try await fetchAllReminders()
        
        if let index = reminders.firstIndex(where: { $0.id == id }) {
            reminders[index].isActivated = isActivated
            try await saveAllReminders(reminders)
        }
    }
    
    func markCompleted(id: UUID, completedAt: Date) async throws {
        var reminders = try await fetchAllReminders()
        
        if let index = reminders.firstIndex(where: { $0.id == id }) {
            reminders[index].isCompleted = true
            reminders[index].completedAt = completedAt
            try await saveAllReminders(reminders)
        }
    }
    
    // MARK: - Private Helpers
    
    private func saveAllReminders(_ reminders: [ScheduledReminder]) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(reminders)
        
        // UserDefaults operations should be on main actor for thread safety
        await MainActor.run {
            userDefaults.set(data, forKey: remindersKey)
        }
    }
    
    /// Clear all reminders (useful for testing)
    func clearAll() async throws {
        await MainActor.run {
            userDefaults.removeObject(forKey: remindersKey)
        }
    }
}
