Feature: Authentication & session
  As a clinic user
  I want to sign in through Wabi's Microsoft CIAM (Azure Entra External ID) flow
  So that only invited, provisioned users reach the clinician workspace.

  # Grounded in wabi-flutter-dev:
  #   lib/features/auth/screens/login_screen.dart
  #   lib/features/auth/screens/no_account_screen.dart
  #   lib/features/auth/ui/login_view_model.dart
  #   lib/features/auth/services/auth_service.dart
  #   lib/main.dart (AuthState: checking, unauthenticated, authenticated, noAccount)
  #   helpers/login.ts + tests/login.spec.ts (CIAM automation facts)
  # IMPORTANT app facts:
  #   - Sign In is SSO-only. The in-app "Sign In" button just redirects to CIAM
  #     (label flips to "Redirecting..."). Password login is superadmin-only (backend).
  #   - The "Stay signed in?" prompt and smart-lockout are Microsoft CIAM behaviours,
  #     not Wabi screens. Wabi has NO in-app remember-me and NO client-side lockout.
  #   - An authenticated identity with no matching Django user lands on NoAccountScreen.
  #   - Token keys in web localStorage: flutter.access_token, flutter.id_token,
  #     flutter.refresh_token, flutter.expires_at. 401 triggers exactly one silent refresh.

  # ─────────────────────────── Landing / sign-in ───────────────────────────

  @smoke @positive
  Scenario: Landing page renders the Wabi Clinic sign-in panel
    Given I open the app while signed out
    Then the page title matches "Wabi Clinic"
    And I see the eyebrow label "SIGN IN"
    And I see the headline "Welcome back"
    And I see the subtitle "SIGN IN TO YOUR WABI CLINIC ACCOUNT."
    And I see a "Sign In" button
    And I see the footer "BY CONTINUING, YOU AGREE TO OUR TERMS · PRIVACY POLICY"

  @smoke @positive
  Scenario: Successful sign-in with a provisioned Microsoft-native account
    Given I open the app while signed out
    When I click "Sign In"
    And I am redirected to the CIAM login at "ciamlogin.com"
    And I enter a valid provisioned email into the "Email address" field and click "Next"
    And I enter the correct password into the "Password" field and click "Sign in"
    And I answer "Yes" to the "Stay signed in?" prompt
    Then I am redirected back to "dev.wabicare.com"
    And a "flutter.access_token" is stored in localStorage
    And the dashboard loads

  @positive
  Scenario: Sign In button shows a redirecting state while launching CIAM
    Given I open the app while signed out
    When I click "Sign In"
    Then the button label changes to "Redirecting..."
    And the button is disabled while redirecting

  # ─────────────────────── CIAM credential negatives ───────────────────────

  @negative @data
  Scenario Outline: CIAM rejects invalid credentials
    Given I open the app while signed out and click "Sign In"
    And I reach the CIAM login page
    When I submit email "<email>" and password "<password>"
    Then the sign-in does not complete
    And CIAM shows a rejection message matching "<message_pattern>"

    Examples:
      | email                       | password       | message_pattern                 |
      | rgchaitanya6@gmail.com      | WrongPass!1    | isn't correct / does not match  |
      | no-such-user@nowhere.test   | anything123    | couldn't find an account        |
      | not-an-email                | anything123    | valid email / enter a valid     |

  @negative
  Scenario: Empty email is not accepted by CIAM
    Given I reach the CIAM login page
    When I leave the "Email address" field empty and click "Next"
    Then I remain on the email step and cannot proceed

  @negative
  Scenario: Empty password is not accepted by CIAM
    Given I reach the CIAM password step for a valid email
    When I leave the "Password" field empty and click "Sign in"
    Then I remain on the password step and cannot proceed

  @security @edge
  Scenario: Repeated failed sign-ins trip Azure AD B2C smart-lockout
    Given I have submitted several wrong passwords in a row at CIAM
    When I then submit the CORRECT credentials
    Then CIAM still refuses with an account-not-found style message
    And the account remains locked until the lockout window elapses
    # Encoded from project memory: do not hammer login; smart-lockout masks correct creds.

  # ─────────────────── Federated / unknown-account handling ─────────────────

  @security @negative
  Scenario: Google-federated email cannot be automated through CIAM
    Given I click "Sign In" and enter a Google-federated email such as "wabicareteam@gmail.com"
    When CIAM redirects the sign-in to Google
    Then Google challenges with a CAPTCHA / rejects the automated sign-in
    And I never receive a Wabi session

  @security @negative
  Scenario: Authenticated identity with no Wabi account is shown the No-Account screen
    Given I authenticate successfully at CIAM with an identity that has no matching Wabi user
    Then I am shown the screen titled "We couldn't sign you in"
    And I see the text "isn't linked to a Wabi account yet."
    And I see the guidance "Ask your organization admin to send an invitation"
    And I see "Wabi is invitation-only. Your admin can add you from Settings → Users."
    And I see the option "Or start a new organization"
    And I see a "Sign out" button

  @security
  Scenario: No-Account fallback message when the email cannot be read from token claims
    Given I authenticate at CIAM but the auth service cannot read the email claim
    Then the No-Account screen shows "No account found. Please sign up at the registration page or ask your organization admin to send you an invitation."

  @negative
  Scenario: Signing out from the No-Account screen returns to sign-in
    Given I am on the "We couldn't sign you in" screen
    When I click "Sign out"
    Then the local session is cleared
    And I am returned to the sign-in landing page

  # ─────────────────────── Generic app-side auth errors ─────────────────────

  @negative
  Scenario: Generic sign-in failure surfaces a retryable banner
    Given the auth service throws during sign-in
    Then the login panel shows the error banner "Sign-in failed. Please try again."

  # ─────────────────────────── Request access (signup) ─────────────────────

  @positive
  Scenario: Switch to the Request access form
    Given I am on the sign-in landing page
    When I click "REQUEST ACCESS"
    Then the eyebrow changes to "GET STARTED"
    And the headline changes to "Request access"
    And I see fields "CLINIC NAME", "FIRST NAME", "LAST NAME", "EMAIL", "PHONE NUMBER" and "LICENSING INFORMATION"
    And I see a "NEXT" button

  @negative
  Scenario: Request access with missing required fields is blocked
    Given I am on the "Request access" form
    When I submit with "CLINIC NAME", "FIRST NAME", "LAST NAME" or "EMAIL" left blank
    Then I see the error banner "Please fill in all required fields."

  @positive
  Scenario: Request access happy path shows the submitted confirmation
    Given I am on the "Request access" form
    When I fill clinic name, first name, last name and email and click "NEXT"
    Then the button shows "SUBMITTING..." while in flight
    And on success I see "Registration Submitted!"
    And I see "Your signup request has been submitted. Our team will review it and send you login instructions via email."
    And I see a "Back to Sign In" action

  @data @edge
  Scenario Outline: Request access email field boundary values
    Given I am on the "Request access" form
    When I enter "<email>" as the email with all other required fields filled
    Then submission is "<result>"

    Examples:
      | email                       | result                       |
      | jane.doe@example.com        | accepted                     |
      |                             | blocked (required field)     |
      |    (whitespace only)        | blocked (trimmed to empty)   |
      | plainaddress                | accepted client-side (backend validates) |
      | 你好@例子.测试               | accepted client-side         |

  @negative
  Scenario: Request access failure surfaces a retryable banner
    Given submitting the "Request access" form fails
    Then I see the error banner "Signup failed. Please try again."

  # ─────────────────────────── Session & token lifecycle ───────────────────

  @positive @edge
  Scenario: Expired access token is refreshed silently on the next API call
    Given I am signed in and my access token is within 2 minutes of expiry
    When the app makes an authenticated API call
    Then the token is refreshed silently using the stored flutter.refresh_token
    And no re-login prompt is shown

  @edge
  Scenario: A 401 response triggers exactly one silent refresh-and-retry
    Given I am signed in and my token is rejected with HTTP 401
    When the API client retries the request
    Then it forces a refresh once and retries the request a single time
    And it does not loop indefinitely on repeated 401s

  @negative @edge
  Scenario: Refresh token older than its fixed 24h lifetime forces a fresh login
    Given my stored refresh token is more than 24 hours old
    When the app attempts a silent refresh
    Then the CIAM token endpoint returns "invalid_grant" (AADSTS700084)
    And only a fresh interactive sign-in can restore access

  @security
  Scenario: Concurrent API calls share a single in-flight token refresh
    Given my token is expiring and several API calls fire at once
    Then only one refresh request is issued
    And the other callers await the same refreshed token

  # ─────────────────────────── Logout ──────────────────────────────────────

  @smoke @positive
  Scenario: Logout clears the session and forces a fresh login next time
    Given I am signed in
    When I sign out
    Then the stored tokens are cleared
    And "auth_force_login" is set so the next sign-in prompts fresh credentials
    And I am returned to the sign-in landing page

  @negative
  Scenario: No logout confirmation dialog is shown
    Given I am signed in
    When I trigger sign out
    Then I am signed out immediately without an "Are you sure?" confirmation

  # ─────────────────── Direct-URL access & deep links ───────────────────────

  @security @permission
  Scenario Outline: Unauthenticated direct-URL access redirects to Sign In
    Given I am signed out
    When I navigate directly to "<path>"
    Then I am redirected to the sign-in landing page

    Examples:
      | path                    |
      | /dashboard              |
      | /patients               |
      | /schedule               |
      | /sessions               |
      | /reports                |
      | /settings               |

  @positive
  Scenario: Deep link is honoured after signing in
    Given I am signed out and open a deep link to a specific patient profile
    When I complete sign-in
    Then I land on the requested patient profile rather than the default dashboard

  @a11y
  Scenario: Sign-in landing exposes the Sign In control to assistive tech
    Given I open the app while signed out with accessibility enabled
    Then the semantics tree contains "Sign In"
