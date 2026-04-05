# Location Inference from Agent Network Consensus System — Claims Draft (BROAD)

**Source spec:** `docs/patents/category_6_location_context_systems/01_location_inference_agent_network/01_location_inference_agent_network.md`
**Generated:** 2026-01-01

> **NOTE:** Draft for counsel review. This file does not change the underlying spec; it proposes an alternative Claim 1 scope posture.

## Claims

1. A method for inferring user location from AI2AI agent network consensus when VPN/proxy masks IP geolocation, comprising:
(a) Detecting VPN/proxy usage through network configuration analysis;
(b) Discovering nearby AI2AI agents via physical proximity (Bluetooth/WiFi);
(c) Calculating proximity scores for discovered agents;
(d) Filtering agents by proximity threshold (> a threshold value) to ensure physical proximity;
(e) Extracting obfuscated city-level locations from nearby agents.

2. A privacy-preserving location inference system using proximity-based agent discovery and consensus algorithms, comprising:
(a) Bluetooth/WiFi agent discovery module finding nearby agents via physical proximity;
(b) Proximity scoring module calculating proximity scores based on signal strength;
(c) Proximity filtering module ensuring only agents with proximity score > 0.5 considered;
(d) Obfuscated location extraction module extracting city-level locations from agents;
(e) Location aggregation module counting occurrences of each location;
(f) Majority consensus algorithm determining location by majority vote;
(g) 60% confidence threshold requiring at least 60% of agents to agree;
(h) Privacy-preserving implementation using only obfuscated city-level locations.

3. The method of claim 1, further comprising accurate location determination when VPN/proxy masks IP geolocation:
(a) Detecting VPN/proxy usage to identify when IP geolocation is unreliable;
(b) Discovering nearby AI2AI agents via Bluetooth/WiFi physical proximity;
(c) Calculating proximity scores and filtering agents (proximity > 0.5);
(d) Extracting obfuscated city-level locations from filtered agents;
(e) Aggregating agent locations and counting occurrences;
(f) Determining location by consensus with confidence calculation: `confidence = top_location_count / total_agents`;
(g) Requiring confidence >= 0.6 for location inference;
(h) Automatically falling back to IP geolocation if consensus unavailable.

4. A location inference system that overrides VPN/proxy IP geolocation using AI2AI agent network consensus, comprising:
(a) VPN/proxy detection module identifying when IP geolocation is unreliable;
(b) Proximity-based agent discovery module finding nearby agents via Bluetooth/WiFi;
(c) Obfuscated location extraction module extracting city-level locations;
(d) Majority consensus algorithm with 60% confidence threshold;
(e) Location priority system: agent network consensus → IP geolocation → user-provided;
(f) Automatic fallback mechanism when consensus unavailable;
(g) Privacy-preserving implementation with opt-in/opt-out control.

## Appendix

### Optional companion independent claims (for counsel)

- **System claim (optional):** A system comprising one or more processors and memory storing instructions that, when executed, cause the system to perform the method of claim 1.
- **Non-transitory computer-readable medium claim (optional):** A non-transitory computer-readable medium storing instructions that, when executed by one or more processors, cause the one or more processors to perform the method of claim 1.
