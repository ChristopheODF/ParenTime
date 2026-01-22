//
//  SuggestionStateStore.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation
import Combine

/// Store for managing suggestion states (ignored/activated)
/// For MVP, this is in-memory only. Future versions should persist to disk.
@MainActor
final class SuggestionStateStore: ObservableObject {
    /// Suggestions that have been ignored by child
    @Published private(set) var ignoredSuggestions: [UUID: Set<String>] = [:]
    
    /// Suggestions that have been activated by child
    @Published private(set) var activatedSuggestions: [UUID: Set<String>] = [:]
    
    /// Check if a suggestion is ignored for a child
    func isIgnored(suggestionId: String, forChild childId: UUID) -> Bool {
        return ignoredSuggestions[childId]?.contains(suggestionId) ?? false
    }
    
    /// Check if a suggestion is activated for a child
    func isActivated(suggestionId: String, forChild childId: UUID) -> Bool {
        return activatedSuggestions[childId]?.contains(suggestionId) ?? false
    }
    
    /// Mark a suggestion as ignored for a child
    func ignoreSuggestion(_ suggestionId: String, forChild childId: UUID) {
        if ignoredSuggestions[childId] == nil {
            ignoredSuggestions[childId] = Set()
        }
        ignoredSuggestions[childId]?.insert(suggestionId)
    }
    
    /// Mark a suggestion as activated for a child
    func activateSuggestion(_ suggestionId: String, forChild childId: UUID) {
        if activatedSuggestions[childId] == nil {
            activatedSuggestions[childId] = Set()
        }
        activatedSuggestions[childId]?.insert(suggestionId)
    }
    
    /// Get all non-ignored, non-activated suggestions for a child
    func filterSuggestions(_ suggestions: [ReminderSuggestion], forChild childId: UUID) -> [ReminderSuggestion] {
        return suggestions.filter { suggestion in
            !isIgnored(suggestionId: suggestion.templateId, forChild: childId) &&
            !isActivated(suggestionId: suggestion.templateId, forChild: childId)
        }
    }
}
