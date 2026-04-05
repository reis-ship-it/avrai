// Google Places API Configuration
// Replace this value with your actual Google Places API key

// Central runtime configuration for Google Places API.
// Values are sourced from compile-time environment where possible to avoid committing secrets.

class GooglePlacesConfig {
  // Prefer passing API key via --dart-define for builds/dev runs
  // e.g., --dart-define=GOOGLE_PLACES_API_KEY=your_api_key_here
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );

  static bool get isValid => apiKey.isNotEmpty;

  /// Get API key (build-time injected)
  ///
  /// **Security:** Never commit real API keys to this repository.
  /// Provide via `--dart-define=GOOGLE_PLACES_API_KEY=...` for development,
  /// and via CI/build secrets for release builds.
  static String getApiKey() {
    return apiKey;
  }
}
