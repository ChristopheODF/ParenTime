//
//  UserDefaultsChildrenStore.swift
//  ParenTime
//
//  Created for ParenTime MVP2
//

import Foundation

/// UserDefaults-based implementation of ChildrenStore
/// Uses a dedicated suite name for isolation and testing
actor UserDefaultsChildrenStore: ChildrenStore {
    private let userDefaults: UserDefaults
    private let childrenKey = "children"
    
    init(suiteName: String? = nil) {
        if let suiteName = suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.userDefaults = .standard
        }
    }
    
    // MARK: - ChildrenStore Protocol
    
    func fetchChildren() async throws -> [Child] {
        let data = await MainActor.run {
            userDefaults.data(forKey: childrenKey)
        }
        
        guard let data = data else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Child].self, from: data)
        } catch {
            // If decode fails, return empty and log error
            print("Error decoding children: \(error)")
            return []
        }
    }
    
    func addChild(_ child: Child) async throws {
        var children = try await fetchChildren()
        
        // Check if child already exists
        if children.contains(where: { $0.id == child.id }) {
            throw NSError(domain: "UserDefaultsChildrenStore", code: 409,
                         userInfo: [NSLocalizedDescriptionKey: "Child already exists"])
        }
        
        children.append(child)
        try await saveAllChildren(children)
    }
    
    func updateChild(_ child: Child) async throws {
        var children = try await fetchChildren()
        
        guard let index = children.firstIndex(where: { $0.id == child.id }) else {
            throw NSError(domain: "UserDefaultsChildrenStore", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "Child not found"])
        }
        
        children[index] = child
        try await saveAllChildren(children)
    }
    
    func deleteChild(id: UUID) async throws {
        var children = try await fetchChildren()
        
        guard let index = children.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "UserDefaultsChildrenStore", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "Child not found"])
        }
        
        children.remove(at: index)
        try await saveAllChildren(children)
    }
    
    // MARK: - Private Helpers
    
    private func saveAllChildren(_ children: [Child]) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(children)
        
        // UserDefaults operations should be on main actor for thread safety
        await MainActor.run {
            userDefaults.set(data, forKey: childrenKey)
        }
    }
    
    /// Clear all children (useful for testing)
    func clearAll() async throws {
        await MainActor.run {
            userDefaults.removeObject(forKey: childrenKey)
        }
    }
}
