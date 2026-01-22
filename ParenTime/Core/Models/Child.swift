//
//  Child.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation

/// Modèle représentant un enfant
struct Child: Identifiable, Codable, Equatable {
    let id: UUID
    var firstName: String
    var lastName: String
    var birthDate: Date
    
    init(id: UUID = UUID(), firstName: String, lastName: String, birthDate: Date) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.birthDate = birthDate
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    /// Calculate the age of the child at a given date
    /// - Parameters:
    ///   - date: The reference date for age calculation (defaults to now)
    ///   - calendar: The calendar to use for calculation (defaults to current)
    /// - Returns: The age in years, or nil if calculation fails
    func age(at date: Date = Date(), calendar: Calendar = .current) -> Int? {
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: date)
        return ageComponents.year
    }
}
