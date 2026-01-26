//
//  AddReminderView.swift
//  ParenTime
//
//  Created for ParenTime MVP2
//

import SwiftUI

/// View for adding a custom reminder for a child
struct AddReminderView: View {
    let child: Child
    let category: SuggestionCategory
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var notes: String = ""
    @State private var priority: SuggestionPriority = .recommended
    @State private var activateImmediately: Bool = true
    @State private var isSaving: Bool = false
    
    private let remindersStore: RemindersStore
    private let notificationScheduler: NotificationScheduler
    
    init(
        child: Child,
        category: SuggestionCategory,
        remindersStore: RemindersStore = AppContainer.shared.remindersStore,
        notificationScheduler: NotificationScheduler = UserNotificationScheduler()
    ) {
        self.child = child
        self.category = category
        self.remindersStore = remindersStore
        self.notificationScheduler = notificationScheduler
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations") {
                    TextField("Titre", text: $title)
                    
                    DatePicker(
                        "Date et heure",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    
                    Picker("Priorité", selection: $priority) {
                        Text("Obligatoire").tag(SuggestionPriority.required)
                        Text("Recommandé").tag(SuggestionPriority.recommended)
                        Text("Info").tag(SuggestionPriority.info)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Toggle("Activer immédiatement", isOn: $activateImmediately)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        Task {
                            await saveReminder()
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }
    
    private var navigationTitle: String {
        switch category {
        case .vaccines: return "Nouveau vaccin"
        case .appointments: return "Nouveau rendez-vous"
        case .medications: return "Nouveau traitement"
        case .custom: return "Nouveau rappel"
        }
    }
    
    private func saveReminder() async {
        isSaving = true
        
        // Check if activating and request authorization if needed
        if activateImmediately {
            let authStatus = await notificationScheduler.authorizationStatus()
            
            if authStatus == .notDetermined {
                do {
                    let granted = try await notificationScheduler.requestAuthorization()
                    if !granted {
                        // Authorization denied, don't activate
                        isSaving = false
                        return
                    }
                } catch {
                    isSaving = false
                    return
                }
            } else if authStatus == .denied {
                // Already denied, don't activate
                isSaving = false
                return
            }
        }
        
        let reminder = ScheduledReminder(
            childId: child.id,
            templateId: nil, // User-created, no template
            title: title,
            category: category,
            priority: priority,
            dueDate: dueDate,
            description: notes.isEmpty ? nil : notes,
            isActivated: activateImmediately
        )
        
        do {
            try await remindersStore.saveReminder(reminder)
            
            // Schedule notification if activated
            if activateImmediately {
                let now = Date()
                if dueDate > now {
                    let identifier = ReminderIdentifierUtils.notificationIdentifier(
                        childId: child.id,
                        templateId: reminder.id.uuidString,
                        dueDate: dueDate
                    )
                    
                    try await notificationScheduler.scheduleNotification(
                        identifier: identifier,
                        title: title,
                        body: "Rappel pour \(child.firstName)",
                        at: dueDate
                    )
                }
            }
            
            dismiss()
        } catch {
            // For MVP, silently fail
            isSaving = false
        }
    }
}

#Preview {
    AddReminderView(
        child: Child(
            firstName: "Alice",
            lastName: "Dupont",
            birthDate: Calendar.current.date(byAdding: .year, value: -5, to: Date())!
        ),
        category: .appointments
    )
}
