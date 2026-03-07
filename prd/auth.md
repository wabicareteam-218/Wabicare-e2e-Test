# Auth & Users Module — PRD

> **Priority**: P0 - Core  
> **Status**: 🟡 In Progress

---

## Overview

The Auth module handles user authentication via Azure Entra External ID (CIAM), user management, and role-based access control. All users belong to an organization and have specific roles that determine their permissions.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-A01 | As a user, I want to sign in with my Google account so that I don't need another password | P0 | 🟢 |
| US-A02 | As a user, I want to stay signed in so that I don't have to log in every time | P0 | 🟡 |
| US-A03 | As a user, I want to sign out so that I can secure my device | P0 | ⚪ |
| US-A04 | As an admin, I want to invite new users so that they can access the clinic | P1 | ⚪ |
| US-A05 | As an admin, I want to assign roles so that users have appropriate access | P1 | ⚪ |
| US-A06 | As an admin, I want to deactivate users so that former employees can't access data | P1 | ⚪ |

---

## Functional Requirements

### Authentication

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-A01 | Support Azure Entra External ID (CIAM) authentication | P0 | 🟢 |
| FR-A02 | Support Google as identity provider | P0 | 🟢 |
| FR-A03 | PKCE flow for web authentication | P0 | 🟢 |
| FR-A04 | Safari-based redirect for iOS/macOS | P0 | 🟢 |
| FR-A05 | Secure token storage (Keychain iOS, encrypted prefs Android) | P0 | 🟢 |
| FR-A06 | Automatic token refresh | P0 | 🟡 |
| FR-A07 | Silent sign-in on app start | P0 | 🟡 |
| FR-A08 | Sign out (clear tokens) | P0 | ⚪ |

### User Management

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-A10 | User profile view (`/profile`) | P1 | ⚪ |
| FR-A11 | Edit profile (name, avatar) | P1 | ⚪ |
| FR-A12 | User list for admins | P1 | ⚪ |
| FR-A13 | Invite user (send email) | P1 | ⚪ |
| FR-A14 | Accept invitation (`/invite/[token]`) | P1 | ⚪ |
| FR-A15 | Resend invitation | P2 | ⚪ |
| FR-A16 | Assign/change user role | P1 | ⚪ |
| FR-A17 | Deactivate user | P1 | ⚪ |

### Notifications

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-A30 | In-app notification bell | P1 | ⚪ |
| FR-A31 | Notification list | P1 | ⚪ |
| FR-A32 | Mark notification as read | P1 | ⚪ |
| FR-A33 | Push notifications (mobile) | P2 | ⚪ |
| FR-A34 | Email notifications | P2 | ⚪ |

### Authorization

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-A20 | Role-based menu visibility | P1 | ⚪ |
| FR-A21 | Route guards for protected pages | P1 | ⚪ |
| FR-A22 | API permission checks | P1 | ⚪ |

---

## Roles & Permissions

| Role | Description | Permissions |
|------|-------------|-------------|
| `super_admin` | Platform admin | Everything |
| `org_admin` | Organization admin | All org data, user management |
| `bcba` | Board Certified Behavior Analyst | Full clinical access |
| `rbt` | Registered Behavior Technician | Sessions, assigned patients |
| `billing` | Billing staff | Billing module only |
| `parent` | Parent/guardian | Parent portal only |

---

## API Requirements

### Endpoints

```
# Authentication
POST   /api/v1/auth/sync           # Sync user from Entra token

# Current User
GET    /api/v1/users/me            # Get current user
PATCH  /api/v1/users/me            # Update current user (profile)

# User Management (admin)
GET    /api/v1/users               # List users
POST   /api/v1/users/invite        # Invite user (sends email)
GET    /api/v1/users/invite/:token # Validate invitation token
POST   /api/v1/users/invite/:token/accept  # Accept invitation
POST   /api/v1/users/:id/resend-invite     # Resend invitation
PATCH  /api/v1/users/:id/role      # Change role
DELETE /api/v1/users/:id           # Deactivate user

# Notifications
GET    /api/v1/notifications       # List user's notifications
PATCH  /api/v1/notifications/:id   # Mark as read
DELETE /api/v1/notifications/:id   # Delete notification
```

### Auth Sync Request

```json
// POST /api/v1/auth/sync
// Authorization: Bearer <entra-jwt>
// No body - extracts user info from JWT claims
```

### Auth Sync Response

```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "organization_id": "uuid",
    "organization_name": "ABC Clinic",
    "role": "bcba",
    "permissions": ["read:patients", "write:patients", "read:sessions"]
  }
}
```

---

## Data Model

```
User
├── id: UUID (PK)
├── azure_id: string (unique, from Entra)
├── email: string (unique)
├── name: string
├── organization_id: UUID (FK)
├── role: enum [super_admin, org_admin, bcba, rbt, billing, parent]
├── is_active: boolean
├── last_login: datetime
├── created_at: datetime
└── updated_at: datetime

Organization
├── id: UUID (PK)
├── name: string
├── slug: string (unique)
├── is_active: boolean
└── created_at: datetime

UserInvitation
├── id: UUID (PK)
├── email: string
├── organization_id: UUID (FK)
├── role: enum
├── token: string (unique)
├── invited_by: UUID (FK to User)
├── expires_at: datetime
├── accepted_at: datetime?
└── created_at: datetime

Notification
├── id: UUID (PK)
├── user_id: UUID (FK)
├── type: enum [intake_update, appointment_reminder, task_assigned, ...]
├── title: string
├── message: text
├── link: string? (deep link)
├── read_at: datetime?
├── created_at: datetime
```

---

## Security Requirements

1. **Token Storage**: Never store tokens in plain SharedPreferences
2. **Token Refresh**: Refresh before expiry, not after
3. **HTTPS Only**: All API calls over TLS
4. **No PHI in Logs**: Never log emails, names, or tokens
5. **Session Timeout**: Auto-logout after 24h inactivity

---

## Tasks Reference

See [tasks/auth.md](../tasks/auth.md) for implementation tasks.
