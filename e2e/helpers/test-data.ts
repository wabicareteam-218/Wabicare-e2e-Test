/**
 * Shared test data for the Wabi Clinic E2E test suite.
 * Uses timestamp suffixes for CI/CD to avoid duplicate patient conflicts.
 */

const timestamp = Date.now().toString().slice(-6);

export const TEST_PATIENT = {
  firstName: 'TestPt',
  lastName: `Auto${timestamp}`,
  dob: '06/15/2019',
  diagnosis: 'ADHD',
};

export const TEST_GUARDIAN = {
  firstName: 'TestGd',
  lastName: `Auto${timestamp}`,
  relationship: 'Mother',
  phone: '5550001234',
  email: `testguardian${timestamp}@example.com`,
};

export const KNOWN_PATIENT = {
  firstName: 'Jane',
  lastName: 'Douglas',
  dob: '03/22/2018',
  diagnosis: 'ADHD',
  guardian: {
    firstName: 'Mary',
    lastName: 'Douglas',
    relationship: 'Mother',
    phone: '5559876543',
    email: 'mary.douglas@example.com',
  },
};

export const SIDEBAR_ITEMS = [
  'Dashboard',
  'Patients',
  'Sessions',
  'Schedule',
  'Reports',
  'Tools',
  'Settings',
] as const;

export const PATIENT_TABS = [
  'Profile',
  'Intake Forms',
  'Scheduling',
  'More',
] as const;

export const INTAKE_SECTIONS = [
  'Basic Information',
  'Insurance Information',
  'Co-Pay Payment',
] as const;
