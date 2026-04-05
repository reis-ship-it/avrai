# Location Obfuscation System with Differential Privacy Noise — Claims Draft (NARROW)

**Source spec:** `docs/patents/category_2_offline_privacy_systems/05_location_obfuscation/05_location_location_obfuscation.md`
**Generated:** 2026-01-01

> **NOTE:** Draft for counsel review. This file does not change the underlying spec; it proposes an alternative Claim 1 scope posture.

## Claims

1. A method for location obfuscation with city-level precision and differential privacy noise, comprising:
(a) Rounding coordinates to city-level precision (0.01 degrees ≈ 1km) using formula `rounded = (coordinate / 0.01).round() * 0.01`;
(b) Adding differential privacy noise (0.005 degrees ≈ 500m) using formula `noise = (random.nextDouble() - 0.5) * 2 * 0.005`;
(c) Detecting home locations and preventing sharing in AI2AI network;
(d) Setting 24-hour expiration for obfuscated locations;
(e) Providing admin override for exact location access, wherein comprising:; and wherein further comprising protecting location privacy in AI networks using obfuscation:.

2. A system for multi-layer location obfuscation with privacy protection, comprising:
(a) City-level precision rounding (0.01 degrees ≈ 1km) for coordinate obfuscation;
(b) Differential privacy noise addition (0.005 degrees ≈ 500m) for additional privacy;
(c) Home location detection and blocking to prevent sharing of sensitive addresses;
(d) Temporal expiration (24 hours) for obfuscated locations;
(e) Admin/godmode override for exact location access when authorized.

3. The method of claim 1, further comprising protecting location privacy in AI networks using obfuscation:
(a) Obfuscating exact coordinates to city-level precision (~1km);
(b) Adding differential privacy noise (~500m) to prevent re-identification;
(c) Detecting and blocking home location sharing;
(d) Expiring locations after 24 hours to prevent correlation;
(e) Maintaining city-level accuracy for network matching while protecting exact location.

## Appendix

### Optional companion independent claims (for counsel)

- **System claim (optional):** A system comprising one or more processors and memory storing instructions that, when executed, cause the system to perform the method of claim 1.
- **Non-transitory computer-readable medium claim (optional):** A non-transitory computer-readable medium storing instructions that, when executed by one or more processors, cause the one or more processors to perform the method of claim 1.
