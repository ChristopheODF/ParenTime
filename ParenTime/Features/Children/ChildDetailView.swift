//
//  ChildDetailView.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

/// Vue de détail d'un enfant avec dashboard simplifié
struct ChildDetailView: View {
    let child: Child
    @StateObject private var suggestionStateStore: SuggestionStateStore
    @State private var allSuggestions: [ReminderSuggestion] = []
    @State private var upcomingEvents: [UpcomingEvent] = []
    @State private var overdueEvents: [UpcomingEvent] = []
    @State private var scheduledReminders: [ScheduledReminder] = []
    @State private var showingPermissionAlert = false
    @State private var permissionDeniedAlert = false
    
    private let notificationScheduler: NotificationScheduler
    private let suggestionsEngine: ReminderSuggestionsEngine
    private let remindersStore: RemindersStore
    
    init(
        child: Child,
        notificationScheduler: NotificationScheduler = UserNotificationScheduler(),
        suggestionsEngine: ReminderSuggestionsEngine = ReminderSuggestionsEngine(),
        suggestionStateStore: SuggestionStateStore = AppContainer.shared.suggestionStateStore,
        remindersStore: RemindersStore = AppContainer.shared.remindersStore
    ) {
        self.child = child
        self.notificationScheduler = notificationScheduler
        self.suggestionsEngine = suggestionsEngine
        self.remindersStore = remindersStore
        _suggestionStateStore = StateObject(wrappedValue: suggestionStateStore)
    }
    
    private var activeSuggestions: [ReminderSuggestion] {
        suggestionStateStore.filterSuggestions(allSuggestions, forChild: child.id)
    }
    
    private var toDoNow: [ReminderSuggestion] {
        // Only show required priority suggestions
        activeSuggestions.filter { $0.priority == .required }
    }
    
    private var overdueReminders: [ScheduledReminder] {
        scheduledReminders.filter { $0.isOverdue() && $0.priority == .required && !$0.isCompleted }
    }
    
    private var hasToDoItems: Bool {
        !toDoNow.isEmpty || !overdueReminders.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with name and age
                headerSection
                
                // Domain cards - moved to top for visibility
                domainCardsSection
                
                // À faire maintenant section
                if hasToDoItems {
                    toDoNowSection
                }
                
                // À venir section
                upcomingSection
            }
            .padding()
        }
        .navigationTitle(child.firstName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Autorisation requise", isPresented: $showingPermissionAlert) {
            Button("Paramètres", role: .cancel) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Pour recevoir des rappels, activez les notifications dans les paramètres de l'application.")
        }
        .alert("Permission refusée", isPresented: $permissionDeniedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Vous avez refusé l'autorisation pour les notifications. Vous pouvez la modifier dans les paramètres.")
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(child.fullName)
                .font(.title2)
                .bold()
            
            if let age = child.age() {
                Text("\(age) ans")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(child.birthDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var toDoNowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text("À faire maintenant")
                    .font(.headline)
            }
            
            // Show overdue reminders first
            ForEach(overdueReminders) { reminder in
                overdueReminderCard(reminder)
            }
            
            // Then show current suggestions
            ForEach(toDoNow) { suggestion in
                suggestionCard(suggestion)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text("À venir")
                    .font(.headline)
            }
            
            // Show only titles of upcoming events in the next 12 months
            if upcomingEvents.isEmpty {
                Text("Aucun événement à venir")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(upcomingEvents) { event in
                        HStack {
                            Text(event.title)
                                .font(.subheadline)
                            Spacer()
                            Text(event.dueDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var domainCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Domaines")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink {
                    VaccinesView(child: child, suggestionsEngine: suggestionsEngine)
                } label: {
                    domainCardContent(title: "Vaccins", icon: "cross.case.fill", color: .blue)
                }
                
                NavigationLink {
                    TreatmentsView(child: child)
                } label: {
                    domainCardContent(title: "Traitements", icon: "pills.fill", color: .green)
                }
                
                NavigationLink {
                    AppointmentsView(child: child)
                } label: {
                    domainCardContent(title: "Rendez-vous", icon: "calendar.badge.clock", color: .orange)
                }
                
                NavigationLink {
                    RemindersView(child: child)
                } label: {
                    domainCardContent(title: "Rappels", icon: "bell.fill", color: .purple)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func domainCardContent(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func suggestionCard(_ suggestion: ReminderSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .bold()
                    
                    // Display description if available
                    if let description = suggestion.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        priorityBadge(suggestion.priority)
                        categoryBadge(suggestion.category)
                    }
                }
                Spacer()
            }
            
            HStack(spacing: 8) {
                Button {
                    Task {
                        await activateSuggestion(suggestion)
                    }
                } label: {
                    Label("Activer", systemImage: "bell.badge")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    ignoreSuggestion(suggestion)
                } label: {
                    Label("Ignorer", systemImage: "xmark")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
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
    
    private func overdueReminderCard(_ reminder: ScheduledReminder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.subheadline)
                        .bold()
                    
                    // Display late since text
                    if let lateSince = reminder.lateSinceText() {
                        Text(lateSince)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .bold()
                    }
                    
                    // Display description if available
                    if let description = reminder.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        priorityBadge(reminder.priority)
                        categoryBadge(reminder.category)
                    }
                }
                Spacer()
            }
            
            HStack(spacing: 8) {
                Button {
                    Task {
                        await markCompleted(reminder)
                    }
                } label: {
                    Label("C'est bon, c'est fait", systemImage: "checkmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
        )
    }
    
    private func categoryBadge(_ category: SuggestionCategory) -> some View {
        let text: String = {
            switch category {
            case .vaccines: return "Vaccins"
            case .appointments: return "RDV"
            case .medications: return "Traitements"
            case .custom: return "Autre"
            }
        }()
        
        return Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.gray.opacity(0.2))
            .foregroundStyle(.secondary)
            .cornerRadius(4)
    }
    
    private func loadData() async {
        loadSuggestions()
        await loadScheduledReminders()
        loadUpcomingEvents()
    }
    
    private func loadSuggestions() {
        allSuggestions = suggestionsEngine.suggestions(for: child)
    }
    
    private func loadUpcomingEvents() {
        // Load upcoming events within 12 months, only next occurrence per vaccine/series
        let allNextOccurrences = suggestionsEngine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: 12)
        
        // Filter to only show activated reminders
        upcomingEvents = allNextOccurrences.filter { event in
            // Check if this event has an activated reminder
            if let reminder = scheduledReminders.first(where: { $0.templateId == event.templateId && !$0.isCompleted }) {
                return reminder.isActivated
            }
            return false
        }
        
        // Also load overdue events for "À faire maintenant"
        overdueEvents = suggestionsEngine.overdueEvents(for: child)
    }
    
    private func loadScheduledReminders() async {
        do {
            scheduledReminders = try await remindersStore.fetchReminders(forChild: child.id)
        } catch {
            // Silently fail for MVP
            scheduledReminders = []
        }
    }
    
    private func markCompleted(_ reminder: ScheduledReminder) async {
        do {
            try await remindersStore.markCompleted(id: reminder.id, completedAt: Date())
            await loadData()
        } catch {
            // Silently fail for MVP
        }
    }
    
    private func ignoreSuggestion(_ suggestion: ReminderSuggestion) {
        suggestionStateStore.ignoreSuggestion(suggestion.templateId, forChild: child.id)
    }
    
    private func activateSuggestion(_ suggestion: ReminderSuggestion) async {
        // Check current authorization status
        let status = await notificationScheduler.authorizationStatus()
        
        switch status {
        case .notDetermined:
            // Request authorization
            do {
                let granted = try await notificationScheduler.requestAuthorization()
                if granted {
                    await scheduleNotification(for: suggestion)
                } else {
                    permissionDeniedAlert = true
                }
            } catch {
                permissionDeniedAlert = true
            }
            
        case .authorized, .provisional, .ephemeral:
            // Already authorized, schedule notification
            await scheduleNotification(for: suggestion)
            
        case .denied:
            // Permission denied, show alert
            showingPermissionAlert = true
            
        @unknown default:
            break
        }
    }
    
    private func scheduleNotification(for suggestion: ReminderSuggestion) async {
        do {
            // Get the next occurrence for this suggestion to get the exact due date
            let allOccurrences = suggestionsEngine.nextOccurrencePerTemplate(for: child, maxMonthsInFuture: 24)
            guard let occurrence = allOccurrences.first(where: { $0.templateId == suggestion.templateId }) else {
                return
            }
            
            let calendar = Calendar.current
            
            // Set notification for the due date at 9 AM (default notification time)
            var components = calendar.dateComponents([.year, .month, .day], from: occurrence.dueDate)
            components.hour = 9
            components.minute = 0
            
            guard let notificationDate = calendar.date(from: components) else {
                return
            }
            
            // Use stable identifier from utility
            let identifier = ReminderIdentifierUtils.notificationIdentifier(
                childId: child.id,
                templateId: suggestion.templateId,
                dueDate: occurrence.dueDate
            )
            
            try await notificationScheduler.scheduleNotification(
                identifier: identifier,
                title: suggestion.title,
                body: "N'oubliez pas de prendre rendez-vous pour \(child.firstName). Catégorie : \(suggestion.category.rawValue)",
                at: notificationDate
            )
            
            // Create and save a ScheduledReminder with activation
            let scheduledReminder = ScheduledReminder.from(event: occurrence, childId: child.id)
            var activatedReminder = scheduledReminder
            activatedReminder.isActivated = true
            try await remindersStore.saveReminder(activatedReminder)
            
            // Reload data to show the change
            await loadData()
        } catch {
            // For MVP, silent failure is acceptable
        }
    }
}

#Preview {
    NavigationStack {
        ChildDetailView(
            child: Child(
                firstName: "Alice",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .year, value: -12, to: Date())!
            )
        )
    }
}
