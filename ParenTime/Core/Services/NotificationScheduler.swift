//
//  NotificationScheduler.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import Foundation
import UserNotifications

/// Protocole pour la gestion des notifications locales
protocol NotificationScheduler {
    /// Demande l'autorisation pour les notifications
    /// - Returns: true si autorisé, false sinon
    func requestAuthorization() async throws -> Bool
    
    /// Programme une notification locale
    /// - Parameters:
    ///   - identifier: Identifiant unique de la notification
    ///   - title: Titre de la notification
    ///   - body: Corps de la notification
    ///   - date: Date de la notification
    func scheduleNotification(
        identifier: String,
        title: String,
        body: String,
        at date: Date
    ) async throws
    
    /// Annule une notification programmée
    /// - Parameter identifier: Identifiant de la notification à annuler
    func cancelNotification(identifier: String) async
    
    /// Vérifie le statut d'autorisation des notifications
    /// - Returns: Le statut d'autorisation actuel
    func authorizationStatus() async -> UNAuthorizationStatus
}
