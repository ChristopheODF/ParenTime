//
//  RemindersView.swift
//  ParenTime
//
//  Created for ParenTime MVP2
//

import SwiftUI

/// View displaying custom reminders for a child with ability to add new ones
struct RemindersView: View {
    let child: Child
    @State private var reminders: [ScheduledReminder] = []
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
            if reminders.isEmpty {
                ContentUnavailableView(
                    "Aucun rappel personnalisé",
                    systemImage: "bell.fill",
                    description: Text("Ajoutez un rappel pour commencer")
                )
            } else {
                ForEach(reminders) { reminder in
                    reminderRow(reminder)
                }
                .onDelete { indexSet in
                    Task {
                        await deleteReminders(at: indexSet)
                    }
                }
            }
        }
        .navigationTitle("Rappels - \(child.firstName)")
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
            AddReminderView(child: child, category: .custom)
                .onDisappear {
                    Task {
                        await loadReminders()
                    }
                }
        }
        .onAppear {
            Task {
                await loadReminders()
            }
        }
    }
    
    private func reminderRow(_ reminder: ScheduledReminder) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reminder.title)
                    .font(.headline)
                    .strikethrough(reminder.isCompleted)
                
                Spacer()
                
                if reminder.isActivated {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 4) {
                priorityBadge(reminder.priority)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Text(reminder.dueDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(reminder.dueDate, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let description = reminder.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !reminder.isCompleted {
                HStack(spacing: 8) {
                    Button {
                        Task {
                            await toggleActivation(for: reminder)
                        }
                    } label: {
                        Label(
                            reminder.isActivated ? "Désactiver" : "Activer",
                            systemImage: reminder.isActivated ? "bell.slash" : "bell.badge"
                        )
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(reminder.isActivated ? .gray : .blue)
                    
                    if reminder.isOverdue() {
                        Button {
                            Task {
                                await markCompleted(reminder)
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
        .opacity(reminder.isCompleted ? 0.5 : 1.0)
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
    
    private func loadReminders() async {
        do {
            let allReminders = try await remindersStore.fetchReminders(forChild: child.id)
            reminders = allReminders
                .filter { $0.category == .custom }
                .sorted { $0.dueDate < $1.dueDate }
        } catch {
            reminders = []
        }
    }
    
    private func toggleActivation(for reminder: ScheduledReminder) async {
        do {
            try await remindersStore.updateActivation(id: reminder.id, isActivated: !reminder.isActivated)
            await loadReminders()
        } catch {
            // Silently fail for MVP
        }
    }
    
    private func markCompleted(_ reminder: ScheduledReminder) async {
        do {
            try await remindersStore.markCompleted(id: reminder.id, completedAt: Date())
            await loadReminders()
        } catch {
            // Silently fail for MVP
        }
    }
    
    private func deleteReminders(at offsets: IndexSet) async {
        for index in offsets {
            let reminder = reminders[index]
            do {
                try await remindersStore.deleteReminder(id: reminder.id)
            } catch {
                // Silently fail for MVP
            }
        }
        await loadReminders()
    }
}

#Preview {
    NavigationStack {
        RemindersView(
            child: Child(
                firstName: "Alice",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .year, value: -5, to: Date())!
            )
        )
    }
}
