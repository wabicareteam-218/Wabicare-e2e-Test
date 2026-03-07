# Clinic Domain Tasks

> Tasks for Patients, Intake, Scheduling, Sessions, Assessments, Reports

**PRD Reference**: [../prd/clinic/README.md](../prd/clinic/README.md)

---

## Patients Module

### ✅ Done
- [x] Patients list with search/filter
- [x] Patient card/row components
- [x] Status badges (Active, Intake, Graduated)
- [x] New Patient button

### 🟡 In Progress
- [ ] Patient detail view
- [ ] Save patient to backend API

### ⚪ Backlog
- [ ] Edit patient info
- [ ] Patient history timeline
- [ ] Delete/archive patient
- [ ] Bulk actions

---

## Intake Module

### ✅ Done
- [x] New patient intake wizard
- [x] Profile tab (basic info form)
- [x] Guardian information fields
- [x] Insurance information fields
- [x] Intake Forms tab with progress tracker
- [x] Centered progress circles
- [x] Medical History form
- [x] Behavioral Questionnaire form

### 🟡 In Progress
- [ ] Form data persistence (save to state)
- [ ] Form completion tracking

### ⚪ Backlog
- [ ] Consent form with signature
- [ ] HIPAA Notice form
- [ ] Insurance Authorization form
- [ ] Document upload
- [ ] Intake → Active transition
- [ ] Send forms to parent
- [ ] Phase 2 & 3 checklists

---

## Scheduling Module

### ✅ Done
- [x] Calendar week view UI
- [x] Time grid layout
- [x] Mini calendar
- [x] Team members sidebar
- [x] Services sidebar

### ⚪ Backlog
- [ ] Appointment creation modal
- [ ] Provider availability management
- [ ] Recurring appointments
- [ ] Drag-to-reschedule
- [ ] Day/Month view toggle
- [ ] Appointment details popup
- [ ] Conflict detection

---

## Sessions Module

### ✅ Done
- [x] Sessions queue list
- [x] Session workspace layout
- [x] Header with patient info
- [x] Tab navigation (Targets, Notes, etc.)

### ⚪ Backlog
- [ ] Target/behavior data entry
- [ ] Trial-by-trial recording
- [ ] Timer for session duration
- [ ] Notes entry (text + voice)
- [ ] Media capture (photos)
- [ ] Session completion flow
- [ ] Offline data collection
- [ ] Sync when online

---

## Assessments Module

### ⚪ Backlog
- [ ] Assessment list screen
- [ ] Assessment workspace
- [ ] VB-MAPP scoring
- [ ] ABLLS-R scoring
- [ ] FBA tools
- [ ] Report generation
- [ ] PDF export

---

## Reports Module

### ✅ Done
- [x] Reports placeholder screen

### ⚪ Backlog
- [ ] Report type selection
- [ ] Date range filters
- [ ] Patient filter
- [ ] Progress charts
- [ ] Export to PDF
- [ ] Export to Excel
- [ ] Email report

---

## Technical Debt

| Item | Priority | Notes |
|------|----------|-------|
| Dead code warnings in intake | Low | `isCompleted` always false |
| Hardcoded mock data | Medium | Replace with API |
| Missing form validation | Medium | Add required field checks |
