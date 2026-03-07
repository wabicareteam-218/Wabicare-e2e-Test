# Domain Architecture for Wabi ABA Practice Management SaaS

---

## Simple Architecture Overview (How It All Works)

### The Big Picture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            USER'S DEVICE                                     │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                     FLUTTER APP (Frontend)                             │  │
│  │                                                                        │  │
│  │   📱 Screens → 🔄 State (Stores) → 🌐 API Services → HTTP Requests    │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ HTTP (REST API)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SERVER                                          │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                   DJANGO BACKEND (API Layer)                           │  │
│  │                                                                        │  │
│  │   🚪 URLs → 👁️ Views → 📋 Serializers → 🏛️ Models → 🗄️ Database     │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                           │                    │                             │
│                           │ Domain Events      │ Background Jobs             │
│                           ▼                    ▼                             │
│  ┌────────────────────┐  ┌────────────────────────────────────────────┐     │
│  │   📨 Event Bus     │  │              🥬 CELERY (Workers)           │     │
│  │   (Pub/Sub)        │  │                                            │     │
│  │                    │  │  📧 Send Emails    📊 Generate Reports     │     │
│  │  PatientCreated    │  │  📱 Send SMS       🔔 Send Notifications   │     │
│  │  SessionCompleted  │  │  📄 Create PDFs    ⏰ Scheduled Tasks      │     │
│  │  AuthExpiring      │  │                                            │     │
│  └────────────────────┘  └────────────────────────────────────────────┘     │
│                                      │                                       │
│                                      ▼                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                        🗄️ DATABASE (PostgreSQL)                       │  │
│  │                                                                        │  │
│  │   📁 Organizations  👤 Users  🧒 Patients  📝 Intakes  📅 Sessions   │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                        ⚡ REDIS (Cache + Message Queue)               │  │
│  │                                                                        │  │
│  │   🔄 Celery Queue    💾 Cache Data    🔐 Session Store                │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### How a Request Flows (Example: Creating a Patient)

```
USER CLICKS "CREATE PATIENT" BUTTON
            │
            ▼
┌──────────────────────────────────────────────────────────────────────┐
│ STEP 1: FLUTTER FRONTEND                                             │
│                                                                      │
│  📱 Screen                    🔄 Store                   🌐 API      │
│  ┌─────────┐                ┌─────────┐               ┌─────────┐   │
│  │ Patient │  onPressed()   │ Patient │  createPat()  │ Patient │   │
│  │ Form    │ ────────────▶  │ Store   │ ────────────▶ │ API Svc │   │
│  └─────────┘                └─────────┘               └────┬────┘   │
│                                                             │        │
│  User fills form           Store calls API              HTTP POST   │
│  and clicks Save           service method               /patients/  │
└─────────────────────────────────────────────────────────────┼────────┘
                                                              │
                                                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│ STEP 2: DJANGO BACKEND                                               │
│                                                                      │
│  🚪 URL Router              👁️ ViewSet                📋 Serializer │
│  ┌─────────┐               ┌─────────┐               ┌─────────┐    │
│  │ /api/v1 │  route to     │ Patient │  validate     │ Patient │    │
│  │/patients│ ────────────▶ │ ViewSet │ ────────────▶ │ Serial. │    │
│  └─────────┘               └────┬────┘               └────┬────┘    │
│                                 │                         │          │
│  Maps URL to view          Handles request           Validates data │
│                                 │                         │          │
│                                 ▼                         ▼          │
│                            🏛️ Model                  🗄️ Database    │
│                           ┌─────────┐               ┌─────────┐     │
│                           │ Patient │  .save()      │ INSERT  │     │
│                           │ Model   │ ────────────▶ │ INTO    │     │
│                           └────┬────┘               │patients │     │
│                                │                    └─────────┘     │
│                                │                                     │
│                                ▼                                     │
│                           📨 Event Bus                               │
│                          ┌──────────┐                                │
│                          │ Publish: │                                │
│                          │ Patient  │                                │
│                          │ Created  │                                │
│                          └────┬─────┘                                │
└───────────────────────────────┼──────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ STEP 3: BACKGROUND PROCESSING (CELERY)                               │
│                                                                      │
│  Event listeners trigger background tasks:                           │
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐      │
│  │ 📧 Send Welcome │  │ 📝 Create Task  │  │ 📊 Update       │      │
│  │    Email        │  │    for BCBA     │  │    Analytics    │      │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘      │
│                                                                      │
│  These run in background - user doesn't wait!                        │
└──────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│ STEP 4: RESPONSE BACK TO USER                                        │
│                                                                      │
│  Django returns JSON ──▶ API Service parses ──▶ Store updates ──▶ UI│
│                                                                      │
│  { "id": "abc-123",         Patient object       setState()         │
│    "first_name": "John",    returned             triggers rebuild   │
│    "status": "active" }                                              │
│                                                                      │
│  ✅ User sees: "Patient created successfully!"                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

### Frontend Architecture (Flutter)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER FRONTEND                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         SCREENS (UI Layer)                           │    │
│  │                                                                      │    │
│  │  What user sees and interacts with                                   │    │
│  │                                                                      │    │
│  │  patients_screen.dart  →  Shows list of patients                     │    │
│  │  intake_workspace.dart →  Intake details & workflow                  │    │
│  │  scheduling_screen.dart → Calendar & appointments                    │    │
│  └──────────────────────────────────┬──────────────────────────────────┘    │
│                                     │ uses                                   │
│                                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        STORES (State Layer)                          │    │
│  │                                                                      │    │
│  │  Holds app data & notifies UI when data changes                      │    │
│  │                                                                      │    │
│  │  patients_store.dart  →  List<Patient>, loading, error states        │    │
│  │  sessions_store.dart  →  List<Session>, current session              │    │
│  │  user_store.dart      →  Current user, permissions                   │    │
│  │                                                                      │    │
│  │  class PatientsStore extends ChangeNotifier {                        │    │
│  │    List<Patient> _patients = [];                                     │    │
│  │    bool _isLoading = false;                                          │    │
│  │                                                                      │    │
│  │    Future<void> loadPatients() async {                               │    │
│  │      _isLoading = true;                                              │    │
│  │      notifyListeners();  // UI rebuilds with loading spinner         │    │
│  │                                                                      │    │
│  │      _patients = await _apiService.getPatients();                    │    │
│  │      _isLoading = false;                                             │    │
│  │      notifyListeners();  // UI rebuilds with patient list            │    │
│  │    }                                                                 │    │
│  │  }                                                                   │    │
│  └──────────────────────────────────┬──────────────────────────────────┘    │
│                                     │ calls                                  │
│                                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      API SERVICES (Network Layer)                    │    │
│  │                                                                      │    │
│  │  Handles HTTP requests to backend                                    │    │
│  │                                                                      │    │
│  │  patient_api_service.dart  →  GET/POST/PATCH /patients/              │    │
│  │  intake_api_service.dart   →  GET/POST /intakes/                     │    │
│  │  session_api_service.dart  →  GET/POST /sessions/                    │    │
│  │                                                                      │    │
│  │  class PatientApiService {                                           │    │
│  │    Future<List<Patient>> getPatients() async {                       │    │
│  │      final response = await http.get('/api/v1/patients/');           │    │
│  │      return response.data.map((json) => Patient.fromJson(json));     │    │
│  │    }                                                                 │    │
│  │  }                                                                   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Backend Architecture (Django)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DJANGO BACKEND                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  HTTP Request: POST /api/v1/patients/                                        │
│        │                                                                     │
│        ▼                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         URLS (Routing)                               │    │
│  │                                                                      │    │
│  │  Maps URL paths to view functions                                    │    │
│  │                                                                      │    │
│  │  /api/v1/patients/     →  PatientViewSet                             │    │
│  │  /api/v1/intakes/      →  IntakeViewSet                              │    │
│  │  /api/v1/sessions/     →  SessionViewSet                             │    │
│  └──────────────────────────────────┬──────────────────────────────────┘    │
│                                     │                                        │
│                                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         VIEWS (Controllers)                          │    │
│  │                                                                      │    │
│  │  Handle requests, call services, return responses                    │    │
│  │                                                                      │    │
│  │  class PatientViewSet(viewsets.ModelViewSet):                        │    │
│  │      def create(self, request):                                      │    │
│  │          # 1. Validate data                                          │    │
│  │          serializer = PatientSerializer(data=request.data)           │    │
│  │          serializer.is_valid()                                       │    │
│  │                                                                      │    │
│  │          # 2. Save to database                                       │    │
│  │          patient = serializer.save(organization=request.org)         │    │
│  │                                                                      │    │
│  │          # 3. Trigger background tasks                               │    │
│  │          send_welcome_email.delay(patient.id)                        │    │
│  │                                                                      │    │
│  │          # 4. Return response                                        │    │
│  │          return Response(PatientSerializer(patient).data)            │    │
│  └──────────────────────────────────┬──────────────────────────────────┘    │
│                                     │                                        │
│                                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      SERIALIZERS (Data Transform)                    │    │
│  │                                                                      │    │
│  │  Convert between JSON ↔ Python objects, validate data                │    │
│  │                                                                      │    │
│  │  class PatientSerializer(serializers.ModelSerializer):               │    │
│  │      class Meta:                                                     │    │
│  │          model = Patient                                             │    │
│  │          fields = ['id', 'first_name', 'last_name', 'dob', ...]     │    │
│  │                                                                      │    │
│  │  JSON Input:                    Python Object:                       │    │
│  │  {"first_name": "John"}    →    Patient(first_name="John")          │    │
│  │                                                                      │    │
│  │  Python Object:                 JSON Output:                         │    │
│  │  Patient(first_name="John") →  {"first_name": "John", "id": "..."}  │    │
│  └──────────────────────────────────┬──────────────────────────────────┘    │
│                                     │                                        │
│                                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         MODELS (Database Layer)                      │    │
│  │                                                                      │    │
│  │  Define database tables and relationships                            │    │
│  │                                                                      │    │
│  │  class Patient(models.Model):                                        │    │
│  │      id = UUIDField(primary_key=True)                                │    │
│  │      organization = ForeignKey(Organization)  # Multi-tenant         │    │
│  │      first_name = CharField(max_length=100)                          │    │
│  │      last_name = CharField(max_length=100)                           │    │
│  │      dob = DateField()                                               │    │
│  │      status = CharField(choices=['active', 'inactive', 'discharged'])│    │
│  │                                                                      │    │
│  │  Patient.objects.create(...)  →  INSERT INTO patients ...            │    │
│  │  Patient.objects.filter(...)  →  SELECT * FROM patients WHERE ...    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Celery Background Jobs (Async Processing)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CELERY BACKGROUND WORKERS                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  WHY CELERY?                                                                 │
│  ───────────                                                                 │
│  Some tasks are SLOW (sending emails, generating PDFs, calling external     │
│  APIs). We don't want users to wait! Celery runs these in the background.   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         HOW IT WORKS                                 │    │
│  │                                                                      │    │
│  │   Django View                    Redis Queue              Celery    │    │
│  │   ┌─────────┐    add task       ┌─────────┐    pick up   ┌────────┐│    │
│  │   │ Create  │  ────────────▶    │ Queue:  │  ──────────▶ │ Worker ││    │
│  │   │ Patient │                   │ [task1] │              │ runs   ││    │
│  │   └────┬────┘                   │ [task2] │              │ task   ││    │
│  │        │                        └─────────┘              └────────┘│    │
│  │        │                                                           │    │
│  │        ▼                                                           │    │
│  │   Returns to user                                                  │    │
│  │   IMMEDIATELY!                  Task runs in background            │    │
│  │   (doesn't wait)                (user doesn't wait)                │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      EXAMPLE CELERY TASKS                            │    │
│  │                                                                      │    │
│  │  # tasks.py                                                          │    │
│  │                                                                      │    │
│  │  @celery_app.task                                                    │    │
│  │  def send_welcome_email(patient_id):                                 │    │
│  │      """Send welcome email to new patient's family"""                │    │
│  │      patient = Patient.objects.get(id=patient_id)                    │    │
│  │      send_email(                                                     │    │
│  │          to=patient.guardian_email,                                  │    │
│  │          subject="Welcome to Wabi Clinic!",                          │    │
│  │          template="welcome.html"                                     │    │
│  │      )                                                               │    │
│  │                                                                      │    │
│  │  @celery_app.task                                                    │    │
│  │  def generate_session_report(session_id):                            │    │
│  │      """Generate PDF report for completed session"""                 │    │
│  │      session = Session.objects.get(id=session_id)                    │    │
│  │      pdf = create_pdf(session.data)                                  │    │
│  │      session.report_url = upload_to_storage(pdf)                     │    │
│  │      session.save()                                                  │    │
│  │                                                                      │    │
│  │  @celery_app.task                                                    │    │
│  │  def check_expiring_authorizations():                                │    │
│  │      """Runs every hour - alerts about expiring auths"""             │    │
│  │      expiring = Authorization.objects.filter(                        │    │
│  │          end_date__lte=now() + timedelta(days=30)                    │    │
│  │      )                                                               │    │
│  │      for auth in expiring:                                           │    │
│  │          send_alert(auth)                                            │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      SCHEDULED TASKS (Celery Beat)                   │    │
│  │                                                                      │    │
│  │  ┌──────────────────┬────────────────────────────────────────────┐  │    │
│  │  │ Schedule         │ Task                                       │  │    │
│  │  ├──────────────────┼────────────────────────────────────────────┤  │    │
│  │  │ Every hour       │ check_expiring_authorizations()            │  │    │
│  │  │ Every day 6am    │ send_daily_schedule_reminders()            │  │    │
│  │  │ Every Monday     │ generate_weekly_reports()                  │  │    │
│  │  │ 1st of month     │ generate_monthly_billing_summary()         │  │    │
│  │  └──────────────────┴────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Domain Events (Pub/Sub Pattern)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DOMAIN EVENTS                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  WHY EVENTS?                                                                 │
│  ───────────                                                                 │
│  When something happens (patient created, session completed), multiple       │
│  things need to happen in response. Events decouple the "what happened"      │
│  from "what to do about it".                                                 │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                                                                      │    │
│  │   BEFORE (Tightly Coupled)         AFTER (Event-Driven)             │    │
│  │   ─────────────────────────        ────────────────────             │    │
│  │                                                                      │    │
│  │   def create_patient():            def create_patient():            │    │
│  │       patient.save()                   patient.save()               │    │
│  │       send_email(...)                  publish(PatientCreated)      │    │
│  │       create_task(...)                                              │    │
│  │       update_analytics(...)        # Listeners handle the rest:     │    │
│  │       notify_bcba(...)             # - EmailListener sends email    │    │
│  │       # 100 more things...         # - TaskListener creates task    │    │
│  │                                    # - AnalyticsListener updates    │    │
│  │   View knows TOO MUCH!             View only saves & publishes!     │    │
│  │                                                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         EXAMPLE FLOW                                 │    │
│  │                                                                      │    │
│  │                    ┌──────────────────┐                              │    │
│  │                    │ Session Completed │                             │    │
│  │                    │     (Event)       │                             │    │
│  │                    └────────┬─────────┘                              │    │
│  │                             │                                        │    │
│  │           ┌─────────────────┼─────────────────┐                      │    │
│  │           │                 │                 │                      │    │
│  │           ▼                 ▼                 ▼                      │    │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │    │
│  │   │ Generate     │  │ Update Unit  │  │ Send Parent  │              │    │
│  │   │ Report (PDF) │  │ Tracking     │  │ Notification │              │    │
│  │   └──────────────┘  └──────────────┘  └──────────────┘              │    │
│  │                                                                      │    │
│  │   Each listener handles ONE thing. Easy to add new behaviors!        │    │
│  │                                                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      COMMON EVENTS                                   │    │
│  │                                                                      │    │
│  │  ┌──────────────────────┬───────────────────────────────────────┐   │    │
│  │  │ Event                │ What Happens                          │   │    │
│  │  ├──────────────────────┼───────────────────────────────────────┤   │    │
│  │  │ PatientCreated       │ Welcome email, create intake, notify  │   │    │
│  │  │ IntakeApproved       │ Schedule assessment, notify BCBA      │   │    │
│  │  │ SessionCompleted     │ Generate notes, update units, notify  │   │    │
│  │  │ AuthorizationExpiring│ Alert billing, notify scheduler       │   │    │
│  │  │ TargetMastered       │ Update program, celebrate, log        │   │    │
│  │  └──────────────────────┴───────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### Complete Workflow Example: Session Check-In to Report

```
┌─────────────────────────────────────────────────────────────────────────────┐
│      COMPLETE WORKFLOW: RBT Conducts Session → Parent Gets Report           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1️⃣ RBT CHECKS IN (EVV)                                                     │
│  ─────────────────────                                                       │
│  📱 RBT opens app → Taps "Check In" → App captures GPS + time                │
│                                                                              │
│  Flutter:  session_api.checkIn(sessionId, location, time)                    │
│  Backend:  SessionViewSet.check_in() → Save EVVData → Return OK              │
│                                                                              │
│  2️⃣ RBT COLLECTS DATA                                                       │
│  ────────────────────                                                        │
│  📱 RBT works with child, records trials: ✓ ✓ ✗ ✓ ✓                         │
│                                                                              │
│  Flutter:  session_api.recordTrial(target, response, prompt)                 │
│  Backend:  TrialDataViewSet.create() → Save to database                      │
│                                                                              │
│  3️⃣ RBT CHECKS OUT                                                          │
│  ──────────────────                                                          │
│  📱 RBT taps "Check Out" → Session marked complete                           │
│                                                                              │
│  Flutter:  session_api.checkOut(sessionId, location, time)                   │
│  Backend:  SessionViewSet.check_out() → Update status → Publish event        │
│                                                                              │
│                    ┌────────────────────────┐                                │
│                    │ SessionCompleted Event │                                │
│                    └───────────┬────────────┘                                │
│                                │                                             │
│          ┌─────────────────────┼─────────────────────┐                       │
│          │                     │                     │                       │
│          ▼                     ▼                     ▼                       │
│  4️⃣ BACKGROUND TASKS (CELERY)                                               │
│  ────────────────────────────                                                │
│                                                                              │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐                  │
│  │ Generate    │      │ Update Unit │      │ Send Parent │                  │
│  │ AI Notes    │      │ Tracking    │      │ Notification│                  │
│  │             │      │             │      │             │                  │
│  │ "John had   │      │ 97001: 4/40 │      │ "Session    │                  │
│  │ a great     │      │ units used  │      │ complete!"  │                  │
│  │ session..." │      │             │      │             │                  │
│  └──────┬──────┘      └─────────────┘      └──────┬──────┘                  │
│         │                                         │                          │
│         ▼                                         ▼                          │
│  ┌─────────────┐                          ┌─────────────┐                   │
│  │ Generate    │                          │ Parent gets │                   │
│  │ PDF Report  │                          │ push notif  │                   │
│  └──────┬──────┘                          └─────────────┘                   │
│         │                                                                    │
│         ▼                                                                    │
│  5️⃣ PARENT VIEWS REPORT                                                     │
│  ──────────────────────                                                      │
│  📱 Parent opens Parent Portal → Sees session summary + progress             │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────┐             │
│  │  SESSION REPORT - Feb 2, 2026                              │             │
│  │                                                            │             │
│  │  Patient: John Doe                                         │             │
│  │  Therapist: Sarah Smith, RBT                               │             │
│  │  Duration: 2 hours                                         │             │
│  │                                                            │             │
│  │  GOALS WORKED:                                             │             │
│  │  ✅ Manding (requesting): 85% accuracy (↑ from 70%)        │             │
│  │  ✅ Following instructions: 90% accuracy                   │             │
│  │  📈 Great progress this week!                              │             │
│  │                                                            │             │
│  │  NOTES:                                                    │             │
│  │  John had a wonderful session today. He successfully       │             │
│  │  requested his favorite toy using a full sentence...       │             │
│  └────────────────────────────────────────────────────────────┘             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Executive Summary

This document defines the **8-domain architecture** for the Wabi ABA Practice Management platform, designed for scalability, maintainability, and multi-tenant SaaS deployment.

**Architecture Style**: Domain-Driven Design (DDD) with bounded contexts
**Deployment Model**: Multi-tenant SaaS with subscription tiers
**Current State**: Layered MVC (migration path defined below)

---

## Domain Overview

| # | Domain | Description | SaaS Tier |
|---|--------|-------------|-----------|
| 1 | **Clinic** | Core clinical operations - patient intake, assessments, authorizations, therapy sessions, scheduling | Essential |
| 2 | **Billing RCM** | Revenue cycle management - claims, accounts receivable, insurance | Professional |
| 3 | **Parent Portal** | Parent/guardian facing - intake forms, progress tracking, resources | Essential |
| 4 | **HRMS** | Human resource management - leaves, benefits, recognition | Professional |
| 5 | **LMS** | Learning management - staff training and certifications | Professional |
| 6 | **Auth** | Authentication & authorization - RBAC, roles, SSO, multi-tenancy | Core (all tiers) |
| 7 | **AI & Insights** | AI features - chatbot, reporting, analytics | Enterprise |
| 8 | **Communication** | Messaging - calls, text, email, chat | Professional |

---

## Domain Context Map

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              WABI PLATFORM                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │                         CORE INFRASTRUCTURE                               │   │
│  │  ┌─────────────┐                                    ┌─────────────┐      │   │
│  │  │    AUTH     │◄──────── All domains depend on ────│ AI/INSIGHTS │      │   │
│  │  │ (RBAC/SSO)  │                                    │ (Analytics) │      │   │
│  │  └─────────────┘                                    └─────────────┘      │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │                         CLINICAL OPERATIONS                               │   │
│  │                                                                           │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                   │   │
│  │  │   CLINIC    │───▶│   BILLING   │───▶│    HRMS     │                   │   │
│  │  │             │    │     RCM     │    │             │                   │   │
│  │  │ - Intake    │    │             │    │ - Leaves    │                   │   │
│  │  │ - Assessment│    │ - Claims    │    │ - Benefits  │                   │   │
│  │  │ - Auth*     │    │ - AR        │    │ - Recognition│                  │   │
│  │  │ - Sessions  │    │ - Insurance │    │             │                   │   │
│  │  │ - Scheduling│    │             │    │             │                   │   │
│  │  │ - Tools     │    │             │    │             │                   │   │
│  │  └──────┬──────┘    └─────────────┘    └─────────────┘                   │   │
│  │         │                                                                 │   │
│  │         ▼                                                                 │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                   │   │
│  │  │   PARENT    │    │     LMS     │    │COMMUNICATION│                   │   │
│  │  │   PORTAL    │    │             │    │             │                   │   │
│  │  │             │    │ - Training  │    │ - Calls     │                   │   │
│  │  │ - Forms     │    │ - Certs     │    │ - Text/SMS  │                   │   │
│  │  │ - Progress  │    │             │    │ - Email     │                   │   │
│  │  │ - Resources │    │             │    │ - Chat      │                   │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘                   │   │
│  │                                                                           │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘

*Auth = Insurance Authorization (not to be confused with Auth domain for RBAC)
```

---

## Domain 1: Clinic

**Purpose**: Core clinical operations for ABA therapy practice management.

### Modules

#### 1.1 Intake
**Submodules**: Patient Registration, Required Documents, Form Distribution, Workflow Management

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Patient` | id, first_name, last_name, dob, diagnosis, status, organization_id | Core patient record |
| `Intake` | id, patient_id, workflow_status, form_data, required_items | Intake workflow instance |
| `IntakeSectionCompletion` | id, intake_id, section, status, completed_at | Section progress tracking |
| `IntakeDocument` | id, intake_id, document_type, file_url, status | Uploaded documents |
| `IntakeNote` | id, intake_id, content, author_id, created_at | Clinical notes |
| `IntakeTimeline` | id, intake_id, event_type, description, timestamp | Audit trail |

**API Endpoints**:
```
POST   /api/v1/clinic/patients/                    # Create patient
GET    /api/v1/clinic/patients/                    # List patients
GET    /api/v1/clinic/patients/{id}/               # Get patient details
PATCH  /api/v1/clinic/patients/{id}/               # Update patient
POST   /api/v1/clinic/patients/{id}/discharge/     # Discharge patient

POST   /api/v1/clinic/intakes/                     # Create intake
GET    /api/v1/clinic/intakes/                     # List intakes
GET    /api/v1/clinic/intakes/{id}/                # Get intake details
PATCH  /api/v1/clinic/intakes/{id}/                # Update intake
POST   /api/v1/clinic/intakes/{id}/advance/        # Advance workflow
POST   /api/v1/clinic/intakes/{id}/send-forms/     # Send forms to parent
GET    /api/v1/clinic/intakes/{id}/documents/      # List documents
POST   /api/v1/clinic/intakes/{id}/documents/      # Upload document
GET    /api/v1/clinic/intakes/{id}/timeline/       # Get timeline
```

**Domain Services**:
- `IntakeWorkflowService` - State machine for intake status transitions
- `FormDistributionService` - Send forms to parents via email/portal
- `IntakeProgressCalculator` - Calculate completion percentage
- `DuplicatePatientDetector` - Check for existing patients

---

#### 1.2 Assessment
**Submodules**: VB-MAPP, ABLLS-R, FBA, Psychological Evaluations

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Assessment` | id, patient_id, intake_id, type, status, assessor_id, scheduled_date | Assessment record |
| `AssessmentData` | id, assessment_id, domain, scores, raw_data | Assessment scores by domain |
| `AssessmentDocument` | id, assessment_id, document_type, file_url | Assessment reports |
| `AssessmentRecommendation` | id, assessment_id, recommended_hours, duration, rationale | Treatment recommendations |

**API Endpoints**:
```
POST   /api/v1/clinic/assessments/                 # Create assessment
GET    /api/v1/clinic/assessments/                 # List assessments
GET    /api/v1/clinic/assessments/{id}/            # Get assessment details
PATCH  /api/v1/clinic/assessments/{id}/            # Update assessment
POST   /api/v1/clinic/assessments/{id}/complete/   # Mark complete
GET    /api/v1/clinic/assessments/{id}/report/     # Generate report
```

**Domain Services**:
- `AssessmentScoringService` - Calculate domain scores
- `AssessmentReportGenerator` - Generate PDF reports

---

#### 1.3 Authorization (Insurance)
**Submodules**: Initial Auth, Re-authorization, Unit Tracking, Expiration Alerts

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Authorization` | id, patient_id, payer_name, auth_number, start_date, end_date, status, type | Insurance authorization |
| `AuthorizedService` | id, authorization_id, cpt_code, units_approved, units_used | Service-level units |
| `AuthorizationDocument` | id, authorization_id, document_type, file_url | Supporting documents |
| `AuthorizationAudit` | id, authorization_id, action, performed_by, timestamp | Audit trail |

**API Endpoints**:
```
POST   /api/v1/clinic/authorizations/              # Create authorization
GET    /api/v1/clinic/authorizations/              # List authorizations
GET    /api/v1/clinic/authorizations/{id}/         # Get authorization details
PATCH  /api/v1/clinic/authorizations/{id}/         # Update authorization
POST   /api/v1/clinic/authorizations/{id}/submit/  # Submit to payer
GET    /api/v1/clinic/authorizations/expiring/     # Get expiring soon
GET    /api/v1/clinic/authorizations/{id}/units/   # Get unit usage
```

**Domain Services**:
- `AuthorizationWorkflowService` - Status transitions (pending → internal_audit → submitted → approved/denied)
- `UnitTrackingService` - Track units used vs approved
- `ExpirationAlertService` - Notify before expiration

---

#### 1.4 Sessions
**Submodules**: Session Management, Data Collection, EVV (Electronic Visit Verification), Notes

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Session` | id, patient_id, therapist_id, appointment_id, session_type, status, session_date | Therapy session |
| `SessionEVV` | id, session_id, check_in_time, check_in_location, check_out_time, check_out_location | EVV compliance |
| `Program` | id, patient_id, name, program_type, domain, mastery_criteria, status | Treatment program |
| `Target` | id, program_id, name, sd, target_response, status, data_collection_type | Program target |
| `TrialData` | id, session_id, target_id, trial_number, response, prompt_level | DTT trial data |
| `BehaviorData` | id, session_id, behavior_name, antecedent, behavior, consequence, function | ABC data |
| `SessionNote` | id, session_id, content, ai_generated, approved_by | Session notes |

**API Endpoints**:
```
POST   /api/v1/clinic/sessions/                    # Create session
GET    /api/v1/clinic/sessions/                    # List sessions
GET    /api/v1/clinic/sessions/{id}/               # Get session details
PATCH  /api/v1/clinic/sessions/{id}/               # Update session
POST   /api/v1/clinic/sessions/{id}/check-in/      # EVV check-in
POST   /api/v1/clinic/sessions/{id}/check-out/     # EVV check-out
GET    /api/v1/clinic/sessions/{id}/trials/        # Get trial data
POST   /api/v1/clinic/sessions/{id}/trials/        # Record trial
GET    /api/v1/clinic/sessions/{id}/behaviors/     # Get behavior data
POST   /api/v1/clinic/sessions/{id}/behaviors/     # Record behavior
POST   /api/v1/clinic/sessions/{id}/generate-note/ # AI generate note
GET    /api/v1/clinic/sessions/{id}/report/        # Get session report

GET    /api/v1/clinic/programs/                    # List programs
POST   /api/v1/clinic/programs/                    # Create program
GET    /api/v1/clinic/programs/{id}/targets/       # Get targets
POST   /api/v1/clinic/programs/{id}/targets/       # Add target
```

**Domain Services**:
- `SessionExecutionService` - Manage session lifecycle
- `EVVComplianceService` - Validate EVV requirements
- `DataCollectionService` - Record and aggregate trial/behavior data
- `MasteryEvaluationService` - Evaluate target mastery criteria
- `SessionNoteGenerator` - AI-powered note generation

---

#### 1.5 Scheduling
**Submodules**: Appointments, Availability, Recurrence, Conflicts

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Appointment` | id, patient_id, therapist_id, start_time, end_time, status, type, recurrence_pattern | Appointment |
| `TherapistAvailability` | id, therapist_id, day_of_week, start_time, end_time, effective_from | Weekly availability |
| `TherapistTimeOff` | id, therapist_id, start_date, end_date, reason, status | Time off requests |
| `AppointmentRecurrence` | id, appointment_id, frequency, interval, days_of_week, end_date | Recurrence rules |

**API Endpoints**:
```
POST   /api/v1/clinic/appointments/                # Create appointment
GET    /api/v1/clinic/appointments/                # List appointments
GET    /api/v1/clinic/appointments/{id}/           # Get appointment details
PATCH  /api/v1/clinic/appointments/{id}/           # Update appointment
DELETE /api/v1/clinic/appointments/{id}/           # Cancel appointment
POST   /api/v1/clinic/appointments/check-conflicts/ # Check conflicts
GET    /api/v1/clinic/appointments/available-slots/ # Get available slots

GET    /api/v1/clinic/therapist-availability/      # Get availability
POST   /api/v1/clinic/therapist-availability/      # Set availability
GET    /api/v1/clinic/therapist-time-off/          # Get time off
POST   /api/v1/clinic/therapist-time-off/          # Request time off
```

**Domain Services**:
- `AppointmentSchedulingService` - Create/update appointments with conflict detection
- `AvailabilityService` - Calculate available time slots
- `RecurrenceService` - Expand recurring appointments (RFC 5545)
- `ConflictDetectionService` - Detect scheduling conflicts

---

#### 1.6 Tools
**Submodules**: Notes, Tasks, Documents

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Task` | id, title, description, assigned_to, patient_id, due_date, priority, status | Staff tasks |
| `Document` | id, name, file_url, document_type, patient_id, uploaded_by | General documents |
| `Note` | id, content, author_id, note_type, created_at | **Ad-hoc notes** for BCBAs/RBTs (general reminders, ideas, meeting notes - NOT clinical session notes) |
| `GoalTemplate` | id, name, domain, description, mastery_criteria, organization_id | Reusable goal templates |

> **Note**: Clinical session notes (`SessionNote`) are part of the **Sessions** module, not Tools. The Notes here are for general staff note-taking.

**API Endpoints**:
```
GET    /api/v1/clinic/tasks/                       # List tasks
POST   /api/v1/clinic/tasks/                       # Create task
PATCH  /api/v1/clinic/tasks/{id}/                  # Update task
POST   /api/v1/clinic/tasks/{id}/complete/         # Complete task

GET    /api/v1/clinic/documents/                   # List documents
POST   /api/v1/clinic/documents/                   # Upload document
DELETE /api/v1/clinic/documents/{id}/              # Delete document

GET    /api/v1/clinic/goal-templates/              # List templates
POST   /api/v1/clinic/goal-templates/              # Create template
```

---

## Domain 2: Billing RCM

**Purpose**: Revenue cycle management for insurance claims and payments.

### Modules

#### 2.1 Claims
**Submodules**: Claim Generation, Submission, Status Tracking, Denial Management

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Claim` | id, patient_id, authorization_id, payer_id, status, total_amount, submitted_date | Insurance claim |
| `ClaimLine` | id, claim_id, session_id, cpt_code, units, amount, status | Claim line item |
| `ClaimRemittance` | id, claim_id, payment_amount, adjustment_codes, paid_date | EOB/ERA data |
| `ClaimDenial` | id, claim_id, denial_reason, denial_code, appeal_status | Denial tracking |

**API Endpoints**:
```
POST   /api/v1/billing/claims/                     # Create claim
GET    /api/v1/billing/claims/                     # List claims
GET    /api/v1/billing/claims/{id}/                # Get claim details
POST   /api/v1/billing/claims/{id}/submit/         # Submit claim
POST   /api/v1/billing/claims/{id}/appeal/         # Appeal denial
GET    /api/v1/billing/claims/pending/             # Get pending claims
```

---

#### 2.2 Accounts Receivable
**Submodules**: Aging Reports, Payment Posting, Collections

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Invoice` | id, patient_id, payer_id, amount, balance, due_date, status | Invoice |
| `Payment` | id, invoice_id, amount, payment_method, payment_date, reference | Payment record |
| `ARAgingBucket` | id, organization_id, bucket_range, total_amount, claim_count | Aging summary |

**API Endpoints**:
```
GET    /api/v1/billing/invoices/                   # List invoices
POST   /api/v1/billing/payments/                   # Record payment
GET    /api/v1/billing/ar-aging/                   # Get aging report
GET    /api/v1/billing/ar-summary/                 # Get AR summary
```

---

#### 2.3 Insurance
**Submodules**: Payer Management, Eligibility Verification, Fee Schedules

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Payer` | id, name, payer_id, address, phone, submission_method | Insurance company |
| `FeeSchedule` | id, payer_id, cpt_code, rate, effective_date | Contracted rates |
| `EligibilityCheck` | id, patient_id, payer_id, check_date, status, response | 270/271 eligibility |

**API Endpoints**:
```
GET    /api/v1/billing/payers/                     # List payers
POST   /api/v1/billing/payers/                     # Add payer
GET    /api/v1/billing/fee-schedules/              # Get fee schedules
POST   /api/v1/billing/eligibility/check/          # Check eligibility
```

---

## Domain 3: Parent Portal

**Purpose**: Parent/guardian-facing features for engagement and transparency.

### Modules

#### 3.1 Intake Forms
**Submodules**: Form Access, Form Submission, E-Signatures

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `ParentUser` | id, email, phone, patient_ids, verified | Parent account |
| `ParentFormSubmission` | id, parent_id, intake_id, form_type, data, signature, submitted_at | Form submission |
| `ParentOTP` | id, parent_id, code, expires_at, verified | OTP for verification |

**API Endpoints**:
```
POST   /api/v1/parent/auth/request-otp/            # Request OTP
POST   /api/v1/parent/auth/verify-otp/             # Verify OTP
GET    /api/v1/parent/forms/                       # Get pending forms
POST   /api/v1/parent/forms/{id}/submit/           # Submit form
GET    /api/v1/parent/patients/                    # Get linked patients
```

---

#### 3.2 Patient Profile & Progress
**Submodules**: Progress Dashboards, Goal Tracking, Session Summaries

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `ProgressSnapshot` | id, patient_id, snapshot_date, programs_summary, behaviors_summary | Progress summary |
| `ParentNotification` | id, parent_id, type, message, read, created_at | Parent notifications |

**API Endpoints**:
```
GET    /api/v1/parent/patients/{id}/progress/      # Get progress summary
GET    /api/v1/parent/patients/{id}/sessions/      # Get session summaries
GET    /api/v1/parent/notifications/               # Get notifications
```

---

#### 3.3 Community Resources
**Submodules**: Resource Library, Support Groups, FAQs

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Resource` | id, title, description, category, file_url, organization_id | Resource item |
| `ResourceCategory` | id, name, description | Resource category |

**API Endpoints**:
```
GET    /api/v1/parent/resources/                   # List resources
GET    /api/v1/parent/resources/categories/        # List categories
```

---

## Domain 4: HRMS

**Purpose**: Human resource management for clinical staff.

### Modules

#### 4.1 Leaves
**Submodules**: Leave Requests, Approvals, Balance Tracking

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `LeaveRequest` | id, user_id, leave_type, start_date, end_date, status, approved_by | Leave request |
| `LeaveBalance` | id, user_id, leave_type, year, total, used, remaining | Leave balance |
| `LeavePolicy` | id, organization_id, leave_type, days_per_year, carry_over | Leave policy |

**API Endpoints**:
```
POST   /api/v1/hrms/leaves/                        # Request leave
GET    /api/v1/hrms/leaves/                        # List leave requests
PATCH  /api/v1/hrms/leaves/{id}/approve/           # Approve leave
GET    /api/v1/hrms/leaves/balance/                # Get leave balance
```

---

#### 4.2 Benefits
**Submodules**: Benefits Enrollment, Benefits Info

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Benefit` | id, organization_id, name, type, description, provider | Benefit offering |
| `BenefitEnrollment` | id, user_id, benefit_id, start_date, status | Enrollment record |

**API Endpoints**:
```
GET    /api/v1/hrms/benefits/                      # List benefits
POST   /api/v1/hrms/benefits/enroll/               # Enroll in benefit
GET    /api/v1/hrms/benefits/my-enrollments/       # Get my enrollments
```

---

#### 4.3 Recognition
**Submodules**: Awards, Kudos, Milestones

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Recognition` | id, recipient_id, giver_id, type, message, points, created_at | Recognition |
| `RecognitionPoints` | id, user_id, total_points, redeemed_points | Points balance |

**API Endpoints**:
```
POST   /api/v1/hrms/recognition/                   # Give recognition
GET    /api/v1/hrms/recognition/received/          # Get received
GET    /api/v1/hrms/recognition/leaderboard/       # Get leaderboard
```

---

## Domain 5: LMS

**Purpose**: Learning management for staff training and certifications.

### Modules

#### 5.1 Training
**Submodules**: Courses, Modules, Quizzes, Progress Tracking

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Course` | id, title, description, category, required_for_roles, duration | Training course |
| `CourseModule` | id, course_id, title, content_type, content_url, order | Course module |
| `CourseEnrollment` | id, user_id, course_id, status, progress, started_at, completed_at | Enrollment |
| `Quiz` | id, module_id, questions, passing_score | Quiz |
| `QuizAttempt` | id, quiz_id, user_id, score, passed, completed_at | Quiz attempt |

**API Endpoints**:
```
GET    /api/v1/lms/courses/                        # List courses
GET    /api/v1/lms/courses/{id}/                   # Get course details
POST   /api/v1/lms/courses/{id}/enroll/            # Enroll in course
GET    /api/v1/lms/my-courses/                     # Get my enrollments
POST   /api/v1/lms/modules/{id}/complete/          # Mark module complete
POST   /api/v1/lms/quizzes/{id}/submit/            # Submit quiz
```

---

#### 5.2 Certifications
**Submodules**: Certification Tracking, Expiration Alerts, Verification

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Certification` | id, name, issuing_body, validity_period, required_for_roles | Certification type |
| `UserCertification` | id, user_id, certification_id, issue_date, expiry_date, document_url, status | User cert |
| `CertificationReminder` | id, user_certification_id, reminder_date, sent | Expiration reminder |

**API Endpoints**:
```
GET    /api/v1/lms/certifications/                 # List certification types
POST   /api/v1/lms/certifications/upload/          # Upload certification
GET    /api/v1/lms/my-certifications/              # Get my certifications
GET    /api/v1/lms/certifications/expiring/        # Get expiring certs
```

---

## Domain 6: Auth (Authorization & Authentication)

**Purpose**: Security, identity, and access management across all domains.

### Modules

#### 6.1 RBAC
**Submodules**: Roles, Permissions, Access Control

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Role` | id, name, description, permissions, organization_id | Role definition |
| `Permission` | id, name, resource, action, description | Permission |
| `UserRole` | id, user_id, role_id, organization_id, branch_id | User-role assignment |

**API Endpoints**:
```
GET    /api/v1/auth/roles/                         # List roles
POST   /api/v1/auth/roles/                         # Create role
GET    /api/v1/auth/permissions/                   # List permissions
POST   /api/v1/auth/users/{id}/roles/              # Assign role
GET    /api/v1/auth/me/permissions/                # Get my permissions
```

---

#### 6.2 Roles
**Submodules**: Role Templates, Role Hierarchy

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `RoleTemplate` | id, name, permissions, is_system | System role templates |
| `RoleHierarchy` | id, parent_role_id, child_role_id | Role inheritance |

---

#### 6.3 SSO
**Submodules**: OAuth, SAML, Social Login

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `SSOProvider` | id, organization_id, provider_type, config, enabled | SSO configuration |
| `SSOSession` | id, user_id, provider_id, external_id, created_at | SSO session |

**API Endpoints**:
```
GET    /api/v1/auth/sso/providers/                 # List SSO providers
POST   /api/v1/auth/sso/configure/                 # Configure SSO
GET    /api/v1/auth/sso/{provider}/login/          # Initiate SSO login
POST   /api/v1/auth/sso/{provider}/callback/       # SSO callback
```

---

## Domain 7: AI & Insights

**Purpose**: AI-powered features and business intelligence.

### Modules

#### 7.1 Chatbot
**Submodules**: Conversational AI, Context Management, Intent Recognition

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `ChatSession` | id, user_id, context, started_at, ended_at | Chat session |
| `ChatMessage` | id, session_id, role, content, timestamp | Chat message |
| `ChatContext` | id, session_id, patient_id, context_type, data | Context for AI |

**API Endpoints**:
```
POST   /api/v1/ai/chat/                            # Send chat message
GET    /api/v1/ai/chat/history/                    # Get chat history
POST   /api/v1/ai/chat/context/                    # Set context
```

---

#### 7.2 AI-Reporting
**Submodules**: Report Generation, Trend Analysis, Predictions

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `AIReport` | id, report_type, parameters, generated_at, content | Generated report |
| `AIInsight` | id, insight_type, patient_id, insight, confidence, created_at | AI insight |
| `AnalyticsDashboard` | id, organization_id, name, widgets, config | Custom dashboard |

**API Endpoints**:
```
POST   /api/v1/ai/generate-note/                   # Generate session note
POST   /api/v1/ai/analyze-progress/                # Analyze patient progress
GET    /api/v1/ai/insights/                        # Get AI insights
POST   /api/v1/ai/reports/generate/                # Generate report
GET    /api/v1/analytics/dashboard/                # Get dashboard data
GET    /api/v1/analytics/metrics/                  # Get metrics
```

---

## Domain 8: Communication

**Purpose**: Multi-channel communication with patients, parents, and staff.

### Modules

#### 8.1 Calls
**Submodules**: VoIP Integration, Call Logs, Voicemail

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Call` | id, caller_id, callee_id, patient_id, direction, duration, status, recording_url | Call record |
| `Voicemail` | id, call_id, transcription, audio_url, listened | Voicemail |

**API Endpoints**:
```
POST   /api/v1/communication/calls/initiate/       # Initiate call
GET    /api/v1/communication/calls/                # Get call logs
GET    /api/v1/communication/voicemails/           # Get voicemails
```

---

#### 8.2 Text/SMS
**Submodules**: SMS Sending, Templates, Opt-in/Opt-out

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `SMSMessage` | id, sender_id, recipient_phone, patient_id, content, status, sent_at | SMS message |
| `SMSTemplate` | id, name, content, organization_id | SMS template |
| `SMSConsent` | id, phone, patient_id, consented, consent_date | SMS consent |

**API Endpoints**:
```
POST   /api/v1/communication/sms/send/             # Send SMS
GET    /api/v1/communication/sms/                  # Get SMS history
GET    /api/v1/communication/sms/templates/        # Get templates
POST   /api/v1/communication/sms/consent/          # Record consent
```

---

#### 8.3 Email
**Submodules**: Transactional Email, Templates, Tracking

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `Email` | id, sender_id, recipient_email, patient_id, subject, body, status, sent_at | Email record |
| `EmailTemplate` | id, name, subject, body, organization_id | Email template |
| `EmailTracking` | id, email_id, event_type, timestamp | Open/click tracking |

**API Endpoints**:
```
POST   /api/v1/communication/email/send/           # Send email
GET    /api/v1/communication/email/                # Get email history
GET    /api/v1/communication/email/templates/      # Get templates
```

---

#### 8.4 Chat
**Submodules**: In-App Messaging, Group Chat, Notifications

| Entity | Key Fields | Description |
|--------|------------|-------------|
| `ChatRoom` | id, name, type, participants, patient_id, created_at | Chat room |
| `ChatRoomMessage` | id, room_id, sender_id, content, sent_at, read_by | Chat message |
| `ChatNotification` | id, user_id, room_id, message_id, read | Chat notification |

**API Endpoints**:
```
POST   /api/v1/communication/chat/rooms/           # Create chat room
GET    /api/v1/communication/chat/rooms/           # Get chat rooms
GET    /api/v1/communication/chat/rooms/{id}/messages/ # Get messages
POST   /api/v1/communication/chat/rooms/{id}/messages/ # Send message
```

---

## Current Code File Mapping

### Backend Files → Domains

| Current File | Domain | Module | Notes |
|--------------|--------|--------|-------|
| `backend/clinic/models.py` | Clinic | All | Contains Patient, Intake, Session, Appointment, Assessment, Authorization, Program, Target, Task models |
| `backend/clinic/views.py` | Clinic | All | 4,489 LOC - needs splitting by module |
| `backend/clinic/serializers.py` | Clinic | All | Needs splitting by module |
| `backend/clinic/services/recurrence_service.py` | Clinic | Scheduling | Good - already a domain service |
| `backend/core/models.py` | Auth | RBAC | Organization, User, Role, Permission, Branch |
| `backend/core/views.py` | Auth | RBAC | User management, invitations |
| `backend/core/parent_views.py` | Parent Portal | Intake Forms | Parent authentication and forms |
| `backend/core/parent_serializers.py` | Parent Portal | Intake Forms | Parent data serialization |
| `backend/core/permissions.py` | Auth | RBAC | Permission classes |
| `backend/core/authentication.py` | Auth | SSO | JWT authentication |
| `backend/core/email_service.py` | Communication | Email | Email sending |

### Frontend Files → Domains

| Current File | Domain | Module | Notes |
|--------------|--------|--------|-------|
| `lib/screens/patients_screen.dart` | Clinic | Intake | Patient list |
| `lib/screens/intake_screen.dart` | Clinic | Intake | Intake list |
| `lib/screens/intake_workspace_screen.dart` | Clinic | Intake | Intake details |
| `lib/screens/new_patient_intake_screen.dart` | Clinic | Intake | New patient form |
| `lib/screens/assessments_screen.dart` | Clinic | Assessment | Assessment list |
| `lib/screens/assessment_detail_screen.dart` | Clinic | Assessment | Assessment details |
| `lib/screens/authorization_detail_screen.dart` | Clinic | Authorization | Auth details |
| `lib/screens/session_workspace_screen.dart` | Clinic | Sessions | Session execution |
| `lib/screens/data_collection_screen.dart` | Clinic | Sessions | Data collection |
| `lib/screens/bcba_programming_screen.dart` | Clinic | Sessions | Program management |
| `lib/screens/scheduling_screen.dart` | Clinic | Scheduling | Calendar view |
| `lib/screens/scheduling/create_appointment_modal.dart` | Clinic | Scheduling | Create appointment |
| `lib/screens/scheduling/scheduling_assistant.dart` | Clinic | Scheduling | Availability assistant |
| `lib/screens/tasks_screen.dart` | Clinic | Tools | Task management |
| `lib/screens/billing_screen.dart` | Billing RCM | All | Billing dashboard |
| `lib/screens/parent_portal_screen.dart` | Parent Portal | All | Parent portal |
| `lib/screens/parent_login_screen.dart` | Parent Portal | Intake Forms | Parent login |
| `lib/screens/parent_intake_screen.dart` | Parent Portal | Intake Forms | Parent intake view |
| `lib/screens/parent_form_screen.dart` | Parent Portal | Intake Forms | Form submission |
| `lib/screens/parent_my_patient_screen.dart` | Parent Portal | Progress | Patient profile |
| `lib/screens/hrms_screen.dart` | HRMS | All | HR dashboard |
| `lib/screens/lms_screen.dart` | LMS | All | LMS dashboard |
| `lib/screens/communication_screen.dart` | Communication | All | Communication hub |
| `lib/screens/login_screen.dart` | Auth | SSO | Login |
| `lib/screens/accept_invitation_screen.dart` | Auth | RBAC | User invitation |
| `lib/screens/admin/admin_users_screen.dart` | Auth | RBAC | User management |
| `lib/screens/reports_screen.dart` | AI & Insights | AI-Reporting | Reports |
| `lib/screens/dashboard_screen.dart` | AI & Insights | AI-Reporting | Analytics dashboard |
| `lib/widgets/ai_chat_panel.dart` | AI & Insights | Chatbot | AI chat widget |
| `lib/services/api/patient_api_service.dart` | Clinic | Intake | Patient API |
| `lib/services/api/intake_api_service.dart` | Clinic | Intake | Intake API |
| `lib/services/api/assessment_api_service.dart` | Clinic | Assessment | Assessment API |
| `lib/services/api/authorization_api_service.dart` | Clinic | Authorization | Auth API |
| `lib/services/api/session_api_service.dart` | Clinic | Sessions | Session API |
| `lib/services/api/appointment_api_service.dart` | Clinic | Scheduling | Appointment API |
| `lib/services/api/task_api_service.dart` | Clinic | Tools | Task API |
| `lib/services/api/user_api_service.dart` | Auth | RBAC | User API |
| `lib/services/api/organization_api_service.dart` | Auth | RBAC | Org API |
| `lib/services/api/parent_api_service.dart` | Parent Portal | All | Parent API |
| `lib/services/auth/auth_service.dart` | Auth | SSO | Auth service |
| `lib/services/auth/parent_auth_service.dart` | Parent Portal | Intake Forms | Parent auth |
| `lib/state/patients_store.dart` | Clinic | Intake | Patient state |
| `lib/state/sessions_store.dart` | Clinic | Sessions | Session state |
| `lib/state/user_store.dart` | Auth | RBAC | User state |

---

## Folder Structure Decision

### Keep Current Root Structure
The current root structure should be **preserved**:
```
wabi-clinic-flutter/
├── lib/              # Flutter frontend (required by Flutter)
├── backend/          # Django backend
├── docs/
├── pubspec.yaml
└── ...
```

**Rationale**:
- Flutter requires `lib/` at the project root - moving to `frontend/` would break the project
- Current structure is already clean with clear separation
- Reorganization happens **within** `lib/` and `backend/`, not at root level

### No Breaking Changes Policy
- All current functionality and UI must remain unchanged
- Migration is incremental - files are reorganized without changing behavior
- API endpoints remain backwards compatible
- Existing imports are updated via barrel files (re-exports)

### Branch Strategy
- Create new branch: `feature/domain-architecture-refactor`
- All refactoring work happens on this branch
- Easy rollback by switching back to `main` or `wabi-flutter-dev`
- Merge only after full testing confirms no regressions

---

## Proposed Directory Structure (Internal Reorganization)

### Backend (Django)

```
backend/
├── clinic/                        # Domain: Clinic
│   ├── intake/
│   │   ├── models.py              # Patient, Intake, IntakeDocument, etc.
│   │   ├── views.py               # IntakeViewSet, PatientViewSet
│   │   ├── serializers.py
│   │   ├── services.py            # IntakeWorkflowService
│   │   └── urls.py
│   ├── assessment/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   └── services.py
│   ├── authorization/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   └── services.py
│   ├── sessions/
│   │   ├── models.py              # Session, Program, Target, TrialData
│   │   ├── views.py
│   │   ├── serializers.py
│   │   └── services.py
│   ├── scheduling/
│   │   ├── models.py              # Appointment, Availability
│   │   ├── views.py
│   │   ├── serializers.py
│   │   └── services.py            # RecurrenceService, AvailabilityService
│   └── tools/
│       ├── models.py              # Task, Document, Note
│       ├── views.py
│       └── serializers.py
│
├── billing/                       # Domain: Billing RCM
│   ├── claims/
│   ├── ar/
│   └── insurance/
│
├── parent_portal/                 # Domain: Parent Portal
│   ├── forms/
│   ├── progress/
│   └── resources/
│
├── hrms/                          # Domain: HRMS
│   ├── leaves/
│   ├── benefits/
│   └── recognition/
│
├── lms/                           # Domain: LMS
│   ├── courses/
│   └── certifications/
│
├── auth/                          # Domain: Auth
│   ├── rbac/
│   ├── roles/
│   └── sso/
│
├── ai/                            # Domain: AI & Insights
│   ├── chatbot/
│   └── reporting/
│
├── communication/                 # Domain: Communication
│   ├── calls/
│   ├── sms/
│   ├── email/
│   └── chat/
│
└── shared/                        # Shared Kernel
    ├── models.py                  # Base models, value objects
    ├── events.py                  # Domain events
    ├── utils.py
    └── middleware.py
```

### Frontend (Flutter)

```
lib/
├── features/                      # Feature-based organization
│   ├── clinic/                    # Domain: Clinic
│   │   ├── intake/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   ├── services/
│   │   │   └── state/
│   │   ├── assessment/
│   │   ├── authorization/
│   │   ├── sessions/
│   │   ├── scheduling/
│   │   └── tools/
│   │
│   ├── billing/                   # Domain: Billing RCM
│   │   ├── claims/
│   │   ├── ar/
│   │   └── insurance/
│   │
│   ├── parent_portal/             # Domain: Parent Portal
│   │
│   ├── hrms/                      # Domain: HRMS
│   │
│   ├── lms/                       # Domain: LMS
│   │
│   ├── auth/                      # Domain: Auth
│   │
│   ├── ai/                        # Domain: AI & Insights
│   │
│   └── communication/             # Domain: Communication
│
├── core/                          # Shared infrastructure
│   ├── api/
│   ├── auth/
│   ├── theme/
│   └── widgets/
│
└── main.dart
```

---

## Scalability & Performance Recommendations

### 1. Multi-Tenant Architecture

**Current**: Organization-based filtering in views
**Recommended**:
- Add `organization_id` to all models
- Use Django middleware to set tenant context
- Consider PostgreSQL Row-Level Security for additional isolation

```python
class TenantMiddleware:
    def __call__(self, request):
        request.organization = get_organization_from_token(request)
        return self.get_response(request)

class TenantQuerySet(models.QuerySet):
    def for_organization(self, org_id):
        return self.filter(organization_id=org_id)
```

### 2. Database Optimization

**Indexing Strategy**:
```python
class Meta:
    indexes = [
        models.Index(fields=['organization_id']),
        models.Index(fields=['organization_id', 'status']),
        models.Index(fields=['organization_id', 'created_at']),
        models.Index(fields=['patient_id', 'session_date']),
    ]
```

**Query Optimization**:
- Use `select_related()` for ForeignKey
- Use `prefetch_related()` for reverse ForeignKey and M2M
- Add custom QuerySet managers

### 3. Caching Strategy

**Redis Caching**:
```python
# Cache frequently accessed data
@cache_page(60 * 5)  # 5 minutes
def list_patients(request):
    ...

# Cache computed values
CACHE_KEY = f"patient:{patient_id}:progress"
progress = cache.get_or_set(CACHE_KEY, compute_progress, timeout=3600)
```

**Cache Invalidation**:
- Invalidate on model save/delete using signals
- Use cache versioning for bulk invalidation

### 4. Event-Driven Architecture

**Domain Events**:
```python
# Define events
class PatientRegistered(DomainEvent):
    patient_id: UUID
    organization_id: UUID

# Publish events
event_bus.publish(PatientRegistered(patient_id=patient.id, ...))

# Handle events asynchronously (Celery)
@celery_app.task
def handle_patient_registered(event_data):
    # Create intake, send notifications, etc.
```

### 5. API Performance

**Pagination**:
```python
class StandardPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = 'page_size'
    max_page_size = 100
```

**Response Compression**:
- Enable gzip middleware
- Use appropriate serializer fields (avoid N+1 queries)

### 6. Background Processing

**Celery Tasks**:
```python
# Long-running operations
@celery_app.task
def generate_session_report(session_id):
    ...

@celery_app.task
def send_bulk_notifications(patient_ids):
    ...

# Scheduled tasks (Celery Beat)
@celery_app.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    sender.add_periodic_task(3600.0, check_expiring_authorizations.s())
```

---

## Migration Strategy

### Pre-Migration Setup
1. **Create feature branch**: `git checkout -b feature/domain-architecture-refactor`
2. **Verify current state**: Ensure all tests pass and app runs correctly
3. **Document current imports**: Map all import paths for later updates

### Phase 1: Foundation (Weeks 1-2)
**Goal**: Set up infrastructure without changing existing code behavior

1. Create shared kernel folder structure (empty initially)
2. Create barrel files (index.dart / __init__.py) for re-exports
3. Extract Auth domain (already mostly in `core/`)
4. **Verify**: App still works identically

### Phase 2: Backend Clinic Domain Split (Weeks 3-6)
**Goal**: Split large files while maintaining API compatibility

1. Split `clinic/views.py` (4,489 LOC) into module-specific files:
   - `clinic/intake/views.py`
   - `clinic/assessment/views.py`
   - `clinic/authorization/views.py`
   - `clinic/sessions/views.py`
   - `clinic/scheduling/views.py`
   - `clinic/tools/views.py`
2. Keep original `views.py` as barrel file with re-exports (backwards compatible)
3. Create domain services for each module
4. **Verify**: All API endpoints work identically

### Phase 3: Frontend Feature-Based Restructure (Weeks 7-10)
**Goal**: Reorganize screens/services while keeping UI identical

1. Create `lib/features/` folder structure
2. Move screens to feature folders with barrel exports
3. Update imports (automated via IDE refactoring)
4. Keep original paths working via re-exports
5. **Verify**: All screens render identically

### Phase 4: New Domains (Weeks 11-14)
**Goal**: Add structure for future domains (placeholder folders)

1. Create Billing RCM domain structure (placeholder)
2. Create HRMS domain structure (placeholder)
3. Create LMS domain structure (placeholder)
4. Create Communication domain structure (placeholder)
5. **Verify**: No changes to existing functionality

### Phase 5: Performance & Scaling (Weeks 15-16)
**Goal**: Add infrastructure for scale

1. Add caching layer (Redis)
2. Implement background processing (Celery)
3. Add monitoring and observability
4. **Verify**: Performance improvements measurable

### Rollback Plan
At any point, if issues arise:
1. `git checkout wabi-flutter-dev` - Return to stable branch
2. `git branch -D feature/domain-architecture-refactor` - Delete problematic branch
3. Start fresh with lessons learned

---

## Conclusion

This 8-domain architecture provides a clear separation of concerns aligned with ABA practice management workflows. The modular structure enables:

- **Scalability**: Each domain can scale independently
- **Maintainability**: Clear boundaries reduce coupling
- **SaaS Flexibility**: Domains map to subscription tiers
- **Team Organization**: Teams can own specific domains

The migration can be done incrementally while maintaining the working system.
