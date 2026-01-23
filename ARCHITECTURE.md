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

## MVP 2 - Gestion des rappels et écrans par domaine

### Vue d'ensemble MVP 2

MVP 2 adresse les problèmes de surcharge d'information pour les nouveau-nés et introduit une gestion complète des rappels avec persistance.

**Problèmes résolus :**
1. **Trop d'occurrences vaccins** : Pour un nouveau-né, l'affichage montrait toutes les doses (1ère, 2ème, 3ème) et tous les rappels. Maintenant, seule la **prochaine occurrence** par vaccin/série est affichée.
2. **Régression activation** : Le bouton activer/désactiver était absent. Maintenant restauré avec indicateur visuel de statut.
3. **Gestion retards** : Les vaccins obligatoires en retard s'affichent dans "À faire maintenant" avec le temps de retard et l'action "C'est bon, c'est fait".
4. **Ajout de rappels** : Nouvelles vues pour Rendez-vous, Traitements et Rappels personnalisés avec possibilité d'ajout.

### Architecture des rappels planifiés

#### ScheduledReminder - Modèle unifié

Représente tous les types de rappels (catalogue et créés par l'utilisateur) :

```swift
struct ScheduledReminder {
    let id: UUID
    let childId: UUID
    let templateId: String?  // nil pour rappels custom
    let title: String
    let category: SuggestionCategory
    let priority: SuggestionPriority
    let dueDate: Date
    let description: String?
    
    // État
    var isActivated: Bool
    var isCompleted: Bool
    var completedAt: Date?
}
```

**Caractéristiques :**
- Unifie les rappels du catalogue (vaccins) et ceux créés par l'utilisateur
- État persisté : activé/complété avec date
- Méthodes utilitaires : `isOverdue()`, `lateSinceText()`

#### RemindersStore - Persistance

Protocole pour la gestion CRUD des rappels :

```swift
protocol RemindersStore {
    func fetchReminders(forChild: UUID) async throws -> [ScheduledReminder]
    func fetchAllReminders() async throws -> [ScheduledReminder]
    func saveReminder(_ reminder: ScheduledReminder) async throws
    func deleteReminder(id: UUID) async throws
    func updateActivation(id: UUID, isActivated: Bool) async throws
    func markCompleted(id: UUID, completedAt: Date) async throws
}
```

**Implémentation actuelle** : `UserDefaultsRemindersStore`
- Stockage via UserDefaults avec encodage JSON/ISO8601
- Thread-safe avec MainActor pour les opérations UserDefaults
- Suite name personnalisable pour isolation des tests
- Opérations atomiques avec actor isolation

**Évolution future** : SwiftData pour persistance robuste et synchronisation CloudKit

### Génération des occurrences - Logique "prochaine occurrence"

#### Problème résolu

Avant : Un nouveau-né voyait ~40 lignes (toutes les doses de tous les vaccins)
Après : ~15 lignes (une seule ligne par vaccin/série)

#### Méthode `nextOccurrencePerTemplate`

```swift
func nextOccurrencePerTemplate(
    for child: Child,
    maxMonthsInFuture: Int? = nil,
    includeOverdue: Bool = false
) -> [UpcomingEvent]
```

**Algorithme :**
1. Génère toutes les occurrences possibles depuis les templates
2. Regroupe par `templateId`
3. Pour chaque groupe, garde uniquement :
   - La prochaine occurrence future (dueDate >= now), OU
   - Si includeOverdue=true et aucune future, la plus récente passée
4. Trie par priorité → date → titre

**Exemple :**
```
Avant :
- DTP 1ère dose (2 mois)
- DTP 2ème dose (4 mois)
- DTP 3ème dose (11 mois)
- DTP Rappel (6 ans)

Après (nouveau-né) :
- DTP 1ère dose (2 mois)  ← seule la prochaine
```

#### Détection des retards

Méthode `overdueEvents` pour identifier les vaccins obligatoires en retard :

```swift
func overdueEvents(for child: Child) -> [UpcomingEvent]
```

**Critères :**
- `dueDate < referenceDate` (date passée)
- `priority == .required` (uniquement obligatoires)
- Non complété

**Affichage :**
- Section "À faire maintenant" avec bordure rouge
- Label "En retard depuis X jours/mois"
- Bouton "C'est bon, c'est fait" pour marquer complété

### Écrans par domaine

#### VaccinesView

Liste des vaccins à venir pour un enfant :
- Affiche uniquement la **prochaine occurrence** par vaccin/série
- Indicateur visuel si activé (icône cloche bleue)
- Boutons Activer/Désactiver
- État persisté dans RemindersStore

#### AppointmentsView

Gestion des rendez-vous médicaux :
- Liste des RDV avec date + heure
- Bouton "+" pour ajouter
- Actions : activer/désactiver, marquer complété, supprimer
- Support swipe-to-delete

#### TreatmentsView

Gestion des traitements/médicaments :
- Similaire à AppointmentsView
- Catégorie `.medications`

#### RemindersView

Rappels personnalisés :
- Catégorie `.custom`
- Flexibilité maximale (titre, date/heure, notes, priorité)

#### AddReminderView

Formulaire unifié pour créer des rappels :
- Champs : titre, date/heure, priorité, notes
- Toggle "Activer immédiatement"
- Adapte le titre selon la catégorie

### ChildDetailView - Dashboard refactorisé

**Section "À faire maintenant"** (seulement required) :
1. **Retards** : Vaccins obligatoires passés non complétés
   - Bordure rouge
   - "En retard depuis X jours/mois"
   - Action "C'est bon, c'est fait"
2. **Suggestions actives** : Suggestions du moteur non encore activées/ignorées

**Section "À venir"** :
- Horizon : 12 mois
- Liste compacte : titre + date
- Pour vaccins : **seulement prochaine occurrence** par serie

**Cartes domaines** :
- Navigation vers VaccinesView, AppointmentsView, TreatmentsView, RemindersView

### Tests MVP 2

#### NextOccurrenceTests
- Sélection prochaine occurrence par templateId
- Gestion des occurrences passées/futures
- Respect de maxMonthsInFuture
- Mode includeOverdue

#### OverdueTests
- Détection vaccins required en retard
- Exclusion des recommended
- Tri par date (plus ancien en premier)
- Texte "En retard depuis..." (jours/mois)

#### UserDefaultsRemindersStoreTests
- CRUD complet
- Filtrage par childId
- Persistance entre instances
- Encodage/décodage dates ISO8601
- Thread-safety (MainActor)

**Couverture :** 100% des cas nominaux et edge cases

### Améliorations futures (post-MVP 2)

- [ ] Notifications réelles au lieu de placeholder (date/heure configurables)
- [ ] Persistance SwiftData au lieu de UserDefaults
- [ ] Synchronisation CloudKit multi-device
- [ ] Notifications récurrentes (rappels annuels)
- [ ] Historique des rappels complétés
- [ ] Export PDF du carnet de santé
- [ ] Widget iOS pour prochains rappels
- [ ] Partage entre parents (multi-user)
