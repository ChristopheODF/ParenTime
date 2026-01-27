//
//  UserDefaultsChildrenStoreTests.swift
//  ParenTimeTests
//
//  Created for ParenTime MVP2
//

import Foundation
import Testing
@testable import ParenTime

@Suite("UserDefaultsChildrenStore Tests")
struct UserDefaultsChildrenStoreTests {
    
    // Use a unique suite name for each test to avoid interference
    private func createStore() -> UserDefaultsChildrenStore {
        let uniqueSuiteName = "com.parentime.tests.\(UUID().uuidString)"
        return UserDefaultsChildrenStore(suiteName: uniqueSuiteName)
    }
    
    @Test("Should start with empty children list")
    func testEmptyInitialState() async throws {
        let store = createStore()
        
        let children = try await store.fetchChildren()
        #expect(children.isEmpty)
    }
    
    @Test("Should add a child")
    func testAddChild() async throws {
        let store = createStore()
        
        let child = Child(
            firstName: "Alice",
            lastName: "Dupont",
            birthDate: Date()
        )
        
        try await store.addChild(child)
        
        let children = try await store.fetchChildren()
        #expect(children.count == 1)
        #expect(children[0].id == child.id)
        #expect(children[0].firstName == "Alice")
        #expect(children[0].lastName == "Dupont")
    }
    
    @Test("Should not add duplicate child")
    func testAddDuplicateChild() async throws {
        let store = createStore()
        
        let child = Child(
            firstName: "Bob",
            lastName: "Martin",
            birthDate: Date()
        )
        
        try await store.addChild(child)
        
        // Try to add the same child again
        do {
            try await store.addChild(child)
            Issue.record("Expected error when adding duplicate child")
        } catch {
            // Expected to throw
            #expect(true)
        }
    }
    
    @Test("Should update a child")
    func testUpdateChild() async throws {
        let store = createStore()
        
        var child = Child(
            firstName: "Charlie",
            lastName: "Brown",
            birthDate: Date()
        )
        
        try await store.addChild(child)
        
        // Update the child
        child.firstName = "Charlotte"
        try await store.updateChild(child)
        
        let children = try await store.fetchChildren()
        #expect(children.count == 1)
        #expect(children[0].firstName == "Charlotte")
        #expect(children[0].id == child.id)
    }
    
    @Test("Should throw when updating non-existent child")
    func testUpdateNonExistentChild() async throws {
        let store = createStore()
        
        let child = Child(
            firstName: "David",
            lastName: "Smith",
            birthDate: Date()
        )
        
        do {
            try await store.updateChild(child)
            Issue.record("Expected error when updating non-existent child")
        } catch {
            // Expected to throw
            #expect(true)
        }
    }
    
    @Test("Should delete a child")
    func testDeleteChild() async throws {
        let store = createStore()
        
        let child1 = Child(
            firstName: "Emma",
            lastName: "Wilson",
            birthDate: Date()
        )
        
        let child2 = Child(
            firstName: "Frank",
            lastName: "Taylor",
            birthDate: Date()
        )
        
        try await store.addChild(child1)
        try await store.addChild(child2)
        
        var children = try await store.fetchChildren()
        #expect(children.count == 2)
        
        // Delete first child
        try await store.deleteChild(id: child1.id)
        
        children = try await store.fetchChildren()
        #expect(children.count == 1)
        #expect(children[0].id == child2.id)
    }
    
    @Test("Should throw when deleting non-existent child")
    func testDeleteNonExistentChild() async throws {
        let store = createStore()
        
        do {
            try await store.deleteChild(id: UUID())
            Issue.record("Expected error when deleting non-existent child")
        } catch {
            // Expected to throw
            #expect(true)
        }
    }
    
    @Test("Should persist data across store instances")
    func testPersistence() async throws {
        let suiteName = "com.parentime.tests.persistence.\(UUID().uuidString)"
        
        // Create first store and add a child
        let store1 = UserDefaultsChildrenStore(suiteName: suiteName)
        
        let child = Child(
            firstName: "Grace",
            lastName: "Lee",
            birthDate: Date()
        )
        
        try await store1.addChild(child)
        
        // Create second store with same suite name
        let store2 = UserDefaultsChildrenStore(suiteName: suiteName)
        
        let children = try await store2.fetchChildren()
        #expect(children.count == 1)
        #expect(children[0].id == child.id)
        #expect(children[0].firstName == "Grace")
    }
    
    @Test("Should handle multiple children")
    func testMultipleChildren() async throws {
        let store = createStore()
        
        let child1 = Child(
            firstName: "Henry",
            lastName: "Anderson",
            birthDate: Date()
        )
        
        let child2 = Child(
            firstName: "Iris",
            lastName: "Thomas",
            birthDate: Date()
        )
        
        let child3 = Child(
            firstName: "Jack",
            lastName: "Jackson",
            birthDate: Date()
        )
        
        try await store.addChild(child1)
        try await store.addChild(child2)
        try await store.addChild(child3)
        
        let children = try await store.fetchChildren()
        #expect(children.count == 3)
        
        let ids = children.map { $0.id }
        #expect(ids.contains(child1.id))
        #expect(ids.contains(child2.id))
        #expect(ids.contains(child3.id))
    }
    
    @Test("Should preserve birthDate accurately")
    func testBirthDatePersistence() async throws {
        let store = createStore()
        
        let calendar = Calendar.current
        let birthDate = calendar.date(from: DateComponents(year: 2020, month: 3, day: 15))!
        
        let child = Child(
            firstName: "Kate",
            lastName: "Martinez",
            birthDate: birthDate
        )
        
        try await store.addChild(child)
        
        let children = try await store.fetchChildren()
        #expect(children.count == 1)
        
        let retrievedBirthDate = children[0].birthDate
        #expect(calendar.isDate(retrievedBirthDate, equalTo: birthDate, toGranularity: .day))
    }
    
    @Test("Should clear all children")
    func testClearAll() async throws {
        let store = createStore()
        
        let child = Child(
            firstName: "Leo",
            lastName: "Garcia",
            birthDate: Date()
        )
        
        try await store.addChild(child)
        
        var children = try await store.fetchChildren()
        #expect(children.count == 1)
        
        // Clear all
        try await store.clearAll()
        
        children = try await store.fetchChildren()
        #expect(children.isEmpty)
    }
}
