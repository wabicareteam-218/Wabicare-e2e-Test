# Admin Module — PRD

> **Priority**: P1 - Important  
> **Status**: ⚪ Not Started

---

## Overview

The Admin module provides super administrators with comprehensive system management capabilities including monitoring, database management, user administration, CRM, infrastructure status, and operational tools. This mirrors the full Next.js admin panel functionality.

---

## User Stories

| ID | User Story | Priority | Status |
|----|------------|----------|--------|
| US-AD01 | As a super admin, I want to see a dashboard with system health so that I can monitor the platform | P1 | ⚪ |
| US-AD02 | As a super admin, I want to run SQL queries so that I can inspect and troubleshoot data | P1 | ⚪ |
| US-AD03 | As a super admin, I want to manage users across all organizations | P1 | ⚪ |
| US-AD04 | As a super admin, I want to view customer/organization details and revenue | P1 | ⚪ |
| US-AD05 | As a super admin, I want to monitor infrastructure health | P1 | ⚪ |
| US-AD06 | As a super admin, I want to view server metrics and logs | P1 | ⚪ |
| US-AD07 | As a super admin, I want to review and manage customer feedback | P2 | ⚪ |
| US-AD08 | As a super admin, I want to manage system tasks | P2 | ⚪ |
| US-AD09 | As a super admin, I want to seed sample data for testing | P2 | ⚪ |
| US-AD10 | As a super admin, I want to run database migrations | P1 | ⚪ |

---

## Functional Requirements

### 1. Admin Dashboard (`/admin`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD001 | Display key metrics (total customers, active customers, total users) | P1 | ⚪ |
| FR-AD002 | Show system health percentage | P1 | ⚪ |
| FR-AD003 | Display uptime statistics | P1 | ⚪ |
| FR-AD004 | Service status cards (Intake, Sessions, Scheduling, HRMS, Parent Portal, Billing) | P1 | ⚪ |
| FR-AD005 | Database status card with response time and throughput | P1 | ⚪ |
| FR-AD006 | Infrastructure status card | P1 | ⚪ |
| FR-AD007 | Quick actions panel (Manage Users, Query Database, View Logs) | P1 | ⚪ |
| FR-AD008 | System alerts list | P1 | ⚪ |
| FR-AD009 | Auto-refresh every 30 seconds | P2 | ⚪ |

### 2. Database Management (`/admin/database`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD010 | SQL query input with syntax highlighting | P1 | ⚪ |
| FR-AD011 | Execute read-only queries | P1 | ⚪ |
| FR-AD012 | Display query results in table format | P1 | ⚪ |
| FR-AD013 | List all database tables | P1 | ⚪ |
| FR-AD014 | Export schema | P1 | ⚪ |
| FR-AD015 | Run migrations | P1 | ⚪ |
| FR-AD016 | View migration history | P1 | ⚪ |
| FR-AD017 | Create dummy data for testing | P2 | ⚪ |
| FR-AD018 | Database connection status | P1 | ⚪ |

### 3. User Management (`/admin/users`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD020 | List all users across organizations | P1 | ⚪ |
| FR-AD021 | Search users by name, email | P1 | ⚪ |
| FR-AD022 | Create new test users | P1 | ⚪ |
| FR-AD023 | View user details (email, status, org, role, created date) | P1 | ⚪ |
| FR-AD024 | Initialize RBAC roles and permissions | P1 | ⚪ |
| FR-AD025 | Assign roles to users | P1 | ⚪ |
| FR-AD026 | Check user role status | P1 | ⚪ |
| FR-AD027 | Find users without organization | P2 | ⚪ |
| FR-AD028 | Delete users without organization | P2 | ⚪ |

### 4. Infrastructure Monitoring (`/admin/infrastructure`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD030 | List all Azure resources with status | P1 | ⚪ |
| FR-AD031 | App Service status (name, SKU, runtime, status) | P1 | ⚪ |
| FR-AD032 | Database status (API type, consistency, throughput) | P1 | ⚪ |
| FR-AD033 | Key Vault status (secrets count, certificates, keys) | P1 | ⚪ |
| FR-AD034 | Application Gateway status (tier, WAF, SSL) | P1 | ⚪ |
| FR-AD035 | Application Insights status (retention, metrics, logs) | P1 | ⚪ |
| FR-AD036 | Storage Account status (performance, replication) | P1 | ⚪ |
| FR-AD037 | Health score calculation | P1 | ⚪ |
| FR-AD038 | Security & Compliance panel (HIPAA, encryption, WAF, audit logging) | P1 | ⚪ |
| FR-AD039 | Network architecture diagram placeholder | P2 | ⚪ |
| FR-AD040 | Auto-refresh every 60 seconds | P2 | ⚪ |

### 5. Server Monitoring (`/admin/server`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD050 | Overview tab with server status | P1 | ⚪ |
| FR-AD051 | CPU usage with progress bar | P1 | ⚪ |
| FR-AD052 | Memory usage with progress bar | P1 | ⚪ |
| FR-AD053 | Requests per second metric | P1 | ⚪ |
| FR-AD054 | Network I/O (in/out KB/s) | P1 | ⚪ |
| FR-AD055 | Server uptime display | P1 | ⚪ |
| FR-AD056 | Metrics tab with performance charts placeholder | P2 | ⚪ |
| FR-AD057 | Logs tab with real-time application logs | P1 | ⚪ |
| FR-AD058 | Log level filtering (All, Info, Warn, Error) | P1 | ⚪ |
| FR-AD059 | Log entry with timestamp, level, source, message | P1 | ⚪ |
| FR-AD060 | Auto-refresh metrics every 10 seconds | P2 | ⚪ |

### 6. Services Status (`/admin/services`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD070 | List all application services with health status | P1 | ⚪ |
| FR-AD071 | Service cards: Intake, Data Collection, Scheduling, HRMS, Parent Portal, Billing | P1 | ⚪ |
| FR-AD072 | Per-service metrics: response time, uptime %, requests, errors | P1 | ⚪ |
| FR-AD073 | Summary stats (total, healthy, degraded, down) | P1 | ⚪ |
| FR-AD074 | Performance trends chart placeholder | P2 | ⚪ |
| FR-AD075 | Last refresh timestamp | P1 | ⚪ |
| FR-AD076 | Auto-refresh every 60 seconds | P2 | ⚪ |

### 7. CRM / Customer Management (`/admin/crm`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD080 | List all customers/organizations | P1 | ⚪ |
| FR-AD081 | Search by name, email, organization ID | P1 | ⚪ |
| FR-AD082 | Filter by status (active, trial, suspended, cancelled) | P1 | ⚪ |
| FR-AD083 | Key metrics: total customers, MRR, total revenue, total users | P1 | ⚪ |
| FR-AD084 | Customer table with: organization, contact, status, subscription tier, revenue, users/patients, last activity | P1 | ⚪ |
| FR-AD085 | Subscription tier badges (Basic, Professional, Enterprise) | P1 | ⚪ |
| FR-AD086 | View customer details dialog | P1 | ⚪ |
| FR-AD087 | Organization branches list | P1 | ⚪ |
| FR-AD088 | Export customers list | P2 | ⚪ |

### 8. Customer Feedback (`/admin/feedback`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD090 | List all customer feedback | P2 | ⚪ |
| FR-AD091 | Search feedback by title, description, org | P2 | ⚪ |
| FR-AD092 | Filter by type (bug, feature request, improvement, complaint, praise) | P2 | ⚪ |
| FR-AD093 | Filter by status (new, reviewed, in progress, resolved, rejected) | P2 | ⚪ |
| FR-AD094 | Filter by priority (low, medium, high, urgent) | P2 | ⚪ |
| FR-AD095 | Stats: total, new, in progress, resolved | P2 | ⚪ |
| FR-AD096 | Create feature request from feedback | P2 | ⚪ |
| FR-AD097 | Update feedback status inline | P2 | ⚪ |
| FR-AD098 | Rating display (1-5 stars) | P2 | ⚪ |

### 9. Task Management (`/admin/tasks`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD100 | List all administrative tasks | P2 | ⚪ |
| FR-AD101 | Search tasks | P2 | ⚪ |
| FR-AD102 | Filter by status (todo, in progress, done, blocked) | P2 | ⚪ |
| FR-AD103 | Filter by priority | P2 | ⚪ |
| FR-AD104 | Filter by category (infrastructure, customer, development, maintenance) | P2 | ⚪ |
| FR-AD105 | Create new task | P2 | ⚪ |
| FR-AD106 | Update task status inline | P2 | ⚪ |
| FR-AD107 | Assignee and due date tracking | P2 | ⚪ |
| FR-AD108 | Stats: todo, in progress, done, blocked counts | P2 | ⚪ |

### 10. Data Seeding (`/admin/seed-*`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD110 | Seed sample users | P2 | ⚪ |
| FR-AD111 | Seed sample intakes | P2 | ⚪ |
| FR-AD112 | Seed sample patients | P2 | ⚪ |
| FR-AD113 | Create dummy assessments | P2 | ⚪ |

### 11. System Architecture (`/admin/architecture`)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AD120 | Display system architecture diagram | P2 | ⚪ |
| FR-AD121 | Azure infrastructure layout | P2 | ⚪ |
| FR-AD122 | Database schema visualization | P2 | ⚪ |
| FR-AD123 | Module dependencies | P2 | ⚪ |

---

## API Requirements

### Endpoints (Backend)

```
# Dashboard
GET    /api/v1/admin/system-stats

# Database
POST   /api/v1/admin/database/query
GET    /api/v1/admin/database/tables
GET    /api/v1/admin/database/status
POST   /api/v1/admin/database/migrate
GET    /api/v1/admin/database/migrations
POST   /api/v1/admin/database/export-schema

# Users
GET    /api/v1/admin/users
POST   /api/v1/admin/users
GET    /api/v1/admin/users/:id
PATCH  /api/v1/admin/users/:id
POST   /api/v1/admin/init-roles
POST   /api/v1/admin/assign-role
GET    /api/v1/admin/check-user-role

# Infrastructure
GET    /api/v1/admin/infrastructure/status

# Server
GET    /api/v1/admin/server/metrics
GET    /api/v1/admin/server/logs?level={level}&limit={limit}

# Services
GET    /api/v1/admin/services/status

# CRM
GET    /api/v1/admin/crm/customers
GET    /api/v1/admin/crm/customers/:id

# Feedback
GET    /api/v1/admin/feedback
POST   /api/v1/admin/feedback
PATCH  /api/v1/admin/feedback/:id
POST   /api/v1/admin/feedback/feature-requests

# Tasks
GET    /api/v1/admin/tasks
POST   /api/v1/admin/tasks
PATCH  /api/v1/admin/tasks/:id

# Seed
POST   /api/v1/admin/seed-users
POST   /api/v1/admin/seed-intakes
POST   /api/v1/admin/seed-patients
```

---

## UI Screens

| Screen | Route | Priority | Status |
|--------|-------|----------|--------|
| Dashboard | `/admin` | P1 | ⚪ |
| Database | `/admin/database` | P1 | ⚪ |
| Users | `/admin/users` | P1 | ⚪ |
| Infrastructure | `/admin/infrastructure` | P1 | ⚪ |
| Server | `/admin/server` | P1 | ⚪ |
| Services | `/admin/services` | P1 | ⚪ |
| CRM | `/admin/crm` | P1 | ⚪ |
| Feedback | `/admin/feedback` | P2 | ⚪ |
| Tasks | `/admin/tasks` | P2 | ⚪ |
| Seed Users | `/admin/seed-users` | P2 | ⚪ |
| Seed Intakes | `/admin/seed-intakes` | P2 | ⚪ |
| Architecture | `/admin/architecture` | P2 | ⚪ |

---

## Data Models

```
CustomerOrganization (CRM view)
├── id: UUID
├── organizationName: string
├── organizationId: string
├── contactEmail: string
├── contactPhone: string?
├── address: string?
├── status: enum [active, trial, suspended, cancelled]
├── subscriptionTier: enum [basic, professional, enterprise]
├── monthlyRevenue: decimal
├── totalRevenue: decimal
├── subscriptionStartDate: date
├── subscriptionEndDate: date?
├── totalUsers: int
├── totalPatients: int
├── lastActivity: datetime
└── branches: Branch[]

Feedback
├── id: UUID
├── organizationId: UUID
├── organizationName: string
├── submittedBy: string
├── submittedByEmail: string
├── type: enum [bug, feature_request, improvement, complaint, praise]
├── category: enum [ui, performance, functionality, billing, other]
├── title: string
├── description: text
├── rating: int? (1-5)
├── status: enum [new, reviewed, in_progress, resolved, rejected]
├── priority: enum [low, medium, high, urgent]
├── reviewedBy: string?
├── reviewedAt: datetime?
├── featureRequestId: string?
├── createdAt: datetime
└── updatedAt: datetime

AdminTask
├── id: UUID
├── title: string
├── description: text
├── status: enum [todo, in_progress, done, blocked]
├── priority: enum [low, medium, high, urgent]
├── assignee: string?
├── dueDate: date?
├── category: enum [infrastructure, customer, development, maintenance, other]
├── createdAt: datetime
└── updatedAt: datetime
```

---

## Security

- **Access Control**: Restricted to `super_admin` role only
- **Audit Logging**: All admin actions logged with user ID and timestamp
- **SQL Injection Prevention**: Parameterized queries only; no raw SQL interpolation
- **Rate Limiting**: Query endpoints limited to prevent abuse
- **No DELETE/DROP**: Destructive SQL operations disabled via UI
- **PHI Protection**: Query results must not expose PHI in logs

---

## UI Layout

The admin module should follow the existing design system but with a distinct admin sidebar:

```
┌─────────────────────────────────────────────────────────────┐
│ Admin Portal                    🔔  👤 Admin User           │
├────────────────┬────────────────────────────────────────────┤
│ 📊 Dashboard   │                                            │
│ 💾 Database    │  [Content Area]                            │
│ 👥 Users       │                                            │
│ 🖥️ Infrastructure│                                            │
│ 📈 Server      │                                            │
│ 🔧 Services    │                                            │
│ 🏢 CRM         │                                            │
│ 💬 Feedback    │                                            │
│ ✅ Tasks       │                                            │
│ ───────────    │                                            │
│ 🌱 Seed Data   │                                            │
│ 🏗️ Architecture│                                            │
└────────────────┴────────────────────────────────────────────┘
```

---

## Tasks Reference

See [../tasks/admin.md](../tasks/admin.md) for implementation tasks.
