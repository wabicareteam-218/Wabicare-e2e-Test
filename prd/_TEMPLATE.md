# [Module Name] — PRD

> **Priority**: P0 / P1 / P2 / P3  
> **Status**: ⚪ Not Started / 🟡 In Progress / 🟢 Complete  
> **Owner**: [Name/Team]

---

## Overview

Brief description of what this module does and why it exists.

---

## User Stories

### As a [Role]...

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-001 | As a BCBA, I want to... so that... | P0 | ⚪ |
| US-002 | As an admin, I want to... so that... | P1 | ⚪ |

---

## Functional Requirements

### [Feature Area 1]

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | The system shall... | P0 |
| FR-002 | The system shall... | P1 |

### [Feature Area 2]

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-010 | The system shall... | P0 |

---

## API Requirements

### Endpoints

```
GET    /api/v1/[resource]
POST   /api/v1/[resource]
GET    /api/v1/[resource]/:id
PATCH  /api/v1/[resource]/:id
DELETE /api/v1/[resource]/:id
```

### Request/Response Examples

```json
// POST /api/v1/[resource]
{
  "field1": "value",
  "field2": 123
}
```

---

## UI/UX Requirements

### Screens

| Screen | Description | Wireframe |
|--------|-------------|-----------|
| List View | Shows all items | [link] |
| Detail View | Single item details | [link] |
| Create/Edit | Form for creating/editing | [link] |

### Responsive Behavior

- **Desktop (>1024px)**: Full layout with sidebar
- **Tablet (600-1024px)**: Condensed sidebar
- **Mobile (<600px)**: Bottom nav, drawer

---

## Data Model

```
ModelName
├── id: UUID (PK)
├── organization_id: UUID (FK)
├── field1: string
├── field2: integer
├── status: enum [...]
├── created_at: datetime
└── updated_at: datetime
```

---

## Business Rules

1. **Rule 1**: Description of constraint or validation
2. **Rule 2**: Description of workflow rule

---

## Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Performance | List load < 500ms |
| Security | All data org-scoped |
| Accessibility | WCAG 2.1 AA compliance |
| Offline | N/A or requirements |

---

## Dependencies

| Dependency | Type | Description |
|------------|------|-------------|
| Auth module | Required | User context for org-scoping |
| Patients module | Required | Patient reference |

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Page load time | < 500ms | Monitoring |
| Error rate | < 1% | Error tracking |

---

## Open Questions

- [ ] Question 1?
- [ ] Question 2?

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| YYYY-MM-DD | 1.0 | Initial draft | Name |
