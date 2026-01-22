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
    
    /// Initialisation avec des dépendances par défaut
    init(childrenStore: ChildrenStore? = nil) {
        // Par défaut, utilise le store en mémoire
        // Plus tard, on pourra injecter une implémentation SwiftData
        self.childrenStore = childrenStore ?? InMemoryChildrenStore()
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
