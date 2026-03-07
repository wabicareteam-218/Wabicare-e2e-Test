/**
 * Locator map for the Wabi Clinic Flutter web application.
 * Generated from comprehensive page exploration on 2026-03-06.
 *
 * Flutter CanvasKit renders to a WebGL canvas. All interactable elements
 * are exposed via `flt-semantics` nodes after enabling accessibility.
 * Inputs are standard `<input>` elements inside `flt-semantics-host`.
 */

// ────────────────────────────────────────────────────────────────
// SIDEBAR NAVIGATION (present on all pages)
// ────────────────────────────────────────────────────────────────
export const SIDEBAR = {
  Dashboard:  'Dashboard',
  Patients:   'Patients',
  Sessions:   'Sessions',
  Schedule:   'Schedule',
  Reports:    'Reports',
  Tools:      'Tools',
  Settings:   'Settings',
} as const;

export const GLOBAL = {
  searchInput: { index: 0, aria: 'Search...' },
  aiCopilot:   'AI Copilot',
  clinicName:  'Vanilla Clinic',
} as const;

// ────────────────────────────────────────────────────────────────
// DASHBOARD
// ────────────────────────────────────────────────────────────────
export const DASHBOARD = {
  buttons: {
    refresh:      'Refresh',
    viewCalendar: 'View Calendar',
    viewAll:      'View All',
  },
  cards: {
    activePatients:  'Active Patients',
    todaysSessions:  "Today's Sessions",
    pendingIntakes:  'Pending Intakes',
    hoursThisWeek:   'Hours This Week',
  },
  sections: {
    todaysSchedule:     "Today's Schedule",
    activePatients:     'Active Patients',
    staffUtilization:   'Staff Utilization',
    authorizationAlerts:'Authorization Alerts',
  },
} as const;

// ────────────────────────────────────────────────────────────────
// PATIENTS LIST
// ────────────────────────────────────────────────────────────────
export const PATIENTS_LIST = {
  buttons: {
    refresh:    'Refresh',
    import:     'Import',
    newPatient: 'New Patient',
    showMenu:   'Show menu',
  },
  inputs: {
    globalSearch:  { index: 0, aria: 'Search...' },
    patientSearch: { index: 1, ariaContains: 'Search patients' },
  },
  statusFilters: ['Intake', 'Auth Pending', 'Active', 'Discharged'],
  columns: ['PATIENT', 'GUARDIAN', 'PHONE', 'NEXT APPOINTMENT', 'STATUS'],
} as const;

// ────────────────────────────────────────────────────────────────
// NEW PATIENT — BASIC INFORMATION
// ────────────────────────────────────────────────────────────────
export const INTAKE_BASIC_INFO = {
  sections: {
    basicInfo:      'Basic Information',
    insuranceInfo:  'Insurance Information',
    coPay:          'Co-Pay Payment',
  },
  tabs: {
    profile:     'Profile',
    intakeForms: 'Intake Forms',
    scheduling:  'Scheduling',
    more:        'More',
  },
  inputs: {
    patientFirstName: { index: 1, defaultAria: 'John',               label: 'First Name' },
    patientLastName:  { index: 2, defaultAria: 'Doe',                label: 'Last Name' },
    dateOfBirth:      { index: 3, defaultAria: 'MM/DD/YYYY',         label: 'Date of Birth' },
    diagnosis:        { index: 4, defaultAria: 'Autism Spectrum Disorder', label: 'Diagnosis' },
    guardianFirstName:{ index: 5, defaultAria: 'Jane',               label: 'Guardian First Name' },
    guardianLastName: { index: 6, defaultAria: 'Doe',                label: 'Guardian Last Name' },
    relationship:     { index: 7, defaultAria: 'Mother, Father, Legal Guardian...', label: 'Relationship' },
    phone:            { index: 8, defaultAria: '(555) 123-4567',     label: 'Phone Number' },
    email:            { index: 9, defaultAria: 'guardian@email.com',  label: 'Email Address' },
  },
  buttons: {
    save:  'Save',
    files: 'Files',
  },
} as const;

// ────────────────────────────────────────────────────────────────
// NEW PATIENT — INSURANCE INFORMATION
// ────────────────────────────────────────────────────────────────
export const INTAKE_INSURANCE = {
  inputs: {
    insuranceProvider: { index: 1, defaultAria: 'Blue Cross Blue Shield', label: 'Insurance Provider' },
    memberId:          { index: 2, defaultAria: 'ABC123456789',           label: 'Member ID' },
    groupNumber:       { index: 3, defaultAria: 'GRP001',                label: 'Group Number' },
    policyHolder:      { index: 4, defaultAria: 'John Doe Sr.',          label: 'Policy Holder Name' },
    effectiveDate:     { index: 5, defaultAria: 'MM/DD/YYYY',            label: 'Effective Date' },
  },
  buttons: {
    uploadFront: 'Upload',
    scanFront:   'Scan',
    save:        'Save',
  },
  cardUpload: {
    frontOfCard: 'Front of Card',
    backOfCard:  'Back of Card',
  },
} as const;

// ────────────────────────────────────────────────────────────────
// NEW PATIENT — CO-PAY PAYMENT
// ────────────────────────────────────────────────────────────────
export const INTAKE_COPAY = {
  inputs: {
    coPayAmount: { index: 1, defaultAria: '$25.00', label: 'Co-Pay Amount' },
  },
  buttons: {
    coPayRequired:  'Co-Pay Required',
    noCoPay:        'No Co-Pay',
    card:           'Card',
    cash:           'Cash',
    check:          'Check',
    waive:          'Waive',
    processPayment: 'Process Payment',
    save:           'Save',
  },
} as const;

// ────────────────────────────────────────────────────────────────
// PATIENT INTAKE FORMS (9 sections under Intake Forms tab)
// ────────────────────────────────────────────────────────────────
export const INTAKE_FORM_SECTIONS = [
  'Client Information',
  'Caregiver & Provider Info',
  'ABA Therapy History',
  'Challenging Behaviors',
  'Education & Therapies',
  'Medical History',
  'Diagnosis & Documents',
  'Availability & Concerns',
  'Consent & Agreements',
] as const;

export const INTAKE_CLIENT_INFO = {
  inputCount: 12,
  inputs: {
    preferredName:  { index: 1, aria: 'If different from legal name' },
    languages:      { index: 2, aria: 'e.g., English, Spanish' },
    medicaidId:     { index: 3, aria: 'If applicable' },
    address:        { index: 4, aria: 'e.g., 123 Main St' },
    city:           { index: 5, aria: 'City' },
    state:          { index: 6, aria: 'State' },
    zip:            { index: 7, aria: 'Zip' },
    numSiblings:    { index: 8, aria: 'e.g., 2' },
    siblingAges:    { index: 9, aria: 'e.g., 5, 8, 12' },
    serviceLocation:{ index: 10, aria: 'Clinic / Home / Either' },
    preferredTimes: { index: 11, aria: 'e.g., Mornings, After school' },
  },
  buttons: { selectGender: 'Select gender', save: 'Save' },
} as const;

export const INTAKE_CAREGIVER_PROVIDER = {
  inputCount: 19,
  inputs: {
    pronouns:            { index: 1,  aria: 'e.g., she/her, he/him' },
    preferredContact:    { index: 2,  aria: 'Phone / Email / Text' },
    availability:        { index: 3,  aria: 'e.g., Weekdays 9am-5pm' },
    workNumber:          { index: 4,  aria: 'Work number' },
    secondaryName:       { index: 5,  aria: 'Full name' },
    secondaryRelation:   { index: 6,  aria: 'e.g., Father, Grandparent' },
    secondaryPhone:      { index: 7,  aria: 'Phone number' },
    secondaryEmail:      { index: 8,  aria: 'Email address' },
    emergencyName:       { index: 9,  aria: 'Emergency contact name' },
    emergencyRelation:   { index: 10, aria: 'e.g., Grandmother, Uncle' },
    pcpName:             { index: 11, aria: 'Full name' },
    pcpOffice:           { index: 12, aria: 'Office name' },
    pcpPhone:            { index: 13, aria: 'Office phone' },
    pcpFax:              { index: 14, aria: 'Fax number (if available)' },
    referringProvider:   { index: 15, aria: 'Referring doctor/specialist name' },
    referringSpecialty:  { index: 16, aria: 'e.g., Developmental Pediatrics' },
    referringOrg:        { index: 17, aria: "e.g., Children's Hospital" },
    referringContact:    { index: 18, aria: 'Contact number' },
  },
  buttons: { save: 'Save' },
} as const;

export const INTAKE_ABA_HISTORY = {
  inputCount: 5,
  inputs: {
    previousABA:    { index: 1, aria: 'Yes / No' },
    monthsService:  { index: 2, aria: 'e.g., 6' },
    yearsService:   { index: 3, aria: 'e.g., 1' },
    previousClinic: { index: 4, aria: 'Name of previous clinic/provider' },
  },
  buttons: { save: 'Save' },
} as const;

export const INTAKE_CHALLENGING_BEHAVIORS = {
  inputCount: 7,
  inputs: {
    behavior1Freq:     { index: 1, aria: 'e.g., 5 times' },
    behavior1Duration: { index: 2, aria: 'e.g., 10-15 minutes' },
    behavior2Freq:     { index: 3, aria: 'e.g., 3 times' },
    behavior2Duration: { index: 4, aria: 'e.g., 5 minutes' },
    behavior3Freq:     { index: 5, aria: 'e.g., 3 times' },
    behavior3Duration: { index: 6, aria: 'e.g., 5 minutes' },
  },
  buttons: { save: 'Save' },
} as const;

export const INTAKE_EDUCATION_THERAPIES = {
  inputCount: 9,
  inputs: {
    schoolName:    { index: 1, aria: 'School name' },
    grade:         { index: 2, aria: 'e.g., Pre-K, 1st' },
    hoursPerWeek:  { index: 3, aria: 'e.g., 30' },
    teacherName:   { index: 4, aria: 'Teacher name' },
    otherTherapy:  { index: 5, aria: 'e.g., Speech Therapy' },
    sessionsWeek:  { index: 6, aria: 'e.g., 2' },
    sessionLength: { index: 7, aria: 'e.g., 45 min' },
    description:   { index: 8, aria: 'Brief description' },
  },
  buttons: { chooseFile: 'Choose File', save: 'Save' },
} as const;

export const INTAKE_MEDICAL_HISTORY = {
  inputCount: 12,
  inputs: {
    allergies:        { index: 1,  aria: 'e.g., Peanuts, Penicillin' },
    reaction:         { index: 2,  aria: 'Describe reaction' },
    treatment:        { index: 3,  aria: 'e.g., EpiPen' },
    hospitalized:     { index: 4,  aria: 'Yes / No' },
    surgeries:        { index: 5,  aria: 'Yes / No - describe if yes' },
    medicationName:   { index: 6,  aria: 'e.g., Ritalin' },
    dosage:           { index: 7,  aria: 'e.g., 10mg' },
    frequency:        { index: 8,  aria: 'e.g., Daily, Twice daily' },
    medStartDate:     { index: 9,  aria: 'MM/DD/YYYY' },
    conditions:       { index: 10, aria: 'e.g., Asthma, Seizures' },
    conditionDate:    { index: 11, aria: 'MM/DD/YYYY' },
  },
  buttons: { save: 'Save' },
} as const;

export const INTAKE_DIAGNOSIS_DOCUMENTS = {
  inputCount: 4,
  inputs: {
    hasDiagnosis:  { index: 1, aria: 'Yes / No' },
    icdCode:       { index: 2, aria: 'e.g., F84.0 - Autism Spectrum Disorder' },
    diagnosisDate: { index: 3, aria: 'MM/DD/YYYY' },
  },
  buttons: { chooseFile: 'Choose File', save: 'Save' },
} as const;

export const INTAKE_AVAILABILITY_CONCERNS = {
  sectionName: 'Availability & Concerns',
  buttons: { save: 'Save' },
} as const;

export const INTAKE_CONSENT_AGREEMENTS = {
  inputCount: 4,
  inputs: {
    legalName:    { index: 1, aria: 'Type your full legal name' },
    signDate:     { index: 2, aria: 'MM/DD/YYYY' },
    relationship: { index: 3, aria: 'e.g., Mother' },
  },
  buttons: { drawSignature: 'Draw Signature', typeSignature: 'Type Signature', save: 'Save' },
} as const;

// ────────────────────────────────────────────────────────────────
// SESSIONS
// ────────────────────────────────────────────────────────────────
export const SESSIONS = {
  buttons: {
    patients:   'Patients',
    reports:    'Reports',
    addSession: 'Add Session',
  },
  inputs: {
    globalSearch:  { index: 0, aria: 'Search...' },
    patientSearch: { index: 1, ariaContains: 'Search patients' },
  },
  columns: ['Patient', 'Total Sessions', 'Last Session', 'Next Scheduled', 'Status'],
  emptyState: 'No patients with sessions found',
} as const;

// ────────────────────────────────────────────────────────────────
// SCHEDULE
// ────────────────────────────────────────────────────────────────
export const SCHEDULE = {
  buttons: {
    today:        'Today',
    calendarView: 'Calendar View',
    tableView:    'Table View',
    day:          'Day',
    week:         'Week',
    month:        'Month',
    new:          'New',
  },
  appointmentTypes: ['Intake', 'Assessment', 'Session', 'Miscellaneous'],
  teamMembers: 'Team Members',
} as const;

// ────────────────────────────────────────────────────────────────
// REPORTS
// ────────────────────────────────────────────────────────────────
export const REPORTS = {
  buttons: {
    refresh:     'Refresh',
    exportExcel: 'Export Excel',
    exportDoc:   'Export DOC',
    generate:    'Generate',
  },
  inputs: {
    globalSearch: { index: 0, aria: 'Search...' },
    filter:       { index: 1, aria: 'Filter by client, BCBA, payer...' },
  },
  tabs: {
    dataView:      'Data View',
    graphsCharts:  'Graphs & Charts',
  },
  columns: ['BCBA Name', 'Total', 'Active', 'Pending', 'Authorized', 'Used', 'Remaining', 'Utilization'],
} as const;

// ────────────────────────────────────────────────────────────────
// TOOLS
// ────────────────────────────────────────────────────────────────
export const TOOLS = {
  buttons: {
    newTask:    'New Task',
    refresh:    'Refresh',
  },
  tabs: {
    tasks:     'Tasks',
    notes:     'Notes',
    documents: 'Documents',
  },
  filters: {
    all:        'All',
    toDo:       'To Do',
    done:       'Done',
    inProgress: 'In Progress',
  },
  emptyState: 'No tasks',
} as const;

// ────────────────────────────────────────────────────────────────
// SETTINGS
// ────────────────────────────────────────────────────────────────
export const SETTINGS = {
  buttons: {
    edit:       'Edit',
    uploadLogo: 'Upload Logo',
  },
  tabs: {
    organization: 'Organization',
    users:        'Users',
    intake:       'Intake',
    import:       'Import',
    more:         'More',
  },
  orgFields: ['Organization Name', 'Type', 'Address', 'City', 'State'],
} as const;
