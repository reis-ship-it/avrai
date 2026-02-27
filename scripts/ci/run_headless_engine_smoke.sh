#!/bin/bash
set -euo pipefail

# Headless smoke gate for core loop surfaces (no app boot path).
# Keep this small and deterministic for CI reliability.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# CI runs from a clean checkout where ignored local files do not exist.
# Bootstrap minimal directories/config + generated artifacts required to compile.
mkdir -p \
  assets/models \
  assets/models/optimized \
  assets/tokenizers \
  assets/three_js/renderers \
  assets/fonts

if [[ ! -f lib/supabase_config.dart ]]; then
  cat > lib/supabase_config.dart <<'EOF'
class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String serviceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const bool debug = bool.fromEnvironment('SUPABASE_DEBUG', defaultValue: false);
  static bool get isValid => url.isNotEmpty && anonKey.isNotEmpty;
}
EOF
fi

if [[ ! -f lib/google_places_config.dart ]]; then
  cat > lib/google_places_config.dart <<'EOF'
class GooglePlacesConfig {
  static const String apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY', defaultValue: '');
  static bool get isValid => apiKey.isNotEmpty;
  static String getApiKey() => apiKey;
}
EOF
fi

if [[ ! -f lib/weather_config.dart ]]; then
  cat > lib/weather_config.dart <<'EOF'
class WeatherConfig {
  static const String apiKey = String.fromEnvironment('OPENWEATHERMAP_API_KEY', defaultValue: '');
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';
  static bool get isValid => apiKey.isNotEmpty;
  static String getApiKey() => apiKey;
  static String getCurrentWeatherUrl(double latitude, double longitude) => '$baseUrl/weather?lat=$latitude&lon=$longitude&appid=${getApiKey()}&units=metric';
  static String getForecastUrl(double latitude, double longitude) => '$baseUrl/forecast?lat=$latitude&lon=$longitude&appid=${getApiKey()}&units=metric';
}
EOF
fi

(cd packages/avrai_core && dart pub get && dart run build_runner build --delete-conflicting-outputs)
(cd packages/avrai_network && dart pub get && dart run build_runner build --delete-conflicting-outputs)
dart run build_runner build \
  --delete-conflicting-outputs \
  --build-filter lib/data/database/app_database.g.dart \
  --build-filter test/unit/ai/continuous_learning_system_phase11_test.mocks.dart

# Main-compatible smoke lane (exists on current main).
flutter test test/unit/ai/continuous_learning_system_test.dart
flutter test test/unit/ai/continuous_learning_system_phase11_test.dart

echo "OK: Headless engine smoke lane passed."
