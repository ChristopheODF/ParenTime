//
//  DefaultSuggestionTemplate.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation

/// Template for default suggestion with conditions
struct DefaultSuggestionTemplate: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let category: String
    let priority: String
    let conditions: Conditions
    let defaultNotificationTime: String
    let description: String?
    let schedule: Schedule?
    
    struct Conditions: Codable, Equatable {
        let minAge: Int?
        let maxAge: Int?
        let minBirthDate: String?
        let maxBirthDate: String?
    }
    
    struct Schedule: Codable, Equatable {
        let dueAgeMonths: [Int]?
        let dueAgeMonthsRange: ScheduleRange?
    }
    
    struct ScheduleRange: Codable, Equatable {
        let min: Int
        let max: Int
    }
    
    /// Check if this template is applicable to a child at a given date
    /// - Parameters:
    ///   - child: The child to check
    ///   - referenceDate: The date to use for age calculation
    ///   - calendar: The calendar to use for calculations
    /// - Returns: true if the template conditions are met
    func isApplicable(to child: Child, at referenceDate: Date = Date(), calendar: Calendar = .current) -> Bool {
        // Check month-based schedule first (higher priority)
        if let schedule = schedule {
            return isScheduleApplicable(schedule: schedule, child: child, at: referenceDate, calendar: calendar)
        }
        
        // Fall back to year-based age conditions
        if let age = child.age(at: referenceDate, calendar: calendar) {
            if let minAge = conditions.minAge, age < minAge {
                return false
            }
            if let maxAge = conditions.maxAge, age > maxAge {
                return false
            }
        } else {
            // If we can't calculate age and age conditions exist, not applicable
            if conditions.minAge != nil || conditions.maxAge != nil {
                return false
            }
        }
        
        // Check birth date conditions
        let birthDate = child.birthDate
        
        if let minBirthDateString = conditions.minBirthDate,
           let minBirthDate = parseDate(minBirthDateString) {
            if birthDate < minBirthDate {
                return false
            }
        }
        
        if let maxBirthDateString = conditions.maxBirthDate,
           let maxBirthDate = parseDate(maxBirthDateString) {
            if birthDate > maxBirthDate {
                return false
            }
        }
        
        return true
    }
    
    /// Check if the schedule is applicable to a child
    private func isScheduleApplicable(schedule: Schedule, child: Child, at referenceDate: Date, calendar: Calendar) -> Bool {
        guard let ageInMonths = child.ageInMonths(at: referenceDate, calendar: calendar) else {
            return false
        }
        
        // Check dueAgeMonths with ±1 month tolerance
        if let dueAgeMonths = schedule.dueAgeMonths {
            for dueMonth in dueAgeMonths {
                // Applicable if ageInMonths is within [dueMonth-1, dueMonth+1]
                if ageInMonths >= dueMonth - 1 && ageInMonths <= dueMonth + 1 {
                    return true
                }
            }
            return false
        }
        
        // Check dueAgeMonthsRange with ±1 month tolerance
        if let range = schedule.dueAgeMonthsRange {
            // Applicable if ageInMonths is within [min-1, max+1]
            return ageInMonths >= range.min - 1 && ageInMonths <= range.max + 1
        }
        
        // Schedule exists but no criteria specified - not applicable
        // Note: A valid schedule should have at least one of dueAgeMonths or dueAgeMonthsRange
        return false
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: dateString)
    }
}
