# Parent Portal Module — PRD

> **Priority**: P2 - Nice to Have  
> **Status**: ⚪ Not Started

---

## Overview

The Parent Portal provides a dedicated interface for parents/guardians to view their child's therapy progress, upcoming sessions, session notes, and complete intake forms. It also enables communication with therapists and access to resources.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-PP01 | As a parent, I want to see my child's schedule so that I know when appointments are | P2 | ⚪ |
| US-PP02 | As a parent, I want to see session notes so that I know what happened in therapy | P2 | ⚪ |
| US-PP03 | As a parent, I want to sign forms online so that I can complete intake remotely | P1 | ⚪ |
| US-PP04 | As a parent, I want to view my child's goals so that I can track progress | P2 | ⚪ |
| US-PP05 | As a parent, I want to message my child's therapist so that I can ask questions | P2 | ⚪ |
| US-PP06 | As a parent, I want to access resources so that I can support therapy at home | P2 | ⚪ |
| US-PP07 | As a parent, I want to join a community so that I can connect with other parents | P3 | ⚪ |

---

## Functional Requirements

### Dashboard (`/parent-portal`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PP01 | Child profile card with photo, age, therapist | P2 | ⚪ |
| FR-PP02 | Current goals with progress bars | P2 | ⚪ |
| FR-PP03 | Upcoming sessions list | P2 | ⚪ |
| FR-PP04 | Recent session notes summary | P2 | ⚪ |
| FR-PP05 | Quick actions (message therapist, view schedule) | P2 | ⚪ |
| FR-PP06 | Pending forms/documents alert | P2 | ⚪ |

### Goals & Progress

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PP10 | List of active goals | P2 | ⚪ |
| FR-PP11 | Goal progress percentage | P2 | ⚪ |
| FR-PP12 | Goal category (Social, Academic, Behavioral) | P2 | ⚪ |
| FR-PP13 | Goal history/timeline | P2 | ⚪ |
| FR-PP14 | Mastered goals archive | P2 | ⚪ |

### Schedule

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PP20 | Upcoming appointments calendar | P2 | ⚪ |
| FR-PP21 | Session type (In-Person, Telehealth) | P2 | ⚪ |
| FR-PP22 | Therapist assignment | P2 | ⚪ |
| FR-PP23 | Cancel/reschedule request | P2 | ⚪ |
| FR-PP24 | Add to personal calendar (iCal, Google) | P2 | ⚪ |

### Session Notes

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PP30 | List of past session notes | P2 | ⚪ |
| FR-PP31 | Note details (date, therapist, summary) | P2 | ⚪ |
| FR-PP32 | Download notes as PDF | P2 | ⚪ |
| FR-PP33 | Search notes | P2 | ⚪ |
| FR-PP34 | Filter by date range | P2 | ⚪ |

### Intake Forms (`/parent-portal/intake`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PP40 | List of required forms | P1 | ⚪ |
| FR-PP41 | Form completion status | P1 | ⚪ |
| FR-PP42 | Fill out forms online | P1 | ⚪ |
| FR-PP43 | Electronic signature | P1 | ⚪ |
| FR-PP44 | Upload supporting documents | P1 | ⚪ |
| FR-PP45 | Save and resume later | P1 | ⚪ |
| FR-PP46 | Form submission confirmation | P1 | ⚪ |

### Communication

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PP50 | Message therapist | P2 | ⚪ |
| FR-PP51 | View message history | P2 | ⚪ |
| FR-PP52 | Receive notifications | P2 | ⚪ |
| FR-PP53 | Therapist contact info | P2 | ⚪ |

### Resources (`/parent-portal/resources`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PP60 | Resource library (articles, videos) | P2 | ⚪ |
| FR-PP61 | Categorized by topic | P2 | ⚪ |
| FR-PP62 | Downloadable materials | P2 | ⚪ |
| FR-PP63 | Home activity suggestions | P2 | ⚪ |
| FR-PP64 | Search resources | P2 | ⚪ |

### Community (`/parent-portal/community`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PP70 | Discussion forums | P3 | ⚪ |
| FR-PP71 | Parent support groups | P3 | ⚪ |
| FR-PP72 | Events calendar | P3 | ⚪ |
| FR-PP73 | Anonymous posting option | P3 | ⚪ |

### Directory (`/parent-portal/directory`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PP80 | Staff directory | P2 | ⚪ |
| FR-PP81 | Staff profiles | P2 | ⚪ |
| FR-PP82 | Contact information | P2 | ⚪ |

---

## UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│ 👤 Emma Johnson                                             │
│ Age 8 • 3rd Grade                                           │
│ Therapist: Sarah Martinez, BCBA                             │
├───────────────────────────┬─────────────────────────────────┤
│ Current Goals             │ Upcoming Sessions               │
│ ┌───────────────────────┐ │ ┌─────────────────────────────┐ │
│ │ Social Interaction    │ │ │ Tomorrow 10:00 AM           │ │
│ │ ████████░░ 75%        │ │ │ Sarah Martinez • In-Person  │ │
│ ├───────────────────────┤ │ ├─────────────────────────────┤ │
│ │ Multi-Step Instruct.  │ │ │ Wed 2:00 PM                 │ │
│ │ ██████░░░░ 60%        │ │ │ Sarah Martinez • In-Person  │ │
│ ├───────────────────────┤ │ └─────────────────────────────┘ │
│ │ Emotional Regulation  │ │                                 │
│ │ ████░░░░░░ 45%        │ │ [View Full Schedule]            │
│ └───────────────────────┘ │                                 │
├───────────────────────────┼─────────────────────────────────┤
│ Recent Session Notes      │ Quick Actions                   │
│ ┌───────────────────────┐ │ [Message Therapist]            │
│ │ Jan 20 - Great prog...│ │ [View Goals]                   │
│ │ Jan 18 - Worked on... │ │ [Resources]                    │
│ │ Jan 15 - Focus on...  │ │ [Complete Forms]               │
│ └───────────────────────┘ │                                 │
└───────────────────────────┴─────────────────────────────────┘
```

---

## API Requirements

```
# Dashboard
GET    /api/v1/parent/dashboard
GET    /api/v1/parent/children/:id

# Goals
GET    /api/v1/parent/children/:id/goals
GET    /api/v1/parent/children/:id/goals/:goalId

# Schedule
GET    /api/v1/parent/children/:id/sessions
POST   /api/v1/parent/children/:id/sessions/:id/cancel

# Session Notes
GET    /api/v1/parent/children/:id/notes
GET    /api/v1/parent/children/:id/notes/:noteId

# Intake
GET    /api/v1/parent/intake/forms
GET    /api/v1/parent/intake/forms/:id
POST   /api/v1/parent/intake/forms/:id/submit
POST   /api/v1/parent/intake/forms/:id/sign

# Communication
GET    /api/v1/parent/messages
POST   /api/v1/parent/messages
GET    /api/v1/parent/therapist

# Resources
GET    /api/v1/parent/resources
GET    /api/v1/parent/resources/:id
```

---

## Data Models

```
ParentChild
├── id: UUID
├── parent_user_id: UUID
├── patient_id: UUID
├── relationship: enum [parent, guardian, other]
├── is_primary: boolean
├── created_at: datetime

ParentResource
├── id: UUID
├── organization_id: UUID
├── title: string
├── description: text
├── category: string
├── type: enum [article, video, document]
├── url: string
├── is_public: boolean
├── created_at: datetime

ParentIntakeForm
├── id: UUID
├── patient_id: UUID
├── parent_user_id: UUID
├── form_type: string
├── data: JSONB
├── status: enum [pending, in_progress, completed]
├── signature_url: string?
├── submitted_at: datetime?
├── created_at: datetime
```

---

## Security

- Parents can only see their own children's data
- Multi-child support (parent with multiple patients)
- Guardian verification during intake
- Session notes may be redacted for clinical sensitivity
- All API calls require parent authentication

---

## Integration Points

| System | Integration |
|--------|-------------|
| Intake | Form completion |
| Sessions | Session notes |
| Scheduling | Appointment display |
| Communications | Messaging |

---

## Tasks Reference

See [tasks/parent-portal.md](../tasks/parent-portal.md) for implementation tasks.
