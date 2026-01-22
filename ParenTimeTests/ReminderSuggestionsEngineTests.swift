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
    
    // Helper to create a child with a specific age in months
    private func createChild(monthsOld: Int, referenceDate: Date = Date()) -> Child {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .month, value: -monthsOld, to: referenceDate)!
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
                defaultNotificationTime: "09:00",
                description: nil,
                schedule: nil
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
                defaultNotificationTime: "09:00",
                description: nil,
                schedule: nil
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
                defaultNotificationTime: "09:00",
                description: nil,
                schedule: nil
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
    
    // MARK: - Age in Months Tests
    
    @Test("Child ageInMonths should be calculated correctly")
    func testAgeInMonthsCalculation() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        
        // Test child exactly 2 months old
        let birthDate2Months = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let child2Months = Child(firstName: "Test", lastName: "Child", birthDate: birthDate2Months)
        #expect(child2Months.ageInMonths(at: referenceDate, calendar: calendar) == 2)
        
        // Test child exactly 12 months old
        let birthDate12Months = calendar.date(from: DateComponents(year: 2025, month: 6, day: 1))!
        let child12Months = Child(firstName: "Test", lastName: "Child", birthDate: birthDate12Months)
        #expect(child12Months.ageInMonths(at: referenceDate, calendar: calendar) == 12)
        
        // Test newborn (0 months)
        let birthDateNewborn = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let childNewborn = Child(firstName: "Test", lastName: "Child", birthDate: birthDateNewborn)
        #expect(childNewborn.ageInMonths(at: referenceDate, calendar: calendar) == 0)
    }
    
    @Test("Child ageInMonths should handle partial months")
    func testAgeInMonthsPartial() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        
        // Child born May 1, 2026 (about 1.5 months old on June 15)
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        // Should be 1 month old (Calendar.dateComponents truncates to complete months)
        #expect(child.ageInMonths(at: referenceDate, calendar: calendar) == 1)
    }
    
    // MARK: - Month-based Schedule Tests
    
    @Test("Template with dueAgeMonths should match child at exact age")
    func testDueAgeMonthsExactMatch() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        
        // Child exactly 2 months old
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let template = DefaultSuggestionTemplate(
            id: "vaccine_2m",
            title: "Vaccin 2 mois",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: "Vaccination à 2 mois",
            schedule: DefaultSuggestionTemplate.Schedule(
                dueAgeMonths: [2],
                dueAgeMonthsRange: nil
            )
        )
        
        #expect(template.isApplicable(to: child, at: referenceDate, calendar: calendar))
    }
    
    @Test("Template with dueAgeMonths should match child at dueMonth - 1 (tolerance)")
    func testDueAgeMonthsMinusTolerance() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        
        // Child exactly 1 month old
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let template = DefaultSuggestionTemplate(
            id: "vaccine_2m",
            title: "Vaccin 2 mois",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: "Vaccination à 2 mois",
            schedule: DefaultSuggestionTemplate.Schedule(
                dueAgeMonths: [2],
                dueAgeMonthsRange: nil
            )
        )
        
        // Should match because of -1 month tolerance
        #expect(template.isApplicable(to: child, at: referenceDate, calendar: calendar))
    }
    
    @Test("Template with dueAgeMonths should match child at dueMonth + 1 (tolerance)")
    func testDueAgeMonthsPlusTolerance() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        
        // Child exactly 3 months old
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let template = DefaultSuggestionTemplate(
            id: "vaccine_2m",
            title: "Vaccin 2 mois",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: "Vaccination à 2 mois",
            schedule: DefaultSuggestionTemplate.Schedule(
                dueAgeMonths: [2],
                dueAgeMonthsRange: nil
            )
        )
        
        // Should match because of +1 month tolerance
        #expect(template.isApplicable(to: child, at: referenceDate, calendar: calendar))
    }
    
    @Test("Template with dueAgeMonths should NOT match child at dueMonth + 2")
    func testDueAgeMonthsOutsideTolerance() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        
        // Child exactly 4 months old
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let template = DefaultSuggestionTemplate(
            id: "vaccine_2m",
            title: "Vaccin 2 mois",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: "Vaccination à 2 mois",
            schedule: DefaultSuggestionTemplate.Schedule(
                dueAgeMonths: [2],
                dueAgeMonthsRange: nil
            )
        )
        
        // Should NOT match because 4 months is outside [1, 3] range
        #expect(!template.isApplicable(to: child, at: referenceDate, calendar: calendar))
    }
    
    @Test("Template with multiple dueAgeMonths should match any of them")
    func testMultipleDueAgeMonths() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        
        // Child exactly 4 months old
        let birthDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let template = DefaultSuggestionTemplate(
            id: "vaccine_multi",
            title: "Vaccin multi-dose",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: "Vaccination à 2, 4 et 11 mois",
            schedule: DefaultSuggestionTemplate.Schedule(
                dueAgeMonths: [2, 4, 11],
                dueAgeMonthsRange: nil
            )
        )
        
        // Should match because child is 4 months (one of the dueAgeMonths)
        #expect(template.isApplicable(to: child, at: referenceDate, calendar: calendar))
    }
    
    @Test("Template with dueAgeMonthsRange should match child within range")
    func testDueAgeMonthsRangeMatch() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        
        // Child exactly 17 months old
        let birthDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let template = DefaultSuggestionTemplate(
            id: "vaccine_range",
            title: "Vaccin 16-18 mois",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: "Vaccination entre 16 et 18 mois",
            schedule: DefaultSuggestionTemplate.Schedule(
                dueAgeMonths: nil,
                dueAgeMonthsRange: DefaultSuggestionTemplate.ScheduleRange(min: 16, max: 18)
            )
        )
        
        // Should match because 17 is in [15, 19] with tolerance
        #expect(template.isApplicable(to: child, at: referenceDate, calendar: calendar))
    }
    
    @Test("Template with dueAgeMonthsRange should match at min - 1 (tolerance)")
    func testDueAgeMonthsRangeMinTolerance() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        
        // Child exactly 15 months old
        let birthDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let template = DefaultSuggestionTemplate(
            id: "vaccine_range",
            title: "Vaccin 16-18 mois",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: "Vaccination entre 16 et 18 mois",
            schedule: DefaultSuggestionTemplate.Schedule(
                dueAgeMonths: nil,
                dueAgeMonthsRange: DefaultSuggestionTemplate.ScheduleRange(min: 16, max: 18)
            )
        )
        
        // Should match because 15 is min - 1
        #expect(template.isApplicable(to: child, at: referenceDate, calendar: calendar))
    }
    
    @Test("Template with dueAgeMonthsRange should match at max + 1 (tolerance)")
    func testDueAgeMonthsRangeMaxTolerance() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!
        
        // Child exactly 19 months old
        let birthDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let template = DefaultSuggestionTemplate(
            id: "vaccine_range",
            title: "Vaccin 16-18 mois",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: "Vaccination entre 16 et 18 mois",
            schedule: DefaultSuggestionTemplate.Schedule(
                dueAgeMonths: nil,
                dueAgeMonthsRange: DefaultSuggestionTemplate.ScheduleRange(min: 16, max: 18)
            )
        )
        
        // Should match because 19 is max + 1
        #expect(template.isApplicable(to: child, at: referenceDate, calendar: calendar))
    }
    
    @Test("Template with dueAgeMonthsRange should NOT match outside tolerance")
    func testDueAgeMonthsRangeOutsideTolerance() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 12, day: 1))!
        
        // Child exactly 22 months old
        let birthDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 1))!
        let child = Child(firstName: "Test", lastName: "Child", birthDate: birthDate)
        
        let template = DefaultSuggestionTemplate(
            id: "vaccine_range",
            title: "Vaccin 16-18 mois",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: "Vaccination entre 16 et 18 mois",
            schedule: DefaultSuggestionTemplate.Schedule(
                dueAgeMonths: nil,
                dueAgeMonthsRange: DefaultSuggestionTemplate.ScheduleRange(min: 16, max: 18)
            )
        )
        
        // Should NOT match because 22 is > max + 1
        #expect(!template.isApplicable(to: child, at: referenceDate, calendar: calendar))
    }
    
    @Test("Template with dueAgeMonths at 0 should handle tolerance correctly")
    func testDueAgeMonths0WithTolerance() {
        let calendar = Calendar.current
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        
        // Newborn (0 months old)
        let birthDateNewborn = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let childNewborn = Child(firstName: "Test", lastName: "Child", birthDate: birthDateNewborn)
        
        // 1 month old
        let birthDate1Month = calendar.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        let child1Month = Child(firstName: "Test", lastName: "Child", birthDate: birthDate1Month)
        
        let template = DefaultSuggestionTemplate(
            id: "vaccine_birth",
            title: "Vaccin naissance",
            category: "vaccines",
            priority: "required",
            conditions: DefaultSuggestionTemplate.Conditions(
                minAge: nil,
                maxAge: nil,
                minBirthDate: nil,
                maxBirthDate: nil
            ),
            defaultNotificationTime: "09:00",
            description: "Vaccination à la naissance",
            schedule: DefaultSuggestionTemplate.Schedule(
                dueAgeMonths: [0],
                dueAgeMonthsRange: nil
            )
        )
        
        // Newborn (0 months) should match
        #expect(template.isApplicable(to: childNewborn, at: referenceDate, calendar: calendar))
        
        // 1 month old should match (within tolerance)
        #expect(template.isApplicable(to: child1Month, at: referenceDate, calendar: calendar))
    }
}

