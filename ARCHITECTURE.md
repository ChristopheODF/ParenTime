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

## Suggestions et Rappels (MVP 2)

### Vue d'ensemble

Le système de suggestions et rappels utilise une architecture data-driven permettant d'ajouter facilement de nouvelles recommandations sans modifier le code. Il fonctionne en trois états :

1. **Suggestions (templates)** : Propositions automatiques chargées depuis un catalogue JSON
2. **Ignorées** : Suggestions que l'utilisateur a choisi d'ignorer (par enfant)
3. **Activées** : Notifications programmées après acceptation par l'utilisateur

### Architecture

```
JSON Catalog → DefaultSuggestionTemplate[]
                         ↓
Child (âge, date naissance) → ReminderSuggestionsEngine → [ReminderSuggestion]
                                                                    ↓
                                                          SuggestionStateStore (ignored/activated)
                                                                    ↓
                                                          User accepts → NotificationScheduler
                                                                               ↓
                                                                    UNUserNotificationCenter
```

### Composants

#### DefaultSuggestionTemplate
Modèle représentant un template de suggestion dans le catalogue JSON :
- `id` : Identifiant stable unique
- `title` : Titre affiché à l'utilisateur
- `category` : Catégorie (vaccines, appointments, medications, custom)
- `priority` : Niveau de priorité (required, recommended, info)
- `conditions` : Conditions d'applicabilité
  - `minAge`, `maxAge` : Plage d'âge (en années, inclus)
  - `minBirthDate`, `maxBirthDate` : Plage de dates de naissance (format ISO YYYY-MM-DD)
- `defaultNotificationTime` : Heure par défaut pour les notifications (format HH:MM)

Le template inclut une méthode `isApplicable(to:at:calendar:)` pour vérifier si les conditions sont remplies.

#### ReminderSuggestion
Structure représentant une suggestion active générée à partir d'un template :
- `id` : UUID unique de la suggestion instance
- `templateId` : Référence au template source
- `title` : Titre affiché
- `category` : Catégorie (SuggestionCategory enum)
- `priority` : Priorité (SuggestionPriority enum)

#### ReminderSuggestionsEngine
Service pur et testable qui génère des suggestions :
- **Entrée** : `Child` + `Date` (référence) + `Calendar`
- **Sortie** : `[ReminderSuggestion]` triées par priorité
- **Logique** : 
  1. Charge le catalogue depuis `Resources/default_suggestions.json`
  2. Filtre les templates applicables au child
  3. Convertit en ReminderSuggestion
  4. Trie par priorité (required > recommended > info)

**Comment ajouter une nouvelle suggestion :**
1. Ajouter une entrée dans `default_suggestions.json` :
```json
{
  "id": "dental_checkup",
  "title": "Contrôle dentaire",
  "category": "appointments",
  "priority": "recommended",
  "conditions": {
    "minAge": 3,
    "maxAge": 18
  },
  "defaultNotificationTime": "09:00"
}
```
2. Ajouter des tests unitaires pour vérifier l'applicabilité
3. Aucune modification du code nécessaire !

#### SuggestionStateStore
Store MainActor pour gérer l'état des suggestions par enfant :
- `ignoredSuggestions: [UUID: Set<String>]` : Suggestions ignorées par enfant
- `activatedSuggestions: [UUID: Set<String>]` : Suggestions activées par enfant
- `isIgnored(suggestionId:forChild:)` : Vérifie si une suggestion est ignorée
- `isActivated(suggestionId:forChild:)` : Vérifie si une suggestion est activée
- `ignoreSuggestion(_:forChild:)` : Marque une suggestion comme ignorée
- `activateSuggestion(_:forChild:)` : Marque une suggestion comme activée
- `filterSuggestions(_:forChild:)` : Filtre les suggestions actives (non ignorées/activées)

**Note MVP 2** : La persistance est en mémoire uniquement. Future version utilisera SwiftData.

#### NotificationScheduler
Protocole pour gérer les notifications locales :
- `requestAuthorization()` : Demande permission utilisateur
- `scheduleNotification()` : Programme une notification
- `cancelNotification()` : Annule une notification
- `authorizationStatus()` : Vérifie le statut d'autorisation

**Implémentation actuelle :** `UserNotificationScheduler`
- Utilise `UNUserNotificationCenter` (iOS)
- Supporte les notifications même app fermée
- Identifiants stables : `reminder_{childId}_{templateId}`

### UI Dashboard (MVP 2)

`ChildDetailView` présente un dashboard simplifié pour éviter la surcharge d'information :

**Structure :**
1. **Header** : Nom, âge, date de naissance de l'enfant
2. **À faire maintenant** (max 3) : Suggestions actives triées par priorité
3. **À venir** (max 3) : Événements planifiés / rappels activés
4. **Cartes domaines** (4 cartes) : Navigation vers sections dédiées
   - Vaccins
   - Traitements
   - Rendez-vous
   - Rappels

**Principes de design :**
- Limiter à 3 items par section pour éviter la surcharge
- Badges de priorité visuels (rouge=obligatoire, orange=recommandé, bleu=info)
- Actions directes : "Activer" ou "Ignorer" sur chaque suggestion
- Placeholder propre si aucun item

### Catalogue actuel (MVP 2)

Le catalogue `default_suggestions.json` contient actuellement :

1. **HPV** : Vaccination HPV pour enfants de 11-14 ans
   - Category: vaccines, Priority: recommended

2. **Vaccins obligatoires 0-2 ans** : Vaccins obligatoires pour enfants de 0-2 ans
   - Category: vaccines, Priority: required

3. **Méningocoque B** : Vaccination pour enfants nés à partir du 2025-01-01 et âgés de 0-2 ans
   - Category: vaccines, Priority: required
   - Démontre l'utilisation de `minBirthDate`

### États des suggestions

```
[Template] → [Suggested] → [Ignored] (fin)
                    ↓
                [Activated] → [Scheduled Notification]
```

- **Suggested** : Visible dans "À faire maintenant"
- **Ignored** : Ne s'affiche plus pour cet enfant (persisté en mémoire)
- **Activated** : Notification planifiée, ne s'affiche plus dans les suggestions

### Notifications

**Comportement actuel (MVP 2) :**
- Notification programmée pour **le lendemain à 09:00** (timezone locale)
- Identifiant stable pour éviter les doublons : `reminder_{childId}_{templateId}`
- Demande d'autorisation au premier clic "Activer"
- Guidance vers Paramètres si permission refusée

**Améliorations futures :**
- Permettre à l'utilisateur de choisir date/heure
- Persister l'état avec SwiftData
- Notifications récurrentes (ex: rappel annuel)
- Gestion des rappels dans une vue dédiée
- Badge sur l'icône de l'app
- Serveur distant pour charger/mettre à jour le catalogue

### Tests

Les tests vérifient l'applicabilité des templates :
- Âge dans/hors plage (ex: HPV à 10, 11, 14, 15 ans)
- Conditions de date de naissance (ex: MenB pour naissances ≥ 2025-01-01)
- Tri par priorité
- Calendrier et date de référence personnalisés

Voir `ReminderSuggestionsEngineTests.swift` pour les exemples complets.
