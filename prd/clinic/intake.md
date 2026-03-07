# Intake Module — PRD

> **Priority**: P0 - Core  
> **Status**: 🟡 In Progress  
> **Domain**: Clinic

---

## Overview

The Intake module manages the new patient onboarding workflow. When a new patient is created, they begin in "Intake" status and progress through a series of forms and approvals before becoming "Active".

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-I01 | As an admin, I want to start a new patient intake so that I can onboard them properly | P0 | 🟢 |
| US-I02 | As an admin, I want to collect parent/guardian information so that I have emergency contacts | P0 | 🟢 |
| US-I03 | As an admin, I want to collect insurance information so that I can verify coverage | P0 | 🟢 |
| US-I04 | As an admin, I want to track which intake forms are complete so that I know what's pending | P0 | 🟢 |
| US-I05 | As an admin, I want to send intake forms to parents so that they can fill them out | P1 | ⚪ |
| US-I06 | As a parent, I want to sign consent forms electronically so that I can complete intake remotely | P1 | ⚪ |
| US-I07 | As an admin, I want to change patient status to Active when intake is complete | P0 | ⚪ |

---

## Functional Requirements

### Intake Wizard

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-I01 | Display 3-tab wizard (Profile, Intake Forms, Documents) | P0 | 🟢 |
| FR-I02 | Profile tab: collect patient basic info | P0 | 🟢 |
| FR-I03 | Profile tab: collect guardian information | P0 | 🟢 |
| FR-I04 | Profile tab: collect insurance information | P0 | 🟢 |
| FR-I05 | Intake Forms tab: display form checklist with progress | P0 | 🟢 |
| FR-I06 | Track form completion status (pending/in progress/complete) | P0 | ⚪ |
| FR-I07 | Documents tab: upload/view intake documents | P1 | ⚪ |

### Intake Forms

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-I10 | HIPAA Notice of Privacy form | P0 | 🟢 |
| FR-I11 | Consent for Treatment form | P0 | ⚪ |
| FR-I12 | Medical History form | P0 | 🟢 |
| FR-I13 | Behavioral Questionnaire form | P0 | 🟢 |
| FR-I14 | Insurance Authorization form | P1 | ⚪ |
| FR-I15 | Photo/Video Release form | P2 | ⚪ |
| FR-I16 | Electronic signature capture | P1 | ⚪ |

### E-Signature Integration

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-I30 | Send signature request to parent email | P1 | ⚪ |
| FR-I31 | Support DocuSign or HelloSign webhook | P2 | ⚪ |
| FR-I32 | In-app signature pad (fallback) | P1 | ⚪ |
| FR-I33 | Store signed document URL | P1 | ⚪ |
| FR-I34 | Download signed PDF | P1 | ⚪ |
| FR-I35 | Signature status tracking (pending/signed) | P1 | ⚪ |

### Intake Workflow

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-I20 | Phase 1: Client profile (patient + guardian + insurance) | P0 | 🟢 |
| FR-I21 | Phase 2: Assessment scheduling | P1 | ⚪ |
| FR-I22 | Phase 3: Insurance verification | P1 | ⚪ |
| FR-I23 | Complete intake and change status to Active | P0 | ⚪ |

---

## API Requirements

### Endpoints

```
GET    /api/v1/clinic/patients/:id/intake           # Get intake workspace
POST   /api/v1/clinic/patients/:id/intake/forms     # Submit a form
PATCH  /api/v1/clinic/patients/:id/intake/forms/:id # Update form
POST   /api/v1/clinic/patients/:id/intake/complete  # Complete intake
```

### Intake Workspace Response

```json
{
  "patient": {
    "id": "uuid",
    "first_name": "John",
    "last_name": "Doe",
    "status": "intake"
  },
  "intake": {
    "phase": 1,
    "progress_percent": 35,
    "forms": [
      {
        "id": "form-1",
        "type": "hipaa_notice",
        "name": "HIPAA Notice",
        "status": "complete",
        "required": true,
        "submitted_at": "2024-01-15T10:00:00Z"
      },
      {
        "id": "form-2",
        "type": "consent_treatment",
        "name": "Consent for Treatment",
        "status": "pending",
        "required": true,
        "submitted_at": null
      }
    ]
  },
  "guardians": [...],
  "insurance": {...}
}
```

---

## Data Model

```
IntakeForm
├── id: UUID (PK)
├── patient_id: UUID (FK)
├── form_type: enum [hipaa_notice, consent_treatment, medical_history, ...]
├── status: enum [pending, in_progress, complete, rejected]
├── form_data: JSONB
├── signature: text (base64)
├── signed_at: datetime
├── signed_by: string
├── submitted_at: datetime
└── created_at: datetime

IntakeDocument
├── id: UUID (PK)
├── patient_id: UUID (FK)
├── document_type: string
├── file_url: string
├── file_name: string
├── uploaded_by: UUID (FK)
└── uploaded_at: datetime
```

---

## UI Screens

| Screen | Route | Status |
|--------|-------|--------|
| Intake Wizard | `/patients/new` | 🟢 |
| Profile Tab | `/patients/new?tab=profile` | 🟢 |
| Intake Forms Tab | `/patients/new?tab=forms` | 🟢 |
| Documents Tab | `/patients/new?tab=documents` | ⚪ |
| Individual Form View | `/patients/:id/intake/forms/:formId` | ⚪ |

---

## Business Rules

1. **Required Forms**: HIPAA Notice and Consent for Treatment must be signed before activation
2. **Guardian Signature**: Forms require guardian signature for minors
3. **Form Versioning**: Keep history of form submissions
4. **Phase Progression**: Phase 2+ requires Phase 1 complete

---

## Wireframe Reference

The intake wizard matches this design:

```
┌─────────────────────────────────────────────────────────────────┐
│ New Patient Intake                              Save │ Cancel  │
├─────────────────────────────────────────────────────────────────┤
│ [Profile] [Intake Forms] [Documents]                            │
├──────────────────────┬──────────────────────────────────────────┤
│ Intake Forms         │  Medical History                         │
│                      │  ┌─────────────────────────────────────┐ │
│ ● HIPAA Notice       │  │ Allergies:                          │ │
│ ○ Consent Treatment  │  │ ____________________________        │ │
│ ○ Medical History    │  │                                     │ │
│ ○ Behavioral Quest.  │  │ Current Medications:                │ │
│                      │  │ ____________________________        │ │
│                      │  └─────────────────────────────────────┘ │
└──────────────────────┴──────────────────────────────────────────┘
```

---

## Tasks Reference

See [../../tasks/clinic.md](../../tasks/clinic.md) for implementation tasks.
