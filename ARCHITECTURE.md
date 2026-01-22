# Architecture ParenTime

## Vue d'ensemble

ParenTime utilise une architecture SwiftUI pragmatique avec injection de dépendances, conçue pour être évolutive sans sur-architecture.

## Structure des dossiers

```
ParenTime/
├── App/                    # Point d'entrée et configuration
│   ├── ParenTimeApp.swift # App principale SwiftUI
│   └── AppContainer.swift # Conteneur de dépendances (DI)
│
├── Core/                   # Fondations partagées
│   ├── Models/            # Modèles de domaine
│   │   └── Child.swift
│   └── Services/          # Services et leurs protocoles
│       ├── ChildrenStore.swift          # Protocol
│       └── InMemoryChildrenStore.swift  # Implémentation
│
├── Features/              # Fonctionnalités organisées par domaine
│   └── Children/
│       ├── ChildrenListView.swift
│       ├── AddChildView.swift
│       └── ChildrenViewModel.swift
│
└── Resources/             # Assets, localization, etc.
    └── Assets.xcassets
```

## Principes architecturaux

### 1. Injection de Dépendances (DI)

Le pattern DI permet de remplacer facilement les implémentations sans modifier le code métier.

**AppContainer** : Centralise l'instanciation des services
- Services exposés via des protocoles
- Injection via SwiftUI Environment ou initialisation explicite
- Facilite le swap entre implémentations (InMemory → SwiftData)

```swift
// Utilisation dans ParenTimeApp
@StateObject private var container = AppContainer.shared

// Injection dans une vue
ChildrenListView(childrenStore: container.childrenStore)
```

### 2. Séparation Core / Features

- **Core** : Modèles et services réutilisables, indépendants de l'UI
- **Features** : Vues et ViewModels spécifiques à une fonctionnalité

Cette séparation permet :
- Testabilité accrue
- Réutilisation du code
- Évolution indépendante des couches

### 3. Protocol-Oriented Design

Les services sont définis par des protocoles (`ChildrenStore`) avec plusieurs implémentations possibles :
- `InMemoryChildrenStore` : Pour développement et tests
- Future `SwiftDataChildrenStore` : Pour persistance
- Future `CloudKitChildrenStore` : Pour synchronisation

## Flux de données

```
User Action → View → ViewModel → Service (Protocol) → Implementation
                ↑                                           ↓
                └───────────── State Update ←───────────────┘
```

1. L'utilisateur interagit avec une **View**
2. La **View** déclenche une action sur le **ViewModel**
3. Le **ViewModel** appelle un **Service** (via son protocole)
4. Le **Service** effectue l'opération et retourne le résultat
5. Le **ViewModel** met à jour son état `@Published`
6. SwiftUI rafraîchit automatiquement la **View**

## Migration vers SwiftData

Pour migrer vers SwiftData à l'avenir :

### Étape 1 : Créer une nouvelle implémentation

```swift
// Core/Services/SwiftDataChildrenStore.swift
final class SwiftDataChildrenStore: ChildrenStore {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchChildren() async throws -> [Child] {
        // Implémentation SwiftData
    }
    // ... autres méthodes
}
```

### Étape 2 : Mettre à jour AppContainer

```swift
final class AppContainer: ObservableObject {
    let childrenStore: ChildrenStore
    
    init(modelContext: ModelContext? = nil) {
        if let modelContext = modelContext {
            self.childrenStore = SwiftDataChildrenStore(modelContext: modelContext)
        } else {
            self.childrenStore = InMemoryChildrenStore()
        }
    }
}
```

### Étape 3 : Configurer SwiftData dans ParenTimeApp

```swift
@main
struct ParenTimeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Child.self)
    }
}
```

**Aucune modification nécessaire dans les ViewModels ou Views !**

## Tests

Les tests utilisent le framework Swift Testing (iOS 17+).

### Tester un service

```swift
@Test func testAddChild() async throws {
    let store = InMemoryChildrenStore()
    let child = Child(firstName: "Test", lastName: "User")
    
    try await store.addChild(child)
    let children = try await store.fetchChildren()
    
    #expect(children.count == 1)
    #expect(children[0].firstName == "Test")
}
```

### Tester un ViewModel

```swift
@Test func testChildrenViewModel() async throws {
    let store = InMemoryChildrenStore()
    let viewModel = ChildrenViewModel(childrenStore: store)
    
    await viewModel.addChild(firstName: "Alice", lastName: "Dupont")
    
    #expect(viewModel.children.count == 1)
    #expect(viewModel.children[0].fullName == "Alice Dupont")
}
```

## Conventions de code

- **Langue** : Français pour le domaine métier, Anglais pour les termes techniques
- **Async/Await** : Privilégier async/await pour les opérations asynchrones
- **@MainActor** : Appliquer aux ViewModels pour garantir l'exécution sur le thread principal
- **Protocol naming** : Pas de suffixe "Protocol" (ex: `ChildrenStore`, pas `ChildrenStoreProtocol`)
- **Thread-safety** : Les stores gèrent leur propre synchronisation (NSLock pour InMemory)

## Évolutions futures

- [ ] Persistance avec SwiftData
- [ ] Synchronisation CloudKit
- [ ] Fonctionnalité de rappels par enfant
- [ ] Notifications locales
- [ ] Widgets
