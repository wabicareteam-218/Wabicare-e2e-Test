# Wabi Clinic — PRD Index

> Master index of all Product Requirement Documents

---

## Module Overview

### Priority Legend
| Priority | Meaning |
|----------|---------|
| **P0** | Must have for MVP launch |
| **P1** | Important, build after core |
| **P2** | Nice to have, can defer |
| **P3** | Future roadmap |

### Status Legend
| Status | Meaning |
|--------|---------|
| ⚪ | Not Started |
| 🟡 | In Progress |
| 🟢 | Complete |

---

## Core Modules (P0)

| Module | Priority | Status | PRD | Description |
|--------|----------|--------|-----|-------------|
| **Auth** | P0 | 🟢 | [auth.md](./auth.md) | Azure Entra External ID, OAuth 2.0, roles |
| **Admin** | P0 | 🟢 | [admin.md](./admin.md) | System admin, DB, users, infrastructure |
| **Infrastructure** | P0 | 🟢 | [infrastructure.md](./infrastructure.md) | Azure deployment, containers, networking |

---

## Clinic Domain (P0-P1)

| Module | Priority | Status | PRD | Description |
|--------|----------|--------|-----|-------------|
| **Dashboard** | P0 | 🟢 | [clinic/dashboard.md](./clinic/dashboard.md) | Role-based home page metrics |
| **Patients** | P0 | 🟢 | [clinic/patients.md](./clinic/patients.md) | Patient profiles, guardians, status |
| **Intake** | P0 | 🟢 | [clinic/intake.md](./clinic/intake.md) | New patient workflow, forms, e-sign |
| **Scheduling** | P0 | 🟢 | [clinic/scheduling.md](./clinic/scheduling.md) | Calendar, appointments, availability |
| **Sessions** | P0 | 🟢 | [clinic/sessions.md](./clinic/sessions.md) | Data collection, targets, behaviors |
| **Tasks** | P1 | 🟢 | [clinic/tasks.md](./clinic/tasks.md) | Kanban task board |
| **Assessments** | P1 | 🟡 | [clinic/assessments.md](./clinic/assessments.md) | VB-MAPP, ABLLS-R, FBAs |
| **Reports** | P1 | 🟡 | [clinic/reports.md](./clinic/reports.md) | Analytics, exports, dashboards |

---

## Supporting Modules (P1-P2)

| Module | Priority | Status | PRD | Description |
|--------|----------|--------|-----|-------------|
| **Settings** | P1 | 🟢 | [settings.md](./settings.md) | Organization, users, intake config |
| **Billing** | P2 | 🟢 | [billing.md](./billing.md) | Claims, authorizations, revenue |
| **Communications** | P2 | 🟢 | [comms.md](./comms.md) | Messages, phone, telehealth |
| **Parent Portal** | P2 | 🟢 | [parent-portal.md](./parent-portal.md) | Parent-facing dashboard |
| **AI Features** | P2 | 🟢 | [ai.md](./ai.md) | Assessment generation, summaries |

---

## Future Modules (P3)

| Module | Priority | Status | PRD | Description |
|--------|----------|--------|-----|-------------|
| **Staff (HRMS+LMS)** | P3 | 🟢 | [staff.md](./staff.md) | HR, training, CEUs |

---

## PRD Template

Use [_TEMPLATE.md](./_TEMPLATE.md) when creating new PRDs.

---

## Quick Stats

| Category | Count |
|----------|-------|
| Total PRDs | 17 |
| Complete | 15 |
| In Progress | 2 |
| Not Started | 0 |

---

## Related Documentation

- **Tasks**: [../tasks/README.md](../tasks/README.md)
- **UI Design**: [../design/UI_design_system.md](../design/UI_design_system.md)
- **Components**: [../design/components.md](../design/components.md)
- **Agent Rules**: [../../AGENTS.md](../../AGENTS.md)
