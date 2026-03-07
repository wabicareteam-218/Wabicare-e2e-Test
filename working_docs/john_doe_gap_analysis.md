# John Doe Intake - Gap Analysis Report

## Overview

This document compares data fields from the John Doe BCBA intake documents (`docs/bcba_masked/`) against the current Wabi Clinic system models to identify gaps.

---

## Patient Model Analysis

### Currently Supported Fields (Covered)

| Field | System Field | Document Value |
|-------|--------------|----------------|
| First Name | `first_name` | John |
| Last Name | `last_name` | Doe |
| Date of Birth | `date_of_birth` | 2021-07-29 |
| Gender | `gender` | Female |
| Phone | `phone` | +1385-377-3040 |
| Email | `email` | mikemandydraper@gmail.com |
| Address | `address` (JSON) | 3846 West Grouse Circle, West Valley City, UT 84120 |
| Guardian First Name | `guardian_first_name` | Mandy |
| Guardian Last Name | `guardian_last_name` | Draper |
| Guardian Email | `guardian_email` | mikemandydraper@gmail.com |
| Guardian Phone | `guardian_phone` | +1385-377-3040 |
| Guardian Relationship | `guardian_relationship` | Grandmother (Primary Custody) |
| Insurance Provider | `insurance_info.provider` | Medicaid |
| Policy Number | `insurance_info.policy_number` | 0412757890 |
| Emergency Contact | `emergency_contact` (JSON) | Mandy Draper, Grandmother |
| Diagnosis | `diagnosis` | ASD (F84.0), Level 3 |
| Medical History | `medical_history` (JSON) | Allergies, medications, conditions |
| Status | `status` | intake |

### Missing Fields (Gaps)

| Document Data | Recommended Field | Priority | Notes |
|---------------|-------------------|----------|-------|
| MRN: 22567753 | `mrn` | P1 | Medical Record Number for external systems |
| Student ID: 417304 | `student_id` | P2 | For school coordination |
| Home Language: English | `home_language` | P2 | Important for therapy |
| Referring Provider | `referring_provider` (JSON) | P1 | Jose Morales Moreno, MD - University of Utah |
| Primary Care Provider | `primary_care_provider` (JSON) | P1 | Same as referring |
| ICD-10 Codes | `icd_codes` (JSON array) | P1 | F84.0, R62.50, F80.9 |
| Diagnosis Details | `diagnosis_details` (JSON) | P1 | Severity level, diagnosed_by, date |
| Living Situation | `living_situation` | P2 | Complex custody - lives with grandparents |
| Previous Services | `previous_services` (JSON) | P2 | DDI Vantage, prior ABA |
| School Status | `school_status` | P2 | IEP information |
| Communication Method | `communication_method` | P1 | PECS, pictures |

---

## Intake Model Analysis

### Currently Supported Fields (Covered)

| Field | System Field | Document Value |
|-------|--------------|----------------|
| Referral Source | `referral_source` | Jose Morales Moreno, MD |
| Diagnosis | `diagnosis` | F84.0 - ASD |
| Workflow Status | `workflow_status` | initial-contact → approved |
| Form Data | `form_data` (JSON) | Flexible - can store assessment results |
| Required Items | `required_items` (JSON) | Checklist for consent forms |

### Missing Fields/Structures (Gaps)

| Document Data | Recommended Field/Model | Priority | Notes |
|---------------|------------------------|----------|-------|
| Assessment Results | `assessment_data` (JSON) | P0 | DAYC-2, CARS-2, CBCL, ABAS-3, ASRS scores |
| FAST Assessment | `fast_assessment` (JSON) | P1 | Functional analysis screening |
| VB-MAPP Data | Dedicated Assessment Model | P0 | Milestones, Barriers scoring |
| Treatment Recommendations | `treatment_recommendations` (JSON) | P1 | From evaluation reports |
| Presenting Concerns | `presenting_concerns` (JSON) | P1 | Behavioral, Communication, Social, Living Skills |
| Consent Forms Status | `consent_forms` (JSON) | P1 | HIPAA, Treatment, Telehealth tracking |
| IEP Information | `iep_data` (JSON) | P2 | School IEP details |
| Availability | `availability` (JSON) | P2 | Schedule preferences |

---

## Authorization Model Analysis

### Current State: NOT IMPLEMENTED

The Authorization model is defined in PRD (`docs/prd/billing.md`) but not implemented.

### Required Fields from Documents

| Field | Type | Document Value |
|-------|------|----------------|
| Authorization Number | string | (from insurance) |
| Start Date | date | 2025-04-24 |
| End Date | date | 2025-10-24 |
| Units Approved | integer | (based on service hours) |
| Units Used | integer | 0 (initial) |
| Service Type | string | CPT 97153, 97155, 97156 |
| Payer Name | string | Medicaid |
| Status | enum | active/expired/exhausted |

---

## Assessment Model Analysis

### Current State: NOT IMPLEMENTED

Assessments are tracked via `Appointment.appointment_type='assessment'` but no structured assessment data storage exists.

### Required Assessment Types

1. **VB-MAPP Assessment**
   - Milestones scoring (Levels 1-3)
   - Barriers assessment
   - Task analysis tracking

2. **ABLLS-R Assessment**
   - Skills tracking across domains

3. **Functional Behavior Assessment (FBA)**
   - FAST data (already in CSV format)
   - Target behaviors
   - Function analysis

4. **Psychological Evaluations**
   - DAYC-2 (cognitive, adaptive)
   - CARS-2 (autism severity)
   - CBCL (behavior checklist)
   - ABAS-3 (adaptive behavior)
   - ASRS (autism symptoms)

### Recommended Assessment Model

```python
class Assessment(models.Model):
    id = models.UUIDField(primary_key=True)
    organization = models.ForeignKey(Organization)
    patient = models.ForeignKey(Patient)
    intake = models.ForeignKey(Intake, null=True)
    
    assessment_type = models.CharField()  # vb-mapp, ablls-r, fba, psychological
    assessment_date = models.DateField()
    assessor = models.ForeignKey(User)  # BCBA
    
    # Scores stored as JSON for flexibility
    scores = models.JSONField(default=dict)
    raw_data = models.JSONField(default=dict)
    
    status = models.CharField()  # scheduled, in-progress, completed
    notes = models.TextField()
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

---

## Session Data Collection Models

### Current State: PARTIAL

The `Session` model has `data_collected` (JSON) but no structured models for:

1. **Program** - BCBA-created treatment programs
2. **Target** - Specific skills to teach
3. **TrialData** - DTT trial-by-trial data
4. **BehaviorData** - ABC behavior tracking

### FAST Assessment Data (from john_doe_01.csv)

Shows structured behavioral assessment:
- **Main Function**: Social - Positive (Access)
- **Sub-Functions**: Attention (2), Access (3), Escape (2), Sensory Seeking (3), Sensory Avoidant (3)

This data structure should be captured in the Assessment model.

---

## Summary of Required Changes

### Priority 0 (Critical for Testing)

1. **Create Authorization Model** - Required for 6-month authorization step
2. **Extend Patient Model** - Add `mrn`, `icd_codes`, `referring_provider`
3. **Create Assessment Model** - For structured assessment data

### Priority 1 (Important)

4. **Add Session Data Models** - Program, Target, TrialData, BehaviorData
5. **Add Report Generation** - Session reports endpoint
6. **Extend Intake Model** - Add assessment_data, consent_forms tracking

### Priority 2 (Nice to Have)

7. **Add Patient Fields** - student_id, home_language, living_situation
8. **Add Intake Fields** - availability, iep_data

---

## Test Execution Plan

Given current system limitations, we will:

1. **Create Patient** - Store extra data in `medical_history` JSON
2. **Create Intake** - Store assessment data in `form_data` JSON
3. **Schedule Assessment Appointment** - Using existing Appointment model
4. **Simulate Authorization** - Document gap, store in `notes` or `form_data`
5. **Schedule Session** - Using existing Appointment model
6. **Create Session** - Store trial/behavior data in `data_collected` JSON
7. **Generate Report** - Document gap (not implemented)

This workaround allows testing the full workflow while documenting model improvements needed.
