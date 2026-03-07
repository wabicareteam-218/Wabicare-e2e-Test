# Clinic Domain — PRDs

> PRDs for core clinical functionality

---

## Module Index

| Module | Priority | Status | PRD | Description |
|--------|----------|--------|-----|-------------|
| **Dashboard** | P0 | 🟢 | [dashboard.md](./dashboard.md) | Role-based home page with metrics |
| **Patients** | P0 | 🟢 | [patients.md](./patients.md) | Patient profiles, guardians, status |
| **Intake** | P0 | 🟢 | [intake.md](./intake.md) | New patient workflow, forms, documents |
| **Scheduling** | P0 | 🟢 | [scheduling.md](./scheduling.md) | Calendar, appointments, availability |
| **Sessions** | P0 | 🟢 | [sessions.md](./sessions.md) | Data collection, targets, behaviors |
| **Assessments** | P1 | 🟡 | [assessments.md](./assessments.md) | VB-MAPP, ABLLS-R, FBAs, reports |
| **Reports** | P1 | 🟡 | [reports.md](./reports.md) | Analytics, exports, dashboards |

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        Clinic Domain                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐     ┌──────────┐     ┌──────────────┐            │
│  │  Intake  │────▶│ Patients │────▶│  Scheduling  │            │
│  │  (New)   │     │ (Active) │     │              │            │
│  └──────────┘     └────┬─────┘     └──────┬───────┘            │
│                        │                   │                    │
│                        │                   ▼                    │
│                        │           ┌──────────────┐             │
│                        │           │   Sessions   │             │
│                        │           │ (Data Coll.) │             │
│                        │           └──────┬───────┘             │
│                        │                   │                    │
│                        ▼                   ▼                    │
│                  ┌─────────────────────────────┐                │
│                  │       Assessments           │                │
│                  │  (VB-MAPP, ABLLS-R, FBA)    │                │
│                  └─────────────┬───────────────┘                │
│                                │                                │
│                                ▼                                │
│                        ┌───────────────┐                        │
│                        │    Reports    │                        │
│                        └───────────────┘                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Cross-Domain Integration

| Clinic Module | Integrates With | Purpose |
|---------------|-----------------|---------|
| Intake | Parent Portal | Parent form completion |
| Intake | Billing | Insurance verification |
| Scheduling | Communications | Appointment reminders |
| Sessions | Reports | Progress analytics |
| Sessions | Parent Portal | Session notes sharing |
| Assessments | Reports | Assessment summaries |

---

## Related Documentation

- [PRD Index](../README.md)
- [Auth PRD](../auth.md)
- [Admin PRD](../admin.md)
- [Billing PRD](../billing.md)
