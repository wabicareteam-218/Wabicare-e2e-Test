# Gherkin feature files

This folder contains **Gherkin** (`.feature`) specs used to describe behavior for QA and future test automation. They are **not tied to a specific runner** (e.g. you can wire them to Cypress, Playwright, Behave, or another tool in a separate test folder).

## Features

- **01_login_qa.feature** – Login flow (open app, title, email/password, submit, logged in).
- **consent_forms_qa.feature** – Consent & Agreements (HIPAA, treatment consent).
- **date_validation_qa.feature** – Date field validation (MM/DD/YYYY).
- **document_upload_qa.feature** – Document upload in intake/patient context.
- **intake_forms_qa.feature** – New patient intake form sections.
- **owner_intake_qa.feature** – Parent/owner intake (forms sent to parent).
- **patient_profile_qa.feature** – Patient list and profile view/edit.
- **validators_qa.feature** – Form validators (name, email, phone, date, required).

## Running these

Implement step definitions and hook these feature files to your chosen test runner in **another folder** (e.g. `e2e/` or `tests/`). The steps (Given/When/Then) define the contract; the implementation lives in your test project.
