# UI Flow Documentation - MVP 2

## Overview

MVP 2 focuses on solving the "too many vaccine occurrences" problem for newborns and adding comprehensive reminder management across multiple domains (vaccines, appointments, treatments, custom reminders).

## Key UI Changes

### Problem Solved: Vaccine Overload for Newborns

**Before MVP 2**: A newborn would see ~40 vaccine items (all doses + recalls)
**After MVP 2**: A newborn sees ~15 vaccine items (one per vaccine/series)

---

## User Journeys

### 1. View Child Dashboard (ChildDetailView)

**Screen**: ChildDetailView - Refactored
```
┌─────────────────────────────────────┐
│ < Alice                             │
├─────────────────────────────────────┤
│ ╔═══════════════════════════════╗   │
│ ║  Alice Dupont                 ║   │
│ ║  3 mois                       ║   │
│ ║  1er janvier 2026             ║   │
│ ╚═══════════════════════════════╝   │
│                                     │
│ ⚠️  À faire maintenant               │
│ ┌─────────────────────────────────┐ │
│ │ 🔴 DTP 1ère dose               │ │ ← Overdue item
│ │ ⚠️ En retard depuis 1 mois     │ │ ← New: Late indicator
│ │ [✓ C'est bon, c'est fait]      │ │ ← New: Mark completed
│ └─────────────────────────────────┘ │
│                                     │
│ 📅 À venir                           │
│ ┌─────────────────────────────────┐ │
│ │ DTP 2ème dose     4 avr. 2026  │ │ ← Only next occurrence
│ │ ROR 1ère dose     1 janv. 2027 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Domaines                            │
│ ┌─────────┬─────────┐               │
│ │ 💉      │ 💊      │               │
│ │ Vaccins │Traiteme.│               │
│ └─────────┴─────────┘               │
│ ┌─────────┬─────────┐               │
│ │ 📅      │ 🔔      │               │
│ │ RDV     │ Rappels │               │
│ └─────────┴─────────┘               │
└─────────────────────────────────────┘
```

**Key Features:**
- **À faire maintenant**: Only shows required items + overdue
- **Overdue items**: Red border, late indicator, completion action
- **À venir**: 12-month window, next occurrence only per vaccine
- **Domain cards**: All 4 cards are now navigable

---

### 2. Vaccines View - Next Occurrence Only

**Screen**: VaccinesView - Enhanced
```
┌─────────────────────────────────────┐
│ < Vaccins - Alice                   │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ DTP 2ème dose            🔔     │ │ ← Bell = activated
│ │ [Obligatoire] • 4 avr. 2026    │ │
│ │ Diphtérie, Tétanos...          │ │
│ │ [📵 Désactiver]                 │ │ ← New: Toggle
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ROR 1ère dose                  │ │ ← Not activated
│ │ [Obligatoire] • 1 janv. 2027   │ │
│ │ Rougeole, Oreillons, Rubéole   │ │
│ │ [🔔 Activer]                    │ │ ← New: Activate
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ BCG                    ~~       │ │ ← Strikethrough = completed
│ │ [Recommandé] • 1 janv. 2026    │ │
│ │ (Complété)                     │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Key Features:**
- **One per vaccine/series**: No more duplicate lines
- **Activation status**: Bell icon for activated reminders
- **Toggle actions**: Activate/Deactivate buttons
- **Completed items**: Shown with strikethrough, grayed out

---

### 3. Appointments View - CRUD Operations

**Screen**: AppointmentsView - New
```
┌─────────────────────────────────────┐
│ < Rendez-vous - Alice          [+]  │ ← New: Add button
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ Dentiste contrôle        🔔     │ │
│ │ [Recommandé] • 15 juin • 10:00 │ │
│ │ Contrôle annuel                │ │
│ │ [📵 Désactiver]                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Pédiatre bilan 3 mois           │ │ ← Overdue
│ │ [Obligatoire] • 1 avr. • 14:30 │ │
│ │ ⚠️ En retard depuis 2 jours     │ │
│ │ [📵 Désactiver] [✓ C'est fait] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Swipe left to delete →              │
└─────────────────────────────────────┘
```

**Key Features:**
- **User-created items**: All appointments are custom
- **Date + time**: Both displayed
- **Swipe to delete**: iOS-standard deletion
- **Add button**: Opens AddReminderView

---

### 4. Add Reminder Form

**Screen**: AddReminderView - New
```
┌─────────────────────────────────────┐
│ Annuler  Nouveau rendez-vous  Ajouter│
├─────────────────────────────────────┤
│ Informations                        │
│ ┌─────────────────────────────────┐ │
│ │ Titre: Dentiste              │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Date: 🗓 15 juin 2026        │ │
│ │ Heure: 🕐 10:00               │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Priorité: Recommandé ▼        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Notes                               │
│ ┌─────────────────────────────────┐ │
│ │ Contrôle annuel               │ │
│ │                               │ │
│ │                               │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ☑️ Activer immédiatement            │
│                                     │
└─────────────────────────────────────┘
```

**Key Features:**
- **Unified form**: Used for all categories
- **Date + time picker**: Combined or separate
- **Priority selector**: Required/Recommended/Info
- **Notes field**: Optional description
- **Immediate activation**: Toggle to activate on creation

---

### 5. Treatments View

**Screen**: TreatmentsView - New
```
┌─────────────────────────────────────┐
│ < Traitements - Alice          [+]  │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ Antibiotique 3x/jour      🔔    │ │
│ │ [Obligatoire] • Jusqu'au 10 juin│ │
│ │ Amoxicilline 250mg            │ │
│ │ [📵 Désactiver]                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Vitamine D quotidienne          │ │
│ │ [Recommandé] • Permanent       │ │
│ │ [🔔 Activer]                    │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Key Features:**
- Similar to AppointmentsView
- Category: `.medications`
- Supports recurring reminders concept

---

### 6. Custom Reminders View

**Screen**: RemindersView - New
```
┌─────────────────────────────────────┐
│ < Rappels - Alice              [+]  │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ Renouveler ordonnance       🔔  │ │
│ │ [Info] • 20 juin • 09:00       │ │
│ │ Chez le médecin               │ │
│ │ [📵 Désactiver]                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Inscription crèche              │ │
│ │ [Recommandé] • 1 sept. • 08:00 │ │
│ │ [🔔 Activer]                    │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Key Features:**
- Fully custom reminders
- Category: `.custom`
- Maximum flexibility

---

## Visual Indicators

### Status Icons

| Icon | Meaning |
|------|---------|
| 🔔 (blue) | Reminder is activated |
| 🔴 (red border) | Item is overdue |
| ~~strikethrough~~ | Item is completed |
| ⚠️ | Warning/overdue indicator |

### Priority Badges

| Badge | Color | Use Case |
|-------|-------|----------|
| Obligatoire | Red | Required vaccines, critical appointments |
| Recommandé | Orange | Recommended vaccines, routine checkups |
| Info | Blue | Optional reminders, low priority |

### Action Buttons

| Button | Action |
|--------|--------|
| 🔔 Activer | Schedule notification, persists state |
| 📵 Désactiver | Cancel notification, persists state |
| ✓ C'est bon, c'est fait | Mark as completed (for overdue items) |
| [+] | Add new reminder |

---

## Data Flow

### Next Occurrence Selection

```
Templates JSON
    ↓
Generate all occurrences (child's birthdate + schedule)
    ↓
Group by templateId
    ↓
For each group: select only NEXT occurrence (dueDate >= now)
    ↓
Display in UI (VaccinesView, "À venir")
```

**Result**: Newborn sees 1 line per vaccine instead of 3-5 lines

### Overdue Detection

```
Templates JSON (priority: required)
    ↓
Generate all occurrences
    ↓
Filter: dueDate < now AND NOT completed
    ↓
Display in "À faire maintenant" with red border + late text
```

**Result**: Parents see exactly what's late and can mark it done

### Persistence Flow

```
User action (activate/complete/create)
    ↓
ScheduledReminder created/updated
    ↓
RemindersStore.saveReminder()
    ↓
Encode to JSON + ISO8601 dates
    ↓
UserDefaults (thread-safe via MainActor)
    ↓
UI reloads → shows updated state
```

**Result**: State survives app restarts

---

## Comparison: Before vs After

### Newborn Vaccine List

**Before MVP 2**:
```
DTP 1ère dose (2 mois)
DTP 2ème dose (4 mois)
DTP 3ème dose (11 mois)
Hépatite B 1ère dose (2 mois)
Hépatite B 2ème dose (4 mois)
Hépatite B 3ème dose (11 mois)
HIB 1ère dose (2 mois)
HIB 2ème dose (4 mois)
HIB 3ème dose (11 mois)
... (40+ lines total)
```

**After MVP 2**:
```
DTP 1ère dose (2 mois)           ← Only next occurrence
Hépatite B 1ère dose (2 mois)    ← Only next occurrence
HIB 1ère dose (2 mois)           ← Only next occurrence
... (15 lines total)
```

### Child Dashboard - À faire maintenant

**Before MVP 2**:
- Showed all suggestions (required + recommended + info)
- No overdue detection

**After MVP 2**:
- Only shows required items
- Overdue items with red border and "En retard depuis X"
- Action to mark completed

---

## Technical Notes

### Thread Safety
- All UserDefaults operations use `MainActor.run { }`
- Actor-isolated RemindersStore for safe concurrent access

### Performance
- Filtering done in-memory (UserDefaults is fast for small datasets)
- Lazy loading: views load data on appear
- Efficient grouping algorithm for next occurrence

### Accessibility
- VoiceOver labels on all interactive elements
- Dynamic Type support
- High contrast mode compatible

---

## Future Enhancements

### Planned for MVP 3+
- [ ] Real notification scheduling (with UNUserNotificationCenter)
- [ ] Recurring reminders (daily, weekly, monthly)
- [ ] Calendar integration (export to iOS Calendar)
- [ ] Share reminders between parents
- [ ] SwiftData migration for robust persistence
- [ ] Widgets for upcoming reminders
- [ ] App badge count for overdue items
