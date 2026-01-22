//
//  ChildDetailView.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI

/// Vue de détail d'un enfant avec suggestions de rappels
struct ChildDetailView: View {
    let child: Child
    @State private var suggestions: [ReminderSuggestion] = []
    @State private var activatedSuggestions: Set<UUID> = []
    @State private var showingPermissionAlert = false
    @State private var permissionDeniedAlert = false
    
    private let notificationScheduler: NotificationScheduler
    private let suggestionsEngine: ReminderSuggestionsEngine
    
    init(
        child: Child,
        notificationScheduler: NotificationScheduler = UserNotificationScheduler(),
        suggestionsEngine: ReminderSuggestionsEngine = ReminderSuggestionsEngine()
    ) {
        self.child = child
        self.notificationScheduler = notificationScheduler
        self.suggestionsEngine = suggestionsEngine
    }
    
    var body: some View {
        List {
            // Child information section
            Section("Informations") {
                HStack {
                    Text("Nom complet")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(child.fullName)
                }
                
                if let age = child.age() {
                    HStack {
                        Text("Âge")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(age) ans")
                    }
                }
                
                HStack {
                    Text("Date de naissance")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(child.birthDate, style: .date)
                }
            }
            
            // Suggestions section
            if !suggestions.isEmpty {
                Section {
                    ForEach(suggestions) { suggestion in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(suggestion.title)
                                        .font(.headline)
                                    Text(suggestion.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            
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
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Suggestions de rappels")
                } footer: {
                    Text("Ces suggestions sont basées sur l'âge de votre enfant et les recommandations médicales.")
                        .font(.caption)
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
            loadSuggestions()
        }
    }
    
    private func loadSuggestions() {
        suggestions = suggestionsEngine.suggestions(for: child)
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
                    // TODO: Replace with proper logging in production (e.g., os_log)
                    // For MVP, silent failure is acceptable as user was prompted
                    permissionDeniedAlert = true
                }
            } catch {
                // TODO: Replace with proper logging framework in production
                // For MVP, show user-facing error
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
            // For MVP, schedule a notification for tomorrow at 9 AM
            // In production, this would be configurable
            let calendar = Calendar.current
            let now = Date()
            
            // Get tomorrow's date safely
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
                // TODO: Replace with proper logging framework (e.g., os_log) in production
                // For MVP, silent failure is acceptable as this is extremely rare
                return
            }
            
            // Set the time to 9 AM
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 9
            components.minute = 0
            
            guard let notificationDate = calendar.date(from: components) else {
                // TODO: Replace with proper logging framework (e.g., os_log) in production
                return
            }
            
            // Use stable identifier based on child ID and suggestion type
            let identifier = "reminder_\(child.id.uuidString)_\(suggestion.type.rawValue)"
            
            try await notificationScheduler.scheduleNotification(
                identifier: identifier,
                title: suggestion.title,
                body: "Rappel pour \(child.firstName): \(suggestion.description)",
                at: notificationDate
            )
            
            // Mark as activated
            activatedSuggestions.insert(suggestion.id)
        } catch {
            // TODO: Replace with proper logging framework (e.g., os_log) in production
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
