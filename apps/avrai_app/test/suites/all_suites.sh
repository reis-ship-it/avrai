#!/usr/bin/env bash
set -euo pipefail

SUITES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUITE_FILES=(
  "auth_suite.sh"
  "onboarding_suite.sh"
  "spots_lists_suite.sh"
  "search_suite.sh"
  "events_suite.sh"
  "expertise_suite.sh"
  "payment_suite.sh"
  "business_suite.sh"
  "partnership_suite.sh"
  "ai_ml_suite.sh"
  "geographic_suite.sh"
  "security_suite.sh"
  "infrastructure_suite.sh"
)

for suite_file in "${SUITE_FILES[@]}"; do
  echo ""
  echo "============================================================"
  echo "Running suite: ${suite_file}"
  echo "============================================================"
  bash "${SUITES_DIR}/${suite_file}" "$@"
done

