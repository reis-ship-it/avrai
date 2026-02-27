#!/bin/bash
set -euo pipefail

# Headless smoke gate for core loop surfaces (no app boot path).
# Keep this small and deterministic for CI reliability.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Main-compatible smoke lane (exists on current main).
flutter test test/unit/ai/continuous_learning_system_test.dart
flutter test test/unit/ai/continuous_learning_system_phase11_test.dart

echo "OK: Headless engine smoke lane passed."
