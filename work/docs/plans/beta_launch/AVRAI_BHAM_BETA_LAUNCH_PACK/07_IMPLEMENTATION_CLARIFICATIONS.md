# Implementation Clarifications

## This Pack Defines Product Intent

This pack captures the intended Birmingham beta contract. Some items still need engineering-level sub-specs before implementation is complete.

## Items That Still Need Lower-Level Specs

### Questionnaire Copy

- exact wording for the 8-12 mandatory direct questions
- which optional questions, if any, are retained under the 20-question hard cap

### Automated Contradiction/Trust Score

- exact formula for external kernel contradiction detection
- how peer/locality/admin evidence weights combine
- quarantine threshold versus reset threshold

### Local Relay TTL

- exact transit expiry windows for store-and-forward payloads
- queue sizing and retry rules

### Offline Footprint

- model pack size target
- Birmingham map/place graph storage budget
- cache eviction rules for lower-priority data

### Admin Authentication And Audit

- secure access control details for the separate admin app
- immutable audit handling for break-glass and quarantine actions

### Device Acceptance

- exact approved-device matrix for iPhone and Android wave-1 testers
- exact degraded-mode behavior if a device falls below target capacity

## Translation Notes

- `Offline` in this beta means `no internet required`, not `single-device isolation only`
- `AI2AI` is the runtime substrate; human p2p is not the architectural authority
- `Admin sharing` remains necessary for beta oversight, but direct human identity remains protected by default
- `Reality-model conviction` can flow downward as a learned lens without automatically forcing user-facing behavior changes
