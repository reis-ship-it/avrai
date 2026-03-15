#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"
APP_DIR="$ROOT_DIR/apps/avrai_app"

run_step() {
  printf '\n==> %s\n' "$1"
}

if [[ "${AVRAI_SKIP_APP_TESTS:-0}" != "1" ]]; then
  run_step "Running full apps/avrai_app test package"
  (
    cd "$ROOT_DIR"
    flutter test --no-pub --reporter compact --concurrency=1 apps/avrai_app/test
  )
fi

if [[ "${AVRAI_SKIP_IOS_BUILD:-0}" != "1" ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    run_step "Building iOS simulator app"
    (
      cd "$APP_DIR"
      flutter build ios --simulator --debug --no-codesign
    )
  else
    run_step "Skipping iOS simulator build on non-macOS host"
  fi
fi

if [[ "${AVRAI_SKIP_ANALYZE:-0}" != "1" ]]; then
  run_step "Running workspace analyze"
  (
    cd "$ROOT_DIR"
    melos exec -c 6 -- flutter analyze
  )
fi

if [[ "${AVRAI_SKIP_ARCHITECTURE:-0}" != "1" ]]; then
  run_step "Running architecture boundary check"
  (
    cd "$ROOT_DIR"
    dart run work/scripts/ci/check_architecture.dart
  )
fi

if [[ "${AVRAI_SKIP_REPO_HYGIENE:-0}" != "1" ]]; then
  run_step "Running repo hygiene check"
  (
    cd "$ROOT_DIR"
    dart run work/scripts/ci/check_repo_hygiene.dart
  )
fi
