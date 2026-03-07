# Dashboard Module — PRD

> **Priority**: P0 - Core  
> **Status**: ⚪ Not Started  
> **Domain**: Clinic

---

## Overview

The Dashboard is the home page users see after logging in. It provides a role-based overview of key metrics, upcoming tasks, and quick actions. Different user roles (Owner, Admin, BCBA, RBT) see different metrics and features.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-D01 | As a user, I want to see my personalized dashboard so that I can get an overview of my work | P0 | ⚪ |
| US-D02 | As an owner, I want to see organization-wide metrics so that I can monitor business health | P0 | ⚪ |
| US-D03 | As a BCBA, I want to see my caseload stats so that I can prioritize my work | P0 | ⚪ |
| US-D04 | As an RBT, I want to see my today's schedule so that I know where to go | P0 | ⚪ |
| US-D05 | As a user, I want quick actions so that I can navigate to common tasks | P0 | ⚪ |

---

## Functional Requirements

### Role-Based Metrics

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-D01 | Display welcome message with user name and role | P0 | ⚪ |
| FR-D02 | Show role-appropriate metric cards | P0 | ⚪ |
| FR-D03 | Owner/Admin: Total students, staff, revenue, utilization | P0 | ⚪ |
| FR-D04 | BCBA: Caseload, assessments due, goal completion | P0 | ⚪ |
| FR-D05 | RBT: Today's sessions, hours, patients | P0 | ⚪ |

### Dashboard Components

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-D10 | Metric cards with icons, values, and trends | P0 | ⚪ |
| FR-D11 | Today's schedule preview | P0 | ⚪ |
| FR-D12 | Calendar widget with appointment markers | P1 | ⚪ |
| FR-D13 | Recent activity feed | P1 | ⚪ |
| FR-D14 | Quick actions panel | P0 | ⚪ |
| FR-D15 | Pending tasks/notifications | P1 | ⚪ |

### Owner-Specific Dashboard

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-D20 | Organization settings card | P1 | ⚪ |
| FR-D21 | Revenue metrics | P1 | ⚪ |
| FR-D22 | Staff overview | P1 | ⚪ |
| FR-D23 | Compliance/authorization alerts | P1 | ⚪ |

---

## Metric Cards by Role

### Owner/Admin
| Metric | Icon | Description |
|--------|------|-------------|
| Total Students | Users | All enrolled patients |
| Total Staff | Users | BCBAs and RBTs |
| Monthly Revenue | DollarSign | Billing this month |
| Utilization Rate | TrendingUp | Session hours / authorized |

### BCBA
| Metric | Icon | Description |
|--------|------|-------------|
| Active Caseload | Users | Assigned patients |
| Assessments Due | FileText | Pending evaluations |
| Goal Progress | Target | Average goal completion |
| Sessions This Week | Calendar | Supervised sessions |

### RBT
| Metric | Icon | Description |
|--------|------|-------------|
| Today's Sessions | Calendar | Sessions scheduled today |
| Hours This Week | Clock | Session hours logged |
| Patients Today | Users | Unique patients |
| Tasks Pending | ClipboardList | Items requiring attention |

---

## UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Welcome back, John! 👋                                      │
│ BCBA • ABC Therapy Center                                   │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐            │
│ │ Metric 1│ │ Metric 2│ │ Metric 3│ │ Metric 4│            │
│ │   24    │ │   156   │ │    8    │ │   78%   │            │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘            │
├─────────────────────────┬───────────────────────────────────┤
│ Today's Schedule        │ Mini Calendar                     │
│ ┌─────────────────────┐ │ ┌───────────────────────────────┐ │
│ │ 9:00 AM - Patient A │ │ │       January 2026            │ │
│ │ 10:30 AM - Patient B│ │ │  Mo Tu We Th Fr Sa Su         │ │
│ │ 1:00 PM - Patient C │ │ │  ... [calendar] ...           │ │
│ └─────────────────────┘ │ └───────────────────────────────┘ │
├─────────────────────────┴───────────────────────────────────┤
│ Quick Actions                                               │
│ [New Session] [View Schedule] [Reports] [Assessments]       │
└─────────────────────────────────────────────────────────────┘
```

---

## API Requirements

```
GET /api/v1/dashboard/metrics       # Role-based metrics
GET /api/v1/dashboard/schedule      # Today's appointments
GET /api/v1/dashboard/tasks         # Pending tasks
GET /api/v1/dashboard/activity      # Recent activity feed
```

---

## Tasks Reference

See [../../tasks/clinic.md](../../tasks/clinic.md) for implementation tasks.
