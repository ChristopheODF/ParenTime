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
    
    init(id: UUID = UUID(), firstName: String, lastName: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
