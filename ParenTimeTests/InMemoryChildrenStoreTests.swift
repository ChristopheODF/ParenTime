//
//  InMemoryChildrenStoreTests.swift
//  ParenTimeTests
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation
import Testing
@testable import ParenTime

@Suite("InMemoryChildrenStore Tests")
struct InMemoryChildrenStoreTests {
    
    @Test("Fetch children returns empty array initially")
    @MainActor
    func testFetchChildrenInitiallyEmpty() async throws {
        let store = InMemoryChildrenStore()
        let children = try await store.fetchChildren()
        #expect(children.isEmpty)
    }
    
    @Test("Add child increases count")
    @MainActor
    func testAddChild() async throws {
        let store = InMemoryChildrenStore()
        let child = Child(firstName: "Alice", lastName: "Dupont")
        
        try await store.addChild(child)
        let children = try await store.fetchChildren()
        
        #expect(children.count == 1)
        #expect(children[0].id == child.id)
        #expect(children[0].firstName == "Alice")
        #expect(children[0].lastName == "Dupont")
    }
    
    @Test("Add multiple children")
    @MainActor
    func testAddMultipleChildren() async throws {
        let store = InMemoryChildrenStore()
        let child1 = Child(firstName: "Alice", lastName: "Dupont")
        let child2 = Child(firstName: "Bob", lastName: "Martin")
        
        try await store.addChild(child1)
        try await store.addChild(child2)
        let children = try await store.fetchChildren()
        
        #expect(children.count == 2)
    }
    
    @Test("Update child modifies existing child")
    @MainActor
    func testUpdateChild() async throws {
        let store = InMemoryChildrenStore()
        let child = Child(firstName: "Alice", lastName: "Dupont")
        
        try await store.addChild(child)
        
        var updatedChild = child
        updatedChild.firstName = "Alicia"
        try await store.updateChild(updatedChild)
        
        let children = try await store.fetchChildren()
        #expect(children.count == 1)
        #expect(children[0].firstName == "Alicia")
        #expect(children[0].lastName == "Dupont")
        #expect(children[0].id == child.id)
    }
    
    @Test("Update non-existent child throws error")
    @MainActor
    func testUpdateNonExistentChild() async throws {
        let store = InMemoryChildrenStore()
        let child = Child(firstName: "Alice", lastName: "Dupont")
        
        do {
            try await store.updateChild(child)
            Issue.record("Expected error but none was thrown")
        } catch {
            // Expected error
        }
    }
    
    @Test("Delete child removes it from store")
    @MainActor
    func testDeleteChild() async throws {
        let store = InMemoryChildrenStore()
        let child1 = Child(firstName: "Alice", lastName: "Dupont")
        let child2 = Child(firstName: "Bob", lastName: "Martin")
        
        try await store.addChild(child1)
        try await store.addChild(child2)
        
        try await store.deleteChild(id: child1.id)
        
        let children = try await store.fetchChildren()
        #expect(children.count == 1)
        #expect(children[0].id == child2.id)
    }
    
    @Test("Delete non-existent child throws error")
    @MainActor
    func testDeleteNonExistentChild() async throws {
        let store = InMemoryChildrenStore()
        let nonExistentId = UUID()
        
        do {
            try await store.deleteChild(id: nonExistentId)
            Issue.record("Expected error but none was thrown")
        } catch {
            // Expected error
        }
    }
    
    @Test("Initialize with initial children")
    @MainActor
    func testInitializeWithChildren() async throws {
        let initialChildren = [
            Child(firstName: "Alice", lastName: "Dupont"),
            Child(firstName: "Bob", lastName: "Martin")
        ]
        let store = InMemoryChildrenStore(initialChildren: initialChildren)
        
        let children = try await store.fetchChildren()
        #expect(children.count == 2)
        #expect(children[0].firstName == "Alice")
        #expect(children[1].firstName == "Bob")
    }
    
    @Test("Full name is computed correctly")
    func testChildFullName() {
        let child = Child(firstName: "Alice", lastName: "Dupont")
        #expect(child.fullName == "Alice Dupont")
    }
}
