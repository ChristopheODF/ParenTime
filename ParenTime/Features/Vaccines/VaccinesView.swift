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
    private let notificationScheduler: NotificationScheduler
    
    init(
        child: Child,
        suggestionsEngine: ReminderSuggestionsEngine = ReminderSuggestionsEngine(),
        remindersStore: RemindersStore = AppContainer.shared.remindersStore,
        notificationScheduler: NotificationScheduler = UserNotificationScheduler()
    ) {
        self.child = child
        self.suggestionsEngine = suggestionsEngine
        self.remindersStore = remindersStore
        self.notificationScheduler = notificationScheduler
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
                
                if isActivated && !isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                        Text("Activé")
                            .font(.caption2)
                            .bold()
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
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
        // Note: For VaccinesView we show ALL vaccines (even non-activated) to allow activation
        let nextOccurrences = suggestionsEngine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: nil)
        upcomingVaccines = nextOccurrences.filter { $0.category == .vaccines }
        
        // Load scheduled reminders for this child to check activation state
        do {
            scheduledReminders = try await remindersStore.fetchReminders(forChild: child.id)
        } catch {
            // Silently fail for MVP
            scheduledReminders = []
        }
    }
    
    private func toggleActivation(for vaccine: UpcomingEvent, currentReminder: ScheduledReminder?) async {
        do {
            // Check authorization status first
            let authStatus = await notificationScheduler.authorizationStatus()
            
            if let reminder = currentReminder {
                // Update existing reminder
                let newActivationState = !reminder.isActivated
                
                if newActivationState {
                    // Activating: request authorization if needed
                    if authStatus == .notDetermined {
                        let granted = try await notificationScheduler.requestAuthorization()
                        if !granted {
                            // Authorization denied, don't activate
                            return
                        }
                    } else if authStatus == .denied {
                        // Already denied, can't activate
                        return
                    }
                }
                
                try await remindersStore.updateActivation(id: reminder.id, isActivated: newActivationState)
                
                // Handle notification scheduling/cancellation
                let identifier = ReminderIdentifierUtils.notificationIdentifier(
                    childId: child.id,
                    templateId: vaccine.templateId,
                    dueDate: vaccine.dueDate
                )
                
                if newActivationState {
                    // Schedule notification
                    await scheduleNotification(for: vaccine, identifier: identifier)
                } else {
                    // Cancel notification
                    await notificationScheduler.cancelNotification(identifier: identifier)
                }
            } else {
                // Create new reminder - request authorization first
                if authStatus == .notDetermined {
                    let granted = try await notificationScheduler.requestAuthorization()
                    if !granted {
                        // Authorization denied
                        return
                    }
                } else if authStatus == .denied {
                    // Already denied, can't activate
                    return
                }
                
                // Create new reminder
                let newReminder = ScheduledReminder.from(event: vaccine, childId: child.id)
                var activatedReminder = newReminder
                activatedReminder.isActivated = true
                try await remindersStore.saveReminder(activatedReminder)
                
                // Schedule notification
                let identifier = ReminderIdentifierUtils.notificationIdentifier(
                    childId: child.id,
                    templateId: vaccine.templateId,
                    dueDate: vaccine.dueDate
                )
                await scheduleNotification(for: vaccine, identifier: identifier)
            }
            
            // Reload data
            await loadUpcomingVaccines()
        } catch {
            // Silently fail for MVP
        }
    }
    
    private func scheduleNotification(for vaccine: UpcomingEvent, identifier: String) async {
        let calendar = Calendar.current
        
        // Set notification for the due date at default notification time
        var components = calendar.dateComponents([.year, .month, .day], from: vaccine.dueDate)
        components.hour = ReminderIdentifierUtils.defaultNotificationHour
        components.minute = 0
        
        guard let notificationDate = calendar.date(from: components) else {
            return
        }
        
        // Ensure notification date is in the future
        let now = Date()
        guard notificationDate > now else {
            print("Warning: Cannot schedule notification for past date: \(notificationDate)")
            return
        }
        
        do {
            try await notificationScheduler.scheduleNotification(
                identifier: identifier,
                title: vaccine.title,
                body: "N'oubliez pas le vaccin pour \(child.firstName)",
                at: notificationDate
            )
        } catch {
            // Log error but don't show to user
            print("Error scheduling notification: \(error)")
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
