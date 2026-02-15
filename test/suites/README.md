# Test Suites (Grouped Test Runs)

This folder provides **domain-oriented** test commands so you can run related tests together without needing to remember lots of individual paths.

These suites intentionally point at the **canonical** grouped-test layout:

- `test/unit/domain/**` (Domain layer tests)
- `test/unit/data/**` (Data layer tests)
- `test/integration/<domain>/**` (Domainized integration tests)
- `test/widget/design/**` + `tool/design_guardrails.dart` (Design regression gate)

## Usage

Run a suite with:

```bash
bash test/suites/auth_suite.sh
bash test/suites/onboarding_suite.sh
bash test/suites/spots_lists_suite.sh
bash test/suites/ble_signal_suite.sh
bash test/suites/design_suite.sh
```

Pass through any `flutter test` flags (they will be forwarded), e.g.:

```bash
bash test/suites/auth_suite.sh --coverage
bash test/suites/onboarding_suite.sh -j 1
```

## Run everything

```bash
bash test/suites/all_suites.sh
```

## Notes

- These suites are designed to be **stable** and **readable**. They run a curated set of paths per domain (unit + widget + integration).
- `design_suite.sh` enforces grouped design coverage and should remain part of full grouped runs.
- If a path moves during cleanup, only the relevant suite script needs updating.
