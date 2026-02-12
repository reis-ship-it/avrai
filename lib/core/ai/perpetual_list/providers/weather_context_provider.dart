// Weather Context Provider
//
// Phase 4.4: Weather-aware list suggestions
//
// Purpose: Adjust suggestions based on weather conditions

import 'dart:developer' as developer;

import 'package:avrai/weather_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Weather Context Provider
///
/// Provides weather context for list generation.
/// Adjusts place suggestions based on current and forecasted weather.
///
/// Part of Phase 4.4: Weather-Aware Suggestions

class WeatherContextProvider {
  static const String _logName = 'WeatherContextProvider';

  /// Category adjustments based on weather
  static const Map<String, List<String>> weatherCategoryBoosts = {
    'rainy': ['cafes', 'museums', 'shopping', 'entertainment'],
    'sunny': ['parks', 'outdoors', 'bars', 'restaurants'],
    'cold': ['cafes', 'wellness', 'entertainment', 'cultural'],
    'hot': ['cafes', 'shopping', 'wellness'],
    'snowy': ['cafes', 'museums', 'entertainment'],
  };

  /// Category penalties based on weather
  static const Map<String, List<String>> weatherCategoryPenalties = {
    'rainy': ['parks', 'outdoors', 'sports'],
    'cold': ['parks', 'outdoors'],
    'hot': ['outdoors', 'sports'],
    'snowy': ['parks', 'outdoors', 'sports'],
  };

  final http.Client _httpClient;
  
  // Location-aware cached weather data
  // Key format: "lat,lon" (rounded to 2 decimal places for ~1km precision)
  final Map<String, WeatherCondition> _cachedConditions = {};
  final Map<String, DateTime> _cacheTimes = {};
  static const Duration _cacheDuration = Duration(minutes: 30);
  static const int _maxCacheEntries = 10;

  WeatherContextProvider({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();
  
  /// Generate cache key from coordinates (rounded to ~1km precision)
  String _cacheKey(double lat, double lon) =>
      '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';

  /// Get current weather condition for a location
  /// 
  /// Returns cached weather if available and not expired.
  /// Returns null if API key is not configured or on error.
  Future<WeatherCondition?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final key = _cacheKey(latitude, longitude);
    
    // Check cache
    final cachedCondition = _cachedConditions[key];
    final cacheTime = _cacheTimes[key];
    if (cachedCondition != null && cacheTime != null) {
      if (DateTime.now().difference(cacheTime) < _cacheDuration) {
        developer.log('Using cached weather for $key', name: _logName);
        return cachedCondition;
      }
    }

    if (!WeatherConfig.isValid) {
      developer.log(
        'Weather API key not configured, skipping weather context',
        name: _logName,
      );
      return null;
    }

    try {
      final url = WeatherConfig.getCurrentWeatherUrl(latitude, longitude);
      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final condition = WeatherCondition.fromOpenWeatherMap(data);
        
        // Cache result (with cleanup if cache is full)
        _cleanupCacheIfNeeded();
        _cachedConditions[key] = condition;
        _cacheTimes[key] = DateTime.now();
        
        developer.log(
          'Weather for $key: ${condition.description} (${condition.temperature}°C)',
          name: _logName,
        );
        
        return condition;
      } else {
        developer.log(
          'Weather API error: ${response.statusCode}',
          name: _logName,
        );
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching weather',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }
  
  /// Cleanup oldest cache entries if cache is full
  void _cleanupCacheIfNeeded() {
    if (_cachedConditions.length >= _maxCacheEntries) {
      // Find oldest entry
      String? oldestKey;
      DateTime? oldestTime;
      for (final entry in _cacheTimes.entries) {
        if (oldestTime == null || entry.value.isBefore(oldestTime)) {
          oldestKey = entry.key;
          oldestTime = entry.value;
        }
      }
      if (oldestKey != null) {
        _cachedConditions.remove(oldestKey);
        _cacheTimes.remove(oldestKey);
      }
    }
  }

  /// Get category score adjustments based on weather conditions
  /// 
  /// Returns a map of category names to score adjustments (-1.0 to 1.0).
  /// Positive values boost the category, negative values penalize it.
  /// 
  /// **Example:**
  /// ```dart
  /// final weather = await provider.getCurrentWeather(...);
  /// if (weather != null) {
  ///   final adjustments = provider.getCategoryAdjustments(weather);
  ///   // adjustments['parks'] might be -0.3 if rainy
  /// }
  /// ```
  Map<String, double> getCategoryAdjustments(WeatherCondition condition) {
    final adjustments = <String, double>{};
    final weatherType = condition.getWeatherType();

    // Apply boosts
    final boosts = weatherCategoryBoosts[weatherType];
    if (boosts != null) {
      for (final category in boosts) {
        adjustments[category] = (adjustments[category] ?? 0) + 0.2;
      }
    }

    // Apply penalties
    final penalties = weatherCategoryPenalties[weatherType];
    if (penalties != null) {
      for (final category in penalties) {
        adjustments[category] = (adjustments[category] ?? 0) - 0.3;
      }
    }

    return adjustments;
  }

  /// Check if outdoor activities are recommended
  bool isOutdoorFriendly(WeatherCondition condition) {
    final weatherType = condition.getWeatherType();
    return weatherType == 'sunny' &&
        condition.temperature > 10 &&
        condition.temperature < 30;
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Weather condition data
class WeatherCondition {
  /// Main weather condition (e.g., 'Rain', 'Clear', 'Clouds')
  final String main;

  /// Description (e.g., 'light rain', 'clear sky')
  final String description;

  /// Temperature in Celsius
  final double temperature;

  /// Feels like temperature in Celsius
  final double feelsLike;

  /// Humidity percentage
  final int humidity;

  /// Wind speed in m/s
  final double windSpeed;

  /// Cloudiness percentage
  final int clouds;

  /// Visibility in meters
  final int visibility;

  const WeatherCondition({
    required this.main,
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.clouds,
    required this.visibility,
  });

  /// Create from OpenWeatherMap API response
  /// 
  /// Throws [FormatException] if response is malformed.
  factory WeatherCondition.fromOpenWeatherMap(Map<String, dynamic> json) {
    try {
      // Validate required fields
      final weatherList = json['weather'] as List?;
      if (weatherList == null || weatherList.isEmpty) {
        throw const FormatException('Missing weather data in API response');
      }
      
      final weather = weatherList.first as Map<String, dynamic>?;
      final mainData = json['main'] as Map<String, dynamic>?;
      final wind = json['wind'] as Map<String, dynamic>?;
      final clouds = json['clouds'] as Map<String, dynamic>?;
      
      if (weather == null || mainData == null) {
        throw const FormatException('Missing required weather fields');
      }

      return WeatherCondition(
        main: weather['main'] as String? ?? 'Unknown',
        description: weather['description'] as String? ?? 'Unknown',
        temperature: (mainData['temp'] as num?)?.toDouble() ?? 0.0,
        feelsLike: (mainData['feels_like'] as num?)?.toDouble() ?? 0.0,
        humidity: mainData['humidity'] as int? ?? 0,
        windSpeed: (wind?['speed'] as num?)?.toDouble() ?? 0.0,
        clouds: clouds?['all'] as int? ?? 0,
        visibility: json['visibility'] as int? ?? 10000,
      );
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Invalid weather API response: $e');
    }
  }

  /// Get weather type for category adjustments
  String getWeatherType() {
    final mainLower = main.toLowerCase();

    if (mainLower.contains('rain') || mainLower.contains('drizzle')) {
      return 'rainy';
    }
    if (mainLower.contains('snow')) {
      return 'snowy';
    }
    if (temperature < 10) {
      return 'cold';
    }
    if (temperature > 30) {
      return 'hot';
    }
    if (mainLower.contains('clear') || mainLower.contains('sun')) {
      return 'sunny';
    }

    return 'moderate';
  }
}
