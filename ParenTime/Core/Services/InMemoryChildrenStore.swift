//
//  InMemoryChildrenStore.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation

/// Implémentation en mémoire du store d'enfants
/// Utile pour le développement et les tests sans persistance
final class InMemoryChildrenStore: ChildrenStore {
    private var children: [Child] = []
    private let lock = NSLock()
    
    init(initialChildren: [Child] = []) {
        self.children = initialChildren
    }
    
    func fetchChildren() async throws -> [Child] {
        lock.lock()
        defer { lock.unlock() }
        return children
    }
    
    func addChild(_ child: Child) async throws {
        lock.lock()
        defer { lock.unlock() }
        children.append(child)
    }
    
    func updateChild(_ child: Child) async throws {
        lock.lock()
        defer { lock.unlock() }
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
        }
    }
    
    func deleteChild(id: UUID) async throws {
        lock.lock()
        defer { lock.unlock() }
        children.removeAll { $0.id == id }
    }
}
