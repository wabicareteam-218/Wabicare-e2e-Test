# Backend Tasks (Django)

> Django REST Framework API development

---

## Project Setup

### ⚪ Backlog
- [ ] Create Django project structure
- [ ] Configure DRF
- [ ] Configure PostgreSQL connection
- [ ] Configure Celery + Redis
- [ ] Configure Azure Blob Storage
- [ ] Add OpenAPI generation (drf-spectacular)
- [ ] Docker setup for local dev
- [ ] Environment configuration

---

## Auth & Middleware

### ⚪ Backlog
- [ ] JWT validation middleware (Entra External ID)
- [ ] User sync from Azure
- [ ] Organization mapping
- [ ] Org-scoped query enforcement
- [ ] Role/permission checks

---

## Core Models

### ⚪ Backlog
- [ ] Organization model
- [ ] User model (extends Django user)
- [ ] Role & Permission models
- [ ] Patient model
- [ ] Guardian model
- [ ] InsuranceInfo model
- [ ] Intake & IntakeForm models
- [ ] Appointment model
- [ ] Session model
- [ ] Assessment model
- [ ] MediaAsset model

---

## API Endpoints

### ⚪ Backlog

#### Clinic
- [ ] `GET/POST /api/v1/clinic/patients`
- [ ] `GET/PATCH/DELETE /api/v1/clinic/patients/:id`
- [ ] `GET /api/v1/clinic/patients/:id/intake`
- [ ] `POST /api/v1/clinic/patients/:id/intake/forms/:formId`
- [ ] `GET/POST /api/v1/clinic/appointments`
- [ ] `GET/POST /api/v1/clinic/sessions`
- [ ] `GET/POST /api/v1/clinic/assessments`

#### Media
- [ ] `POST /api/v1/media/upload-url` (get signed URL)
- [ ] `POST /api/v1/media/confirm` (confirm upload)
- [ ] `GET /api/v1/media/:id` (get download URL)

#### Admin
- [ ] `POST /api/v1/admin/query` (run SQL)
- [ ] `GET /api/v1/admin/health`
- [ ] `GET /api/v1/admin/migrations`

---

## Background Jobs (Celery)

### ⚪ Backlog
- [ ] Intake workflow progression
- [ ] Media processing (thumbnails)
- [ ] Report generation
- [ ] Email notifications

---

## Observability

### ⚪ Backlog
- [ ] Structured JSON logging
- [ ] Request ID propagation
- [ ] Health check endpoint
- [ ] Metrics endpoint

---

## Deployment

### ⚪ Backlog
- [ ] Dockerfile
- [ ] Azure Container Apps config
- [ ] CI pipeline (GitHub Actions)
- [ ] Migration strategy
- [ ] Secrets management (Key Vault)
