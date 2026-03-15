# Private Agent Infrastructure And Certainty Plan

**Date:** March 9, 2026  
**Status:** Explicit beta infrastructure planning document  
**Scope:** Birmingham beta private higher-agent hosting, hardware baseline, budget categories, and BLE / local Wi-Fi / AI2AI certainty testing

## 1. Normative Status

This document captures infrastructure and test requirements that should be treated as explicit planning inputs for the Birmingham beta build.

It exists so hardware, reliability, BLE, local Wi-Fi, and AI2AI certainty requirements do not remain implicit.

## 2. Intended Hosting Model

### 2.1 Personal agent

Personal reality agent runs on the user device.

### 2.2 Higher agents

For Birmingham beta, the higher-agent hierarchy should run on controlled private infrastructure:

1. locality agents
2. Birmingham city agent
3. top-level reality agent

### 2.3 Admin

The admin app is the control plane, not the always-on cognition host.

### 2.4 Temporary backend support

Supabase is acceptable in beta as:

1. auth
2. relay
3. event / audit store
4. sync support
5. coordination layer

Supabase should not be treated as the long-term cognitive authority host.

## 3. Recommended Beta Hardware Baseline

The discussed Mac Studio configuration is sufficient as the main Birmingham beta higher-agent host:

1. Apple Mac Studio
2. M3 Ultra
3. 32-core CPU
4. 80-core GPU
5. 256GB memory
6. 2TB storage

### 3.1 What it is good enough for

This hardware is more than sufficient for beta-scale:

1. locality-agent hosting
2. Birmingham city-agent hosting
3. top-level reality-agent hosting
4. self-hosted backend services
5. admin-adjacent observability and audit processes
6. local inference experimentation
7. storage of beta-scale learning artifacts and logs

### 3.2 What it is not sufficient for by itself

The Mac Studio should not be assumed to solve locality physical presence by itself.

By itself, it is not enough to guarantee:

1. strong locality BLE coverage across real Birmingham geography
2. meaningful locality-presence sensing everywhere
3. physical radio reach for all desired test environments

BLE/locality presence should be treated as a separate hardware and field-testing concern.

## 4. Recommended Ideal Beta Setup

The ideal Birmingham beta setup should include:

1. one private always-on higher-agent host
2. Wi-Fi connectivity with stable upstream internet
3. UPS / battery backup
4. encrypted disk
5. external backup storage
6. system health monitoring
7. automated restart / watchdog behavior
8. strong admin access controls
9. self-hosted database / relay pathway where practical
10. BLE testing and extension kit

### 4.1 Additional BLE / physical setup

Recommended additional equipment:

1. one or more external BLE radios / adapters for testing
2. BLE range extension / stronger radio hardware for field trials
3. a dedicated Wi-Fi access point for repeatable local-network testing
4. mobile battery packs for field test nodes
5. test phones spanning the approved beta device set
6. distance-measurement tools for repeatable range tests
7. field notebooks / logging rig for physical environment test results

### 4.2 Reliability additions

Recommended reliability additions:

1. UPS sized for controlled shutdown and short outages
2. encrypted external backup drive
3. hardware temperature and resource monitoring
4. remote-access hardening
5. service auto-restart and watchdog alerts

## 5. Budget Update Structure For Birmingham Beta

This section is intentionally structured as a budget update template and planning list.

Current market pricing should be filled in separately before purchase commitments.

### 5.1 Capital hardware

Budget line items:

1. main higher-agent host machine
2. UPS
3. external encrypted backup storage
4. BLE radios / extenders / adapters
5. dedicated Wi-Fi testing equipment
6. spare approved beta devices for QA
7. cables, mounts, and networking accessories

### 5.2 Hosting and software

Budget line items:

1. temporary Supabase usage
2. self-hosted database / relay hosting costs
3. domain / DNS / secure remote admin access
4. monitoring / alerting software costs if any
5. backup / storage replication costs if any

### 5.3 Field-testing and certainty

Budget line items:

1. Birmingham field range testing sessions
2. beta device transportation and staging
3. test logging equipment
4. battery packs / portable power for field nodes
5. replacement hardware margin

### 5.4 Recommended budget framing

The beta budget should separate:

1. must-have launch hardware
2. must-have certainty testing hardware
3. temporary bridge infrastructure
4. nice-to-have expansion hardware

## 6. Core Certainty Principle

BLE, local Wi-Fi, user-to-user relay behavior, and AI2AI behavior should not be assumed.

They must be tested directly in controlled and real Birmingham conditions before they are trusted in the launch gate.

## 7. BLE / Local Wi-Fi / AI2AI Test Matrix

### 7.1 BLE discovery certainty

Required tests:

1. device discovery success rate by device pair
2. discovery latency at multiple distances
3. signal stability indoors versus outdoors
4. discovery behavior through pockets, bags, and body obstruction
5. impact of crowd density and radio noise
6. repeated discovery success over time windows

### 7.2 DNA quick-exchange certainty

Required tests:

1. time to complete lightweight DNA comparison over BLE
2. packet success rate for quick DNA payloads
3. retry behavior on partial transfer
4. data integrity verification on receipt
5. ephemeral deletion verification after comparison
6. note-for-later-sync creation when strong similarity is detected

### 7.3 Local Wi-Fi richer-sync certainty

Required tests:

1. deferred richer exchange completion over local Wi-Fi
2. sync resume after interruption
3. queue behavior when Wi-Fi disappears mid-transfer
4. integrity verification for richer exchange payloads
5. bounded retention and cleanup verification

### 7.4 AI2AI relay certainty

Required tests:

1. store-and-forward behavior when one device is offline
2. delayed delivery after reconnect
3. relay TTL behavior
4. duplicate suppression
5. malicious or malformed payload quarantine
6. contradiction handling and conflict-routing upward

### 7.5 User-to-user behavior over AI2AI transport

Architecture remains AI2AI-first, not direct raw human-to-human cognition exchange.

Required tests:

1. user message creation while offline
2. AI2AI-mediated queueing of that message
3. eventual delivery under relay conditions
4. no identity leakage beyond intended contract
5. clear failure handling when delivery cannot complete

### 7.6 Higher-agent uplink certainty

Required tests:

1. personal-agent upward sharing of bounded truths
2. locality-agent receipt and aggregation
3. locality-to-city propagation
4. city-to-reality propagation
5. privacy-bounded summaries only
6. no direct personal data leakage

### 7.7 Downward guidance certainty

Required tests:

1. locality priors flowing downward to personal agents
2. confidence adjustments flowing downward
3. conflict-resolution heuristics flowing downward
4. opportunity candidates flowing downward
5. conviction challenges flowing downward without bypassing personal-agent judgment

### 7.8 Failure and recovery certainty

Required tests:

1. host reboot recovery
2. service crash recovery
3. Wi-Fi outage behavior
4. BLE adapter failure behavior
5. queue persistence across restart
6. backup restore verification

## 8. Exact Launch-Test Categories

Before trusting the Birmingham beta infrastructure, the following test categories should exist and be passed:

1. radio-range tests
2. packet-integrity tests
3. queue persistence tests
4. AI2AI relay tests
5. higher-agent propagation tests
6. privacy-boundary tests
7. admin observability tests
8. offline-to-online recovery tests
9. certainty-threshold tests for DNA quick-compare and richer sync follow-up
10. field tests in Birmingham environments such as downtown, Avondale, Homewood, Mountain Brook, Hoover, and Vestavia Hills

## 9. Field Test Environments

At minimum, certainty testing should include:

1. quiet indoor environment
2. dense indoor public environment
3. outdoor urban environment
4. moving-device environment
5. car transit / short-distance carryover environment
6. neighborhood-to-neighborhood Birmingham comparison environments

## 10. Admin Observability Requirements

Admin should be able to inspect:

1. higher-agent health
2. queue backlogs
3. BLE discovery success rates
4. DNA quick-compare success rates
5. richer-sync completion rates
6. locality and city propagation success rates
7. contradiction and conflict traffic
8. privacy-boundary violations or attempted violations

## 11. Launch Recommendation

Recommended Birmingham beta infrastructure sequence:

1. stand up the private always-on host
2. run self-hosted supporting services where practical
3. keep Supabase as temporary bridge infrastructure
4. add BLE / local Wi-Fi test kit
5. run controlled lab tests
6. run Birmingham field tests
7. only then trust locality and above-agent pathways for launch-critical behavior
