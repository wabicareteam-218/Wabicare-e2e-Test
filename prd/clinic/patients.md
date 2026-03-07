# Patients Module — PRD

> **Priority**: P0 - Core  
> **Status**: 🟡 In Progress  
> **Domain**: Clinic

---

## Overview

The Patients module is the central hub for managing patient information. It provides the patient directory, profile management, and serves as the foundation for all other clinical modules.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-P01 | As an admin, I want to view a list of all patients so that I can find a specific patient quickly | P0 | 🟢 |
| US-P02 | As an admin, I want to search patients by name so that I can find patients faster | P0 | 🟢 |
| US-P03 | As an admin, I want to filter patients by status so that I can see only active or intake patients | P0 | 🟢 |
| US-P04 | As an admin, I want to add a new patient so that I can begin their intake process | P0 | 🟢 |
| US-P05 | As a BCBA, I want to view patient details so that I can review their history | P0 | ⚪ |
| US-P06 | As an admin, I want to edit patient information so that I can keep records current | P1 | ⚪ |

---

## Functional Requirements

### Patient List

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-P01 | Display patient list with name, DOB, status, and diagnosis | P0 | 🟢 |
| FR-P02 | Search patients by first name, last name, or ID | P0 | 🟢 |
| FR-P03 | Filter patients by status (All, Active, Intake, Graduated) | P0 | 🟢 |
| FR-P04 | Display patient count by status in legend | P0 | 🟢 |
| FR-P05 | Click patient row to view details | P0 | 🟢 |
| FR-P06 | Paginate list when > 50 patients | P1 | ⚪ |

### Patient Details

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-P10 | Display patient demographics | P0 | ⚪ |
| FR-P11 | Display guardian information | P0 | ⚪ |
| FR-P12 | Display insurance information | P0 | ⚪ |
| FR-P13 | Display patient status timeline | P1 | ⚪ |

### Patient Management

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-P20 | Create new patient (starts intake flow) | P0 | 🟢 |
| FR-P21 | Edit patient information | P1 | ⚪ |
| FR-P22 | Change patient status | P1 | ⚪ |
| FR-P23 | Archive/deactivate patient | P2 | ⚪ |

---

## API Requirements

### Endpoints

```
GET    /api/v1/clinic/patients              # List patients
POST   /api/v1/clinic/patients              # Create patient
GET    /api/v1/clinic/patients/:id          # Get patient details
PATCH  /api/v1/clinic/patients/:id          # Update patient
DELETE /api/v1/clinic/patients/:id          # Archive patient
```

### List Response

```json
{
  "data": [
    {
      "id": "uuid",
      "first_name": "John",
      "last_name": "Doe",
      "date_of_birth": "2015-03-15",
      "diagnosis": "Autism Spectrum Disorder",
      "status": "active",
      "guardians": [
        {"name": "Jane Doe", "relationship": "Mother", "is_primary": true}
      ],
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "pagination": {
    "total": 125,
    "page": 1,
    "per_page": 50
  }
}
```

---

## Data Model

```
Patient
├── id: UUID (PK)
├── organization_id: UUID (FK) [required]
├── first_name: string(100) [required]
├── last_name: string(100) [required]
├── date_of_birth: date [required]
├── diagnosis: string(500)
├── status: enum [intake, active, graduated, discharged]
├── created_by: UUID (FK to User)
├── created_at: datetime
└── updated_at: datetime

Guardian
├── id: UUID (PK)
├── patient_id: UUID (FK)
├── name: string(200) [required]
├── relationship: string(50) [required]
├── phone: string(20)
├── email: string(255)
├── address: text
├── is_primary: boolean [default: false]
└── created_at: datetime
```

---

## UI Screens

| Screen | Route | Status |
|--------|-------|--------|
| Patient List | `/patients` | 🟢 |
| New Patient Intake | `/patients/new` | 🟢 |
| Patient Details | `/patients/:id` | ⚪ |
| Edit Patient | `/patients/:id/edit` | ⚪ |

---

## Business Rules

1. **Org Scoping**: Patients are always scoped to the user's organization
2. **Status Flow**: `intake` → `active` → `graduated` OR `discharged`
3. **Primary Guardian**: Each patient must have exactly one primary guardian
4. **Soft Delete**: Archived patients are soft-deleted, not removed

---

## Tasks Reference

See [../../tasks/clinic.md](../../tasks/clinic.md) for implementation tasks.
