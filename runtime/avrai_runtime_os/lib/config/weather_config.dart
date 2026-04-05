// OpenWeatherMap API Configuration
// Replace this value with your actual OpenWeatherMap API key

// Central runtime configuration for OpenWeatherMap API.
// Values are sourced from compile-time environment where possible to avoid committing secrets.

class WeatherConfig {
  // Prefer passing API key via --dart-define for builds/dev runs
  // e.g., --dart-define=OPENWEATHERMAP_API_KEY=your_api_key_here
  static const String apiKey = String.fromEnvironment(
    'OPENWEATHERMAP_API_KEY',
    defaultValue: '',
  );

  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  static bool get isValid => apiKey.isNotEmpty;

  /// Get API key with fallback to direct value (for development)
  /// In production, always use environment variable
  ///
  /// To get a free API key:
  /// 1. Sign up at https://openweathermap.org/api
  /// 2. Free tier: 1,000 calls/day, 60 calls/minute
  /// 3. Set API key via environment variable or here for development
  static String getApiKey() {
    if (apiKey.isNotEmpty) {
      return apiKey;
    }

    // Fallback: You can set your API key here directly for development
    // WARNING: Never commit this file with a real API key!
    //
    // To set your API key:
    // Option 1 (Recommended): Use environment variable when running:
    //   flutter run --dart-define=OPENWEATHERMAP_API_KEY=your_key_here
    //
    // Option 2 (Development only): Replace the empty string below with your key
    //   return 'your_api_key_here';
    //
    // ⚠️ IMPORTANT: If you use Option 2, make sure this file is in .gitignore!
    return ''; // Provide via --dart-define=OPENWEATHERMAP_API_KEY=your_key_here
  }

  /// Get current weather endpoint URL
  static String getCurrentWeatherUrl(double latitude, double longitude) {
    return '$baseUrl/weather?lat=$latitude&lon=$longitude&appid=${getApiKey()}&units=metric';
  }

  /// Get weather forecast endpoint URL
  static String getForecastUrl(double latitude, double longitude) {
    return '$baseUrl/forecast?lat=$latitude&lon=$longitude&appid=${getApiKey()}&units=metric';
  }
}
