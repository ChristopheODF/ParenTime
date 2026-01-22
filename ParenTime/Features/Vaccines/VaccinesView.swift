//
//  VaccinesView.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

/// Vue pour afficher les vaccins d'un enfant
struct VaccinesView: View {
    let child: Child
    @StateObject private var suggestionStateStore: SuggestionStateStore
    @State private var vaccineSuggestions: [ReminderSuggestion] = []
    
    private let suggestionsEngine: ReminderSuggestionsEngine
    
    init(
        child: Child,
        suggestionsEngine: ReminderSuggestionsEngine = ReminderSuggestionsEngine(),
        suggestionStateStore: SuggestionStateStore = AppContainer.shared.suggestionStateStore
    ) {
        self.child = child
        self.suggestionsEngine = suggestionsEngine
        _suggestionStateStore = StateObject(wrappedValue: suggestionStateStore)
    }
    
    private var activeVaccineSuggestions: [ReminderSuggestion] {
        suggestionStateStore.filterSuggestions(vaccineSuggestions, forChild: child.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if activeVaccineSuggestions.isEmpty {
                    emptyStateView
                } else {
                    ForEach(activeVaccineSuggestions) { suggestion in
                        vaccineCard(suggestion)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Vaccins")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadVaccineSuggestions()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            Text("Aucun vaccin suggéré")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Il n'y a pas de suggestions de vaccins pour \(child.firstName) pour le moment.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func vaccineCard(_ suggestion: ReminderSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.headline)
                    
                    if let description = suggestion.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    priorityBadge(suggestion.priority)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func priorityBadge(_ priority: SuggestionPriority) -> some View {
        let (text, color): (String, Color) = {
            switch priority {
            case .required: return ("Obligatoire", .red)
            case .recommended: return ("Recommandé", .orange)
            case .info: return ("Info", .blue)
            }
        }()
        
        return Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
    
    private func loadVaccineSuggestions() {
        let allSuggestions = suggestionsEngine.suggestions(for: child)
        vaccineSuggestions = allSuggestions.filter { $0.category == .vaccines }
    }
}

#Preview {
    NavigationStack {
        VaccinesView(
            child: Child(
                firstName: "Alice",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .year, value: -12, to: Date())!
            )
        )
    }
}
