//
//  TreatmentsView.swift
//  ParenTime
//
//  Created for ParenTime MVP2
//

import SwiftUI

/// View displaying treatments/medications for a child with ability to add new ones
struct TreatmentsView: View {
    let child: Child
    @State private var treatments: [ScheduledReminder] = []
    @State private var showingAddSheet = false
    
    private let remindersStore: RemindersStore
    
    init(
        child: Child,
        remindersStore: RemindersStore = AppContainer.shared.remindersStore
    ) {
        self.child = child
        self.remindersStore = remindersStore
    }
    
    var body: some View {
        List {
            if treatments.isEmpty {
                ContentUnavailableView(
                    "Aucun traitement",
                    systemImage: "pills.fill",
                    description: Text("Ajoutez un traitement pour commencer")
                )
            } else {
                ForEach(treatments) { treatment in
                    treatmentRow(treatment)
                }
                .onDelete { indexSet in
                    Task {
                        await deleteTreatments(at: indexSet)
                    }
                }
            }
        }
        .navigationTitle("Traitements - \(child.firstName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddReminderView(child: child, category: .medications)
                .onDisappear {
                    Task {
                        await loadTreatments()
                    }
                }
        }
        .onAppear {
            Task {
                await loadTreatments()
            }
        }
    }
    
    private func treatmentRow(_ treatment: ScheduledReminder) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(treatment.title)
                    .font(.headline)
                    .strikethrough(treatment.isCompleted)
                
                Spacer()
                
                if treatment.isActivated {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 4) {
                priorityBadge(treatment.priority)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Text(treatment.dueDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(treatment.dueDate, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let description = treatment.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !treatment.isCompleted {
                HStack(spacing: 8) {
                    Button {
                        Task {
                            await toggleActivation(for: treatment)
                        }
                    } label: {
                        Label(
                            treatment.isActivated ? "Désactiver" : "Activer",
                            systemImage: treatment.isActivated ? "bell.slash" : "bell.badge"
                        )
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(treatment.isActivated ? .gray : .blue)
                    
                    if treatment.isOverdue() {
                        Button {
                            Task {
                                await markCompleted(treatment)
                            }
                        } label: {
                            Label("C'est fait", systemImage: "checkmark.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(treatment.isCompleted ? 0.5 : 1.0)
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
    
    private func loadTreatments() async {
        do {
            let allReminders = try await remindersStore.fetchReminders(forChild: child.id)
            treatments = allReminders.filtered(by: .medications)
        } catch {
            treatments = []
        }
    }
    
    private func toggleActivation(for treatment: ScheduledReminder) async {
        do {
            try await remindersStore.updateActivation(id: treatment.id, isActivated: !treatment.isActivated)
            await loadTreatments()
        } catch {
            // Silently fail for MVP
        }
    }
    
    private func markCompleted(_ treatment: ScheduledReminder) async {
        do {
            try await remindersStore.markCompleted(id: treatment.id, completedAt: Date())
            await loadTreatments()
        } catch {
            // Silently fail for MVP
        }
    }
    
    private func deleteTreatments(at offsets: IndexSet) async {
        for index in offsets {
            let treatment = treatments[index]
            do {
                try await remindersStore.deleteReminder(id: treatment.id)
            } catch {
                // Silently fail for MVP
            }
        }
        await loadTreatments()
    }
}

#Preview {
    NavigationStack {
        TreatmentsView(
            child: Child(
                firstName: "Alice",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .year, value: -5, to: Date())!
            )
        )
    }
}
