//
//  ChildAgeTests.swift
//  ParenTimeTests
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation
import Testing
@testable import ParenTime

@Suite("Child Age Calculation Tests")
struct ChildAgeTests {
    
    @Test("Age calculation with exact birthday")
    func testAgeOnBirthday() {
        let calendar = Calendar.current
        // Create a reference date: Jan 1, 2026
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        // Child born exactly 12 years ago
        let birthDate = calendar.date(from: DateComponents(year: 2014, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let age = child.age(at: referenceDate, calendar: calendar)
        
        #expect(age == 12)
    }
    
    @Test("Age calculation one day before birthday")
    func testAgeBeforeBirthday() {
        let calendar = Calendar.current
        // Reference date: Dec 31, 2025
        let referenceDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 31))!
        // Child born Jan 1, 2014 (birthday is tomorrow)
        let birthDate = calendar.date(from: DateComponents(year: 2014, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let age = child.age(at: referenceDate, calendar: calendar)
        
        // Should still be 11, not 12 yet
        #expect(age == 11)
    }
    
    @Test("Age calculation one day after birthday")
    func testAgeAfterBirthday() {
        let calendar = Calendar.current
        // Reference date: Jan 2, 2026
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 2))!
        // Child born Jan 1, 2014 (birthday was yesterday)
        let birthDate = calendar.date(from: DateComponents(year: 2014, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let age = child.age(at: referenceDate, calendar: calendar)
        
        // Should be 12 now
        #expect(age == 12)
    }
    
    @Test("Age of newborn")
    func testNewbornAge() {
        let calendar = Calendar.current
        let now = Date()
        let birthDate = calendar.date(byAdding: .day, value: -1, to: now)!
        let child = Child(firstName: "Test", lastName: "Baby", birthDate: birthDate)
        
        let age = child.age(at: now, calendar: calendar)
        
        #expect(age == 0)
    }
    
    @Test("Age uses default date when not specified")
    func testAgeDefaultDate() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -10, to: Date())!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let age = child.age()
        
        // Should be approximately 10 (might be 9 or 10 depending on exact date/time)
        #expect(age != nil)
        #expect(age! >= 9 && age! <= 10)
    }
    
    @Test("Age uses default calendar when not specified")
    func testAgeDefaultCalendar() {
        let birthDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let age = child.age(at: Date())
        
        #expect(age != nil)
        #expect(age! >= 9 && age! <= 10)
    }
}
