//
//  ChildrenStore.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation

/// Protocole définissant le contrat pour le stockage des enfants
/// Permet une injection de dépendances et un remplacement facile de l'implémentation
protocol ChildrenStore {
    /// Récupère tous les enfants
    func fetchChildren() async throws -> [Child]
    
    /// Ajoute un nouvel enfant
    func addChild(_ child: Child) async throws
    
    /// Met à jour un enfant existant
    func updateChild(_ child: Child) async throws
    
    /// Supprime un enfant
    func deleteChild(id: UUID) async throws
}
