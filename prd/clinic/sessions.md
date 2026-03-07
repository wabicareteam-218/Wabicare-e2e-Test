# Sessions & Data Collection Module — PRD

> **Priority**: P0 - Core  
> **Status**: 🟡 In Progress  
> **Domain**: Clinic  
> **Last Updated**: January 2026

---

## Overview

The Sessions module is the heart of ABA therapy operations where:
- **BCBAs** design comprehensive treatment programs with goals, targets, and data collection methods
- **RBTs** collect real-time data during therapy sessions with clients
- **AI** assists both roles with smart suggestions, voice commands, and automated documentation

This module draws inspiration from industry leaders like [CentralReach](https://centralreach.com/products/pm-plus-clinical/) and [Motivity](https://www.motivity.net/solutions/aba-data-collection), while adding innovative AI features to reduce friction and improve outcomes.

---

## Key Pain Points Addressed

| Pain Point | Solution |
|------------|----------|
| RBTs struggle to manage children AND record data | Voice commands, one-tap data entry, wearable integration |
| BCBAs spend hours writing session notes | AI-generated session notes from collected data |
| Goal programming is time-consuming | AI suggests goals from assessment data |
| Data entry errors are common | Real-time validation, smart defaults |
| Offline scenarios (home visits) | Offline-first architecture with sync |
| Hard to visualize progress | Real-time graphs and analytics |

---

## User Roles & Workflows

### BCBA Workflow (Programming)

```
Assessment Complete → Patient moves to Sessions Queue → BCBA Programs Goals
                                                              ↓
                                                    Define Skill Acquisition Targets
                                                              ↓
                                                    Define Behavior Reduction Programs
                                                              ↓
                                                    Set Mastery Criteria
                                                              ↓
                                                    Assign to RBTs
```

### RBT Workflow (Data Collection)

```
View Today's Schedule → Start Session → Collect Data → End Session
                              ↓              ↓
                        Check-in (EVV)   Voice Commands
                                         One-Tap Entry
                                         Timer Controls
                                              ↓
                                      AI Generates Notes
                                              ↓
                                      Submit & Sync
```

---

## Feature Categories

### 1. Session Queue & Management

| ID | Feature | Priority | Description |
|----|---------|----------|-------------|
| SQ-01 | Today's Sessions View | P0 | List of scheduled sessions with patient, time, location |
| SQ-02 | Session Status Tracking | P0 | Not Started, In Progress, Completed, Cancelled |
| SQ-03 | Electronic Visit Verification (EVV) | P0 | Geolocation capture at session start/end |
| SQ-04 | Session Timer | P0 | Track session duration with pause/resume |
| SQ-05 | Quick Session Start | P0 | One-tap to begin session from queue |
| SQ-06 | Multi-Patient View | P1 | For group sessions or school settings |
| SQ-07 | Calendar Integration | P1 | Sync with scheduling module |

### 2. BCBA Programming Interface

| ID | Feature | Priority | Description |
|----|---------|----------|-------------|
| BP-01 | Goal Library | P0 | Pre-built goals from VB-MAPP, ABLLS-R, AFLS domains |
| BP-02 | Custom Goal Creation | P0 | Create goals with targets, prompts, criteria |
| BP-03 | AI Goal Suggestions | P0 | **AI suggests goals based on assessment data** |
| BP-04 | Skill Acquisition Programs | P0 | Discrete Trial, Natural Environment Teaching |
| BP-05 | Behavior Reduction Programs | P0 | Functional analysis, intervention plans |
| BP-06 | Prompt Hierarchy Setup | P0 | Define prompts (Full Physical → Independent) |
| BP-07 | Mastery Criteria | P0 | Auto-advance when criteria met (e.g., 80% x 3 sessions) |
| BP-08 | Task Analysis Builder | P1 | Forward/backward chaining with step isolation |
| BP-09 | Program Templates | P1 | Save and reuse program configurations |
| BP-10 | Treatment Plan Generator | P1 | **AI generates treatment plan document** |

### 3. Data Collection Methods

| ID | Method | Priority | Description |
|----|--------|----------|-------------|
| DC-01 | Discrete Trial Training (DTT) | P0 | Trial-by-trial with prompt tracking |
| DC-02 | Frequency Count | P0 | Count occurrences of behavior |
| DC-03 | Duration Recording | P0 | Time how long behavior lasts |
| DC-04 | Interval Recording | P0 | Partial/Whole interval sampling |
| DC-05 | ABC Data Collection | P0 | Antecedent-Behavior-Consequence logging |
| DC-06 | Task Analysis | P0 | Step-by-step chaining data |
| DC-07 | Percent Correct | P0 | Automatic calculation from trials |
| DC-08 | Latency Recording | P1 | Time from SD to response |
| DC-09 | Rate/Fluency | P1 | Responses per minute |
| DC-10 | Momentary Time Sampling | P2 | Sample at random intervals |

### 4. AI-Powered Features (Our Differentiators)

| ID | Feature | Priority | Description |
|----|---------|----------|-------------|
| AI-01 | Voice Commands | P0 | **"Record correct", "Start timer", "Mark tantrum"** |
| AI-02 | AI Session Notes | P0 | **Auto-generate notes from collected data** |
| AI-03 | Smart Goal Suggestions | P0 | **AI recommends goals from assessments** |
| AI-04 | Behavior Pattern Recognition | P1 | **AI identifies triggers and patterns** |
| AI-05 | Predictive Mastery | P1 | **AI predicts when goal will be mastered** |
| AI-06 | Real-time Coaching | P1 | **AI suggests prompts/interventions during session** |
| AI-07 | Parent Summary Generation | P1 | **AI creates parent-friendly progress summaries** |
| AI-08 | Session Planning AI | P2 | **AI suggests optimal session activities** |
| AI-09 | Wearable Integration | P2 | **Meta glasses for hands-free video capture** |
| AI-10 | Speech-to-Text Notes | P1 | **Dictate notes, AI transcribes and structures** |

### 5. Visualization & Reporting

| ID | Feature | Priority | Description |
|----|---------|----------|-------------|
| VR-01 | Real-time Graphs | P0 | Live progress charts during session |
| VR-02 | Trend Lines | P0 | Visual trend analysis |
| VR-03 | Phase Change Lines | P0 | Mark intervention changes |
| VR-04 | Celeration Charts | P1 | Standard celeration charting |
| VR-05 | Multi-Target Comparison | P1 | Compare across goals |
| VR-06 | Export to PDF/Excel | P1 | Generate reports for stakeholders |
| VR-07 | Dashboard Analytics | P1 | Aggregate views for supervisors |

### 6. Mobile & Offline Support

| ID | Feature | Priority | Description |
|----|---------|----------|-------------|
| MO-01 | Responsive Design | P0 | Phone, tablet, laptop optimized |
| MO-02 | Offline Data Collection | P0 | Work without internet, sync later |
| MO-03 | Background Sync | P0 | Auto-sync when connection restored |
| MO-04 | Photo/Video Capture | P1 | Document sessions with media |
| MO-05 | Native App Performance | P1 | Fast, smooth interactions |

---

## User Stories

### BCBA Stories

| ID | Story | Priority |
|----|-------|----------|
| US-BP-01 | As a BCBA, I want to view patients who completed assessment so I can program their goals | P0 |
| US-BP-02 | As a BCBA, I want AI to suggest goals based on VB-MAPP results so I can save time | P0 |
| US-BP-03 | As a BCBA, I want to create skill acquisition programs with custom prompts | P0 |
| US-BP-04 | As a BCBA, I want to set mastery criteria so programs auto-advance | P0 |
| US-BP-05 | As a BCBA, I want to review RBT session data and provide feedback | P0 |
| US-BP-06 | As a BCBA, I want AI to generate treatment plans from my programs | P1 |
| US-BP-07 | As a BCBA, I want to see predictive analytics on client progress | P1 |

### RBT Stories

| ID | Story | Priority |
|----|-------|----------|
| US-RBT-01 | As an RBT, I want to see my daily session schedule | P0 |
| US-RBT-02 | As an RBT, I want to use voice commands to record data hands-free | P0 |
| US-RBT-03 | As an RBT, I want one-tap buttons to record correct/incorrect | P0 |
| US-RBT-04 | As an RBT, I want AI to generate my session notes automatically | P0 |
| US-RBT-05 | As an RBT, I want to work offline during home visits | P0 |
| US-RBT-06 | As an RBT, I want to record behaviors with ABC data | P0 |
| US-RBT-07 | As an RBT, I want to take photos/videos during sessions | P1 |
| US-RBT-08 | As an RBT, I want AI coaching suggestions during difficult moments | P1 |

### Parent Stories

| ID | Story | Priority |
|----|-------|----------|
| US-PA-01 | As a parent, I want to see my child's progress summary | P1 |
| US-PA-02 | As a parent, I want to receive AI-generated weekly updates | P1 |

---

## Data Models

### Session
```
Session {
  id: UUID
  patient_id: FK
  therapist_id: FK (RBT)
  supervisor_id: FK (BCBA)
  scheduled_start: DateTime
  scheduled_end: DateTime
  actual_start: DateTime?
  actual_end: DateTime?
  location: enum (clinic, home, school, telehealth)
  status: enum (scheduled, in_progress, completed, cancelled, no_show)
  evv_check_in: GeoPoint?
  evv_check_out: GeoPoint?
  notes: Text
  ai_generated_notes: Text?
  created_at: DateTime
  updated_at: DateTime
}
```

### Program (BCBA-created)
```
Program {
  id: UUID
  patient_id: FK
  name: String
  type: enum (skill_acquisition, behavior_reduction)
  domain: String (e.g., "Manding", "Social Skills")
  status: enum (active, on_hold, mastered, discontinued)
  mastery_criteria: JSON {
    percent: 80,
    consecutive_sessions: 3
  }
  prompt_hierarchy: String[] (e.g., ["Full Physical", "Partial Physical", "Gestural", "Independent"])
  created_by: FK (BCBA)
  created_at: DateTime
}
```

### Target (within a Program)
```
Target {
  id: UUID
  program_id: FK
  name: String
  description: Text
  sd: String (discriminative stimulus)
  response: String (expected response)
  current_prompt_level: String
  data_collection_type: enum (dtt, frequency, duration, interval, task_analysis)
  status: enum (baseline, teaching, maintenance, mastered)
  baseline_data: JSON
  created_at: DateTime
}
```

### TrialData (for DTT)
```
TrialData {
  id: UUID
  session_id: FK
  target_id: FK
  trial_number: Int
  response: enum (correct, incorrect, no_response)
  prompt_used: String
  timestamp: DateTime
  recorded_by: FK
}
```

### BehaviorData
```
BehaviorData {
  id: UUID
  session_id: FK
  behavior_id: FK
  antecedent: Text
  behavior_description: Text
  consequence: Text
  intensity: enum (low, medium, high)
  duration_seconds: Int?
  timestamp: DateTime
  recorded_by: FK
}
```

---

## API Endpoints

### Sessions
```
GET    /api/v1/sessions                      # List user's sessions
GET    /api/v1/sessions/today                # Today's schedule
GET    /api/v1/sessions/:id                  # Get session details
POST   /api/v1/sessions/:id/start            # Start session (EVV check-in)
POST   /api/v1/sessions/:id/end              # End session (EVV check-out)
PATCH  /api/v1/sessions/:id/notes            # Update notes
```

### Programs (BCBA)
```
GET    /api/v1/patients/:id/programs         # Get patient's programs
POST   /api/v1/patients/:id/programs         # Create program
PATCH  /api/v1/programs/:id                  # Update program
DELETE /api/v1/programs/:id                  # Archive program
POST   /api/v1/programs/:id/targets          # Add target to program
```

### Data Collection (RBT)
```
POST   /api/v1/sessions/:id/trials           # Record trial data
POST   /api/v1/sessions/:id/behaviors        # Record behavior
POST   /api/v1/sessions/:id/frequency        # Record frequency count
POST   /api/v1/sessions/:id/duration         # Record duration
GET    /api/v1/sessions/:id/data             # Get all session data
```

### AI Features
```
POST   /api/v1/ai/suggest-goals              # AI goal suggestions from assessment
POST   /api/v1/ai/generate-notes             # Generate session notes
POST   /api/v1/ai/transcribe                 # Speech-to-text
POST   /api/v1/ai/pattern-analysis           # Behavior pattern analysis
POST   /api/v1/ai/parent-summary             # Generate parent summary
```

### Analytics
```
GET    /api/v1/analytics/patient/:id/progress    # Patient progress data
GET    /api/v1/analytics/target/:id/graph        # Target graph data
GET    /api/v1/analytics/therapist/:id/stats     # Therapist productivity
```

---

## Voice Commands (AI-01)

### Supported Commands

| Command | Action |
|---------|--------|
| "Start session" | Begin session timer, EVV check-in |
| "End session" | Stop timer, prompt for notes |
| "Record correct" / "Correct" | Log correct trial response |
| "Record incorrect" / "Incorrect" | Log incorrect trial response |
| "No response" | Log no response trial |
| "Start timer" | Begin duration recording |
| "Stop timer" | End duration recording |
| "Mark [behavior name]" | Record behavior occurrence |
| "Add note [text]" | Add voice note to session |
| "Next target" | Move to next target |
| "Show graph" | Display progress graph |
| "Prompt level [level]" | Set current prompt level |

---

## UI Screens

### 1. Sessions Queue (RBT Home)
- Today's sessions with patient cards
- Status indicators (upcoming, in progress, completed)
- Quick-start button for each session
- Filter by status, time

### 2. Session Workspace (RBT Data Collection)
- **Header**: Patient name, timer, session info
- **Left Panel**: Target list with progress indicators
- **Main Area**: Data collection interface
  - Large +/- buttons for trial data
  - Prompt level selector
  - Timer controls for duration
  - Frequency counter
- **Right Panel**: Real-time graph
- **Bottom Bar**: Voice command indicator, notes, end session

### 3. BCBA Programming Dashboard
- Patients awaiting programming
- Program builder wizard
- Goal library browser
- AI suggestions panel
- Treatment plan generator

### 4. Progress Analytics
- Multi-target graphs
- Trend analysis
- Phase change annotations
- Export options

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Data collection time per trial | < 2 seconds |
| Session note generation time | < 5 seconds (AI) |
| Offline sync reliability | 99.9% |
| Voice command accuracy | > 95% |
| RBT satisfaction score | > 4.5/5 |
| Data entry error rate | < 1% |

---

## Competitive Differentiation

| Feature | CentralReach | Motivity | Wabi Clinic |
|---------|--------------|----------|-------------|
| Real-time data sync | ✅ | ✅ | ✅ |
| Voice commands | ❌ | ❌ | ✅ **Unique** |
| AI session notes | ❌ | ❌ | ✅ **Unique** |
| AI goal suggestions | ❌ | ❌ | ✅ **Unique** |
| Wearable integration | ❌ | ❌ | ✅ **Unique** |
| Real-time coaching | ❌ | ❌ | ✅ **Unique** |
| Offline support | ✅ | ✅ | ✅ |
| Mobile apps | ✅ | ✅ | ✅ |
| Task analysis | ✅ | ✅ | ✅ |
| ABC data | ✅ | ✅ | ✅ |

---

## Implementation Phases

### Phase 1: Core Data Collection (MVP)
- Session queue and management
- Basic trial-by-trial data collection
- Frequency and duration recording
- Manual session notes
- Basic graphs

### Phase 2: BCBA Programming
- Goal library and creation
- Mastery criteria
- Program assignment
- Supervision dashboard

### Phase 3: AI Features
- Voice commands
- AI-generated session notes
- AI goal suggestions
- Pattern recognition

### Phase 4: Advanced Features
- Wearable integration
- Real-time coaching
- Predictive analytics
- Parent portal integration

---

## Dependencies

- Patient assessment completion (from Intake/Assessment modules)
- Scheduling module for session creation
- Auth module for role-based access
- AI/ML backend services (Azure OpenAI)
- Speech recognition API (Web Speech API / Azure Speech)

---

## Tasks Reference

See [../../tasks/sessions.md](../../tasks/sessions.md) for detailed implementation tasks.
