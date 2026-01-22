# UI Flow Documentation - MVP 1

## User Journey

### 1. Add a Child with Birthdate

**Screen**: AddChildView
```
┌─────────────────────────────┐
│   Nouvel Enfant        [X]  │
├─────────────────────────────┤
│ Informations                │
│ ┌─────────────────────────┐ │
│ │ Prénom: Alice          │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Nom: Dupont            │ │
│ └─────────────────────────┘ │
│                             │
│ Date de naissance           │
│ ┌─────────────────────────┐ │
│ │ 🗓  15 mars 2014        │ │ ← New DatePicker
│ └─────────────────────────┘ │
│                             │
│     [    Ajouter    ]       │
│                             │
└─────────────────────────────┘
```

**Changes from before**:
- Added "Date de naissance" section
- DatePicker limited to past dates only
- Organized into clear sections

---

### 2. View Children List with Ages

**Screen**: ChildrenListView
```
┌─────────────────────────────┐
│ < Mes Enfants          [+]  │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Alice Dupont        >   │ │ ← Tappable
│ │ 12 ans                  │ │ ← New: shows age
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Bob Martin          >   │ │
│ │ 8 ans                   │ │ ← New: shows age
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

**Changes from before**:
- Each child now shows age below name
- Added NavigationLink (>) to detail view
- More informative at a glance

---

### 3. View Child Detail with Suggestions

**Screen**: ChildDetailView (New!)
```
┌─────────────────────────────┐
│ < Alice                     │
├─────────────────────────────┤
│ INFORMATIONS                │
│ Nom complet    Alice Dupont │
│ Âge                  12 ans │
│ Date de naissance  15/03/14 │
│                             │
│ SUGGESTIONS DE RAPPELS      │
│ ┌─────────────────────────┐ │
│ │ 💉 Vaccination HPV      │ │
│ │                         │ │
│ │ La vaccination contre   │ │
│ │ le papillomavirus (HPV) │ │
│ │ est recommandée entre   │ │
│ │ 11 et 14 ans...         │ │
│ │                         │ │
│ │ [🔔 Activer le rappel] │ │ ← New: activation button
│ └─────────────────────────┘ │
│                             │
│ Ces suggestions sont basées │
│ sur l'âge de votre enfant   │
│ et les recommandations      │
│ médicales.                  │
└─────────────────────────────┘
```

**New features**:
- Shows all child information
- Lists applicable suggestions based on age
- Button to activate each suggestion
- Helpful footer text

---

### 4. Activate a Reminder (First Time)

**Flow when user taps "Activer le rappel"**:

#### Step A: Request Permission (if not determined)
```
┌─────────────────────────────┐
│     iOS System Alert        │
├─────────────────────────────┤
│  ParenTime souhaite vous    │
│  envoyer des notifications  │
│                             │
│      [Ne pas autoriser]     │
│      [    Autoriser   ]     │
└─────────────────────────────┘
```

#### Step B: Success State
```
┌─────────────────────────────┐
│ SUGGESTIONS DE RAPPELS      │
│ ┌─────────────────────────┐ │
│ │ 💉 Vaccination HPV      │ │
│ │ ...                     │ │
│ │                         │ │
│ │ ✅ Rappel activé        │ │ ← Shows success
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

### 5. If Permission Denied

**Alert shown when permission was previously denied**:
```
┌─────────────────────────────┐
│    Autorisation requise     │
├─────────────────────────────┤
│  Pour recevoir des rappels, │
│  activez les notifications  │
│  dans les paramètres de     │
│  l'application.             │
│                             │
│      [  Paramètres  ]       │ ← Opens iOS Settings
│      [      OK      ]       │
└─────────────────────────────┘
```

---

## Age-Based Suggestion Logic

### Suggestion Rules

```
Age  │ Suggestions
─────┼──────────────────────────
0-10 │ (none)
11   │ ✅ HPV Vaccination
12   │ ✅ HPV Vaccination
13   │ ✅ HPV Vaccination
14   │ ✅ HPV Vaccination
15+  │ (none)
```

### Example Scenarios

#### Scenario 1: Child aged 12
- **Shows**: HPV vaccination suggestion
- **User can**: Activate reminder
- **Result**: Notification scheduled for next day at 9 AM

#### Scenario 2: Child aged 8
- **Shows**: No suggestions
- **UI**: "Suggestions de rappels" section is hidden

#### Scenario 3: Child aged 15
- **Shows**: No suggestions (too old for HPV suggestion)
- **UI**: "Suggestions de rappels" section is hidden

---

## Complete User Flow Diagram

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       ├─(1)─> ChildrenListView (shows all children with ages)
       │         │
       │         ├─(2)─> Tap [+] button
       │         │         │
       │         │         └─> AddChildView
       │         │               │
       │         │               ├─ Enter: Prénom, Nom
       │         │               ├─ Pick: Date de naissance
       │         │               └─ Tap [Ajouter]
       │         │                   │
       │         │                   └─> Returns to ChildrenListView
       │         │
       │         └─(3)─> Tap on a child row
       │                   │
       │                   └─> ChildDetailView
       │                         │
       │                         ├─ View: Child info (name, age, birthdate)
       │                         ├─ View: Suggestions (if applicable)
       │                         │
       │                         └─(4)─> Tap [Activer le rappel]
       │                                   │
       │                                   ├─> Check permission status
       │                                   │
       │                                   ├─(if not determined)─> Request permission
       │                                   │                         │
       │                                   │                         ├─(granted)─> Schedule notification
       │                                   │                         │
       │                                   │                         └─(denied)─> Show error alert
       │                                   │
       │                                   ├─(if authorized)─> Schedule notification
       │                                   │
       │                                   └─(if denied)─> Show "go to settings" alert
       │
       └─(5)─> Notification appears (next day at 9 AM)
                 │
                 └─> User taps notification
                       │
                       └─> Opens app (to child detail in future)
```

---

## Technical Implementation Notes

### Notification Identifier
Format: `reminder_{childId}_{suggestionType}`
Example: `reminder_12345678-1234-1234-1234-123456789012_hpv_vaccination`

**Benefits**:
- Stable across app launches
- Allows cancellation of specific reminders
- Prevents duplicate notifications
- Easy to track which child and which suggestion

### Notification Content
```swift
Title: "Vaccination HPV"
Body:  "Rappel pour Alice: La vaccination contre le 
        papillomavirus (HPV) est recommandée entre 
        11 et 14 ans pour prévenir certains cancers."
```

### Notification Timing (MVP 1)
- **Current**: Next day at 9:00 AM
- **Future**: User-configurable date and time
- **Reason**: Simplified for MVP, demonstrates concept

---

## Edge Cases Handled

1. **Permission Already Denied**: Shows helpful alert to guide user to Settings
2. **Permission Request Failed**: Shows error alert
3. **Child with No Suggestions**: Suggestions section is hidden
4. **Notification Already Activated**: Shows checkmark instead of button
5. **Age Changes Over Time**: Suggestions update based on current date

---

## Future Enhancements (Not in MVP 1)

1. **Custom Times**: Let user choose notification date/time
2. **Persistent State**: Remember which reminders are activated
3. **Reminder Management**: Screen to view/edit all active reminders
4. **Recurring Notifications**: Annual reminders
5. **More Suggestions**: Dental checkups, vaccines, etc.
6. **Smart Notifications**: Based on last visit dates
7. **Notification Actions**: Quick actions from notification
8. **Badge Support**: Show count of pending reminders

---

## Testing the UI Flow

### Manual Test Checklist

- [ ] Add child with birthdate (age 12) - should see HPV suggestion
- [ ] Add child with birthdate (age 8) - should NOT see suggestions
- [ ] Add child with birthdate (age 15) - should NOT see suggestions
- [ ] Tap "Activer" - should request permission (first time)
- [ ] Grant permission - should show success
- [ ] Deny permission - should show error
- [ ] Tap "Activer" when denied - should show settings alert
- [ ] View children list - should show ages
- [ ] Navigate to child detail - should show all info
- [ ] Check notification appears next day at 9 AM

---

This document describes the complete user experience for MVP 1 of the reminder suggestions feature.
