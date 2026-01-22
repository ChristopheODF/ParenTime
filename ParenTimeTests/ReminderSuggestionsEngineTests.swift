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
    
    // Helper to create test templates
    private func createTestTemplates() -> [DefaultSuggestionTemplate] {
        return [
            DefaultSuggestionTemplate(
                id: "hpv_vaccination",
                title: "Vaccination HPV",
                category: "vaccines",
                priority: "recommended",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: 11,
                    maxAge: 14,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00"
            ),
            DefaultSuggestionTemplate(
                id: "mandatory_vaccines_0_2",
                title: "Vaccins obligatoires (0-2 ans)",
                category: "vaccines",
                priority: "required",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: 0,
                    maxAge: 2,
                    minBirthDate: nil,
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00"
            ),
            DefaultSuggestionTemplate(
                id: "meningococcus_b_2025",
                title: "Méningocoque B",
                category: "vaccines",
                priority: "required",
                conditions: DefaultSuggestionTemplate.Conditions(
                    minAge: 0,
                    maxAge: 2,
                    minBirthDate: "2025-01-01",
                    maxBirthDate: nil
                ),
                defaultNotificationTime: "09:00"
            )
        ]
    }
    
    @Test("Child aged 10 should not receive HPV suggestion")
    func testChild10YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 10, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate, templates: createTestTemplates())
        
        let suggestions = engine.suggestions(for: child)
        let hpvSuggestions = suggestions.filter { $0.templateId == "hpv_vaccination" }
        
        #expect(hpvSuggestions.isEmpty)
    }
    
    @Test("Child aged 11 should receive HPV suggestion")
    func testChild11YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 11, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate, templates: createTestTemplates())
        
        let suggestions = engine.suggestions(for: child)
        let hpvSuggestions = suggestions.filter { $0.templateId == "hpv_vaccination" }
        
        #expect(hpvSuggestions.count == 1)
        #expect(hpvSuggestions[0].title == "Vaccination HPV")
    }
    
    @Test("Child aged 12 should receive HPV suggestion")
    func testChild12YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 12, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate, templates: createTestTemplates())
        
        let suggestions = engine.suggestions(for: child)
        let hpvSuggestions = suggestions.filter { $0.templateId == "hpv_vaccination" }
        
        #expect(hpvSuggestions.count == 1)
        #expect(hpvSuggestions[0].title == "Vaccination HPV")
    }
    
    @Test("Child aged 13 should receive HPV suggestion")
    func testChild13YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 13, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate, templates: createTestTemplates())
        
        let suggestions = engine.suggestions(for: child)
        let hpvSuggestions = suggestions.filter { $0.templateId == "hpv_vaccination" }
        
        #expect(hpvSuggestions.count == 1)
        #expect(hpvSuggestions[0].title == "Vaccination HPV")
    }
    
    @Test("Child aged 14 should receive HPV suggestion")
    func testChild14YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 14, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate, templates: createTestTemplates())
        
        let suggestions = engine.suggestions(for: child)
        let hpvSuggestions = suggestions.filter { $0.templateId == "hpv_vaccination" }
        
        #expect(hpvSuggestions.count == 1)
        #expect(hpvSuggestions[0].title == "Vaccination HPV")
    }
    
    @Test("Child aged 15 should not receive HPV suggestion")
    func testChild15YearsOld() {
        let referenceDate = Date()
        let child = createChild(yearsOld: 15, referenceDate: referenceDate)
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate, templates: createTestTemplates())
        
        let suggestions = engine.suggestions(for: child)
        let hpvSuggestions = suggestions.filter { $0.templateId == "hpv_vaccination" }
        
        #expect(hpvSuggestions.isEmpty)
    }
    
    @Test("Engine uses custom reference date for deterministic testing")
    func testCustomReferenceDate() {
        // Create a specific reference date: Jan 1, 2026
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        
        // Child born on Jan 1, 2014 will be exactly 12 years old on Jan 1, 2026
        let birthDate = calendar.date(from: DateComponents(year: 2014, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate, templates: createTestTemplates())
        let suggestions = engine.suggestions(for: child)
        let hpvSuggestions = suggestions.filter { $0.templateId == "hpv_vaccination" }
        
        #expect(hpvSuggestions.count == 1)
        #expect(hpvSuggestions[0].title == "Vaccination HPV")
    }
    
    @Test("Engine respects custom calendar")
    func testCustomCalendar() {
        let calendar = Calendar.current
        let referenceDate = Date()
        let child = createChild(yearsOld: 12, referenceDate: referenceDate)
        
        let engine = ReminderSuggestionsEngine(calendar: calendar, referenceDate: referenceDate, templates: createTestTemplates())
        let suggestions = engine.suggestions(for: child)
        let hpvSuggestions = suggestions.filter { $0.templateId == "hpv_vaccination" }
        
        #expect(hpvSuggestions.count == 1)
        #expect(hpvSuggestions[0].title == "Vaccination HPV")
    }
    
    @Test("Child born before 2025 should not receive MenB suggestion")
    func testMenBNotApplicableBefore2025() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate, templates: createTestTemplates())
        let suggestions = engine.suggestions(for: child)
        let menBSuggestions = suggestions.filter { $0.templateId == "meningococcus_b_2025" }
        
        #expect(menBSuggestions.isEmpty)
    }
    
    @Test("Child born on or after 2025-01-01 should receive MenB suggestion if age matches")
    func testMenBApplicableAfter2025() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate, templates: createTestTemplates())
        let suggestions = engine.suggestions(for: child)
        let menBSuggestions = suggestions.filter { $0.templateId == "meningococcus_b_2025" }
        
        #expect(menBSuggestions.count == 1)
        #expect(menBSuggestions[0].title == "Méningocoque B")
    }
    
    @Test("Suggestions are sorted by priority (required before recommended)")
    func testSuggestionsSortedByPriority() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let birthDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let engine = ReminderSuggestionsEngine(referenceDate: referenceDate, templates: createTestTemplates())
        let suggestions = engine.suggestions(for: child)
        
        // Should have both mandatory vaccines and MenB (both required priority)
        // No HPV (child is too young)
        #expect(suggestions.count == 2)
        
        // All required priority items should come first
        for suggestion in suggestions {
            #expect(suggestion.priority == .required)
        }
    }
}

