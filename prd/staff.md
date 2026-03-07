# Staff Module (HRMS + LMS) — PRD

> **Priority**: P3 - Future  
> **Status**: ⚪ Not Started

---

## Overview

The Staff module combines Human Resource Management (HRMS) and Learning Management (LMS) systems. HRMS covers organizational structure, employee onboarding, payroll, and team management. LMS provides training courses, CEU tracking, and compliance certification.

---

## User Stories

### HRMS

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-H01 | As an HR admin, I want to view the org chart so that I understand team structure | P3 | ⚪ |
| US-H02 | As an HR admin, I want to onboard new employees so that they can start working | P3 | ⚪ |
| US-H03 | As an employee, I want to view my profile so that I can see my info | P3 | ⚪ |
| US-H04 | As a manager, I want to view my team so that I can manage schedules | P3 | ⚪ |
| US-H05 | As a manager, I want to give rewards so that I can recognize good work | P3 | ⚪ |

### LMS

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-L01 | As an employee, I want to view available courses so that I can learn | P3 | ⚪ |
| US-L02 | As a BCBA, I want to track my CEUs so that I stay certified | P3 | ⚪ |
| US-L03 | As a manager, I want to assign training so that staff stay compliant | P3 | ⚪ |
| US-L04 | As an employee, I want to earn certificates so that I can prove completion | P3 | ⚪ |

---

## Functional Requirements

### HRMS: Org Chart (`/hrms/org-chart`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-H01 | Visual organization chart | P3 | ⚪ |
| FR-H02 | Reporting relationships | P3 | ⚪ |
| FR-H03 | Filter by department/role | P3 | ⚪ |
| FR-H04 | Employee profiles on click | P3 | ⚪ |

### HRMS: Onboarding (`/hrms/onboarding`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-H10 | Open positions list | P3 | ⚪ |
| FR-H11 | Position details (RBT, BCBA, Admin) | P3 | ⚪ |
| FR-H12 | Onboarding checklist | P3 | ⚪ |
| FR-H13 | Document collection | P3 | ⚪ |
| FR-H14 | Background check status | P3 | ⚪ |
| FR-H15 | Credential verification | P3 | ⚪ |

### HRMS: Employee Portal (`/hrms/employee`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-H20 | Employee profile view | P3 | ⚪ |
| FR-H21 | CEU tracking display | P3 | ⚪ |
| FR-H22 | Payroll information | P3 | ⚪ |
| FR-H23 | Time off requests | P3 | ⚪ |
| FR-H24 | Document upload | P3 | ⚪ |
| FR-H25 | Edit personal info | P3 | ⚪ |

### HRMS: Manager Portal (`/hrms/manager`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-H30 | Team member list | P3 | ⚪ |
| FR-H31 | Team schedules | P3 | ⚪ |
| FR-H32 | Time off approval | P3 | ⚪ |
| FR-H33 | Performance notes | P3 | ⚪ |

### HRMS: Rewards (`/hrms/rewards`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-H40 | Send spot rewards | P3 | ⚪ |
| FR-H41 | Reward history | P3 | ⚪ |
| FR-H42 | Reward types (kudos, bonus, badge) | P3 | ⚪ |
| FR-H43 | Leaderboard | P3 | ⚪ |

### LMS: Courses (`/lms/courses`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-L01 | Course catalog | P3 | ⚪ |
| FR-L02 | Course details (description, duration, CEUs) | P3 | ⚪ |
| FR-L03 | Video lessons | P3 | ⚪ |
| FR-L04 | Quizzes | P3 | ⚪ |
| FR-L05 | Progress tracking | P3 | ⚪ |
| FR-L06 | Course completion certificates | P3 | ⚪ |

### LMS: CEU Tracking (`/lms/ceu`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-L10 | CEU requirements by certification | P3 | ⚪ |
| FR-L11 | CEU credits earned | P3 | ⚪ |
| FR-L12 | Expiration warnings | P3 | ⚪ |
| FR-L13 | External CEU upload | P3 | ⚪ |
| FR-L14 | CEU certificate download | P3 | ⚪ |

---

## API Requirements

```
# HRMS
GET    /api/v1/hrms/org-chart
GET    /api/v1/hrms/employees
GET    /api/v1/hrms/employees/:id
PATCH  /api/v1/hrms/employees/:id
GET    /api/v1/hrms/teams/:id
POST   /api/v1/hrms/rewards
GET    /api/v1/hrms/rewards
GET    /api/v1/hrms/time-off
POST   /api/v1/hrms/time-off
PATCH  /api/v1/hrms/time-off/:id

# LMS
GET    /api/v1/lms/courses
GET    /api/v1/lms/courses/:id
POST   /api/v1/lms/courses/:id/enroll
GET    /api/v1/lms/courses/:id/progress
POST   /api/v1/lms/courses/:id/complete
GET    /api/v1/lms/ceu
POST   /api/v1/lms/ceu/upload
GET    /api/v1/lms/certificates
```

---

## Data Models

```
Employee
├── id: UUID
├── user_id: UUID
├── organization_id: UUID
├── department: string
├── role: string
├── manager_id: UUID?
├── hire_date: date
├── certifications: JSONB[]
├── ceu_credits: int
├── ceu_expiry: date?
├── created_at: datetime

Reward
├── id: UUID
├── organization_id: UUID
├── from_user_id: UUID
├── to_user_id: UUID
├── type: enum [kudos, bonus, badge]
├── message: text
├── amount: decimal? (for bonus)
├── created_at: datetime

Course
├── id: UUID
├── title: string
├── description: text
├── duration_minutes: int
├── ceu_credits: decimal
├── category: string
├── lessons: JSONB[]
├── quiz: JSONB?
├── is_active: boolean
├── created_at: datetime

CourseEnrollment
├── id: UUID
├── user_id: UUID
├── course_id: UUID
├── progress_percent: int
├── completed_at: datetime?
├── certificate_url: string?
├── created_at: datetime

CEURecord
├── id: UUID
├── user_id: UUID
├── source: enum [internal, external]
├── credits: decimal
├── description: string
├── document_url: string?
├── earned_date: date
├── created_at: datetime
```

---

## Integration Points

| System | Integration |
|--------|-------------|
| Auth | User roles and permissions |
| Scheduling | Staff availability |
| Billing | Payroll data |

---

## Tasks Reference

See [tasks/staff.md](../tasks/staff.md) for implementation tasks.
