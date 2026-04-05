# Combined Test Run + Fix + Local Lint Cleanup Playbook
**Date:** January 1, 2026  
**Status:** 🎯 **ACTIVE PROTOCOL**  
**Purpose:** Run domain test suites (Option A) while incrementally reducing warnings/infos (Option B) **without** turning stabilization into a repo-wide refactor.  
**Related:** Phase 6 (Continuous Improvement) + `test/suites/*.sh`

---

## 🎯 Non‑Negotiable Rules (Read First)

1. **Compilation gate:** `flutter analyze` must stay at **0 errors** at all times.
2. **Stabilization scope:** You only “clean lints” in files you touched **because a test failed**.
3. **Runtime failures first:** If a test fails at runtime, fix that first. Do **not** chase style-only lints mid-failure.
4. **Option 1 for `avoid_print`:**
   - ✅ Allowed: add `// ignore_for_file: avoid_print` in **shared test helper** files that intentionally print
   - ❌ Forbidden: disable `avoid_print` globally
   - ❌ Discouraged: add `// ignore: avoid_print` throughout normal test files (unless temporary)
5. **Determinism first:** During stabilization, always run tests with `-j 1`.

---

## 0) One‑Time Setup Checklist

- [ ] Confirm suites exist: `test/suites/*.sh`
- [ ] Confirm analysis baseline:

```bash
flutter analyze
```

✅ Proceed only if errors = **0**.

---

## 1) Choose Your Suite Order (Recommended)

Run small/core suites first to reduce blast radius.

**Recommended order:**
1. `infrastructure_suite.sh`
2. `auth_suite.sh`
3. `onboarding_suite.sh`
4. `security_suite.sh`
5. `events_suite.sh`
6. `payment_suite.sh`
7. `partnership_suite.sh`
8. `expertise_suite.sh`
9. `business_suite.sh`
10. `search_suite.sh`
11. `geographic_suite.sh`
12. `spots_lists_suite.sh`
13. `ai_ml_suite.sh`
14. `all_suites.sh` (only after the above are green)

---

## 2) The Core Loop (Follow This Exactly)

### Step A — Run one suite (Option A)

Pick a suite and run it with single-threaded execution:

```bash
bash /Users/reisgordon/SPOTS/test/suites/<SUITE_NAME>.sh -j 1
```

**Examples:**

```bash
bash /Users/reisgordon/SPOTS/test/suites/infrastructure_suite.sh -j 1
bash /Users/reisgordon/SPOTS/test/suites/auth_suite.sh -j 1
```

### Step B — If it FAILS: fix only what’s needed

For the failing suite, do **exactly** this triage:

#### B1) Identify the failure type

- **Type 1: Compile / analyzer error**
  - Action: run:
    ```bash
    flutter analyze
    ```
  - Fix until errors = 0 again.

- **Type 2: Runtime test failure** (assertion failed, exception, timeout)
  - Action: re-run **only the failing test file**:
    ```bash
    flutter test /Users/reisgordon/SPOTS/<path-to-failing-test>.dart -j 1
    ```
  - Fix until that single test file passes.

- **Type 3: Flake / timing**
  - Action: re-run the failing test multiple times:
    ```bash
    flutter test /Users/reisgordon/SPOTS/<path-to-failing-test>.dart -j 1
    ```
  - Fix by making time deterministic (fake clocks/timers), avoiding reliance on timers/network/real plugins.

- **Type 4: Environment / plugin dependency**
  - Action: replace plugin reliance with test-friendly mechanisms (existing `MockGetStorage` + `SharedPreferencesCompat`, in-memory fallbacks, fakes).

#### B2) “Touched-files lint cleanup” (Option B, scoped)

After the failing test file passes, do **local cleanup only in files you touched**:

**Fix immediately (fast, low-risk):**
- `unused_import`
- `dead_code`
- `unused_local_variable`
- trivial `unused_field` in test files

**Defer unless you’re already editing that line:**
- `prefer_const_declarations`
- “formatting / style” infos

### Step C — Re-run the suite

Re-run the suite you started with:

```bash
bash /Users/reisgordon/SPOTS/test/suites/<SUITE_NAME>.sh -j 1
```

✅ Only when it is green do you move to the next suite.

### Step D — Keep analysis from regressing

After each suite turns green (or after a batch of fixes), run:

```bash
flutter analyze
```

✅ Continue only if errors = **0**.

---

## 3) Option 1: How to Handle `avoid_print` (Exactly)

### Goal
Stop `avoid_print` from exploding into hundreds of “info” issues during stabilization, while **still preventing `print()` in production code**.

### Allowed change (Option 1)
If a file is a **shared test helper** used by many tests and it intentionally prints diagnostic output:

Add this at the top of the helper file:

```dart
// ignore_for_file: avoid_print
```

### Where this is typically allowed
- `test/**/helpers/*.dart`
- `test/widget/helpers/*.dart`

### Where this is NOT allowed
- `lib/**` (production code)
- normal test files unless absolutely necessary (prefer removing prints or using test-only patterns)

---

## 4) Logging / Tracking (Simple but Mandatory)

After each suite run, append a short entry to `test/testing/results.md`:

- [ ] suite name
- [ ] pass/fail
- [ ] failing test file(s)
- [ ] summary of fix categories (runtime vs compile vs flake)

This prevents “fixing the same thing twice” next session.

---

## 5) Exit Criteria (When This Protocol Is “Done”)

You are done with stabilization when:
- [ ] `bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh -j 1` is green **twice in a row**
- [ ] `flutter analyze` stays at **0 errors**

Only after that should you consider a repo-wide lint cleanup pass.

---

## 6) Optional “After Stabilization” Cleanup Pass (Do Later)

If you want to reduce warnings/infos systematically:
- Do it as a dedicated phase, broken down by categories (unused imports, dead code, const suggestions, etc.)
- Keep it separate from suite stabilization so you don’t mix runtime changes with mechanical cleanup.

