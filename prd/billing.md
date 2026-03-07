# Billing Module — PRD

> **Priority**: P2 - Nice to Have (MVP can start without)  
> **Status**: ⚪ Not Started

---

## Overview

The Smart Billing module manages the complete billing lifecycle from session-based claim generation to insurance submission, ERA processing, and revenue tracking. It includes AI-assisted claim validation, CPT code mapping, authorization tracking, and comprehensive reporting.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-B01 | As a billing admin, I want to see a dashboard of all claims so that I can monitor billing status | P2 | ⚪ |
| US-B02 | As a billing admin, I want to create claims from sessions so that I can bill insurance | P2 | ⚪ |
| US-B03 | As a billing admin, I want to audit claims before submission so that I can catch errors | P2 | ⚪ |
| US-B04 | As a billing admin, I want to track authorizations so that I don't exceed approved units | P2 | ⚪ |
| US-B05 | As a billing admin, I want to export claims for clearinghouse so that I can submit to payers | P2 | ⚪ |
| US-B06 | As a billing admin, I want to view revenue reports so that I can track financial health | P2 | ⚪ |
| US-B07 | As a billing admin, I want to manage denied claims so that I can resubmit or appeal | P2 | ⚪ |

---

## Functional Requirements

### Billing Dashboard (`/billing`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-B01 | Display key metrics (total claims, amount, collected, denial rate) | P2 | ⚪ |
| FR-B02 | Status breakdown cards (submitted, pending, paid, flagged, rejected) | P2 | ⚪ |
| FR-B03 | Filter by status, time range, payer | P2 | ⚪ |
| FR-B04 | Submission & payment trend chart | P2 | ⚪ |
| FR-B05 | Top payers summary | P2 | ⚪ |
| FR-B06 | Claims table with pagination | P2 | ⚪ |
| FR-B07 | Recent claims activity feed | P2 | ⚪ |
| FR-B08 | Quick actions: New Claim, Claim Audit, Reports | P2 | ⚪ |

### Claim Audit (`/billing/claim-audit`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-B10 | Create new claim from session data | P2 | ⚪ |
| FR-B11 | Auto-extract billing data (patient, date, service, duration) | P2 | ⚪ |
| FR-B12 | CPT code mapping (97153, 97155, 97156, etc.) | P2 | ⚪ |
| FR-B13 | Unit calculation (15-min or 30-min increments) | P2 | ⚪ |
| FR-B14 | Pre-validation against authorization | P2 | ⚪ |
| FR-B15 | Error flagging with reasons | P2 | ⚪ |
| FR-B16 | Claim status workflow (draft → submitted → paid/rejected) | P2 | ⚪ |
| FR-B17 | Edit claim details | P2 | ⚪ |
| FR-B18 | CSV export for clearinghouse | P2 | ⚪ |

### Authorizations (`/billing/authorizations`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-B20 | List all authorizations | P2 | ⚪ |
| FR-B21 | Authorization details: payer, dates, units approved | P2 | ⚪ |
| FR-B22 | Track units used vs remaining | P2 | ⚪ |
| FR-B23 | Expiration warnings | P2 | ⚪ |
| FR-B24 | Link authorizations to patients | P2 | ⚪ |
| FR-B25 | Create/edit authorization | P2 | ⚪ |

### Reports (`/billing/reports`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-B30 | Monthly billing summary | P2 | ⚪ |
| FR-B31 | Revenue by payer report | P2 | ⚪ |
| FR-B32 | Denial analysis report | P2 | ⚪ |
| FR-B33 | Authorization utilization report | P2 | ⚪ |
| FR-B34 | Date range filtering | P2 | ⚪ |
| FR-B35 | Export to CSV/Excel | P2 | ⚪ |
| FR-B36 | Print-friendly view | P2 | ⚪ |

### Settings (`/billing/settings`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-B40 | CPT code configuration | P2 | ⚪ |
| FR-B41 | Payer setup and rates | P2 | ⚪ |
| FR-B42 | Default billing codes | P2 | ⚪ |
| FR-B43 | Clearinghouse integration settings | P2 | ⚪ |

---

## Claim Lifecycle

```
┌──────────┐    ┌───────────┐    ┌───────────┐    ┌──────────┐
│  Draft   │───▶│ Submitted │───▶│  Pending  │───▶│   Paid   │
└──────────┘    └───────────┘    └───────────┘    └──────────┘
                      │                │
                      │                ▼
                      │          ┌──────────┐
                      └─────────▶│ Rejected │
                                 └──────────┘
                                       │
                                       ▼
                                 ┌──────────┐
                                 │ Appealed │
                                 └──────────┘
```

---

## API Requirements

```
# Claims
GET    /api/v1/billing/claims
POST   /api/v1/billing/claims
GET    /api/v1/billing/claims/:id
PATCH  /api/v1/billing/claims/:id
POST   /api/v1/billing/claims/:id/submit
POST   /api/v1/billing/claims/export

# Dashboard
GET    /api/v1/billing/overview
GET    /api/v1/billing/status-breakdown
GET    /api/v1/billing/payer-summary
GET    /api/v1/billing/timeline

# Authorizations
GET    /api/v1/billing/authorizations
POST   /api/v1/billing/authorizations
GET    /api/v1/billing/authorizations/:id
PATCH  /api/v1/billing/authorizations/:id

# Reports
GET    /api/v1/billing/reports/summary
GET    /api/v1/billing/reports/by-payer
GET    /api/v1/billing/reports/denials
GET    /api/v1/billing/reports/utilization
```

---

## Data Models

```
Claim
├── id: UUID
├── organization_id: UUID
├── patient_id: UUID
├── session_id: UUID? (source session)
├── patient_name: string
├── payer_id: UUID?
├── payer_name: string?
├── authorization_id: UUID?
├── service_type: string (CPT code)
├── service_label: string
├── service_date: date
├── units: int
├── amount: decimal
├── amount_paid: decimal
├── status: enum [draft, submitted, pending, paid, approved, flagged, rejected]
├── submitted_at: datetime?
├── paid_at: datetime?
├── denied_at: datetime?
├── denial_reason: string?
├── last_status_change: datetime
├── location: string?
├── notes: text?
├── created_at: datetime
└── updated_at: datetime

Authorization
├── id: UUID
├── organization_id: UUID
├── patient_id: UUID
├── payer_id: UUID
├── payer_name: string
├── authorization_number: string
├── service_type: string (CPT code)
├── units_approved: int
├── units_used: int
├── start_date: date
├── end_date: date
├── status: enum [active, expired, exhausted]
├── created_at: datetime
└── updated_at: datetime

Payer
├── id: UUID
├── organization_id: UUID
├── name: string
├── payer_id: string (external ID)
├── address: text?
├── phone: string?
├── rates: JSONB (CPT → rate mapping)
├── is_active: boolean
├── created_at: datetime
└── updated_at: datetime
```

---

## CPT Codes (ABA Therapy)

| Code | Description | Typical Rate |
|------|-------------|--------------|
| 97151 | Behavior identification assessment | $150-200/hr |
| 97152 | Behavior identification supporting assessment | $75-100/hr |
| 97153 | Adaptive behavior treatment (direct 1:1) | $60-90/unit |
| 97154 | Group adaptive behavior treatment | $40-60/unit |
| 97155 | Adaptive behavior treatment with protocol modification | $80-120/unit |
| 97156 | Family adaptive behavior treatment guidance | $70-100/unit |
| 97157 | Multiple-family group behavior guidance | $50-75/unit |
| 97158 | Behavior follow-up assessment | $100-150/hr |

---

## UI Screens

| Screen | Route | Priority | Status |
|--------|-------|----------|--------|
| Billing Dashboard | `/billing` | P2 | ⚪ |
| Claim Audit | `/billing/claim-audit` | P2 | ⚪ |
| Authorizations | `/billing/authorizations` | P2 | ⚪ |
| Reports | `/billing/reports` | P2 | ⚪ |
| Settings | `/billing/settings` | P2 | ⚪ |

---

## HIPAA Compliance

- All billing data is PHI — encrypt at rest and in transit
- Audit logging for all claim access and modifications
- Role-based access (only billing staff can view/edit claims)
- No PHI in logs
- Secure export (password-protected or encrypted files)

---

## Integration Points

| System | Integration |
|--------|-------------|
| Scheduling | Session data → claim generation |
| Intake | Patient insurance info |
| Sessions | Service hours, dates |
| Reports | Revenue analytics |

---

## Tasks Reference

Add to `docs/tasks/billing.md` when created.
