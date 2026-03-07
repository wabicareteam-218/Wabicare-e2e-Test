# Architecture Migration Phases

## Overview
Complete migration to Domain-Driven Design with Event Architecture.

## Completed
- ✅ Backend models split into domain modules
- ✅ Frontend barrel file structure created
- ✅ All 8 domain folders created

---

## Phase A: Backend Views & Serializers Split (Clinic Domain)

**Goal**: Split monolithic views.py and serializers.py into domain modules

**Files to Split**:
```
backend/clinic/views.py (4,400+ lines) →
├── intake/views.py        (PatientViewSet, IntakeViewSet, IntakeSectionCompletionViewSet, ParentFormViewSet)
├── scheduling/views.py    (AppointmentViewSet, TherapistAvailabilityViewSet, TherapistTimeOffViewSet)
├── sessions/views.py      (SessionViewSet, ProgramViewSet, TargetViewSet, TrialDataViewSet, BehaviorDataViewSet, AnalyticsViewSet)
├── tools/views.py         (TaskViewSet, GoalTemplateViewSet)
├── assessment/views.py    (AssessmentViewSet)
├── authorization/views.py (AuthorizationViewSet)
└── views.py               (barrel file - re-exports for backwards compatibility)

backend/clinic/serializers.py (60,000+ bytes) →
├── intake/serializers.py
├── scheduling/serializers.py
├── sessions/serializers.py
├── tools/serializers.py
├── assessment/serializers.py
├── authorization/serializers.py
└── serializers.py         (barrel file)
```

**Verification**: `python manage.py check` passes, all API endpoints work

---

## Phase B: Backend Domain Services Layer

**Goal**: Extract business logic from views into domain services

**Services to Create**:
```
backend/clinic/
├── intake/services.py
│   ├── IntakeWorkflowService      - State machine for intake status
│   ├── FormDistributionService    - Send forms to parents
│   └── DuplicatePatientDetector   - Check for existing patients
│
├── scheduling/services.py
│   ├── AppointmentSchedulingService - Create/update with conflict detection
│   ├── AvailabilityService          - Calculate available slots
│   └── RecurrenceService            - Expand recurring appointments (exists)
│
├── sessions/services.py
│   ├── SessionExecutionService    - Manage session lifecycle
│   ├── EVVComplianceService       - Validate EVV requirements
│   ├── DataCollectionService      - Record trial/behavior data
│   └── MasteryEvaluationService   - Evaluate target mastery
│
├── authorization/services.py
│   ├── AuthorizationWorkflowService - Status transitions
│   ├── UnitTrackingService          - Track units used vs approved
│   └── ExpirationAlertService       - Notify before expiration
│
└── assessment/services.py
    ├── AssessmentScoringService   - Calculate domain scores
    └── AssessmentReportGenerator  - Generate PDF reports
```

**Verification**: Views become thin controllers, logic is in services

---

## Phase C: Event Bus & Domain Events

**Goal**: Implement pub/sub pattern for cross-domain communication

**Infrastructure**:
```
backend/shared_kernel/events/
├── __init__.py
├── event_bus.py           - Singleton event dispatcher
├── base_event.py          - Base DomainEvent class
├── decorators.py          - @event_handler decorator
└── registry.py            - Event handler registry
```

**Domain Events**:
```python
# Clinic Events
PatientCreated(patient_id, organization_id)
PatientDischarged(patient_id, reason)
IntakeStatusChanged(intake_id, old_status, new_status)
IntakeApproved(intake_id, patient_id)

# Session Events
SessionStarted(session_id, patient_id, therapist_id)
SessionCompleted(session_id, duration_minutes, trials_count)
TargetMastered(target_id, program_id, patient_id)

# Authorization Events
AuthorizationApproved(auth_id, patient_id, units_approved)
AuthorizationExpiring(auth_id, days_remaining)
UnitsRunningLow(auth_id, units_remaining, threshold)

# Assessment Events
AssessmentScheduled(assessment_id, patient_id, date)
AssessmentCompleted(assessment_id, recommendations)
```

**Usage Pattern**:
```python
# In view after saving
from shared_kernel.events import event_bus, PatientCreated

def perform_create(self, serializer):
    patient = serializer.save(...)
    event_bus.publish(PatientCreated(
        patient_id=patient.id,
        organization_id=patient.organization_id
    ))
```

**Verification**: Events published and handlers called synchronously first

---

## Phase D: Frontend File Migration (Clinic Domain)

**Goal**: Move screens, services, state to feature folders

**Migration Order** (by module):
1. clinic/tools (smallest - 1 screen)
2. clinic/authorization (1 screen)
3. clinic/assessment (screens in assessments_screen.dart)
4. clinic/intake (3 screens)
5. clinic/sessions (3 screens)
6. clinic/scheduling (4 screens)

**For Each File**:
1. Move to `lib/features/clinic/{module}/screens/`
2. Update imports within moved file
3. Create re-export at old location
4. Run `flutter analyze`
5. Test app

**Verification**: `flutter analyze` passes, all screens render

---

## Phase E: Auth Domain Extraction

**Goal**: Move auth-related code from core/ to auth/ domain

**Files to Move**:
```
backend/core/
├── authentication.py    → backend/auth/authentication.py
├── permissions.py       → backend/auth/permissions.py
├── views.py (user mgmt) → backend/auth/views.py
└── parent_views.py      → backend/parent_portal/views.py

lib/services/auth/       → lib/features/auth/services/
lib/state/user_store.dart → lib/features/auth/state/
```

**Verification**: Auth flows work, permissions enforced

---

## Phase F: Frontend Migration (Remaining Domains)

**Goal**: Complete frontend file migration

**Domains**:
- auth/ (login, invitation, admin screens)
- parent_portal/ (parent screens)
- ai_insights/ (dashboard, reports)

**Verification**: All screens accessible and functional

---

## Phase G: Celery/Redis Infrastructure

**Goal**: Set up async task processing

**Configuration**:
```python
# backend/wabi/celery.py
from celery import Celery

app = Celery('wabi')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

# backend/wabi/settings.py
CELERY_BROKER_URL = 'redis://localhost:6379/0'
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
```

**Task Structure**:
```
backend/
├── clinic/
│   └── tasks.py          - Clinic-specific async tasks
├── communication/
│   └── tasks.py          - Email, SMS, notifications
└── shared_kernel/
    └── tasks.py          - Shared tasks (reporting, etc.)
```

**Verification**: Celery worker starts, tasks execute

---

## Phase H: Wire Events to Celery Tasks

**Goal**: Connect domain events to async task handlers

**Example**:
```python
# backend/clinic/intake/event_handlers.py
from shared_kernel.events import event_handler
from clinic.events import PatientCreated
from communication.tasks import send_welcome_email
from clinic.tasks import create_intake_task

@event_handler(PatientCreated)
def handle_patient_created(event: PatientCreated):
    # Dispatch to Celery for async processing
    send_welcome_email.delay(event.patient_id)
    create_intake_task.delay(event.patient_id)
```

**Verification**: Events trigger async tasks, tasks complete successfully

---

## Rollback Strategy

Each phase is a separate commit. To rollback:
```bash
git revert <commit-hash>  # Revert specific phase
# OR
git reset --hard <last-good-commit>  # Reset to known good state
```

---

## Success Criteria

- [ ] All API endpoints return same data as before
- [ ] All UI screens render and function identically
- [ ] `python manage.py check` passes
- [ ] `flutter analyze` passes (no new errors)
- [ ] Events published for key domain actions
- [ ] Celery tasks execute for async operations
