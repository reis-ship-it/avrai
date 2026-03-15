#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"
APP_DIR="$ROOT_DIR/apps/avrai_app"

mkdir -p \
  "$APP_DIR/assets/models" \
  "$APP_DIR/assets/models/optimized" \
  "$APP_DIR/assets/tokenizers" \
  "$APP_DIR/assets/three_js/renderers" \
  "$APP_DIR/assets/fonts"

if [[ ! -f "$APP_DIR/lib/supabase_config.dart" ]]; then
  cat >"$APP_DIR/lib/supabase_config.dart" <<'EOF'
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

if [[ ! -f "$APP_DIR/lib/google_places_config.dart" ]]; then
  cat >"$APP_DIR/lib/google_places_config.dart" <<'EOF'
class GooglePlacesConfig {
  static const String apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY', defaultValue: '');
  static bool get isValid => apiKey.isNotEmpty;
  static String getApiKey() => apiKey;
}
EOF
fi

if [[ ! -f "$APP_DIR/lib/weather_config.dart" ]]; then
  cat >"$APP_DIR/lib/weather_config.dart" <<'EOF'
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

(cd "$ROOT_DIR/shared/avrai_core" && dart pub get && dart run build_runner build --delete-conflicting-outputs)
(cd "$ROOT_DIR/runtime/avrai_network" && dart pub get && dart run build_runner build --delete-conflicting-outputs)
(cd "$APP_DIR" && flutter pub get)
(cd "$APP_DIR" && dart run build_runner build \
  --delete-conflicting-outputs \
  --build-filter lib/data/database/app_database.g.dart \
  --build-filter test/unit/ai2ai/connection_orchestrator_test.mocks.dart)
