# Automatic Passive Check-In System with Dual-Trigger Verification — Claims Draft (MEDIUM (current spec claims))

**Source spec:** `docs/patents/category_2_offline_privacy_systems/04_automatic_passive_checkin/04_automatic_passive_checkin.md`
**Generated:** 2026-01-01

> **NOTE:** Draft for counsel review. This file does not change the underlying spec; it proposes an alternative Claim 1 scope posture.

## Claims

1. A method for automatic passive check-ins using geofencing and Bluetooth proximity verification, comprising:
(a) Detecting user entry into geofence with 50m radius using background location monitoring;
(b) Verifying proximity via Bluetooth/AI2AI network (works offline);
(c) Requiring both geofencing AND Bluetooth/AI2AI confirmation before recording visit;
(d) Calculating dwell time from entry to exit;
(e) Recording visit only if dwell time ≥ 5 minutes.

2. A system for dual-trigger visit detection requiring both geofence and proximity confirmation, comprising:
(a) Geofencing detection system with 50m radius background monitoring;
(b) Bluetooth/AI2AI proximity verification system (offline-capable);
(c) Dual-trigger verification logic requiring both triggers to confirm;
(d) Dwell time calculation tracking time from entry to exit;
(e) Visit quality scoring based on dwell time, review given, repeat visits, and detailed reviews.

3. The method of claim 1, further comprising calculating visit quality scores based on dwell time and engagement metrics:
(a) Calculating dwell time component: `dwell_time/30` (normalized to 30 minutes);
(b) Adding review bonus for review given;
(c) Adding repeat bonus for repeat visits;
(d) Adding detail bonus for detailed reviews;
(e) Combining components: `quality = (dwell_time/30) + review_bonus + repeat_bonus + detail_bonus`.

4. An offline-capable automatic check-in system using AI2AI network proximity verification, comprising:
(a) Geofencing detection with 50m radius (background location monitoring);
(b) Bluetooth/AI2AI proximity verification (works without internet);
(c) Dual-trigger verification requiring both geofence and proximity confirmation;
(d) Dwell time calculation with 5-minute minimum threshold;
(e) Quality scoring system with formula: `quality = (dwell_time/30) + review_bonus + repeat_bonus + detail_bonus`.

## Appendix

### Optional companion independent claims (for counsel)

- **System claim (optional):** A system comprising one or more processors and memory storing instructions that, when executed, cause the system to perform the method of claim 1.
- **Non-transitory computer-readable medium claim (optional):** A non-transitory computer-readable medium storing instructions that, when executed by one or more processors, cause the one or more processors to perform the method of claim 1.
