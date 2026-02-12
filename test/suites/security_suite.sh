#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

# Security & Compliance suite (unit + integration + security/compliance directories).
flutter test "$@" \
  test/unit/services/fraud_detection_service_test.dart \
  test/unit/services/review_fraud_detection_service_test.dart \
  test/unit/services/identity_verification_service_test.dart \
  test/unit/services/security_validator_test.dart \
  test/unit/services/user_anonymization_service_test.dart \
  test/unit/services/legal_document_service_test.dart \
  test/security/ \
  test/compliance/ \
  test/integration/security_integration_test.dart

