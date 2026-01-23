//
//  VaccinesView.swift
//  ParenTime
//
//  Created for ParenTime MVP
//

import SwiftUI

/// Vue affichant la liste complète des vaccins à venir pour un enfant
struct VaccinesView: View {
    let child: Child
    @State private var upcomingVaccines: [UpcomingEvent] = []
    
    private let suggestionsEngine: ReminderSuggestionsEngine
    
    init(
        child: Child,
        suggestionsEngine: ReminderSuggestionsEngine = ReminderSuggestionsEngine()
    ) {
        self.child = child
        self.suggestionsEngine = suggestionsEngine
    }
    
    var body: some View {
        List {
            if upcomingVaccines.isEmpty {
                ContentUnavailableView(
                    "Aucun vaccin à venir",
                    systemImage: "checkmark.circle",
                    description: Text("Tous les vaccins sont à jour")
                )
            } else {
                ForEach(upcomingVaccines) { vaccine in
                    vaccineRow(vaccine)
                }
            }
        }
        .navigationTitle("Vaccins - \(child.firstName)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUpcomingVaccines()
        }
    }
    
    private func vaccineRow(_ vaccine: UpcomingEvent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vaccine.title)
                .font(.headline)
            
            HStack(spacing: 4) {
                priorityBadge(vaccine.priority)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Text(vaccine.dueDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let description = vaccine.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
    
    private func loadUpcomingVaccines() {
        // Get all upcoming events and filter to vaccines only
        let allUpcomingEvents = suggestionsEngine.upcomingEvents(for: child, maxMonthsInFuture: nil)
        upcomingVaccines = allUpcomingEvents.filter { $0.category == .vaccines }
    }
}

#Preview {
    NavigationStack {
        VaccinesView(
            child: Child(
                firstName: "Alice",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!
            )
        )
    }
}
