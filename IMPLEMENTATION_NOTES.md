# UI Optimization and Next Occurrence Logic - Implementation Notes

## Problem Statement
The child detail screen and "À venir" (Upcoming) section were displaying too many elements (all future doses), making the app unreadable, especially for newborns. For example, a newborn would see all vaccine doses for the next 2+ years displayed at once.

### Example of the Problem
For a vaccine series like "DTP et Coqueluche" with 3 doses at 2, 4, and 11 months:
- **Before**: All 3 doses shown in "À venir"
- **After**: Only the next dose shown (e.g., if child is 1 month old, only "1ère dose at 2 months" is shown)

## Solution Overview

### Key Changes

#### 1. UI Reordering (ChildDetailView)
- **Domain tiles** moved to top of screen (above "À faire maintenant" and "À venir")
- This ensures navigation options are always visible without scrolling

#### 2. "À venir" Section Filtering
- Only shows **activated reminders** (user must explicitly activate a vaccine)
- Uses `nextOccurrencePerTemplate()` to show only **one occurrence per vaccine** (the next one)
- Limited to 12 months horizon
- Result: Dramatically reduced clutter

#### 3. VaccinesView Enhancements
- Shows **all vaccines** (even non-activated) to allow user to activate them
- Clear visual indicator for activated vaccines: blue badge with "Activé" text
- Activation/Deactivation toggle button for each vaccine
- Shows only next occurrence per vaccine series

#### 4. Stable Occurrence IDs
- Format: `{templateId}_{dueDate-ISO8601}`
- Example: `dtp_coqueluche_1_2026-03-01`
- Ensures consistent identification across app lifecycle
- Used for notification identifiers

#### 5. Notification Improvements
- Notifications scheduled at actual **due date** (not tomorrow)
- Default time: 9 AM (from template's `defaultNotificationTime`)
- Stable identifiers: `reminder_{childId}_{templateId}_{dueDateISO}`
- Notifications **cancelled** when vaccine is deactivated
- Proper permission handling with alerts

## Technical Implementation

### Data Flow

```
Child born -> Templates with schedules -> Generate all occurrences
                                          |
                                          v
                              nextOccurrencePerTemplate()
                                          |
                                          v
                            Filter by activation state
                                          |
                                          v
                              Display in "À venir"
```

### Key Methods

#### `ReminderSuggestionsEngine.nextOccurrencePerTemplate()`
```swift
// Groups events by templateId
// Returns only the next (earliest future) occurrence per template
// Respects maxMonthsInFuture parameter
```

#### `ChildDetailView.loadUpcomingEvents()`
```swift
// 1. Load next occurrences (12 month horizon)
// 2. Filter to only activated reminders
// 3. Display in UI
```

#### Activation Flow
```swift
VaccinesView -> Toggle Activation
              |
              v
    Create/Update ScheduledReminder
              |
              v
    Schedule/Cancel Notification
              |
              v
         Reload UI
```

## Code Changes Summary

### Modified Files
1. **ChildDetailView.swift**
   - Reordered sections (domain tiles first)
   - Added activation filtering
   - Fixed async loading order
   - Improved notification scheduling

2. **VaccinesView.swift**
   - Enhanced visual feedback (blue "Activé" badge)
   - Added notification scheduling/cancellation
   - All vaccines shown (not just activated)

3. **UpcomingEvent.swift**
   - Stable ID generation based on templateId + dueDate

4. **ReminderSuggestionsEngine.swift**
   - Updated `generateEvents()` to handle past events (for overdue detection)

### New Files
5. **ActivationFilterTests.swift**
   - Tests for activation filtering logic
   - Tests for stable ID generation
   - Validates completed reminders are not shown

## Testing Strategy

### Unit Tests
- ✅ `NextOccurrenceTests.swift` - Validates single occurrence per template
- ✅ `OverdueTests.swift` - Validates overdue detection
- ✅ `ActivationFilterTests.swift` - Validates activation filtering
- ✅ `StableIDTests.swift` - Validates stable ID generation

### Manual Testing Required
- [ ] Test with newborn (verify only next vaccines shown)
- [ ] Test activation flow (verify notifications scheduled)
- [ ] Test deactivation (verify notifications cancelled)
- [ ] Test "À venir" section (verify only activated shown)
- [ ] Test VaccinesView (verify all vaccines shown with activation state)

## Product Decisions Implemented

1. ✅ "À venir" contains only **ACTIVATED** reminders
2. ✅ For vaccines, display only **one line per vaccine** (next occurrence)
3. ✅ Overdue items appear in "À faire maintenant" with "En retard depuis..." indicator
4. ✅ "C'est bon, c'est fait" action marks occurrence as completed
5. ✅ Domain tiles placed at **top** of page
6. ✅ VaccinesView shows all vaccines (even non-activated) with Activate/Deactivate button
7. ✅ Local notifications with stable identifiers

## Known Limitations

1. Tests cannot be run in CI without macOS/Xcode
2. UI testing requires iOS simulator (not available in current environment)
3. Notification testing requires physical device or simulator with notification permissions

## Migration Notes

- Existing users: No data migration needed (new fields have defaults)
- `ScheduledReminder.isActivated` defaults to `false`
- Users must explicitly activate vaccines to see them in "À venir"

## Performance Impact

- **Positive**: Reduced UI clutter = fewer views to render
- **Positive**: Filtering happens in-memory (fast)
- **Neutral**: Notification scheduling is async (doesn't block UI)

## Future Improvements

1. Persist `SuggestionStateStore` to disk (currently in-memory only)
2. Batch notification scheduling for better performance
3. Add undo action for accidental completion
4. Add reminder to activate important vaccines
5. Add settings for notification time per vaccine
