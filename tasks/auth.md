# Auth Tasks

> Authentication, authorization, and user management

**PRD Reference**: [../prd/auth.md](../prd/auth.md)

---

## Azure Entra External ID

### ✅ Done
- [x] PKCE flow for web
- [x] Safari-based flow for iOS/macOS
- [x] Token secure storage
- [x] Login screen
- [x] Google IdP integration
- [x] Error handling + display

### 🟡 In Progress
- [ ] Token refresh flow
- [ ] Silent sign-in on app start

### ⚪ Backlog
- [ ] Sign out flow (clear tokens)
- [ ] Session timeout handling
- [ ] Multi-org user switching
- [ ] Role display in UI
- [ ] Android testing

---

## Backend JWT Validation

### ⚪ Backlog
- [ ] Middleware to validate Entra JWT
- [ ] Extract user claims
- [ ] Map to Django user
- [ ] Org context from token
- [ ] Permission checks

---

## User Management

### ⚪ Backlog
- [ ] User profile screen
- [ ] Change password flow
- [ ] Invite new user flow
- [ ] User list (admin)
- [ ] Role assignment (admin)
- [ ] Deactivate user (admin)
