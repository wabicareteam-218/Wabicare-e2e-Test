# Sessions & Data Collection — Implementation Tasks

> **Module**: Sessions  
> **PRD**: [sessions.md](../prd/clinic/sessions.md)  
> **Last Updated**: January 2026

---

## Task Overview

| Phase | Tasks | Status |
|-------|-------|--------|
| Phase 1: Core Data Collection | 15 | ⚪ Not Started |
| Phase 2: BCBA Programming | 12 | ⚪ Not Started |
| Phase 3: AI Features | 10 | ⚪ Not Started |
| Phase 4: Advanced Features | 8 | ⚪ Not Started |

---

## Phase 1: Core Data Collection (MVP)

### Backend Tasks

| ID | Task | Priority | Status | Notes |
|----|------|----------|--------|-------|
| BE-S01 | Create Session model and migrations | P0 | ⚪ | session_id, patient_id, therapist_id, times, status, EVV |
| BE-S02 | Create Program model | P0 | ⚪ | Skill acquisition & behavior reduction |
| BE-S03 | Create Target model | P0 | ⚪ | Linked to programs with mastery criteria |
| BE-S04 | Create TrialData model | P0 | ⚪ | Trial-by-trial data storage |
| BE-S05 | Create BehaviorData model | P0 | ⚪ | ABC data, frequency, duration |
| BE-S06 | Sessions API endpoints | P0 | ⚪ | CRUD + start/end with EVV |
| BE-S07 | Data collection endpoints | P0 | ⚪ | POST trials, behaviors, frequency |
| BE-S08 | Basic analytics endpoints | P0 | ⚪ | Graph data for targets |

### Frontend Tasks

| ID | Task | Priority | Status | Notes |
|----|------|----------|--------|-------|
| FE-S01 | Sessions Queue Screen | P0 | ⚪ | Today's sessions list with status badges |
| FE-S02 | Session Workspace - Header | P0 | ⚪ | Patient info, timer, controls |
| FE-S03 | Session Workspace - Target List | P0 | ⚪ | Left panel with programs/targets |
| FE-S04 | DTT Data Collection UI | P0 | ⚪ | Large +/- buttons, prompt selector |
| FE-S05 | Frequency Counter UI | P0 | ⚪ | Tap counter with undo |
| FE-S06 | Duration Timer UI | P0 | ⚪ | Start/stop/lap timer |
| FE-S07 | Session Notes Panel | P0 | ⚪ | Text input with auto-save |
| FE-S08 | Real-time Progress Graph | P0 | ⚪ | Line chart for current target |
| FE-S09 | EVV Check-in/out | P0 | ⚪ | Geolocation capture |
| FE-S10 | Offline Data Storage | P0 | ⚪ | Local storage with sync queue |

### Integration Tasks

| ID | Task | Priority | Status | Notes |
|----|------|----------|--------|-------|
| IN-S01 | Connect sessions to scheduling | P0 | ⚪ | Scheduled appointments → session queue |
| IN-S02 | Patient data from intake | P0 | ⚪ | Assessment data for programming |
| IN-S03 | Real-time sync architecture | P0 | ⚪ | WebSocket or polling for live updates |

---

## Phase 2: BCBA Programming Interface

### Backend Tasks

| ID | Task | Priority | Status | Notes |
|----|------|----------|--------|-------|
| BE-P01 | Goal Library seed data | P0 | ⚪ | VB-MAPP, ABLLS-R, AFLS domains |
| BE-P02 | Program template system | P1 | ⚪ | Save/load program configurations |
| BE-P03 | Mastery criteria automation | P0 | ⚪ | Auto-advance programs when criteria met |
| BE-P04 | Supervision assignment | P0 | ⚪ | BCBA oversight of RBT sessions |

### Frontend Tasks

| ID | Task | Priority | Status | Notes |
|----|------|----------|--------|-------|
| FE-P01 | BCBA Programming Dashboard | P0 | ⚪ | Patients awaiting programming |
| FE-P02 | Goal Library Browser | P0 | ⚪ | Search, filter, select goals |
| FE-P03 | Program Builder Wizard | P0 | ⚪ | Step-by-step program creation |
| FE-P04 | Target Configuration UI | P0 | ⚪ | SD, response, prompt hierarchy |
| FE-P05 | Mastery Criteria Setup | P0 | ⚪ | Configure % correct, sessions |
| FE-P06 | Task Analysis Builder | P1 | ⚪ | Chain steps with isolation options |
| FE-P07 | RBT Assignment UI | P0 | ⚪ | Assign programs to therapists |
| FE-P08 | Supervision Review Dashboard | P0 | ⚪ | Review RBT session data, add notes |

---

## Phase 3: AI Features

### Backend Tasks

| ID | Task | Priority | Status | Notes |
|----|------|----------|--------|-------|
| BE-AI01 | AI Goal Suggestion Service | P0 | ⚪ | Azure OpenAI integration |
| BE-AI02 | AI Session Notes Generator | P0 | ⚪ | Generate notes from data |
| BE-AI03 | Speech-to-Text Service | P0 | ⚪ | Azure Speech or Web Speech API |
| BE-AI04 | Behavior Pattern Analysis | P1 | ⚪ | ML model for trigger identification |
| BE-AI05 | Parent Summary Generator | P1 | ⚪ | Simplified progress summaries |

### Frontend Tasks

| ID | Task | Priority | Status | Notes |
|----|------|----------|--------|-------|
| FE-AI01 | Voice Command System | P0 | ⚪ | Web Speech API integration |
| FE-AI02 | Voice Command UI Feedback | P0 | ⚪ | Visual indicator, command confirmation |
| FE-AI03 | AI Notes Review Panel | P0 | ⚪ | Display, edit, approve AI notes |
| FE-AI04 | AI Goal Suggestions UI | P0 | ⚪ | Review and accept/reject suggestions |
| FE-AI05 | Real-time Coaching Alerts | P1 | ⚪ | Pop-up suggestions during session |

---

## Phase 4: Advanced Features

### Wearable Integration

| ID | Task | Priority | Status | Notes |
|----|------|----------|--------|-------|
| WR-01 | Meta Glasses SDK integration | P2 | ⚪ | Video capture API |
| WR-02 | Hands-free video recording | P2 | ⚪ | Start/stop via voice |
| WR-03 | Video annotation system | P2 | ⚪ | Mark key moments |
| WR-04 | Video storage (Azure Blob) | P2 | ⚪ | Secure HIPAA-compliant storage |

### Predictive Analytics

| ID | Task | Priority | Status | Notes |
|----|------|----------|--------|-------|
| PA-01 | Mastery prediction model | P2 | ⚪ | ML model for progress forecasting |
| PA-02 | Progress dashboard | P2 | ⚪ | Predictive insights display |
| PA-03 | Alert system for stalled progress | P2 | ⚪ | Notify BCBA of concerns |
| PA-04 | Comparative analytics | P2 | ⚪ | Benchmark against norms |

---

## UI Component Breakdown

### Sessions Queue Screen

```
┌─────────────────────────────────────────────────────────────┐
│  Today's Sessions                            [Filter ▼]     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 9:00 AM  │  Emma Thompson  │ Home     │ [Start]     │   │
│  │          │  Session        │          │ Upcoming    │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 10:30 AM │  Lucas Martinez │ Clinic   │ [Resume]    │   │
│  │          │  Assessment     │          │ In Progress │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 1:00 PM  │  Sophia Chen    │ School   │ [View]      │   │
│  │          │  Session        │          │ Completed   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Session Workspace

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Emma Thompson  │  Session  │  ⏱ 00:23:45  │  [Pause] [End Session]    │
├─────────────────┬───────────────────────────────────────────────────────┤
│  PROGRAMS       │                    DATA COLLECTION                    │
│ ─────────────── │  ─────────────────────────────────────────────────── │
│ ▼ Manding       │                                                       │
│   • Request item│    Target: Request item using "I want [item]"        │
│   • Request help│    SD: Present preferred item                         │
│                 │    ─────────────────────────────────────────────────  │
│ ▼ Social Skills │                                                       │
│   • Eye contact │        ┌─────────┐           ┌─────────┐             │
│   • Turn taking │        │    +    │           │    -    │             │
│                 │        │ CORRECT │           │ WRONG   │             │
│ ▼ Behaviors     │        └─────────┘           └─────────┘             │
│   • Tantrum     │                                                       │
│   • Elopement   │    Prompt: [Independent ▼]      Trial: 5/10          │
│                 │                                                       │
│                 │    ─────────────────────────────────────────────────  │
│                 │                    📊 Progress                        │
│                 │    100%│    ╭─────────────────────────╮              │
│                 │     80%│───╱                                          │
│                 │     60%│──╱                                           │
│                 │     40%│─╱                                            │
│                 │     20%│╱                                             │
│                 │      0%└─────────────────────────────                 │
├─────────────────┴───────────────────────────────────────────────────────┤
│  🎤 Voice: Listening...  │  📝 Notes  │  [Generate AI Notes]            │
└─────────────────────────────────────────────────────────────────────────┘
```

### BCBA Programming Dashboard

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Programming Dashboard                              [+ New Program]     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  PATIENTS AWAITING PROGRAMMING                                          │
│  ─────────────────────────────────────────────────────────────────────  │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Emma Thompson │ Assessment: Jan 15 │ [View Assessment] [Program]│    │
│  │ VB-MAPP: Level 2 │ Recommended domains: Manding, Tacting      │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  AI SUGGESTED GOALS                                                     │
│  ─────────────────────────────────────────────────────────────────────  │
│  Based on Emma's VB-MAPP results, we recommend:                        │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ ✨ Manding: Request 10 different items using "I want [item]"    │   │
│  │    [Accept] [Modify] [Reject]                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ ✨ Tacting: Label 20 common objects                              │   │
│  │    [Accept] [Modify] [Reject]                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Voice Commands Implementation

### Technical Approach

1. **Web Speech API** for browser-based recognition
2. **Fallback** to Azure Speech Services for better accuracy
3. **Wake word**: "Hey Wabi" or always-listening mode
4. **Command parsing** with intent recognition
5. **Visual feedback** with command confirmation

### Command Flow

```
User speaks → Web Speech API → Parse Intent → Execute Action → Confirm
     ↓                                              ↓
 "Record correct"                            Log trial data
     ↓                                              ↓
 Visual: "✓ Correct recorded"              Update UI/graph
```

### Supported Commands (P0)

```dart
final voiceCommands = {
  // Trial data
  r'(record )?(correct|right|yes)': () => recordTrial(correct: true),
  r'(record )?(incorrect|wrong|no)': () => recordTrial(correct: false),
  r'no response': () => recordTrial(noResponse: true),
  
  // Timer
  r'start timer': () => startDurationTimer(),
  r'stop timer': () => stopDurationTimer(),
  
  // Behaviors
  r'mark (\w+)': (match) => recordBehavior(match.group(1)),
  
  // Navigation
  r'next target': () => moveToNextTarget(),
  r'previous target': () => moveToPreviousTarget(),
  
  // Session
  r'start session': () => startSession(),
  r'end session': () => endSession(),
  
  // Notes
  r'add note (.+)': (match) => addNote(match.group(1)),
};
```

---

## AI Session Notes Generation

### Input Data

```json
{
  "session": {
    "patient": "Emma Thompson",
    "date": "2026-01-23",
    "duration_minutes": 45,
    "therapist": "Sarah Johnson"
  },
  "programs_worked": [
    {
      "name": "Request item",
      "trials": 20,
      "correct": 16,
      "percent": 80,
      "prompt_levels": {"independent": 12, "gestural": 4, "partial_physical": 4}
    }
  ],
  "behaviors": [
    {"type": "tantrum", "count": 2, "avg_duration": 45}
  ],
  "notes": ["Emma was engaged today", "Preferred crackers as reinforcer"]
}
```

### Generated Output

```
SESSION NOTES - Emma Thompson - January 23, 2026

Duration: 45 minutes | Location: Clinic | Therapist: Sarah Johnson, RBT

SKILL ACQUISITION:
• Request Item: 80% correct (16/20 trials). 60% independent responses, 
  20% with gestural prompt, 20% with partial physical prompt. 
  Showing steady progress toward mastery criteria of 80% x 3 sessions.

BEHAVIOR DATA:
• Tantrum: 2 occurrences, average duration 45 seconds. Both occurred during 
  transition periods.

CLINICAL NOTES:
• Emma demonstrated good engagement throughout the session
• Highly motivated by crackers as reinforcer
• Recommend continuing current prompt fading schedule

NEXT SESSION RECOMMENDATIONS:
• Continue request item program with current prompt levels
• Introduce new tacting targets
• Prepare transition supports to reduce tantrum frequency
```

---

## Testing Checklist

### Phase 1 Testing

- [ ] Session queue displays correct sessions for logged-in RBT
- [ ] EVV check-in captures geolocation
- [ ] Trial data saves correctly (+/- buttons)
- [ ] Timer functions (start, stop, lap)
- [ ] Frequency counter increments/decrements
- [ ] Notes auto-save every 30 seconds
- [ ] Graph updates in real-time
- [ ] Offline mode stores data locally
- [ ] Data syncs when connection restored
- [ ] Session end generates summary

### Phase 2 Testing

- [ ] BCBA can view patients awaiting programming
- [ ] Goal library search and filtering works
- [ ] Program creation wizard saves correctly
- [ ] Mastery criteria auto-advances programs
- [ ] BCBA can review RBT session data
- [ ] Task analysis chaining works correctly

### Phase 3 Testing

- [ ] Voice commands recognized accurately
- [ ] AI generates session notes within 5 seconds
- [ ] AI goal suggestions match assessment data
- [ ] Speech-to-text transcription works
- [ ] Real-time coaching alerts appear appropriately

---

## Dependencies & Blockers

| Dependency | Status | Notes |
|------------|--------|-------|
| Patient assessment data | ⚪ | Needed for AI goal suggestions |
| Scheduling integration | ⚪ | Sessions created from appointments |
| Azure OpenAI setup | ⚪ | For AI features |
| Azure Speech Services | ⚪ | For voice commands |
| Offline storage solution | ⚪ | IndexedDB or Hive |

---

## Acceptance Criteria

### Phase 1 Complete When:
1. RBT can view and start sessions from queue
2. RBT can collect trial-by-trial data with < 2 second latency
3. RBT can record behaviors with ABC data
4. Session notes can be saved
5. Progress graphs display in real-time
6. Data persists when offline and syncs when online

### Phase 2 Complete When:
1. BCBA can create programs with goals and targets
2. Mastery criteria auto-advances programs
3. BCBA can assign programs to RBTs
4. BCBA can review and approve session data

### Phase 3 Complete When:
1. Voice commands work with > 95% accuracy
2. AI generates session notes in < 5 seconds
3. AI suggests relevant goals from assessment data
4. Parent summaries generate automatically

---

## Timeline Estimate

| Phase | Estimated Duration | Dependencies |
|-------|-------------------|--------------|
| Phase 1: Core Data Collection | 3-4 weeks | Backend setup |
| Phase 2: BCBA Programming | 2-3 weeks | Phase 1 |
| Phase 3: AI Features | 3-4 weeks | Azure AI services |
| Phase 4: Advanced Features | 4-6 weeks | Wearable SDKs |

**Total: 12-17 weeks for full implementation**

---

## Notes

- Follow existing design system (white cards, colored tags only)
- Mobile-first approach for RBT interface
- Test extensively on iPad (primary RBT device)
- HIPAA compliance for all data storage
- Real-time sync critical for supervision workflow
