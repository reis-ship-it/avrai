# BLE + Signal Dev Loop (Fast Iteration Protocol)

**Purpose:** Let you iterate on the BLE prekey priming + inbox bootstrap path without re-running the entire test matrix after every small change.

This is the “fast loop” that keeps you productive while the feature is still moving.

---

## The problem this solves

BLE work tends to introduce:
- background timers (`Timer.periodic`)
- MethodChannel calls (not available in `flutter test`)
- long BLE timeouts (connect/discover)

Those can make tests flaky or hang.

So we isolate BLE side-effects in tests by default and provide a small suite for quick validation.

---

## Default behavior (safe)

In tests, BLE side-effects are **disabled by default** unless explicitly enabled.

The orchestrator checks the binding type (test vs app runtime) and only runs BLE inbox polling / BLE reads when allowed.

Override flag:

```bash
--dart-define=SPOTS_ALLOW_BLE_SIDE_EFFECTS_IN_TESTS=true
```

---

## Fast loop commands

### 1) Analyze (must stay 0 errors)

```bash
flutter analyze
```

### 2) Run focused BLE+Signal suite (single-threaded recommended)

```bash
bash /Users/reisgordon/SPOTS/test/suites/ble_signal_suite.sh -j 1
```

This suite includes the hardware-free walk-by regression:
- `test/unit/ai2ai/walkby_hotpath_simulation_test.dart` (no BLE radio required)

**Note on Signal native tests:** Some Signal FFI tests can SIGABRT on macOS during OS-level library unload/finalization (per `PHASE_14_TEST_STRATEGY_AND_SIGABRT.md`). Keep the fast loop focused on orchestration; run native Signal validation only when you’re ready for that slower loop.

---

## When to run the full suite

Run the full suite runner when you hit a milestone like:
- “Stream-1 contract stabilized”
- “Silent bootstrap packet works on device”
- “Inbox polling logic finalized”

```bash
bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh -j 1
```

Playbook completion still requires `all_suites` green twice in a row, but you should **not** do that on every micro-change during active feature development.

