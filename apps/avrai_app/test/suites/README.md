# Test Suites (Grouped Test Runs)

This folder provides **domain-oriented** test commands so you can run related tests together without needing to remember lots of individual paths.

These suites intentionally point at the **canonical** unit-test layout we’re standardizing on:

- `test/unit/domain/**` (Domain layer tests)
- `test/unit/data/**` (Data layer tests)

## Usage

Run a suite with:

```bash
bash /Users/reisgordon/SPOTS/test/suites/auth_suite.sh
bash /Users/reisgordon/SPOTS/test/suites/onboarding_suite.sh
bash /Users/reisgordon/SPOTS/test/suites/spots_lists_suite.sh
bash /Users/reisgordon/SPOTS/test/suites/ble_signal_suite.sh
```

Pass through any `flutter test` flags (they will be forwarded), e.g.:

```bash
bash /Users/reisgordon/SPOTS/test/suites/auth_suite.sh --coverage
bash /Users/reisgordon/SPOTS/test/suites/onboarding_suite.sh -j 1
```

## Run everything

```bash
bash /Users/reisgordon/SPOTS/test/suites/all_suites.sh
```

## Notes

- These suites are designed to be **stable** and **readable**. They run a curated set of paths per domain (unit + widget + integration).
- If a path moves during cleanup, only the relevant suite script needs updating.

