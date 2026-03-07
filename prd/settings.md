# Settings Module — PRD

> **Priority**: P1 - Important  
> **Status**: ⚪ Not Started

---

## Overview

The Settings module allows users and administrators to configure organization settings, manage team members, customize intake workflows, import data, and manage notification and security preferences.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-S01 | As an admin, I want to configure my organization details so that they appear correctly | P1 | ⚪ |
| US-S02 | As an admin, I want to manage team members so that I can add/remove staff | P1 | ⚪ |
| US-S03 | As an admin, I want to customize intake forms so that they match our workflow | P1 | ⚪ |
| US-S04 | As an admin, I want to import patient data so that I can migrate from another system | P2 | ⚪ |
| US-S05 | As a user, I want to configure my notification preferences | P2 | ⚪ |
| US-S06 | As an admin, I want to manage security settings so that data stays protected | P1 | ⚪ |

---

## Functional Requirements

### Organization Tab

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-S01 | Display organization name, address, phone, email | P1 | ⚪ |
| FR-S02 | Edit organization details | P1 | ⚪ |
| FR-S03 | Upload organization logo | P2 | ⚪ |
| FR-S04 | Organization setup wizard for new orgs | P1 | ⚪ |
| FR-S05 | Manage organization branches | P2 | ⚪ |

### Users Tab

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-S10 | List all organization users | P1 | ⚪ |
| FR-S11 | Search and filter users | P1 | ⚪ |
| FR-S12 | Invite new users | P1 | ⚪ |
| FR-S13 | Edit user roles | P1 | ⚪ |
| FR-S14 | Deactivate users | P1 | ⚪ |
| FR-S15 | Resend invitation | P2 | ⚪ |

### Intake Tab

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-S20 | Configure intake form fields | P1 | ⚪ |
| FR-S21 | Enable/disable intake forms | P1 | ⚪ |
| FR-S22 | Set required fields | P1 | ⚪ |
| FR-S23 | Configure intake phases | P2 | ⚪ |
| FR-S24 | Email templates for intake | P2 | ⚪ |

### Import Tab

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-S30 | Upload CSV for patient import | P2 | ⚪ |
| FR-S31 | Field mapping UI | P2 | ⚪ |
| FR-S32 | Validation and error display | P2 | ⚪ |
| FR-S33 | Import progress tracking | P2 | ⚪ |
| FR-S34 | Assessment data import | P2 | ⚪ |

### Notifications Tab

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-S40 | Email notification preferences | P2 | ⚪ |
| FR-S41 | Push notification preferences | P2 | ⚪ |
| FR-S42 | Appointment reminders toggle | P2 | ⚪ |
| FR-S43 | Intake status updates toggle | P2 | ⚪ |

### Security Tab

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-S50 | Two-factor authentication settings | P1 | ⚪ |
| FR-S51 | Session timeout configuration | P2 | ⚪ |
| FR-S52 | Password policy display | P2 | ⚪ |
| FR-S53 | Active sessions list | P2 | ⚪ |
| FR-S54 | Audit log access | P1 | ⚪ |

### General Tab

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-S60 | Timezone settings | P2 | ⚪ |
| FR-S61 | Date/time format preferences | P2 | ⚪ |
| FR-S62 | Language preferences | P3 | ⚪ |
| FR-S63 | Theme preferences (dark/light) | P3 | ⚪ |

---

## UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Settings                                                    │
├─────────────────────────────────────────────────────────────┤
│ [Organization] [Users] [Intake] [Import] [Notifications]    │
│ [Security] [General]                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Organization Tab Content                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Organization Name: ABC Therapy Center               │   │
│  │ Address: 123 Main St, City, State 12345            │   │
│  │ Phone: (555) 123-4567                              │   │
│  │ Email: admin@abctherapy.com                        │   │
│  │                                                     │   │
│  │ [Edit Organization]                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## API Requirements

```
# Organization
GET    /api/v1/organizations/current
PATCH  /api/v1/organizations/current
POST   /api/v1/organizations/logo

# Users
GET    /api/v1/organizations/users
POST   /api/v1/organizations/users/invite
PATCH  /api/v1/organizations/users/:id
DELETE /api/v1/organizations/users/:id

# Intake Settings
GET    /api/v1/settings/intake
PATCH  /api/v1/settings/intake

# Import
POST   /api/v1/import/patients
POST   /api/v1/import/assessments

# Notifications
GET    /api/v1/settings/notifications
PATCH  /api/v1/settings/notifications

# Security
GET    /api/v1/settings/security
POST   /api/v1/settings/security/2fa
GET    /api/v1/settings/sessions
DELETE /api/v1/settings/sessions/:id
```

---

## Data Models

```
OrganizationSettings
├── id: UUID
├── organization_id: UUID
├── timezone: string
├── date_format: string
├── session_timeout: int (minutes)
├── require_2fa: boolean
└── updated_at: datetime

NotificationPreferences
├── id: UUID
├── user_id: UUID
├── email_appointments: boolean
├── email_intake_updates: boolean
├── push_enabled: boolean
└── updated_at: datetime

IntakeSettings
├── id: UUID
├── organization_id: UUID
├── enabled_forms: string[] (form types)
├── required_forms: string[]
├── phase_config: JSONB
└── updated_at: datetime
```

---

## Security

- Only `org_admin` or higher can access Organization tab
- Only `org_admin` can manage users
- Users can only edit their own notification preferences
- Security tab requires re-authentication for sensitive changes

---

## Tasks Reference

Add to `docs/tasks/settings.md` when created.
