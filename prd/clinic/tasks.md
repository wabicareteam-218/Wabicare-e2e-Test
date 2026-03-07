# Tasks Module — PRD

> **Priority**: P1 - Important  
> **Status**: ⚪ Not Started  
> **Domain**: Clinic

---

## Overview

The Tasks module provides a Kanban-style task management interface for clinical staff to track their work items. Tasks can be linked to intakes, assessments, and patients.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-T01 | As a BCBA, I want to see my assigned tasks so that I can prioritize my work | P1 | ⚪ |
| US-T02 | As a user, I want to drag tasks between columns so that I can update status quickly | P1 | ⚪ |
| US-T03 | As a user, I want to create new tasks so that I can track ad-hoc work | P1 | ⚪ |
| US-T04 | As a user, I want to click a task to navigate to the related intake/assessment | P1 | ⚪ |

---

## Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-T01 | Kanban board with 3 columns: To Do, In Progress, Done | P1 | ⚪ |
| FR-T02 | Drag-and-drop to change task status | P1 | ⚪ |
| FR-T03 | Task card shows: title, patient name, priority, due date, tags | P1 | ⚪ |
| FR-T04 | Create new task with title, description, priority, due date | P1 | ⚪ |
| FR-T05 | Edit task details | P1 | ⚪ |
| FR-T06 | Delete task | P1 | ⚪ |
| FR-T07 | Click task to navigate to linked intake/assessment | P1 | ⚪ |
| FR-T08 | Filter tasks by assignee, priority, due date | P2 | ⚪ |
| FR-T09 | Task counts per column | P1 | ⚪ |

---

## API Requirements

```
GET    /api/v1/tasks                    # List user's tasks
POST   /api/v1/tasks                    # Create task
GET    /api/v1/tasks/:id                # Get task details
PATCH  /api/v1/tasks/:id                # Update task (status, priority, etc.)
DELETE /api/v1/tasks/:id                # Delete task
```

---

## Data Model

```
Task
├── id: UUID
├── organization_id: UUID
├── assignee_id: UUID
├── title: string
├── description: text?
├── task_type: string? (complete_assessment, review_intake, etc.)
├── priority: enum [urgent, high, normal, low]
├── status: enum [pending, assigned, in_progress, completed, blocked, cancelled]
├── due_date: date?
├── intake_id: UUID? (linked intake)
├── patient_id: UUID? (linked patient)
├── created_at: datetime
└── updated_at: datetime
```
