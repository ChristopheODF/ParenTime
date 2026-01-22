//
//  ReminderSuggestionsEngineTests.swift
//  ParenTimeTests
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation
import Testing
@testable import ParenTime

@Suite("ReminderSuggestionsEngine Tests")
struct ReminderSuggestionsEngineTests {
    
    // Helper to create a child with a specific age
    private func createChild(yearsOld: Int, referenceDate: Date = Date()) -> Child {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -yearsOld, to: referenceDate)!
        return Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
    }
    
    @Test("Child aged 10 should not receive HPV suggestion")
    func testChild10YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 10, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate)
        
        let suggestions = engine.suggestions(for: child)
        
        #expect(suggestions.isEmpty)
    }
    
    @Test("Child aged 11 should receive HPV suggestion")
    func testChild11YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 11, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate)
        
        let suggestions = engine.suggestions(for: child)
        
        #expect(suggestions.count == 1)
        #expect(suggestions[0].type == .hpvVaccination)
    }
    
    @Test("Child aged 12 should receive HPV suggestion")
    func testChild12YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 12, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate)
        
        let suggestions = engine.suggestions(for: child)
        
        #expect(suggestions.count == 1)
        #expect(suggestions[0].type == .hpvVaccination)
    }
    
    @Test("Child aged 13 should receive HPV suggestion")
    func testChild13YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 13, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate)
        
        let suggestions = engine.suggestions(for: child)
        
        #expect(suggestions.count == 1)
        #expect(suggestions[0].type == .hpvVaccination)
    }
    
    @Test("Child aged 14 should receive HPV suggestion")
    func testChild14YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 14, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate)
        
        let suggestions = engine.suggestions(for: child)
        
        #expect(suggestions.count == 1)
        #expect(suggestions[0].type == .hpvVaccination)
    }
    
    @Test("Child aged 15 should not receive HPV suggestion")
    func testChild15YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 15, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate)
        
        let suggestions = engine.suggestions(for: child)
        
        #expect(suggestions.isEmpty)
    }
    
    @Test("Engine uses custom reference date for deterministic testing")
    func testCustomReferenceDate() {
        // Create a specific reference date: Jan 1, 2026
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        
        // Child born on Jan 1, 2014 will be exactly 12 years old on Jan 1, 2026
        let birthDate = calendar.date(from: DateComponents(year: 2014, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate)
        let suggestions = engine.suggestions(for: child)
        
        #expect(suggestions.count == 1)
        #expect(suggestions[0].type == .hpvVaccination)
    }
    
    @Test("Engine respects custom calendar")
    func testCustomCalendar() {
        let calendar = Calendar.current
        let referenceDate = Date()
        let child = createChild(yearsOld: 12, referenceDate: referenceDate)
        
        let engine = ReminderSuggestionsEngine(calendar: calendar, referenceDate: referenceDate)
        let suggestions = engine.suggestions(for: child)
        
        #expect(suggestions.count == 1)
        #expect(suggestions[0].type == .hpvVaccination)
    }
}
