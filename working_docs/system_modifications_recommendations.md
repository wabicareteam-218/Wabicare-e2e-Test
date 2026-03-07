# System Modifications Recommendations

## Overview

Based on the end-to-end testing of the John Doe patient lifecycle (intake → assessment → authorization → session → report), this document details the required system modifications to fully support ABA therapy workflows.

> **See Also**: [Domain Architecture](./domain_architecture.md) - Comprehensive 8-domain architecture for scalable multi-tenant SaaS deployment.

**Test Results Summary:**
- Patient: John Doe (ID: `438fc19d-37fc-4542-b460-bcb969720c61`)
- Intake: `9c743180-8975-4dc4-96a4-9190ba8222ab` (Status: approved)
- Session: `f8de288c-9f31-4d0e-8bc7-a16a01b4437c` (Status: completed)
- All data successfully stored using JSON fields as workaround

---

## Priority 0: Critical Models (Required for Production)

### 1. Authorization Model

**Current State:** Not implemented. Data stored in `intake.form_data.authorization`.

**Recommendation:** Create dedicated model in `backend/clinic/models.py`:

```python
class Authorization(models.Model):
    """Insurance authorization for ABA services."""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('exhausted', 'Exhausted'),
        ('denied', 'Denied'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='authorizations')
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='authorizations')
    intake = models.ForeignKey(Intake, on_delete=models.SET_NULL, null=True, blank=True, related_name='authorizations')
    
    # Payer info
    payer_name = models.CharField(max_length=255)
    payer_id = models.CharField(max_length=100, blank=True, null=True)
    authorization_number = models.CharField(max_length=100)
    
    # Authorization period
    start_date = models.DateField()
    end_date = models.DateField()
    
    # Services
    services_authorized = models.JSONField(default=list)  # [{cpt_code, description, units_approved, units_used}]
    
    # Status tracking
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='pending')
    
    # Notes
    notes = models.TextField(blank=True, null=True)
    
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'authorizations'
        indexes = [
            models.Index(fields=['organization']),
            models.Index(fields=['patient']),
            models.Index(fields=['status']),
            models.Index(fields=['end_date']),
        ]
```

**API Endpoints Needed:**
- `GET /api/v1/authorizations/` - List authorizations
- `POST /api/v1/authorizations/` - Create authorization
- `GET /api/v1/authorizations/<id>/` - Get authorization details
- `PATCH /api/v1/authorizations/<id>/` - Update authorization
- `GET /api/v1/authorizations/expiring/` - Get expiring authorizations (alert system)

### 2. Assessment Model

**Current State:** Not implemented. Data stored in `intake.form_data.assessment_completed`.

**Recommendation:** Create dedicated model:

```python
class Assessment(models.Model):
    """Clinical assessments (VB-MAPP, ABLLS-R, FBA, etc.)."""
    
    ASSESSMENT_TYPES = [
        ('vb-mapp', 'VB-MAPP'),
        ('ablls-r', 'ABLLS-R'),
        ('fba', 'Functional Behavior Assessment'),
        ('afls', 'AFLS'),
        ('psychological', 'Psychological Evaluation'),
        ('other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('in-progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='assessments')
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='assessments')
    intake = models.ForeignKey(Intake, on_delete=models.SET_NULL, null=True, blank=True, related_name='assessments')
    appointment = models.ForeignKey(Appointment, on_delete=models.SET_NULL, null=True, blank=True)
    
    assessment_type = models.CharField(max_length=50, choices=ASSESSMENT_TYPES)
    assessment_date = models.DateField()
    assessor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='conducted_assessments')
    
    # Scores and data (flexible JSON for different assessment types)
    scores = models.JSONField(default=dict)  # Domain scores, totals, etc.
    raw_data = models.JSONField(default=dict)  # Item-level data
    barriers = models.JSONField(default=list)  # Identified barriers
    recommendations = models.JSONField(default=list)  # Treatment recommendations
    
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='scheduled')
    notes = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'assessments'
```

**VB-MAPP Specific Structure (for `scores` field):**
```json
{
    "milestones_total": 25,
    "level": 1,
    "domains": [
        {"name": "Mand", "score": 3, "max": 10},
        {"name": "Tact", "score": 2, "max": 10},
        ...
    ]
}
```

---

## Priority 1: Session Data Collection Models

### 3. Program Model

**Current State:** Not implemented. Goals stored in `session.data_collected.goals_worked`.

**Recommendation:**

```python
class Program(models.Model):
    """BCBA-created treatment programs."""
    
    PROGRAM_TYPES = [
        ('skill-acquisition', 'Skill Acquisition'),
        ('behavior-reduction', 'Behavior Reduction'),
        ('maintenance', 'Maintenance'),
    ]
    
    DOMAINS = [
        ('communication', 'Communication'),
        ('social', 'Social'),
        ('play', 'Play'),
        ('daily-living', 'Daily Living'),
        ('academic', 'Academic'),
        ('behavior', 'Behavior'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='programs')
    
    name = models.CharField(max_length=255)
    program_type = models.CharField(max_length=50, choices=PROGRAM_TYPES)
    domain = models.CharField(max_length=50, choices=DOMAINS)
    
    description = models.TextField(blank=True, null=True)
    mastery_criteria = models.CharField(max_length=255)
    prompt_hierarchy = models.JSONField(default=list)  # ['independent', 'gestural', 'verbal', 'model', 'physical']
    
    status = models.CharField(max_length=50, default='active')
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'programs'
```

### 4. Target Model

```python
class Target(models.Model):
    """Specific targets within a program."""
    
    STATUS_CHOICES = [
        ('baseline', 'Baseline'),
        ('acquisition', 'Acquisition'),
        ('mastered', 'Mastered'),
        ('maintenance', 'Maintenance'),
        ('generalization', 'Generalization'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    program = models.ForeignKey(Program, on_delete=models.CASCADE, related_name='targets')
    
    name = models.CharField(max_length=255)
    sd = models.TextField(blank=True, null=True)  # Discriminative stimulus
    target_response = models.TextField(blank=True, null=True)
    
    data_collection_type = models.CharField(max_length=50)  # 'dtt', 'frequency', 'duration', 'abc'
    current_prompt_level = models.CharField(max_length=50, blank=True, null=True)
    
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='baseline')
    baseline_data = models.JSONField(default=dict)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'targets'
```

### 5. TrialData Model

```python
class TrialData(models.Model):
    """Trial-by-trial data for DTT."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='trial_data')
    target = models.ForeignKey(Target, on_delete=models.CASCADE, related_name='trial_data')
    
    trial_number = models.IntegerField()
    response = models.CharField(max_length=50)  # 'correct', 'incorrect', 'no-response'
    prompt_level = models.CharField(max_length=50, blank=True, null=True)
    
    timestamp = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True, null=True)

    class Meta:
        db_table = 'trial_data'
        indexes = [
            models.Index(fields=['session']),
            models.Index(fields=['target']),
        ]
```

### 6. BehaviorData Model

```python
class BehaviorData(models.Model):
    """ABC behavior data collection."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='behavior_data')
    
    behavior_name = models.CharField(max_length=255)
    behavior_definition = models.TextField(blank=True, null=True)
    
    # ABC data
    antecedent = models.TextField(blank=True, null=True)
    behavior_description = models.TextField()
    consequence = models.TextField(blank=True, null=True)
    
    # Measurement
    occurrence_time = models.TimeField()
    duration_seconds = models.IntegerField(blank=True, null=True)
    intensity = models.CharField(max_length=50, blank=True, null=True)  # 'mild', 'moderate', 'severe'
    
    function = models.CharField(max_length=50, blank=True, null=True)  # 'attention', 'escape', 'access', 'automatic'
    
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'behavior_data'
```

---

## Priority 1: Patient Model Extensions

### 7. Extend Patient Model

Add these fields to the existing Patient model:

```python
# Add to Patient model
mrn = models.CharField(max_length=100, blank=True, null=True)  # Medical Record Number
student_id = models.CharField(max_length=100, blank=True, null=True)
home_language = models.CharField(max_length=100, default='English')

# Enhanced medical fields (consider separate JSONFields or models)
referring_provider = models.JSONField(default=dict, blank=True)  # {name, clinic, phone, npi}
primary_care_provider = models.JSONField(default=dict, blank=True)  # {name, clinic, phone, npi}

# ICD-10 codes (important for billing)
icd_codes = models.JSONField(default=list, blank=True)  # ['F84.0', 'R62.50', 'F80.9']

# Enhanced diagnosis info
diagnosis_details = models.JSONField(default=dict, blank=True)  # {severity, diagnosed_by, date, etc.}
```

---

## Priority 2: API Endpoints

### 8. New API Endpoints Required

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/authorizations/` | GET, POST | List/Create authorizations |
| `/api/v1/authorizations/<id>/` | GET, PATCH, DELETE | CRUD for authorization |
| `/api/v1/authorizations/expiring/` | GET | Get authorizations expiring soon |
| `/api/v1/assessments/` | GET, POST | List/Create assessments |
| `/api/v1/assessments/<id>/` | GET, PATCH | CRUD for assessment |
| `/api/v1/programs/` | GET, POST | List/Create programs |
| `/api/v1/programs/<id>/targets/` | GET, POST | Targets within program |
| `/api/v1/sessions/<id>/trials/` | GET, POST | Trial data for session |
| `/api/v1/sessions/<id>/behaviors/` | GET, POST | Behavior data for session |
| `/api/v1/sessions/<id>/report/` | GET | Generate session report |
| `/api/v1/patients/<id>/progress/` | GET | Patient progress summary |

---

## Priority 2: Frontend Updates

### 9. Intake Workspace Updates

- Add assessment data display section
- Add authorization status and details view
- Connect document upload to backend
- Add signature capture functionality

### 10. Session Workspace Updates

- Implement Reporting tab (currently placeholder)
- Add real-time data sync (currently offline storage only)
- Add session report generation button
- Add parent signature capture for session notes

### 11. New Screens Needed

- Authorization management screen (`/billing/authorizations`)
- Assessment management screen (`/clinic/assessments`)
- Program management screen (`/clinic/programs`)
- Progress report viewer (`/clinic/reports`)

---

## Database Migration Plan

### Phase 1: Core Models
1. Create Authorization model
2. Create Assessment model
3. Extend Patient model
4. Run migrations

### Phase 2: Session Data Models
1. Create Program model
2. Create Target model
3. Create TrialData model
4. Create BehaviorData model
5. Run migrations

### Phase 3: Data Migration
1. Migrate authorization data from `intake.form_data` to Authorization model
2. Migrate assessment data from `intake.form_data` to Assessment model
3. Migrate trial/behavior data from `session.data_collected` to respective models

---

## Testing Validation

The John Doe workflow test (`backend/test_john_doe_workflow.py`) successfully demonstrated:

1. **Patient Creation** - All fields from BCBA documents captured in Patient model
2. **Intake Workflow** - Form data, required items, timeline working correctly
3. **Assessment Tracking** - Data stored in form_data (needs dedicated model)
4. **Authorization** - Data stored in form_data (needs dedicated model)
5. **Session Data Collection** - Trial and behavior data captured in JSON (needs structured models)
6. **Session Report** - Generated locally (needs API endpoint)

### Data Verified in Database

```sql
-- Patient created
SELECT id, first_name, last_name, status FROM patients WHERE first_name = 'John';

-- Intake with full form_data
SELECT id, workflow_status, form_data FROM intakes WHERE patient_id = '438fc19d-...';

-- Session with data_collected
SELECT id, session_date, data_collected FROM sessions WHERE patient_id = '438fc19d-...';
```

---

## Conclusion

The current system can handle the ABA therapy workflow using JSON fields as workarounds, but for production use, the following priorities should be addressed:

**Immediate (P0):**
1. Authorization model - Critical for billing and compliance
2. Assessment model - Critical for clinical workflows

**Short-term (P1):**
3. Program/Target/TrialData/BehaviorData models - For proper data collection
4. Session report generation API
5. Patient model extensions

**Medium-term (P2):**
6. Frontend updates for new models
7. Data migration from JSON fields to structured tables
8. Progress reporting and analytics

The test script (`test_john_doe_workflow.py`) can be used as a reference for expected data structures and workflow validation.
