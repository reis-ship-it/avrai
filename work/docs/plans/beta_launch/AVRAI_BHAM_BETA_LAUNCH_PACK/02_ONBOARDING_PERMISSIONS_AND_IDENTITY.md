# Onboarding, Permissions, And Identity

## Onboarding Sequence

### 1. Login And Account Creation

- Required
- Supported entry paths: email, Apple, Google
- Output: account exists and the initial agent boot path begins

### 2. Mandatory Questionnaire

- Required
- Hard max: 20 questions
- Purpose: initial knot/DNA formation
- Completion condition: required direct questions answered

### 3. Privacy And Beta Consent

- Required
- User must scroll through and consent to privacy/beta terms
- Consent is logged into agent knowledge
- Privacy text must explain:
  - what stays on device
  - what flows through the air gap
  - what admin can and cannot see
  - break-glass conditions for dangerous or malicious behavior
  - air-gap strength controls
  - admin sharing as a necessary beta condition, not a full opt-out

### 4. Permissions

- Permission sheet appears once, backed by an explainer page
- User can review and later adjust permissions in settings
- The system must adapt when permissions are removed

## Questionnaire Content Rules

### Direct Mandatory Topics

- goals
- interests
- values
- what the user wants more of
- what the user wants less of
- favorite places
- spending preference
- how the user gets around
- what the user does for fun or wants to do for fun
- whether the user is more introverted, extroverted, or in the middle
- final freeform bio

### Prefer To Learn Rather Than Ask

- exact routine
- exact time-of-day patterns
- exact social style beyond the broad introvert/extrovert positioning
- exact energy patterns
- who the user goes with
- comfort with strangers
- exact homebase if location-based inference is available

### Off-Limits For Beta Prompting

- explicit routine interrogation
- prompts asking about illegal activity
- prompts about comfort with strangers
- prompts about sexuality
- prompts about exact address or exact household composition

Users can still volunteer relevant context in the freeform bio.

## Permissions Model

### Intended Full Beta Mode

- precise location
- background location
- Bluetooth
- calendar
- health/activity data
- passive dwell/movement sensing

### Helpful But Optional

- notifications
- social bridges

### Not Required For Beta

- contacts
- camera/photo library
- microphone

## Permission Adaptation Rules

- No account-creation hard block for optional features
- If a permission is removed later, the app must adapt instead of breaking
- Local-only personal learning never stops
- Bluetooth off disables Bluetooth AI2AI, but local Wi-Fi or other approved local transports can still carry exchange when available

## Identity Rules

- One account per human in beta
- One primary device per account in wave 1
- Pseudonymous toward admin by default
- Display name is for user/community-facing surfaces, not for default admin visibility
- Admin must never see names, numbers, addresses, social handles, or linked account identity by default

## Onboarding Completion Definition

Onboarding is complete when:

1. account exists
2. consent is recorded
3. minimum usable permissions are granted
4. optional bridges are either connected or skipped
5. knot/DNA is generated
6. walkthrough is completed or skipped
7. first daily-drop screen is shown
