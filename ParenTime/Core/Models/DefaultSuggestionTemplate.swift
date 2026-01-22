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
    
    struct Conditions: Codable, Equatable {
        let minAge: Int?
        let maxAge: Int?
        let minBirthDate: String?
        let maxBirthDate: String?
    }
    
    /// Check if this template is applicable to a child at a given date
    /// - Parameters:
    ///   - child: The child to check
    ///   - referenceDate: The date to use for age calculation
    ///   - calendar: The calendar to use for calculations
    /// - Returns: true if the template conditions are met
    func isApplicable(to child: Child, at referenceDate: Date = Date(), calendar: Calendar = .current) -> Bool {
        // Check age conditions
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
            if birthDate >= maxBirthDate {
                return false
            }
        }
        
        return true
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: dateString)
    }
}
