//
//  VaccinesView.swift
//  ParenTime
//
//  Created for ParenTime MVP
//

import SwiftUI

/// View displaying the complete list of upcoming vaccines for a child
/// Shows only the next occurrence per vaccine/series
struct VaccinesView: View {
    let child: Child
    @State private var upcomingVaccines: [UpcomingEvent] = []
    @State private var scheduledReminders: [ScheduledReminder] = []
    
    private let suggestionsEngine: ReminderSuggestionsEngine
    private let remindersStore: RemindersStore
    
    init(
        child: Child,
        suggestionsEngine: ReminderSuggestionsEngine = ReminderSuggestionsEngine(),
        remindersStore: RemindersStore = AppContainer.shared.remindersStore
    ) {
        self.child = child
        self.suggestionsEngine = suggestionsEngine
        self.remindersStore = remindersStore
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
            Task {
                await loadUpcomingVaccines()
            }
        }
    }
    
    private func vaccineRow(_ vaccine: UpcomingEvent) -> some View {
        let reminder = scheduledReminders.first { $0.templateId == vaccine.templateId }
        let isActivated = reminder?.isActivated ?? false
        let isCompleted = reminder?.isCompleted ?? false
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(vaccine.title)
                    .font(.headline)
                    .strikethrough(isCompleted)
                
                Spacer()
                
                if isActivated {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
            }
            
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
            
            if !isCompleted {
                HStack(spacing: 8) {
                    Button {
                        Task {
                            await toggleActivation(for: vaccine, currentReminder: reminder)
                        }
                    } label: {
                        Label(isActivated ? "Désactiver" : "Activer", systemImage: isActivated ? "bell.slash" : "bell.badge")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(isActivated ? .gray : .blue)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(isCompleted ? 0.5 : 1.0)
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
    
    private func loadUpcomingVaccines() async {
        // Get only next occurrence per vaccine/series, and filter to vaccines only
        let nextOccurrences = suggestionsEngine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: nil)
        upcomingVaccines = nextOccurrences.filter { $0.category == .vaccines }
        
        // Load scheduled reminders for this child
        do {
            scheduledReminders = try await remindersStore.fetchReminders(forChild: child.id)
        } catch {
            // Silently fail for MVP
            scheduledReminders = []
        }
    }
    
    private func toggleActivation(for vaccine: UpcomingEvent, currentReminder: ScheduledReminder?) async {
        do {
            if let reminder = currentReminder {
                // Update existing reminder
                try await remindersStore.updateActivation(id: reminder.id, isActivated: !reminder.isActivated)
            } else {
                // Create new reminder
                let newReminder = ScheduledReminder.from(event: vaccine, childId: child.id)
                var activatedReminder = newReminder
                activatedReminder.isActivated = true
                try await remindersStore.saveReminder(activatedReminder)
            }
            
            // Reload data
            await loadUpcomingVaccines()
        } catch {
            // Silently fail for MVP
        }
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
