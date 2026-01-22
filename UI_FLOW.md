# UI/UX Flow Documentation

## App Screenshots (Conceptual)

Since this is an iOS SwiftUI app that requires Xcode to build, here's what the user will see:

### 1. Empty State - First Launch
```
┌─────────────────────────────┐
│  Mes Enfants            [+] │
├─────────────────────────────┤
│                             │
│          👥                  │
│                             │
│      Aucun enfant           │
│                             │
│  Appuyez sur + pour ajouter │
│    votre premier enfant     │
│                             │
│                             │
└─────────────────────────────┘
```

### 2. Add Child Sheet
When user taps the [+] button:
```
┌─────────────────────────────┐
│ [Annuler]  Nouvel Enfant    │
├─────────────────────────────┤
│                             │
│  Prénom                     │
│  ┌─────────────────────┐   │
│  │ Alice               │   │
│  └─────────────────────┘   │
│                             │
│  Nom                        │
│  ┌─────────────────────┐   │
│  │ Dupont              │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │      Ajouter        │   │
│  └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

### 3. List with Children
After adding children:
```
┌─────────────────────────────┐
│  Mes Enfants            [+] │
├─────────────────────────────┤
│                             │
│  Alice Dupont               │
│                             │
├─────────────────────────────┤
│                             │
│  Bob Martin                 │
│                             │
├─────────────────────────────┤
│                             │
│  Claire Bernard             │
│                             │
└─────────────────────────────┘
```

### 4. Delete Action
Swipe left on any child to reveal delete:
```
┌─────────────────────────────┐
│  Mes Enfants            [+] │
├─────────────────────────────┤
│                             │
│  Alice Dupont      [Delete] │◄── Swipe left
│                             │
├─────────────────────────────┤
│                             │
│  Bob Martin                 │
│                             │
└─────────────────────────────┘
```

## Features Implemented

✅ **Navigation**
- NavigationStack with title "Mes Enfants"
- Plus button in toolbar for adding children

✅ **Empty State**
- Friendly icon (person.2.fill)
- Clear message
- Helpful hint about the + button

✅ **Add Child**
- Modal sheet presentation
- Two text fields (Prénom, Nom)
- Form validation (both fields required)
- Cancel and Add buttons

✅ **List View**
- Clean list layout
- Child full name displayed prominently
- Swipe-to-delete gesture
- Automatic refresh after operations

✅ **Error Handling**
- Alert dialog for errors
- User-friendly error messages
- Graceful failure handling

## SwiftUI Components Used

- `NavigationStack` - Modern navigation
- `List` + `ForEach` - Scrollable list
- `Form` - Structured input
- `TextField` - Text input with content types
- `Button` - Actions
- `.sheet()` - Modal presentation
- `.alert()` - Error messages
- `.task()` - Async loading
- `@StateObject` - ViewModel lifecycle
- `@Published` - Reactive state

## To Build and Run

```bash
# Open in Xcode
open ParenTime.xcodeproj

# Select iPhone 15 simulator (iOS 17+)
# Press Cmd+R to build and run
```

The app will launch showing the empty state. Tap + to add children and interact with the list.
