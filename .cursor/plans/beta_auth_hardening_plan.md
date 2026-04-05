# Beta Auth + Onboarding Hardening Plan

## Goal
Ship a beta-safe auth and onboarding flow that is honest, deterministic, and fully wired end-to-end.

## Work Queue

### 1. Fix onboarding exit path
- Route successful onboarding to `'/ai-loading'`, not `'/home'`
- Keep `AILoadingPage` as the canonical onboarding completion marker
- Ensure router behavior is consistent on relaunch

### 2. Correct Supabase signup/session logic
- Distinguish `account created + active session` from `account created + no session`
- Surface an explicit confirmation-required state when `session == null`
- Keep router-driven post-auth navigation

### 3. Simplify beta auth semantics
- Make login email-only
- Remove fake username assumptions
- Keep signup fields minimal and aligned with backend reality

### 4. Preserve onboarding payload
- Ensure `openResponses` survives serialization, storage, reload, and AI initialization
- Sanity-check other onboarding fields for silent drops

### 5. Trim onboarding to the shortest trustworthy beta path
- Welcome
- Legal + age
- Homebase
- Open intake
- Optional social connects
- Starter lists
- AI loading
- Home

### 6. Stabilize password reset expectations
- Keep messaging narrow and honest
- Treat reset as an email-link flow until full recovery-session wiring exists

### 7. Verify Supabase beta environment
- Confirm runtime env requirements (`SUPABASE_URL`, `SUPABASE_ANON_KEY`)
- Verify `public.users` trigger/RLS/profile provisioning behavior
- Check live schema against app assumptions and repair mismatches if needed

## Validation
- Auth bloc coverage for signup-with-session and signup-without-session
- Onboarding routing coverage for completion through `AILoadingPage`
- Onboarding data round-trip coverage for `openResponses`
- Focused auth/onboarding test runs
- One beta-environment smoke test path when code is stable
