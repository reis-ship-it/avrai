# AVRAI System Architecture

This file serves as the definitive map of the AVRAI codebase. It exists so that anyone opening the repository instantly understands *what* belongs *where*.

## The 3-Prong Isolation Strategy

AVRAI is strictly separated into **4 root domains** to ensure deterministic execution, privacy, and architectural purity. Under no circumstances should dependencies flow backwards (e.g., the Engine cannot import the Runtime).

### 🖥️ 1. `apps/` (User Experience & UI Surfaces)
Holds the visible product shells. These shells are extremely thin and contain almost no logic.
- **`apps/consumer_app/`**: The primary user application.
- **`apps/admin_app/`**: Internal governance controls.
- **Rule:** May only import from `runtime/` and `shared/`.

### ⚡ 2. `runtime/` (The Operating System)
Orchestrates events, network calls, device hardware access, and local storage. This is the nervous system.
- **`runtime/avrai_network/`**: Bluetooth, APIs, and connectivity logic.
- **`runtime/avrai_data/`**: Local persistence and SQLite schemas.
- **`runtime/avrai_runtime_os/`**: Service locators, event dispatchers, and external system integrations.
- **Rule:** May only import from `engine/` and `shared/`. **No UI logic allowed.**

### 🧠 3. `engine/` (The Truth Models)
Contains pure-Dart, deterministic mathematics, ML topology, AI calculations, and domain logic.
- **`engine/avrai_knot/`**: Topological knot calculations.
- **`engine/avrai_ml/`**: On-device neural inference and predictive models.
- **`engine/avrai_ai/`**: Agent logic and chat intelligence.
- **`engine/avrai_quantum/`**: Quantum state algorithms.
- **`engine/reality_engine/`**: The central computational core.
- **Rule:** May only import from `shared/`. **No Flutter SDK dependencies allowed. Pure Dart only.**

### 🧱 4. `shared/` (Contracts & Primitives)
The foundational types that the rest of the app agrees upon.
- **`shared/avrai_core/`**: Abstract interfaces, enums, constants, and data primitives.
- **Rule:** The absolute bottom of the dependency graph. Cannot import any other PRONG.

---

## Workspace Hygiene Rules

To maintain the pristine nature of the root directory:
1. **Raw ML Data/Weights:** Do not store loose `.onnx` or `.json` models in the root. Use `assets/ml_data/` or `assets/ml_models/`.
2. **Scripts & Automation:** Do not scatter `.py` or `.sh` files in the root. Group all dev-ops into `scripts/`.
3. **Sub-Packages:** Sub-packages must be placed directly into the proper `engine/` or `runtime/` folder. Do not create isolated `packages/` holding folders.
