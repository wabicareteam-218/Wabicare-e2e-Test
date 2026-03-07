# Admin Tasks

> System administration tasks — mirrors Next.js `/admin` module

**PRD Reference**: [../prd/admin.md](../prd/admin.md)

---

## 1. Admin Dashboard

### ⚪ Backlog
- [ ] Admin layout with separate sidebar
- [ ] System stats API integration
- [ ] Key metrics cards (customers, users, health, uptime)
- [ ] Services status panel
- [ ] Database status panel
- [ ] Infrastructure status panel
- [ ] Quick actions panel
- [ ] System alerts list
- [ ] Auto-refresh (30s)

---

## 2. Database Management

### ⚪ Backlog
- [ ] Database page layout
- [ ] SQL query input (textarea or code editor)
- [ ] Execute query button (read-only queries)
- [ ] Query results table
- [ ] Tables list sidebar
- [ ] Export schema button
- [ ] Migrations list view
- [ ] Run migration button
- [ ] Connection status indicator

### Backend
- [ ] `POST /api/v1/admin/database/query`
- [ ] `GET /api/v1/admin/database/tables`
- [ ] `GET /api/v1/admin/database/status`
- [ ] `POST /api/v1/admin/database/migrate`
- [ ] `GET /api/v1/admin/database/migrations`
- [ ] Query sanitization (prevent DROP/DELETE)

---

## 3. User Management

### ⚪ Backlog
- [ ] Users list page
- [ ] Search users input
- [ ] User table (name, email, org, role, status, created)
- [ ] Create test user form
- [ ] Initialize RBAC button
- [ ] Assign role dropdown
- [ ] Check user role utility
- [ ] Find users without org

### Backend
- [ ] `GET /api/v1/admin/users`
- [ ] `POST /api/v1/admin/users`
- [ ] `POST /api/v1/admin/init-roles`
- [ ] `POST /api/v1/admin/assign-role`

---

## 4. Infrastructure Monitoring

### ⚪ Backlog
- [ ] Infrastructure page layout
- [ ] Summary cards (total resources, healthy, score, region)
- [ ] Resource cards grid:
  - [ ] App Service card
  - [ ] Database card
  - [ ] Key Vault card
  - [ ] Application Gateway card
  - [ ] Application Insights card
  - [ ] Storage Account card
- [ ] Security & Compliance panel
- [ ] Network architecture placeholder
- [ ] Auto-refresh (60s)

### Backend
- [ ] `GET /api/v1/admin/infrastructure/status`
- [ ] Azure resource health integration

---

## 5. Server Monitoring

### ⚪ Backlog
- [ ] Server page layout with tabs
- [ ] Overview tab:
  - [ ] Server status badge
  - [ ] CPU usage card + progress bar
  - [ ] Memory usage card + progress bar
  - [ ] Requests/sec card
  - [ ] Network I/O card
  - [ ] Uptime display
- [ ] Metrics tab (charts placeholder)
- [ ] Logs tab:
  - [ ] Log level filter buttons (All, Errors, Warnings)
  - [ ] Log entries list
  - [ ] Timestamp, level badge, source, message
- [ ] Auto-refresh (10s for metrics, 30s for logs)

### Backend
- [ ] `GET /api/v1/admin/server/metrics`
- [ ] `GET /api/v1/admin/server/logs`

---

## 6. Services Status

### ⚪ Backlog
- [ ] Services page layout
- [ ] Summary cards (total, healthy, degraded, down)
- [ ] Service cards grid:
  - [ ] Intake Service
  - [ ] Data Collection
  - [ ] Scheduling
  - [ ] HRMS
  - [ ] Parent Portal
  - [ ] Smart Billing
- [ ] Per-service: status badge, response time, uptime, requests, errors
- [ ] Performance trends placeholder
- [ ] Last refresh timestamp
- [ ] Auto-refresh (60s)

### Backend
- [ ] `GET /api/v1/admin/services/status`
- [ ] Health check per service

---

## 7. CRM / Customer Management

### ⚪ Backlog
- [ ] CRM page layout
- [ ] Key metrics cards (customers, MRR, total revenue, users)
- [ ] Search input
- [ ] Status filter dropdown
- [ ] Customers table:
  - [ ] Organization name + ID
  - [ ] Contact (email, phone, address)
  - [ ] Status badge
  - [ ] Subscription tier badge
  - [ ] Monthly revenue
  - [ ] Users/Patients count
  - [ ] Last activity
- [ ] View Details button → Dialog
- [ ] Customer details dialog:
  - [ ] Organization info
  - [ ] Contact info
  - [ ] Branches table
- [ ] Export button

### Backend
- [ ] `GET /api/v1/admin/crm/customers`
- [ ] Customer aggregation queries

---

## 8. Customer Feedback

### ⚪ Backlog
- [ ] Feedback page layout
- [ ] Stats cards (total, new, in progress, resolved)
- [ ] Search input
- [ ] Type filter (bug, feature request, improvement, complaint, praise)
- [ ] Status filter
- [ ] Priority filter
- [ ] Feedback table:
  - [ ] Title + description
  - [ ] Organization + submitter
  - [ ] Type badge
  - [ ] Status dropdown (inline update)
  - [ ] Priority badge
  - [ ] Rating (stars)
  - [ ] Submitted date
- [ ] Create Feature Request button → Dialog
- [ ] Feature Request form

### Backend
- [ ] `GET /api/v1/admin/feedback`
- [ ] `PATCH /api/v1/admin/feedback/:id`
- [ ] `POST /api/v1/admin/feedback/feature-requests`

---

## 9. Task Management

### ⚪ Backlog
- [ ] Tasks page layout
- [ ] Stats cards (todo, in progress, done, blocked)
- [ ] Search input
- [ ] Status/Priority/Category filters
- [ ] Tasks table:
  - [ ] Title + description
  - [ ] Status dropdown (inline update)
  - [ ] Priority badge
  - [ ] Category badge
  - [ ] Assignee
  - [ ] Due date
- [ ] New Task button → Dialog
- [ ] Create task form

### Backend
- [ ] `GET /api/v1/admin/tasks`
- [ ] `POST /api/v1/admin/tasks`
- [ ] `PATCH /api/v1/admin/tasks/:id`

---

## 10. Data Seeding

### ⚪ Backlog
- [ ] Seed Users page
- [ ] Seed Intakes page
- [ ] Sample data configuration
- [ ] Execute seed button
- [ ] Progress/results display

### Backend
- [ ] `POST /api/v1/admin/seed-users`
- [ ] `POST /api/v1/admin/seed-intakes`
- [ ] `POST /api/v1/admin/seed-patients`

---

## 11. Architecture View

### ⚪ Backlog
- [ ] Architecture page layout
- [ ] System diagram (static or generated)
- [ ] Azure infrastructure view
- [ ] Database schema view
- [ ] Module dependencies view

---

## Technical Debt

| Item | Priority | Notes |
|------|----------|-------|
| Real-time metrics | Medium | Use WebSocket for live updates |
| Query result pagination | Medium | Large result sets |
| Role-based admin menu | High | Show/hide based on permissions |
