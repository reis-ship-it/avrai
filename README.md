# AVRAI

**know you belong.**

A privacy-first, offline-capable AI platform that helps people find the places, communities, and people where they truly belong. Powered by AI2AI mesh networking, quantum-inspired matching, and Signal Protocol encryption — all running on-device.

[![GitHub](https://img.shields.io/badge/GitHub-AVRA--CADAVRA-blue)](https://github.com/AVRA-CADAVRA/avrai)
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-blue)](https://dart.dev)
[![Signal](https://img.shields.io/badge/Signal-Protocol-enabled-green)](https://signal.org/)

---

## Philosophy: "Doors, Not Badges"

> **"There is no secret to life. Just doors that haven't been opened yet."**

Every spot is a door. Every person is a door. Every community is a door. Every event is a door. AVRAI is the key — you open the doors, you find your life.

We don't show recommendations. We show doors.
We don't match you with people. We connect you with people who open similar doors.
We don't measure engagement. We measure doors opened.

**The Journey:**
Find YOUR spots &rarr; Those spots have communities &rarr; Those communities have events &rarr; You find YOUR people &rarr; You find YOUR life.

---

## Core Technology

### Intelligence-First Architecture (LeCun World Model)

AVRAI's brain is built on LeCun's autonomous machine intelligence framework. Every hardcoded formula is systematically replaced by learned energy functions trained on real outcome data:

| Component | Role | Implementation |
|-----------|------|----------------|
| **Perception** | Observes the world, extracts features | `WorldModelFeatureExtractor` (145-155D from 19+ services) |
| **World Model** | Predicts next state given current state + action | `TransitionPredictor` (ONNX MLP) |
| **Cost / Critic** | Evaluates quality of state-action pairs as energy | `EnergyFunctionService` (ONNX critic) |
| **Actor** | Proposes action sequences to minimize cost | `MPCPlanner` (N-step future simulation) |
| **Guardrails** | Hard constraints the actor cannot violate | Diversity, safety, doors, notification constraints |
| **Memory** | Episodic, semantic, and procedural memory layers | `EpisodicMemoryStore` + vector embeddings |

### Signal Protocol Security
- **End-to-End Encryption:** X3DH key exchange + Double Ratchet
- **Forward Secrecy:** Post-compromise security with automatic key rotation
- **Hybrid Fallback:** Graceful degradation to AES-256-GCM when needed
- **On-Device Only:** All personal data stays on your device

### AI2AI Mesh Network
- **Offline-First:** Bluetooth Low Energy + WiFi Direct mesh networking
- **Topological Knot Theory:** Personality modeling with string evolution
- **4D Quantum Worldmapping:** Temporal personality state tracking
- **Battery-Adaptive Scheduling:** Intelligent connection orchestration

### Quantum Matching
- **12-Dimensional Personality Vectors:** Quantum state compatibility calculation
- **Multi-Entity Entanglement:** Group compatibility matching
- **Energy Functions:** Learned scoring replaces hardcoded formulas
- **Continuous Learning:** Self-improving AI that adapts from real outcomes

---

## What It Does

**For people looking for their places:**
- Personalized spot recommendations powered by AI that learns your vibe
- Instant compatibility matching with people nearby — even offline
- Build expertise through authentic contributions: curated lists, trusted reviews
- Host events once recognized as a local expert in your community
- Communities and events matched to who you actually are

**Privacy is architecture, not policy:**
- All personal data stays on-device — no surveillance, no data harvesting
- AI learning happens locally — only anonymized, DP-protected signals are ever shared
- Offline discovery works without internet connectivity
- Post-quantum encryption protects everything in transit

---

## Business Capabilities

**Revenue & Partnerships:**
- Event hosting and ticketing with Stripe integration
- Multi-path expertise partnerships with automated revenue distribution
- Business account management for venues, brands, and partners
- Reservation system with recurring bookings and timezone-aware scheduling
- Privacy-preserving analytics for businesses (differential privacy exports)

**Enterprise Infrastructure:**
- White-label deployment options
- AI2AI network monitoring and admin tools
- Web sync hub and desktop platform support
- Restaurant technology integrations (Toast, POS systems)
- Hospitality, government, and finance industry compliance-ready architecture

---

## Innovation Portfolio

**31 Patentable Innovations** including:
- Signal Protocol mesh networking architecture
- Topological knot theory personality modeling
- Quantum atomic clock synchronization
- Battery-adaptive AI2AI scheduling
- Multi-entity quantum entanglement matching
- Intelligence-first energy function architecture

**Status:** 6 Tier 1 patents ready for filing. See [`docs/patents/`](docs/patents/) for complete documentation.

---

## Quick Start

### Prerequisites
- Flutter SDK (3.24+), Dart SDK (3.3+)
- iOS / Android development environment
- Signal Protocol FFI bindings (macOS complete, other platforms pending)

### Installation

```bash
git clone https://github.com/AVRA-CADAVRA/avrai.git
cd avrai
flutter pub get
flutter run
```

### ML Model Setup

```bash
./scripts/ml/setup_models.sh
```

---

## Project Stats

| Metric | Count |
|--------|-------|
| **Lib source lines** | 414,000+ |
| **Test source lines** | 264,000+ |
| **Lib files** | 1,200+ |
| **Test files** | 940+ |
| **Services** | 378+ |
| **Models** | 149+ |
| **Controllers** | 21 |
| **Packages** | 9 (`avrai_core`, `avrai_ai`, `avrai_app`, `avrai_data`, `avrai_knot`, `avrai_ml`, `avrai_network`, `avrai_quantum`, `spots_knot`) |
| **Platforms** | iOS, Android (macOS, Web, Desktop in progress) |

---

## Architecture

**Clean Architecture** with intelligence-first AI and Signal Protocol integration:

- **Core:** AI2AI protocol, quantum algorithms, Signal encryption, world model
- **Data:** Offline-first Sembast, Supabase sync, episodic memory
- **Domain:** Use cases, repository interfaces, energy functions
- **Presentation:** Flutter / BLoC UI with privacy controls
- **Network:** AI2AI mesh with battery-adaptive orchestration
- **ML:** ONNX Runtime models for on-device inference

**Key Technologies:** Flutter, Dart, BLoC, Sembast, Supabase, Firebase, Stripe, ONNX Runtime, Signal Protocol FFI

---

## Documentation

- **Master Plan:** [`docs/MASTER_PLAN.md`](docs/MASTER_PLAN.md) — Intelligence-first execution plan
- **Philosophy:** [`docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md`](docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md)
- **ML Roadmap:** [`docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`](docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md)
- **Signal Protocol:** [`docs/plans/security_implementation/`](docs/plans/security_implementation/)
- **AI2AI Network:** [`docs/plans/ai2ai_system/`](docs/plans/ai2ai_system/)
- **Business Overview:** [`docs/business/SPOTS_COMPREHENSIVE_OVERVIEW.md`](docs/business/SPOTS_COMPREHENSIVE_OVERVIEW.md)
- **Development Guide:** [`README_DEVELOPMENT.md`](README_DEVELOPMENT.md)

---

## Contributing

1. **Read the philosophy:** Understand "Doors, Not Badges" before contributing
2. **Follow the methodology:** See [`docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md`](docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md)
3. **Check the master plan:** See [`docs/MASTER_PLAN.md`](docs/MASTER_PLAN.md) for current priorities
4. **Write tests:** All new features must include tests
5. **Follow code standards:** See `.cursorrules` for coding standards

---

**"There is no secret to life. Just doors that haven't been opened yet."**

*AVRAI is the key. You open the doors. You find your life.*
