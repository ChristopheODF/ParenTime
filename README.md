# ParenTime

Application iOS de gestion de rappels par enfant, construite avec SwiftUI.

## Prérequis

- Xcode 15.0+
- iOS 17.0+
- Swift 6.0+

## Architecture

Ce projet utilise une architecture pragmatique avec injection de dépendances. Voir [ARCHITECTURE.md](ARCHITECTURE.md) pour plus de détails sur :
- La structure des dossiers (App, Core, Features)
- Le pattern d'injection de dépendances
- La migration vers SwiftData
- Les conventions de code

## Démarrage

1. Ouvrir `ParenTime.xcodeproj` avec Xcode
2. Sélectionner un simulateur iOS 17+
3. Appuyer sur `Cmd + R` pour lancer l'application

## Fonctionnalités

- ✅ Liste des enfants
- ✅ Ajout d'un enfant
- ✅ Suppression d'un enfant
- ⏳ Rappels par enfant (à venir)

## Tests

Le projet utilise Swift Testing (iOS 17+) :

```bash
# Dans Xcode : Cmd + U
# Ou via la ligne de commande :
xcodebuild test -project ParenTime.xcodeproj -scheme ParenTime -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Structure du projet

```
ParenTime/
├── App/                    # Point d'entrée et DI
├── Core/                   # Modèles et services
│   ├── Models/
│   └── Services/
├── Features/              # Fonctionnalités par domaine
│   └── Children/
└── Resources/             # Assets, etc.
```

## État actuel

🚧 **MVP en cours** : L'application utilise actuellement un stockage en mémoire (`InMemoryChildrenStore`).

La migration vers SwiftData est préparée via l'injection de dépendances et pourra être effectuée sans modifier les ViewModels ou Views.

## Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/ma-fonctionnalite`)
3. Commit les changements (`git commit -m 'Ajout de ma fonctionnalité'`)
4. Push vers la branche (`git push origin feature/ma-fonctionnalite`)
5. Ouvrir une Pull Request

## License

À définir
