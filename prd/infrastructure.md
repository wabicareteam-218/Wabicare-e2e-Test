# Infrastructure Module — PRD

> **Priority**: P0 - Core  
> **Status**: ⚪ Not Started

---

## Overview

This document defines the Azure infrastructure required to deploy the Wabi Clinic Flutter application across DEV, QA, and PROD environments. The architecture is **100% portable** — no vendor lock-in to Azure-specific services like Azure Functions.

### Design Principles

1. **Portability First** — Can migrate to AWS, GCP, or on-prem with config changes only
2. **Scale to Zero** — Minimize costs in non-production environments
3. **HIPAA Compliant** — Encryption, audit logs, access controls
4. **Simple Operations** — One codebase, one runtime, easy debugging

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    100% Portable Architecture                       │
│                    (No Azure-specific services)                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────┐    ┌─────────────────────┐                │
│  │ Azure Static Web    │    │ Azure Entra         │                │
│  │ Apps (Flutter Web)  │───▶│ External ID (Auth)  │                │
│  └─────────┬───────────┘    └─────────────────────┘                │
│            │ API calls                                              │
│            ▼                                                        │
│  ┌─────────────────────────────────────────────────────────┐       │
│  │              Azure Container Apps Environment            │       │
│  │  ┌─────────────────┐  ┌─────────────────┐              │       │
│  │  │  Django API     │  │  Celery Workers │              │       │
│  │  │  (gunicorn)     │  │  (scale 0-10)   │              │       │
│  │  │  min: 1         │  │  min: 0 ⚡       │              │       │
│  │  └────────┬────────┘  └────────┬────────┘              │       │
│  │           │                    │                        │       │
│  │           │           ┌────────┴────────┐              │       │
│  │           │           │  Celery Beat    │              │       │
│  │           │           │  (scheduler)    │              │       │
│  │           │           │  min: 1         │              │       │
│  │           │           └────────┬────────┘              │       │
│  └───────────┼────────────────────┼────────────────────────┘       │
│              │                    │                                 │
│     ┌────────┴────────┬───────────┴─────────┬──────────────┐       │
│     ▼                 ▼                     ▼              ▼       │
│  ┌──────────┐  ┌────────────┐  ┌─────────────┐  ┌──────────┐      │
│  │PostgreSQL│  │Azure Blob  │  │Azure Redis  │  │Key Vault │      │
│  │(Flexible)│  │Storage     │  │Cache        │  │(secrets) │      │
│  └──────────┘  └────────────┘  └─────────────┘  └──────────┘      │
│                                                                     │
│     ┌─────────────────────────────────────────────────┐            │
│     │            Monitoring & Logging                  │            │
│     │  Application Insights + Log Analytics            │            │
│     └─────────────────────────────────────────────────┘            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

Portable Components (can run anywhere):
├── Django + DRF (any container platform)
├── Celery Workers (any container platform)
├── Celery Beat (any container platform)
├── PostgreSQL (any managed/self-hosted)
├── Redis (any managed/self-hosted)
└── S3-compatible storage (MinIO/AWS S3/GCS/Azure Blob)
```

---

## Components

### 1. Flutter Web App (Azure Static Web Apps)

| Setting | DEV | QA | PROD |
|---------|-----|-----|------|
| SKU | Free | Standard | Standard |
| Custom Domain | ❌ | ✅ | ✅ |
| Staging Slots | ❌ | ✅ | ✅ |
| CDN | ❌ | ✅ | ✅ |

**Portable Alternative:** Any static hosting (Netlify, Vercel, CloudFront + S3, nginx)

### 2. Django API (Azure Container Apps)

| Setting | DEV | QA | PROD |
|---------|-----|-----|------|
| CPU | 0.25 | 0.5 | 1.0 |
| Memory | 0.5 GB | 1 GB | 2 GB |
| Min Replicas | 1 | 1 | 2 |
| Max Replicas | 2 | 5 | 20 |
| VNet Integration | ❌ | ✅ | ✅ |

**Container Image:**
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["gunicorn", "wabi_backend.wsgi:application", "-b", "0.0.0.0:8000", "-w", "4"]
```

**Portable Alternative:** AWS ECS, GCP Cloud Run, Kubernetes, Railway, Render

### 3. Celery Workers (Azure Container Apps — Scale to Zero ⚡)

| Setting | DEV | QA | PROD |
|---------|-----|-----|------|
| CPU | 0.25 | 0.5 | 1.0 |
| Memory | 0.5 GB | 1 GB | 2 GB |
| **Min Replicas** | **0** ⚡ | **0** ⚡ | 1 |
| Max Replicas | 3 | 10 | 30 |
| Scale Trigger | Redis queue length | Redis queue length | Redis queue length |

**Scale-to-Zero Configuration:**
```yaml
# Container Apps scaling rules
scale:
  minReplicas: 0
  maxReplicas: 10
  rules:
    - name: celery-queue-scaler
      custom:
        type: redis
        metadata:
          host: <redis-host>
          port: "6379"
          listName: celery
          listLength: "5"  # Scale up when 5+ tasks queued
```

**Container Command:**
```bash
celery -A wabi_backend worker -l INFO -c 4
```

**Portable Alternative:** Same container on any platform

### 4. Celery Beat (Scheduler)

| Setting | DEV | QA | PROD |
|---------|-----|-----|------|
| CPU | 0.25 | 0.25 | 0.25 |
| Memory | 0.5 GB | 0.5 GB | 0.5 GB |
| Replicas | 1 | 1 | 1 |

**Container Command:**
```bash
celery -A wabi_backend beat -l INFO --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

**Note:** Only ONE Beat instance should run (uses DB scheduler for HA)

### 5. PostgreSQL (Azure Database for PostgreSQL - Flexible Server)

| Setting | DEV | QA | PROD |
|---------|-----|-----|------|
| SKU | Burstable B1ms | GP_Standard_D2s_v3 | GP_Standard_D4s_v3 |
| vCores | 1 | 2 | 4 |
| Storage | 32 GB | 128 GB | 512 GB |
| Backup Retention | 7 days | 14 days | 35 days |
| Geo-Redundant Backup | ❌ | ❌ | ✅ |
| High Availability | ❌ | ❌ | ✅ (Zone redundant) |
| Private Endpoint | ❌ | ✅ | ✅ |

**Portable Alternative:** AWS RDS, GCP Cloud SQL, Supabase, self-hosted

### 6. Redis Cache (Azure Cache for Redis)

| Setting | DEV | QA | PROD |
|---------|-----|-----|------|
| SKU | Basic C0 | Standard C1 | Premium P1 |
| Memory | 250 MB | 1 GB | 6 GB |
| Persistence | ❌ | ❌ | ✅ |
| VNet Integration | ❌ | ✅ | ✅ |

**Usage:**
- Celery broker (task queue)
- Celery result backend
- Django cache
- Rate limiting

**Portable Alternative:** AWS ElastiCache, GCP Memorystore, Upstash, self-hosted

### 7. Azure Blob Storage

| Setting | DEV | QA | PROD |
|---------|-----|-----|------|
| SKU | Standard_LRS | Standard_GRS | Standard_RAGRS |
| Access | Private | Private | Private |
| Lifecycle Policy | 30 days | 90 days | 7 years |

**Containers:**
- `patient-documents` — Intake forms, consents (PHI)
- `session-media` — Photos, voice notes (PHI)
- `reports` — Generated PDFs
- `exports` — Data exports (temporary)

**Django Storage Backend:**
```python
# settings.py - easily switch providers
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.azure_storage.AzureStorage",
        # Or: "storages.backends.s3boto3.S3Boto3Storage"  # AWS
        # Or: "storages.backends.gcloud.GoogleCloudStorage"  # GCP
    },
}
```

**Portable Alternative:** AWS S3, GCP Cloud Storage, MinIO (self-hosted)

### 8. Azure Key Vault

| Setting | DEV | QA | PROD |
|---------|-----|-----|------|
| SKU | Standard | Standard | Premium |
| Purge Protection | ❌ | ❌ | ✅ |
| Private Endpoint | ❌ | ✅ | ✅ |

**Secrets:**
```
DATABASE_URL
REDIS_URL
AZURE_STORAGE_CONNECTION_STRING
ENTRA_CLIENT_ID
ENTRA_CLIENT_SECRET
SECRET_KEY
```

**Portable Alternative:** AWS Secrets Manager, GCP Secret Manager, HashiCorp Vault, environment variables

### 9. Monitoring (Application Insights + Log Analytics)

| Setting | DEV | QA | PROD |
|---------|-----|-----|------|
| Retention | 30 days | 90 days | 730 days |
| Sampling | 100% | 100% | Adaptive |
| Alerts | ❌ | ✅ | ✅ |

**Portable Alternative:** Datadog, New Relic, Grafana + Prometheus

---

## Celery Task Configuration

### Task Categories

| Category | Examples | Priority | Retry |
|----------|----------|----------|-------|
| **Critical** | Insurance verification, patient creation | High | 3x |
| **Standard** | Email sending, PDF generation | Normal | 3x |
| **Bulk** | Data exports, reports | Low | 1x |
| **Scheduled** | Appointment reminders, cleanup | Normal | 3x |

### Celery Configuration

```python
# celery.py
from celery import Celery
from celery.schedules import crontab

app = Celery('wabi_backend')

app.conf.update(
    # Broker (Redis)
    broker_url=os.environ['REDIS_URL'],
    result_backend=os.environ['REDIS_URL'],
    
    # Serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    
    # Task settings
    task_acks_late=True,  # For reliability
    task_reject_on_worker_lost=True,
    
    # Time limits
    task_soft_time_limit=300,  # 5 min soft limit
    task_time_limit=600,  # 10 min hard limit
    
    # Retry settings
    task_default_retry_delay=60,  # 1 min
    task_max_retries=3,
    
    # Queues
    task_routes={
        'tasks.critical.*': {'queue': 'critical'},
        'tasks.bulk.*': {'queue': 'bulk'},
        'tasks.*': {'queue': 'default'},
    },
    
    # Beat schedule (replaces Azure Timer Triggers)
    beat_schedule={
        # Daily at 8 AM
        'send-appointment-reminders': {
            'task': 'tasks.send_appointment_reminders',
            'schedule': crontab(hour=8, minute=0),
        },
        # Every hour
        'sync-external-calendars': {
            'task': 'tasks.sync_calendars',
            'schedule': crontab(minute=0),
        },
        # Daily at midnight
        'cleanup-expired-exports': {
            'task': 'tasks.cleanup_exports',
            'schedule': crontab(hour=0, minute=0),
        },
        # Every 5 minutes
        'process-pending-notifications': {
            'task': 'tasks.process_notifications',
            'schedule': crontab(minute='*/5'),
        },
    },
)
```

### Example Tasks

```python
# tasks/intake.py
from celery import shared_task

@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_kwargs={'max_retries': 3},
)
def process_intake(self, intake_id):
    """Process new intake - verify insurance, create patient"""
    intake = Intake.objects.get(id=intake_id)
    
    # Chain of tasks
    from celery import chain
    workflow = chain(
        verify_insurance.s(intake_id),
        create_patient_record.s(),
        assign_bcba.s(),
        send_welcome_email.s(),
        notify_admin.s(),
    )
    workflow.apply_async()

@shared_task
def send_appointment_reminders():
    """Daily task - send reminders for tomorrow's appointments"""
    tomorrow = timezone.now().date() + timedelta(days=1)
    appointments = Appointment.objects.filter(date=tomorrow, reminder_sent=False)
    
    for appt in appointments:
        send_reminder.delay(appt.id)

@shared_task(queue='bulk')
def generate_monthly_report(organization_id, month, year):
    """Bulk task - generate PDF report"""
    # Long-running task in bulk queue
    ...
```

---

## Cost Estimates (with Scale-to-Zero)

### DEV Environment

| Component | Always-On | Scale-to-Zero | Savings |
|-----------|-----------|---------------|---------|
| Django API | $20 | $20 | — |
| Celery Workers | $15 | **$2** ⚡ | 87% |
| Celery Beat | $5 | $5 | — |
| Redis | $16 | $16 | — |
| PostgreSQL | $30 | $30 | — |
| Storage | $5 | $5 | — |
| **Total** | **$91** | **$78** | **14%** |

### QA Environment

| Component | Always-On | Scale-to-Zero | Savings |
|-----------|-----------|---------------|---------|
| Django API | $50 | $50 | — |
| Celery Workers | $40 | **$5** ⚡ | 88% |
| Celery Beat | $10 | $10 | — |
| Redis | $50 | $50 | — |
| PostgreSQL | $150 | $150 | — |
| Storage | $20 | $20 | — |
| Monitoring | $20 | $20 | — |
| **Total** | **$340** | **$305** | **10%** |

### PROD Environment

| Component | Cost/mo |
|-----------|---------|
| Django API (min 2 replicas) | $150 |
| Celery Workers (min 1, max 30) | $100 |
| Celery Beat | $20 |
| Redis (Premium) | $250 |
| PostgreSQL (HA) | $400 |
| Storage | $50 |
| Monitoring | $100 |
| Key Vault | $10 |
| **Total** | **~$1,080** |

### Total Monthly Cost

| Environment | Cost |
|-------------|------|
| DEV | ~$78 |
| QA | ~$305 |
| PROD | ~$1,080 |
| **All Environments** | **~$1,463** |

---

## Network Architecture

### DEV (Simple)
```
Internet → Static Web Apps → Container Apps (public) → PostgreSQL (public)
```

### QA/PROD (Secure)
```
Internet → Static Web Apps → Container Apps Environment
                                     │
                              ┌──────┴──────┐
                              │    VNet     │
                              │  10.0.0.0/16│
                              └──────┬──────┘
                                     │
               ┌─────────────────────┼─────────────────────┐
               ▼                     ▼                     ▼
        ┌────────────┐        ┌────────────┐        ┌────────────┐
        │ PostgreSQL │        │   Redis    │        │ Key Vault  │
        │ Private EP │        │ Private EP │        │ Private EP │
        │ 10.0.1.x   │        │ 10.0.2.x   │        │ 10.0.3.x   │
        └────────────┘        └────────────┘        └────────────┘
```

---

## Deployment Pipeline

### GitHub Actions Workflow

```yaml
name: Deploy Wabi Clinic

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: wabiclinic.azurecr.io
  
jobs:
  # Build Flutter Web
  build-flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter build web --release
      - uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_TOKEN }}
          action: upload
          app_location: build/web

  # Build Django + Celery
  build-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}
      - run: |
          docker build -t $REGISTRY/wabi-api:${{ github.sha }} -f Dockerfile.api .
          docker build -t $REGISTRY/wabi-worker:${{ github.sha }} -f Dockerfile.worker .
          docker push $REGISTRY/wabi-api:${{ github.sha }}
          docker push $REGISTRY/wabi-worker:${{ github.sha }}

  # Deploy to Container Apps
  deploy:
    needs: [build-flutter, build-backend]
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - run: |
          az containerapp update \
            --name wabi-api \
            --resource-group rg-wabi-${{ env.ENVIRONMENT }} \
            --image $REGISTRY/wabi-api:${{ github.sha }}
          az containerapp update \
            --name wabi-worker \
            --resource-group rg-wabi-${{ env.ENVIRONMENT }} \
            --image $REGISTRY/wabi-worker:${{ github.sha }}

  # Run migrations
  migrate:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - run: |
          az containerapp job start \
            --name wabi-migrate \
            --resource-group rg-wabi-${{ env.ENVIRONMENT }}
```

---

## HIPAA Compliance Checklist

| Requirement | Implementation | Status |
|-------------|----------------|--------|
| Encryption at rest | PostgreSQL TDE, Storage encryption, Redis encryption | ⚪ |
| Encryption in transit | TLS 1.2+ on all connections | ⚪ |
| Access logging | Application Insights, PostgreSQL audit logs | ⚪ |
| Audit trails | 2-year retention in PROD | ⚪ |
| Network isolation | VNet + Private Endpoints (QA/PROD) | ⚪ |
| Secrets management | Key Vault with Managed Identity | ⚪ |
| Backup & recovery | Geo-redundant backups (PROD) | ⚪ |
| Access controls | RBAC, least privilege | ⚪ |
| BAA | Sign Microsoft Azure BAA | ⚪ |

---

## Portability Matrix

| Component | Azure | AWS | GCP | Self-Hosted |
|-----------|-------|-----|-----|-------------|
| Flutter Web | Static Web Apps | CloudFront + S3 | Firebase Hosting | nginx |
| Django API | Container Apps | ECS/Fargate | Cloud Run | Kubernetes |
| Celery Workers | Container Apps | ECS/Fargate | Cloud Run | Kubernetes |
| PostgreSQL | Flexible Server | RDS | Cloud SQL | PostgreSQL |
| Redis | Azure Cache | ElastiCache | Memorystore | Redis |
| Storage | Blob Storage | S3 | Cloud Storage | MinIO |
| Secrets | Key Vault | Secrets Manager | Secret Manager | Vault |
| Monitoring | App Insights | CloudWatch | Cloud Monitoring | Grafana |

**Migration effort:** Change environment variables + Terraform providers. No code changes.

---

## Terraform Modules

```
infrastructure/terraform/
├── modules/
│   ├── static-web-app/      # Flutter hosting
│   ├── container-apps/      # Django + Celery
│   ├── postgresql/          # Database
│   ├── redis/               # Cache + Broker
│   ├── storage/             # Blob storage
│   ├── key-vault/           # Secrets
│   ├── monitoring/          # App Insights
│   └── networking/          # VNet (QA/PROD)
├── environments/
│   ├── dev/
│   ├── qa/
│   └── prod/
└── shared/
    └── state-storage.tf     # Terraform state
```

---

## No Azure Functions ✅

This architecture uses **100% Celery** instead of Azure Functions:

| Use Case | Azure Functions (Old) | Celery (New) |
|----------|----------------------|--------------|
| Timer triggers | Timer Trigger | Celery Beat |
| Event processing | Service Bus Trigger | Celery task + Redis |
| HTTP webhooks | HTTP Trigger | Django view → `.delay()` |
| Orchestrations | Durable Functions | Celery Canvas |

**Benefits:**
- ✅ Zero vendor lock-in
- ✅ Same codebase as API
- ✅ Easier debugging
- ✅ No cold starts
- ✅ Can migrate to any cloud

---

## Tasks Reference

See [../tasks/infrastructure.md](../tasks/infrastructure.md) for implementation tasks.
