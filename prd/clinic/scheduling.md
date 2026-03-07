# Scheduling Module — PRD

> **Priority**: P0 - Core  
> **Status**: ⚪ Not Started (UI done, needs backend)  
> **Domain**: Clinic

---

## Overview

The Scheduling module manages appointments, provider availability, and calendar views for the clinic.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-SC01 | As an admin, I want to view the weekly calendar so that I can see all appointments | P0 | 🟢 |
| US-SC02 | As an admin, I want to create appointments so that I can schedule sessions | P0 | ⚪ |
| US-SC03 | As a BCBA, I want to see my schedule so that I know where to go | P0 | ⚪ |
| US-SC04 | As an admin, I want to manage provider availability so that I don't double-book | P1 | ⚪ |

---

## Functional Requirements

### Calendar Views

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-SC01 | Week view with time grid | P0 | 🟢 |
| FR-SC02 | Day view | P1 | ⚪ |
| FR-SC03 | Month view | P2 | ⚪ |
| FR-SC04 | Mini calendar for date navigation | P0 | 🟢 |
| FR-SC05 | Filter by provider | P0 | 🟢 |

### Appointment Management

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-SC10 | Create appointment | P0 | ⚪ |
| FR-SC11 | Edit appointment | P0 | ⚪ |
| FR-SC12 | Cancel appointment | P0 | ⚪ |
| FR-SC13 | Recurring appointments | P1 | ⚪ |
| FR-SC14 | Drag to reschedule | P2 | ⚪ |

---

## API Requirements

```
GET    /api/v1/clinic/appointments        # List appointments
POST   /api/v1/clinic/appointments        # Create appointment
PATCH  /api/v1/clinic/appointments/:id    # Update appointment
DELETE /api/v1/clinic/appointments/:id    # Cancel appointment
GET    /api/v1/users/availability         # Get provider availability
```

---

## Tasks Reference

See [../../tasks/clinic.md](../../tasks/clinic.md) for implementation tasks.
