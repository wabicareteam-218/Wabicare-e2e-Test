# Scheduling Modal Enhancements — Implementation Plan

> **Goal:** Add Outlook-style recurring appointments and scheduling assistant to the existing appointment modal.

---

## Current State

| Component | Location | Status |
|-----------|----------|--------|
| Create Appointment Modal | `lib/screens/scheduling/create_appointment_modal.dart` | ✅ Exists (718 lines) |
| Appointment API Service | `lib/services/api/appointment_api_service.dart` | ✅ Exists (319 lines) |
| Backend Model | `backend/clinic/models.py` (lines 289-359) | ✅ Has `recurrence_pattern` JSONField (unused) |
| Backend Serializer | `backend/clinic/serializers.py` (lines 312-362) | ✅ Exposes `recurrence_pattern` |

---

## Features to Implement

### Feature 1: Inline Date/Time Picker Row

**Current UI:**
- Separate date picker field
- Separate start time picker field
- Duration dropdown (30, 45, 60, 90, 120, 180 min)

**Target UI (from screenshot):**
```
┌─────────────┬─────────────┬─────────────┬───┐
│ 2/11/2026 📅│ 9:00 AM  ▼  │ 9:30 AM  ▼  │ 🌐│
└─────────────┴─────────────┴─────────────┴───┘
```

**Changes:**
1. Replace date picker with compact inline date field + calendar popup
2. Replace time picker with dropdown showing 15-min intervals (8:00 AM, 8:15 AM, etc.)
3. Calculate end time from start time + duration OR show explicit end time dropdown
4. Add timezone indicator icon (optional, can be tooltip)

---

### Feature 2: Recurring Appointment Options

**Target UI:**
```
┌─────────────────────────────────────────────────────┐
│ ☐ All day     🔄 Recurring                          │
├─────────────────────────────────────────────────────┤
│ Repeat every │ 1 ▼│ week ▼│                         │
│                                                     │
│ [M] [T] [W] [T] [F] [S] [S]   Until │Aug 5, 2026 📅│🗑│
└─────────────────────────────────────────────────────┘
```

**Data Model (recurrence_pattern JSONField):**
```json
{
  "is_recurring": true,
  "frequency": "weekly",           // "daily", "weekly", "biweekly", "monthly"
  "interval": 1,                   // Every X weeks
  "days_of_week": ["WE"],          // ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
  "end_date": "2026-08-05",        // Or null for no end
  "end_after_occurrences": null,   // Alternative: end after N occurrences
  "all_day": false
}
```

**Backend Changes:**
1. Add recurrence expansion logic to create multiple appointments
2. Add `series_id` field to link recurring appointments
3. Add endpoint to update/delete series vs single occurrence

---

### Feature 3: Time Suggestions

**Target UI:**
```
┌─────────────────────────────────────────────────────────┐
│ 📅 Time suggestions ⓘ                                   │
├─────────────────────────────────────────────────────────┤
│ 🔄 Occurs every Wednesday  9:00 AM - 9:30 AM (30 min)  │ 👥 100% available │
│ 🔄 Occurs every Wednesday  9:30 AM - 10:00 AM (30 min) │ 👥 100% available │
│ 🔄 Occurs every Wednesday 10:00 AM - 10:30 AM (30 min) │ 👥 100% available │
└─────────────────────────────────────────────────────────┘
```

**Requirements:**
1. Query therapist availability for selected day(s)
2. Check existing appointments for conflicts
3. Generate suggested time slots based on duration
4. Show availability percentage when multiple attendees

---

### Feature 4: Scheduling Assistant (Scheduler View)

**Target UI:**
```
┌──────────────────────────────────────────────────────────────────────┐
│ 📅 2/11/2026  📅  9:00 AM ▼  to  9:30 AM ▼  🌐 All day ○            │
├──────────────────────────────────────────────────────────────────────┤
│              │ Wed, Feb 11, 2026          │ Thu, Feb 12, 2026       │
│              │ 9AM 10AM 11AM 12PM 1PM ... │ 9AM 10AM ...            │
├──────────────┼───────────────────────────┼─────────────────────────│
│ Availability │ [::::SELECTED BLOCK::::] │                          │
├──────────────┼───────────────────────────┼─────────────────────────│
│ ▼ Required   │                           │                          │
│   PJ Prince  │ ███████░░░░░░░░░░░░░░░░░░ │                          │
│   RK Rakesh  │ ░░░░░░░░░░░░░░░░░░░░░░░░░ │                          │
│   MJ Megha   │ ░░░░░░░░░░░░░░░░░░░░░░░░░ │                          │
├──────────────┼───────────────────────────┼─────────────────────────│
│ ▼ Optional   │                           │                          │
│ + Add        │                           │                          │
├──────────────┼───────────────────────────┼─────────────────────────│
│ Legend: ■ Busy  ▤ Tentative  ⊠ OOO  ▧ Unknown  ░ Available         │
└──────────────────────────────────────────────────────────────────────┘
```

**Requirements:**
1. Full-page modal or slide-out panel
2. Multi-day timeline view (horizontal scroll)
3. Attendee rows with availability blocks
4. Click-to-select time range
5. Visual conflict indicators

---

## Implementation Tasks

### Phase 1: Backend Enhancements

#### Task 1.1: Add Recurrence Support to Model
**File:** `backend/clinic/models.py`

```python
# Add to Appointment model (after line 339)
series_id = models.UUIDField(null=True, blank=True, db_index=True)
is_series_master = models.BooleanField(default=False)
original_start_time = models.DateTimeField(null=True, blank=True)  # For modified occurrences
```

#### Task 1.2: Add Availability Model
**File:** `backend/clinic/models.py`

```python
class TherapistAvailability(models.Model):
    """Weekly recurring availability slots for therapists"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE)
    therapist = models.ForeignKey(User, on_delete=models.CASCADE, related_name='availability_slots')

    day_of_week = models.IntegerField(choices=[
        (0, 'Monday'), (1, 'Tuesday'), (2, 'Wednesday'),
        (3, 'Thursday'), (4, 'Friday'), (5, 'Saturday'), (6, 'Sunday')
    ])
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'clinic_therapist_availability'
        indexes = [models.Index(fields=['organization', 'therapist'])]
```

#### Task 1.3: Create Recurrence Expansion Logic
**File:** `backend/clinic/services/recurrence_service.py` (new file)

```python
from datetime import date, timedelta
from dateutil.rrule import rrule, DAILY, WEEKLY, MONTHLY

class RecurrenceService:
    @staticmethod
    def expand_recurrence(appointment, recurrence_pattern):
        """Generate appointment instances from recurrence pattern"""
        # Parse pattern
        # Generate dates using rrule
        # Create Appointment objects for each occurrence
        # Link with series_id
        pass

    @staticmethod
    def get_available_slots(therapist_ids, date_range, duration_minutes):
        """Find available time slots for given therapists"""
        # Get therapist availability
        # Get existing appointments
        # Calculate free slots
        # Return sorted list of available slots with availability %
        pass
```

#### Task 1.4: Add API Endpoints
**File:** `backend/clinic/views.py`

```python
# Add to AppointmentViewSet

@action(detail=False, methods=['post'])
def create_recurring(self, request):
    """Create a recurring appointment series"""
    # Validate recurrence_pattern
    # Create master appointment
    # Expand into individual occurrences
    # Return created appointments

@action(detail=True, methods=['post'])
def update_series(self, request, pk=None):
    """Update all appointments in a series"""
    # Find all appointments with same series_id
    # Apply updates to all/future only

@action(detail=True, methods=['post'])
def delete_series(self, request, pk=None):
    """Delete all appointments in a series"""
    # Options: this only, this and future, all

@action(detail=False, methods=['get'])
def available_slots(self, request):
    """Get available time slots for scheduling"""
    # Params: therapist_ids[], date, duration_minutes
    # Returns: list of available slots with % availability
```

#### Task 1.5: Add Availability Endpoints
**File:** `backend/clinic/views.py`

```python
class TherapistAvailabilityViewSet(viewsets.ModelViewSet):
    """CRUD for therapist weekly availability"""

@action(detail=False, methods=['get'])
def check_conflicts(self, request):
    """Check if a proposed time conflicts with existing appointments"""
    # Params: therapist_ids[], start_time, end_time
    # Returns: conflicts list, availability percentage
```

---

### Phase 2: Flutter API Service Updates

#### Task 2.1: Update Appointment Model
**File:** `lib/services/api/appointment_api_service.dart`

```dart
class Appointment {
  // ... existing fields

  // Add new fields
  final RecurrencePattern? recurrencePattern;
  final String? seriesId;
  final bool isSeriesMaster;

  // Add computed property
  bool get isRecurring => recurrencePattern != null;
}

class RecurrencePattern {
  final bool isRecurring;
  final String frequency;  // daily, weekly, biweekly, monthly
  final int interval;
  final List<String> daysOfWeek;  // MO, TU, WE, TH, FR, SA, SU
  final DateTime? endDate;
  final int? endAfterOccurrences;
  final bool allDay;

  factory RecurrencePattern.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### Task 2.2: Add New API Methods
**File:** `lib/services/api/appointment_api_service.dart`

```dart
// Create recurring appointment
Future<AppointmentCreateResult> createRecurringAppointment({
  required String patientId,
  required String appointmentType,
  required DateTime startTime,
  required DateTime endTime,
  required RecurrencePattern recurrence,
  String? therapistId,
  // ... other fields
});

// Get available slots
Future<AvailableSlotsResult> getAvailableSlots({
  required List<String> therapistIds,
  required DateTime date,
  required int durationMinutes,
  RecurrencePattern? recurrence,  // For recurring suggestions
});

// Update series
Future<AppointmentUpdateResult> updateSeries({
  required String appointmentId,
  required Map<String, dynamic> updates,
  required SeriesUpdateScope scope,  // thisOnly, thisAndFuture, all
});

// Delete series
Future<bool> deleteSeries({
  required String appointmentId,
  required SeriesDeleteScope scope,
});

enum SeriesUpdateScope { thisOnly, thisAndFuture, all }
enum SeriesDeleteScope { thisOnly, thisAndFuture, all }
```

---

### Phase 3: Frontend UI Components

#### Task 3.1: Create Inline Date/Time Picker Widget
**File:** `lib/widgets/inline_datetime_picker.dart` (new)

```dart
class InlineDateTimePicker extends StatelessWidget {
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;

  // Renders: [Date 📅] [Start Time ▼] [End Time ▼] [🌐]
}
```

#### Task 3.2: Create Recurrence Selector Widget
**File:** `lib/widgets/recurrence_selector.dart` (new)

```dart
class RecurrenceSelector extends StatefulWidget {
  final RecurrencePattern? pattern;
  final ValueChanged<RecurrencePattern?> onChanged;
}

class _RecurrenceSelectorState extends State<RecurrenceSelector> {
  bool _isRecurring = false;
  bool _isAllDay = false;
  String _frequency = 'weekly';
  int _interval = 1;
  Set<String> _selectedDays = {};
  DateTime? _endDate;

  // Renders:
  // [☐ All day] [🔄 Recurring toggle]
  // ─────────────────────────────────
  // If recurring:
  // Repeat every [1▼] [week▼]
  // [M][T][W][T][F][S][S]  Until [date📅][🗑]
}
```

#### Task 3.3: Create Time Suggestions Widget
**File:** `lib/widgets/time_suggestions.dart` (new)

```dart
class TimeSuggestions extends StatelessWidget {
  final List<String> therapistIds;
  final DateTime date;
  final int durationMinutes;
  final RecurrencePattern? recurrence;
  final ValueChanged<TimeSlot> onSlotSelected;

  // Fetches available slots from API
  // Renders list of suggested times with availability %
}

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final double availabilityPercentage;
  final String? recurrenceDescription;  // "Occurs every Wednesday"
}
```

#### Task 3.4: Create Scheduling Assistant Screen
**File:** `lib/screens/scheduling/scheduling_assistant.dart` (new)

```dart
class SchedulingAssistant extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay initialStartTime;
  final TimeOfDay initialEndTime;
  final List<Attendee> attendees;
  final ValueChanged<SchedulingResult> onConfirm;
}

class Attendee {
  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final bool isRequired;
  final AvailabilityStatus status;  // available, busy, tentative, outOfOffice, unknown
}

// Main UI:
// - Header with date/time selectors
// - Timeline grid (horizontal: hours, vertical: attendees)
// - Attendee list with availability indicators
// - Drag-to-select time range
// - Confirm/Cancel buttons
```

#### Task 3.5: Update Create Appointment Modal
**File:** `lib/screens/scheduling/create_appointment_modal.dart`

**Changes:**
1. Replace date/time row with `InlineDateTimePicker`
2. Add `RecurrenceSelector` after date/time row
3. Add `TimeSuggestions` panel (collapsible)
4. Add "Scheduler" button that opens `SchedulingAssistant`
5. Add therapist multi-select for attendees
6. Update form submission to handle recurrence

---

### Phase 4: Integration & Testing

#### Task 4.1: Database Migration
```bash
python manage.py makemigrations clinic
python manage.py migrate
```

#### Task 4.2: Test Recurrence Expansion
- Create recurring appointment (weekly, every Wednesday)
- Verify individual appointments created with correct dates
- Verify series_id links them
- Test update/delete series with different scopes

#### Task 4.3: Test Availability Checking
- Set therapist availability hours
- Create conflicting appointments
- Verify available_slots returns correct results
- Verify availability percentage calculation

#### Task 4.4: UI Testing
- Test date/time picker interactions
- Test recurrence toggle and day selection
- Test time suggestions loading and selection
- Test scheduling assistant drag-to-select
- Test on mobile, tablet, desktop

---

## File Changes Summary

### New Files (Frontend)
| File | Description |
|------|-------------|
| `lib/widgets/inline_datetime_picker.dart` | Compact date/time row widget |
| `lib/widgets/recurrence_selector.dart` | Recurring options widget |
| `lib/widgets/time_suggestions.dart` | Available slots suggestions |
| `lib/screens/scheduling/scheduling_assistant.dart` | Full scheduling assistant view |

### Modified Files (Frontend)
| File | Changes |
|------|---------|
| `lib/screens/scheduling/create_appointment_modal.dart` | Integrate new widgets, add Scheduler button |
| `lib/services/api/appointment_api_service.dart` | Add RecurrencePattern, new API methods |

### New Files (Backend)
| File | Description |
|------|-------------|
| `backend/clinic/services/recurrence_service.py` | RRULE expansion logic |
| `backend/clinic/migrations/00XX_add_recurrence_fields.py` | Auto-generated |

### Modified Files (Backend)
| File | Changes |
|------|---------|
| `backend/clinic/models.py` | Add series_id, TherapistAvailability |
| `backend/clinic/serializers.py` | Add TherapistAvailabilitySerializer |
| `backend/clinic/views.py` | Add new endpoints |
| `backend/clinic/urls.py` | Register new routes |

---

## Dependencies

### Python (Backend)
```
python-dateutil  # For rrule recurrence expansion
```

### Flutter (Frontend)
No new dependencies needed — using existing Flutter Material components.

---

## Estimated Scope

| Phase | Components | Complexity |
|-------|------------|------------|
| Phase 1: Backend | Model + Service + API | Medium |
| Phase 2: API Service | Dart models + methods | Low |
| Phase 3: UI Widgets | 4 new widgets + modal update | High |
| Phase 4: Testing | Integration + UI tests | Medium |

---

## UI Mockup Reference

Based on Outlook/Teams scheduling UI from screenshots:
- Compact inline date/time picker row
- Expandable recurrence options section
- Time suggestions panel with availability percentages
- Full scheduling assistant with timeline grid
