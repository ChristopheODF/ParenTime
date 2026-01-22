//
//  InMemoryChildrenStore.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation

/// Implémentation en mémoire du store d'enfants
/// Utile pour le développement et les tests sans persistance
actor InMemoryChildrenStore: ChildrenStore {
    private var children: [Child] = []
    
    init(initialChildren: [Child] = []) {
        self.children = initialChildren
    }
    
    func fetchChildren() async throws -> [Child] {
        return children
    }
    
    func addChild(_ child: Child) async throws {
        children.append(child)
    }
    
    func updateChild(_ child: Child) async throws {
        guard let index = children.firstIndex(where: { $0.id == child.id }) else {
            throw NSError(domain: "InMemoryChildrenStore", code: 404, 
                         userInfo: [NSLocalizedDescriptionKey: "Child not found"])
        }
        children[index] = child
    }
    
    func deleteChild(id: UUID) async throws {
        guard let index = children.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "InMemoryChildrenStore", code: 404, 
                         userInfo: [NSLocalizedDescriptionKey: "Child not found"])
        }
        children.remove(at: index)
    }
}
