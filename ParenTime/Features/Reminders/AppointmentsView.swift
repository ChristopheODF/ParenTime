//
//  AppointmentsView.swift
//  ParenTime
//
//  Created for ParenTime MVP2
//

import SwiftUI

/// View displaying appointments for a child with ability to add new ones
struct AppointmentsView: View {
    let child: Child
    @State private var appointments: [ScheduledReminder] = []
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
            if appointments.isEmpty {
                ContentUnavailableView(
                    "Aucun rendez-vous",
                    systemImage: "calendar.badge.clock",
                    description: Text("Ajoutez un rendez-vous pour commencer")
                )
            } else {
                ForEach(appointments) { appointment in
                    appointmentRow(appointment)
                }
                .onDelete { indexSet in
                    Task {
                        await deleteAppointments(at: indexSet)
                    }
                }
            }
        }
        .navigationTitle("Rendez-vous - \(child.firstName)")
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
            AddReminderView(child: child, category: .appointments)
                .onDisappear {
                    Task {
                        await loadAppointments()
                    }
                }
        }
        .onAppear {
            Task {
                await loadAppointments()
            }
        }
    }
    
    private func appointmentRow(_ appointment: ScheduledReminder) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(appointment.title)
                    .font(.headline)
                    .strikethrough(appointment.isCompleted)
                
                Spacer()
                
                if appointment.isActivated {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 4) {
                priorityBadge(appointment.priority)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Text(appointment.dueDate, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(appointment.dueDate, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let description = appointment.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !appointment.isCompleted {
                HStack(spacing: 8) {
                    Button {
                        Task {
                            await toggleActivation(for: appointment)
                        }
                    } label: {
                        Label(
                            appointment.isActivated ? "Désactiver" : "Activer",
                            systemImage: appointment.isActivated ? "bell.slash" : "bell.badge"
                        )
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(appointment.isActivated ? .gray : .blue)
                    
                    if appointment.isOverdue() {
                        Button {
                            Task {
                                await markCompleted(appointment)
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
        .opacity(appointment.isCompleted ? 0.5 : 1.0)
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
    
    private func loadAppointments() async {
        do {
            let allReminders = try await remindersStore.fetchReminders(forChild: child.id)
            appointments = allReminders
                .filter { $0.category == .appointments }
                .sorted { $0.dueDate < $1.dueDate }
        } catch {
            appointments = []
        }
    }
    
    private func toggleActivation(for appointment: ScheduledReminder) async {
        do {
            try await remindersStore.updateActivation(id: appointment.id, isActivated: !appointment.isActivated)
            await loadAppointments()
        } catch {
            // Silently fail for MVP
        }
    }
    
    private func markCompleted(_ appointment: ScheduledReminder) async {
        do {
            try await remindersStore.markCompleted(id: appointment.id, completedAt: Date())
            await loadAppointments()
        } catch {
            // Silently fail for MVP
        }
    }
    
    private func deleteAppointments(at offsets: IndexSet) async {
        for index in offsets {
            let appointment = appointments[index]
            do {
                try await remindersStore.deleteReminder(id: appointment.id)
            } catch {
                // Silently fail for MVP
            }
        }
        await loadAppointments()
    }
}

#Preview {
    NavigationStack {
        AppointmentsView(
            child: Child(
                firstName: "Alice",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .year, value: -5, to: Date())!
            )
        )
    }
}
