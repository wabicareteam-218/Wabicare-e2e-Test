# Communications Module — PRD

> **Priority**: P2 - Nice to Have  
> **Status**: ⚪ Not Started

---

## Overview

The Communications module enables staff-to-parent and staff-to-staff communication through multiple channels: phone calls, text messages, and telehealth video sessions. It includes appointment reminders, session notifications, and secure messaging.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-C01 | As a BCBA, I want to message parents so that I can communicate session updates | P2 | ⚪ |
| US-C02 | As an admin, I want to send appointment reminders so that we reduce no-shows | P2 | ⚪ |
| US-C03 | As a BCBA, I want to conduct telehealth sessions so that I can serve remote clients | P2 | ⚪ |
| US-C04 | As a parent, I want to receive notifications so that I stay informed | P2 | ⚪ |
| US-C05 | As a staff member, I want to call contacts through the app so that I have a log | P2 | ⚪ |

---

## Functional Requirements

### Communication Hub (`/communication`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-C01 | Dashboard showing all communication channels | P2 | ⚪ |
| FR-C02 | Quick access to phone, messages, telehealth | P2 | ⚪ |
| FR-C03 | Recent communications list | P2 | ⚪ |
| FR-C04 | Unread message count badges | P2 | ⚪ |

### Phone Calls (`/communication/phone`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-C10 | Contact directory with search | P2 | ⚪ |
| FR-C11 | Click-to-call functionality | P2 | ⚪ |
| FR-C12 | Call history log | P2 | ⚪ |
| FR-C13 | Call notes after each call | P2 | ⚪ |
| FR-C14 | Link calls to patients | P2 | ⚪ |

### Text Messages (`/communication/messages`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-C20 | Conversation list (threaded) | P2 | ⚪ |
| FR-C21 | Send/receive text messages | P2 | ⚪ |
| FR-C22 | Attachment support (images, PDFs) | P2 | ⚪ |
| FR-C23 | Search messages | P2 | ⚪ |
| FR-C24 | New conversation composer | P2 | ⚪ |
| FR-C25 | Message templates | P2 | ⚪ |
| FR-C26 | Read receipts | P3 | ⚪ |

### Telehealth (`/communication/telehealth`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-C30 | Video call sessions | P2 | ⚪ |
| FR-C31 | Schedule telehealth appointments | P2 | ⚪ |
| FR-C32 | Send meeting invites | P2 | ⚪ |
| FR-C33 | In-session notes | P2 | ⚪ |
| FR-C34 | Screen sharing | P3 | ⚪ |
| FR-C35 | Recording with consent | P3 | ⚪ |
| FR-C36 | Auto-generate session notes | P2 | ⚪ |

### Notifications

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-C40 | Appointment reminders (24h, 1h before) | P2 | ⚪ |
| FR-C41 | Session note published notification | P2 | ⚪ |
| FR-C42 | New message notification | P2 | ⚪ |
| FR-C43 | Push notifications (mobile) | P2 | ⚪ |
| FR-C44 | Email notifications | P2 | ⚪ |
| FR-C45 | SMS notifications | P2 | ⚪ |

---

## API Requirements

```
# Messages
GET    /api/v1/messages/conversations
GET    /api/v1/messages/conversations/:id
POST   /api/v1/messages/conversations
POST   /api/v1/messages/conversations/:id/messages

# Phone
GET    /api/v1/phone/contacts
GET    /api/v1/phone/calls
POST   /api/v1/phone/calls/:id/notes

# Telehealth
GET    /api/v1/telehealth/sessions
POST   /api/v1/telehealth/sessions
GET    /api/v1/telehealth/sessions/:id
POST   /api/v1/telehealth/sessions/:id/join

# Notifications
GET    /api/v1/notifications
PATCH  /api/v1/notifications/:id/read
POST   /api/v1/notifications/settings
```

---

## Data Models

```
Message
├── id: UUID
├── conversation_id: UUID
├── sender_id: UUID
├── content: text
├── attachments: JSONB[]
├── read_at: datetime?
├── created_at: datetime

Conversation
├── id: UUID
├── organization_id: UUID
├── participants: UUID[]
├── patient_id: UUID? (linked patient)
├── last_message_at: datetime
├── created_at: datetime

PhoneCall
├── id: UUID
├── organization_id: UUID
├── user_id: UUID (caller)
├── contact_id: UUID
├── patient_id: UUID?
├── direction: enum [inbound, outbound]
├── duration: int (seconds)
├── notes: text?
├── created_at: datetime

TelehealthSession
├── id: UUID
├── organization_id: UUID
├── patient_id: UUID
├── staff_id: UUID
├── scheduled_at: datetime
├── started_at: datetime?
├── ended_at: datetime?
├── meeting_url: string
├── recording_url: string?
├── notes: text?
├── status: enum [scheduled, in_progress, completed, cancelled]
└── created_at: datetime
```

---

## Integration Points

| System | Integration |
|--------|-------------|
| Scheduling | Appointment reminders |
| Parent Portal | Parent notifications |
| Sessions | Telehealth session notes |

---

## HIPAA Compliance

- All messages are encrypted at rest and in transit
- Telehealth recordings require explicit consent
- Audit log for all communication access
- PHI only shared with authorized users
- Auto-delete messages after retention period (configurable)

---

## Tasks Reference

See [tasks/comms.md](../tasks/comms.md) for implementation tasks.
