//
//  ChildDetailView.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

/// Vue tableau de bord d'un enfant avec suggestions et rappels prioritisés
struct ChildDetailView: View {
    let child: Child
    @State private var nowItems: [DashboardItem] = []
    @State private var upcomingItems: [DashboardItem] = []
    @State private var activatedSuggestions: Set<UUID> = []
    @State private var showingPermissionAlert = false
    @State private var permissionDeniedAlert = false
    
    private let notificationScheduler: NotificationScheduler
    private let suggestionsEngine: ReminderSuggestionsEngine
    private let dashboardPrioritizer: DashboardPrioritizer
    
    init(
        child: Child,
        notificationScheduler: NotificationScheduler = UserNotificationScheduler(),
        suggestionsEngine: ReminderSuggestionsEngine = ReminderSuggestionsEngine(),
        dashboardPrioritizer: DashboardPrioritizer = DashboardPrioritizer()
    ) {
        self.child = child
        self.notificationScheduler = notificationScheduler
        self.suggestionsEngine = suggestionsEngine
        self.dashboardPrioritizer = dashboardPrioritizer
    }
    
    var body: some View {
        List {
            // Header: child info
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(child.fullName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    if let age = child.age() {
                        Text("\(age) ans")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // À faire maintenant
            if !nowItems.isEmpty {
                Section {
                    ForEach(nowItems) { item in
                        dashboardItemRow(item)
                    }
                } header: {
                    Text("À faire maintenant")
                }
            }
            
            // À venir
            if !upcomingItems.isEmpty {
                Section {
                    ForEach(upcomingItems) { item in
                        dashboardItemRow(item)
                    }
                } header: {
                    Text("À venir")
                }
            }
            
            // Domain cards
            Section {
                NavigationLink(destination: VaccinesView(child: child)) {
                    domainCard(
                        icon: "syringe",
                        title: "Vaccins",
                        status: "À jour"
                    )
                }
                
                NavigationLink(destination: TreatmentsView(child: child)) {
                    domainCard(
                        icon: "pills",
                        title: "Traitements",
                        status: "Aucun en cours"
                    )
                }
                
                NavigationLink(destination: AppointmentsView(child: child)) {
                    domainCard(
                        icon: "calendar",
                        title: "Rendez-vous",
                        status: "Aucun planifié"
                    )
                }
                
                NavigationLink(destination: RemindersView(child: child)) {
                    domainCard(
                        icon: "bell",
                        title: "Rappels",
                        status: "Aucun actif"
                    )
                }
            }
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
            loadDashboardItems()
        }
    }
    
    @ViewBuilder
    private func dashboardItemRow(_ item: DashboardItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Show due date for reminders
                    if let dueDate = item.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                Spacer()
            }
            
            // Action button for suggestions
            if case .suggestion(let suggestion) = item {
                if activatedSuggestions.contains(suggestion.id) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Rappel activé")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } else {
                    Button {
                        Task {
                            await activateSuggestion(suggestion)
                        }
                    } label: {
                        Label("Activer le rappel", systemImage: "bell.badge")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func domainCard(icon: String, title: String, status: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
    
    private func loadDashboardItems() {
        // Get suggestions
        let suggestions = suggestionsEngine.suggestions(for: child)
        
        // For MVP, no active reminders - placeholder empty array
        // In the future, this would fetch from a store
        let activeReminders: [ActiveReminder] = []
        
        // Combine into dashboard items
        let allItems = suggestions.map { DashboardItem.suggestion($0) }
            + activeReminders.map { DashboardItem.reminder($0) }
        
        // Prioritize
        let prioritized = dashboardPrioritizer.prioritize(items: allItems)
        nowItems = prioritized.now
        upcomingItems = prioritized.upcoming
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
            let calendar = Calendar.current
            let now = Date()
            
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
                return
            }
            
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 9
            components.minute = 0
            
            guard let notificationDate = calendar.date(from: components) else {
                return
            }
            
            let identifier = "reminder_\(child.id.uuidString)_\(suggestion.type.rawValue)"
            
            try await notificationScheduler.scheduleNotification(
                identifier: identifier,
                title: suggestion.title,
                body: "Rappel pour \(child.firstName): \(suggestion.description)",
                at: notificationDate
            )
            
            activatedSuggestions.insert(suggestion.id)
        } catch {
            // Silent failure for MVP
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
