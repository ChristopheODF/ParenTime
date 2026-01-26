//
//  AppContainer.swift
//  ParenTime
//
//  Created by Christophe Gaudout on 22/01/2026.
//

import SwiftUI
import Combine

/// Conteneur de dépendances pour l'application
/// Centralise l'instanciation et la gestion des services
final class AppContainer: ObservableObject {
    // Services
    let childrenStore: ChildrenStore
    let suggestionStateStore: SuggestionStateStore
    let remindersStore: RemindersStore
    
    /// Initialisation avec des dépendances par défaut
    init(
        childrenStore: ChildrenStore? = nil,
        suggestionStateStore: SuggestionStateStore? = nil,
        remindersStore: RemindersStore? = nil
    ) {
        // Par défaut, utilise UserDefaultsChildrenStore pour la persistance
        self.childrenStore = childrenStore ?? UserDefaultsChildrenStore()
        self.suggestionStateStore = suggestionStateStore ?? SuggestionStateStore()
        self.remindersStore = remindersStore ?? UserDefaultsRemindersStore()
    }
    
    /// Conteneur partagé pour l'application
    static let shared = AppContainer()
}

// MARK: - Environment Key pour DI via SwiftUI Environment

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue = AppContainer.shared
}

extension EnvironmentValues {
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}
