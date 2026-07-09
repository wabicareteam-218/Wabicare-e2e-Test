# Grounded in wabi-flutter-dev:
#   lib/features/clinic/sessions/screens/session_workspace_screen.dart   (AI Generate, Save Notes, Approve Notes, Edit Notes, amend-reason dialog, Sign dialog, permission gate canAmend)
#   lib/features/clinic/sessions/widgets/workspace/native_session_note.dart      ("Document <Section>…" placeholders, "No data collected this session.")
#   lib/features/clinic/sessions/widgets/workspace/enhanced_notes_panel.dart     (Enhance with AI, Auto-saved, CPT service badges)
#   lib/features/clinic/sessions/widgets/workspace/notes_export_menu.dart        (Export → PDF/Word/Google Docs)
#   lib/features/clinic/scheduling/screens/scheduling_screen.dart                (approved-note lock banner on the Schedule)
# KEY FACTS:
#   - Amend gate mirrors backend _is_clinical_lead: canAmend = isBcba || isAdmin || isAdministrator (inline field edit also allows isOwner).
#   - Approve is only enabled once the session is Completed; tooltip when not: "End the session before approving notes."
#   - Editing an approved note requires a >= 20-character amendment reason logged to the chart audit trail.
#   - The Schedule lock banner "Notes approved — only a BCBA can amend." lives in a HOVER card and only shows for non-BCBA viewers.

Feature: Session Notes & Reporting — AI draft, save, approve, and amend
  As a clinician documenting a completed session
  I want to AI-draft, edit, save, approve/sign and (with authority) amend the note
  So that the progress note is accurate, signed, billable, and audit-tracked.
  The note editor sits on the Session Workspace after End Session. "AI Generate"
  drafts from the collected data, "Save Notes" persists a draft, and (once the
  session is Completed) "Approve Notes" locks it. Approved notes can only be
  amended by a BCBA / clinical lead, with a logged reason.

  Background:
    Given I am logged in and have ended a session for "Demo Patient 2"
    And I am on the Session Notes report for that session

  # ── AI generation: happy paths ───────────────────────────────────────────
  @smoke @positive
  Scenario: AI-generate a session note from collected data
    When I click "AI Generate"
    Then the button shows "Generating..." while it runs
    And the generated content replaces the "Document <Section>…" placeholders
    And the action flips to "Regenerate"
    And "Save Notes" becomes available

  @positive
  Scenario: Regenerate refreshes only the unlocked sections
    Given a note was AI-generated and I edited one section
    When I click "AI Generate" again
    And no section needed force-regen
    Then only the unedited (unlocked) sections are refreshed
    And my edited section is preserved verbatim

  @edge
  Scenario: Regenerating over manually-edited sections asks for confirmation
    Given some sections kept my manual edits and were not refreshed
    When I trigger a regenerate-all
    Then a dialog "Regenerate all sections?" lists the kept sections
    And warns "Regenerate every section from the latest session data? This discards your edits to those sections."
    And offers "Regenerate all" and "Keep my edits"

  @edge
  Scenario: Generating a note for a session with no data
    Given the session had no data collected
    When I click "AI Generate"
    Then the note is still drafted
    And the Data Summary section reads "No data collected this session."

  @negative
  Scenario: AI generation failure surfaces an error toast
    Given the AI generation call fails
    When I click "AI Generate"
    Then I see the toast "Failed to generate notes"
    And the note remains editable/saveable

  @edge
  Scenario: A long AI generation keeps the button in its loading state
    When I click "AI Generate" and generation is slow
    Then the button stays "Generating..." and disabled until it completes or errors
    And no duplicate generation is triggered by clicking again

  # ── Editing ──────────────────────────────────────────────────────────────
  @positive
  Scenario: Manually edit the note body before saving
    Given the editor shows placeholder 'ABA Progress Note — tap "AI Generate" to draft, or start writing your note here.'
    When I type observations into a section
    Then my text is retained and the note becomes saveable

  @positive
  Scenario: Clear resets the note editor
    Given the note editor has content
    When I click "Clear"
    Then the editor content is cleared

  # ── Save ─────────────────────────────────────────────────────────────────
  @smoke @positive
  Scenario: Save a draft note
    Given the note has content
    When I click "Save Notes"
    Then the button shows "Saving..." while it persists
    And I see the toast "Notes saved successfully"
    And the "Approve Notes" action becomes available

  @negative
  Scenario: A save failure surfaces an error toast
    Given the save call fails
    When I click "Save Notes"
    Then I see the toast "Failed to save notes"

  # ── Approve (BCBA / completed-session gating) ────────────────────────────
  @smoke @positive
  Scenario: Approve a saved note on a completed session
    Given the session is "Completed" and a draft note is saved
    When I click "Approve Notes"
    Then I see the toast "Notes approved successfully"
    And the note shows the "Approved" status pill
    And the primary action becomes "Edit Notes"

  @negative @permission
  Scenario: Notes cannot be approved before the session is ended
    Given the session is NOT yet completed
    Then the "Approve Notes" button is disabled
    And its tooltip reads "End the session before approving notes."

  @edge
  Scenario: When completed, the approve tooltip explains the lock
    Given the session is "Completed" with a saved draft
    Then the "Approve Notes" tooltip reads "Approve and lock this session note"

  @negative
  Scenario: An edit-capture failure aborts approval
    Given my in-progress edits fail to capture at approval time
    When I click "Approve Notes"
    Then nothing is approved
    And I see "Couldn't capture your note edits — nothing was approved. Please try again."

  # ── Amend-lock after approval ────────────────────────────────────────────
  @permission @positive
  Scenario: A BCBA reopens an approved note to amend with a logged reason
    Given a note is "Approved" and I am a BCBA / clinical lead
    When I click "Edit Notes"
    Then a dialog "Edit approved note" explains the edit and reason are logged to the chart audit trail
    When I type a reason of at least 20 characters in "Reason for edit"
    And I click "Edit"
    Then I see "Note unlocked for amendment. Make your edits, then click Re-Approve to re-lock the note."
    And the status pill shows "Amending"

  @negative
  Scenario: The amendment reason must be at least a sentence (20 characters)
    Given the "Edit approved note" dialog is open
    When I type a reason shorter than 20 characters
    Then the "Edit" button stays disabled
    And the helper reads "At least a sentence — <n> more character(s) needed."
    When the reason reaches 20+ characters
    Then the helper reads "Looks good." and "Edit" becomes enabled

  @positive
  Scenario: Re-approving re-locks an amended note
    Given I unlocked an approved note and made edits
    When I click "Re-Approve"
    Then the button shows "Re-Approving…" while saving
    And I see the toast "Amendment saved and re-approved"
    And the note returns to the "Approved" state

  # ── Non-BCBA cannot amend ────────────────────────────────────────────────
  @negative @permission @security
  Scenario: A non-BCBA cannot edit an approved note
    Given a note is "Approved" and I am NOT a BCBA / clinical lead
    Then the "Edit Notes" action is disabled
    And its tooltip reads "Only a BCBA or clinical lead can edit an approved note."

  @permission
  Scenario: Approve is only offered while an unapproved AI note exists
    Given the note is already "Approved"
    Then the green "Approve" button is no longer shown
    And only "Edit Notes" (amend) remains

  # ── Signing ──────────────────────────────────────────────────────────────
  @positive
  Scenario: Sign a note by drawing a signature
    When I open the "Sign Session Note" dialog
    Then it says "Draw your signature below. This attests the note is accurate."
    And "Sign" is disabled until a signature is drawn
    When I draw a signature and click "Sign"
    Then I see the toast "Session note signed"
    And the sign action reads "Signed"

  @negative
  Scenario: Signing failure surfaces an error
    Given the sign call fails
    When I sign the note
    Then I see the toast "Failed to sign note"

  @edge
  Scenario: A supervision note awaits the RBT signature
    Given a supervised session note
    Then the note shows "Awaiting RBT signature" until the RBT signs

  # ── Schedule reflection of approval ──────────────────────────────────────
  @smoke @positive
  Scenario: The Schedule shows an approved session as BCBA-amend-only for a non-BCBA
    Given I approved the note as a non-BCBA (Owner) viewer
    When I open the Schedule Calendar in Day view on the session's date
    And I hover the session block to raise its hover card
    Then the card shows "Notes approved — only a BCBA can amend."
    And a "View" action opens the read-only appointment details

  @permission
  Scenario: A BCBA viewer is not locked out on the Schedule
    Given I approved the note and I view the Schedule as a BCBA
    Then the appointment block is NOT locked
    And no "Notes approved — only a BCBA can amend." banner is shown to me

  # ── Billing / CPT metadata ───────────────────────────────────────────────
  @data
  Scenario Outline: The note metadata header shows the service CPT code
    Given a "<service>" session note
    Then the metadata badge reads "<badge>"

    Examples:
      | service            | badge                    |
      | Direct Service     | Direct Service · 97153   |
      | Supervision        | Supervision · 97155      |
      | Caregiver Training | Caregiver Training · 97156 |
      | Assessment         | Assessment · 97151       |
      | Group              | Group · 97158            |

  # ── Export ───────────────────────────────────────────────────────────────
  @positive
  Scenario: Export an approved note
    Given a note is "Approved"
    When I open the "Export" menu
    Then it offers "Download as PDF", "Download as Word" and "Open in Google Docs"
    When I choose "Download as Word"
    Then I see the toast "Word document downloaded"

  @edge
  Scenario: Copy-for-Google-Docs places note text on the clipboard
    When I choose "Open in Google Docs" from the "Export" menu
    Then I see "Notes copied to clipboard — paste into the new document"

  # ── Auto-save / voice notes ──────────────────────────────────────────────
  @edge
  Scenario: The enhanced notes panel auto-saves after typing
    Given I am typing in the enhanced notes panel with hint "Start typing session notes..."
    When I pause typing for a moment
    Then an "Auto-saved" indicator is shown

  @positive
  Scenario: Enhance a manual note with AI
    Given manual note text exists in the enhanced notes panel
    When I click "Enhance with AI"
    Then it shows "Enhancing..." then briefly confirms "Enhanced"

  # ── Audit trail ──────────────────────────────────────────────────────────
  @security
  Scenario: Each amendment is appended to the chart audit trail
    Given an approved note is amended with a reason and re-approved
    Then a "Summary of Amendments" entry records the edit, the reason, and the actor
    And the "Note History" reflects the "amended" action

  # ── Accessibility ────────────────────────────────────────────────────────
  @a11y
  Scenario: Note actions expose accessible names and states
    Given the Session Notes report is open
    Then "AI Generate", "Save Notes", "Approve Notes" and "Edit Notes" expose accessible names
    And the "Approved" / "Amending" status pills convey the note's lock state
