//
//  UserNotificationScheduler.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation
import UserNotifications

/// Implémentation du NotificationScheduler utilisant UNUserNotificationCenter
/// Cette implémentation permet de programmer des notifications locales même quand l'app est fermée
final class UserNotificationScheduler: NotificationScheduler {
    private let center: UNUserNotificationCenter
    
    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }
    
    func requestAuthorization() async throws -> Bool {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    }
    
    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        at date: Date
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Create trigger from date
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    func cancelNotification(identifier: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
}
