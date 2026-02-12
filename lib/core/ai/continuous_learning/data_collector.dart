import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:avrai/weather_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';

/// Collects learning data from all available sources
///
/// Responsible for gathering data from 10 different sources:
/// - User actions
/// - Location data
/// - Weather conditions
/// - Time patterns
/// - Social connections
/// - Age demographics
/// - App usage patterns
/// - Community interactions
/// - AI2AI communications
/// - External context
class LearningDataCollector {
  static const String _logName = 'LearningDataCollector';
  final AgentIdService _agentIdService;

  LearningDataCollector({
    required AgentIdService agentIdService,
  }) : _agentIdService = agentIdService;

  /// Collects learning data from all available sources
  Future<LearningData> collectLearningData() async {
    try {
      final userActions = await collectUserActions();
      final locationData = await collectLocationData();
      final weatherData = await collectWeatherData();
      final timeData = await collectTimeData();
      final socialData = await collectSocialData();
      final demographicData = await collectDemographicData();
      final appUsageData = await collectAppUsageData();
      final communityData = await collectCommunityData();
      final ai2aiData = await collectAI2AIData();
      final externalData = await collectExternalData();

      return LearningData(
        userActions: userActions,
        locationData: locationData,
        weatherData: weatherData,
        timeData: timeData,
        socialData: socialData,
        demographicData: demographicData,
        appUsageData: appUsageData,
        communityData: communityData,
        ai2aiData: ai2aiData,
        externalData: externalData,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error collecting learning data: $e', name: _logName);
      return LearningData.empty();
    }
  }

  /// Collect user actions from analytics/database
  Future<List<dynamic>> collectUserActions() async {
    try {
      final actions = <dynamic>[];

      // Note: Firebase Analytics doesn't provide a direct way to query events
      // In a real implementation, you would:
      // 1. Log events as they happen: FirebaseAnalytics.instance.logEvent(name: 'spot_visited', parameters: {...})
      // 2. Store events in your database for querying
      // 3. Query your database here to get recent actions

      // For now, we'll log that we're collecting and return empty
      // The actual tracking should happen at the point of user interaction
      developer.log('Collecting user actions from Firebase Analytics',
          name: _logName);

      // TODO: Query your database for recent user actions
      // This would include:
      // - Spot visits (tracked via analytics.logEvent('spot_visited'))
      // - List interactions (tracked via analytics.logEvent('list_viewed'))
      // - Search queries (tracked via analytics.logEvent('search_performed'))
      // - Preference changes (tracked via analytics.logEvent('preference_changed'))

      return actions;
    } catch (e) {
      developer.log('Error collecting user actions: $e', name: _logName);
      return [];
    }
  }

  /// Collect location data from device location services
  Future<List<dynamic>> collectLocationData() async {
    try {
      final locationData = <dynamic>[];

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('Location services are disabled', name: _logName);
        return [];
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          developer.log('Location permissions denied', name: _logName);
          return [];
        }
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log('Location permissions permanently denied',
            name: _logName);
        return [];
      }

      // Get current position
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Location request timed out'),
        );

        locationData.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'speed': position.speed,
          'heading': position.heading,
          'timestamp': position.timestamp.toIso8601String(),
          'type': 'current',
        });

        developer.log(
            'Collected current location: ${position.latitude}, ${position.longitude}',
            name: _logName);
      } catch (e) {
        developer.log('Error getting current position: $e', name: _logName);
      }

      // TODO: Get location history from database
      // This would include:
      // - Recent locations (stored when user visits spots)
      // - Movement patterns (calculated from location history)
      // - Frequent locations (derived from visit frequency)

      return locationData;
    } catch (e) {
      developer.log('Error collecting location data: $e', name: _logName);
      return [];
    }
  }

  /// Collect weather data from OpenWeatherMap API
  Future<List<dynamic>> collectWeatherData() async {
    try {
      if (!WeatherConfig.isValid) {
        developer.log('OpenWeatherMap API key not configured', name: _logName);
        return [];
      }

      final weatherData = <dynamic>[];

      // Get current location first (needed for weather API)
      final locationData = await collectLocationData();
      if (locationData.isEmpty) {
        developer.log('No location data available for weather collection',
            name: _logName);
        return [];
      }

      final currentLocation = locationData.first as Map<String, dynamic>;
      final latitude = currentLocation['latitude'] as double;
      final longitude = currentLocation['longitude'] as double;

      // Fetch current weather
      try {
        final currentWeatherUrl =
            WeatherConfig.getCurrentWeatherUrl(latitude, longitude);
        final response = await http.get(Uri.parse(currentWeatherUrl)).timeout(
              const Duration(seconds: 10),
            );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;

          weatherData.add({
            'type': 'current',
            'temperature':
                (data['main'] as Map<String, dynamic>)['temp'] as double,
            'feels_like':
                (data['main'] as Map<String, dynamic>)['feels_like'] as double,
            'humidity':
                (data['main'] as Map<String, dynamic>)['humidity'] as int,
            'pressure':
                (data['main'] as Map<String, dynamic>)['pressure'] as int,
            'conditions': ((data['weather'] as List)[0]
                as Map<String, dynamic>)['main'] as String,
            'description': ((data['weather'] as List)[0]
                as Map<String, dynamic>)['description'] as String,
            'wind_speed':
                (data['wind'] as Map<String, dynamic>?)?['speed'] as double? ??
                    0.0,
            'cloudiness':
                (data['clouds'] as Map<String, dynamic>)['all'] as int,
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': DateTime.now().toIso8601String(),
          });

          developer.log(
              'Collected current weather: ${weatherData.first['conditions']}',
              name: _logName);
        } else {
          developer.log('Weather API error: ${response.statusCode}',
              name: _logName);
        }
      } catch (e) {
        developer.log('Error fetching current weather: $e', name: _logName);
      }

      // Fetch weather forecast (optional, can be rate-limited)
      try {
        final forecastUrl = WeatherConfig.getForecastUrl(latitude, longitude);
        final response = await http.get(Uri.parse(forecastUrl)).timeout(
              const Duration(seconds: 10),
            );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final forecasts = data['list'] as List;

          // Add first 3 forecast entries (next 24 hours)
          for (int i = 0; i < math.min(3, forecasts.length); i++) {
            final forecast = forecasts[i] as Map<String, dynamic>;
            weatherData.add({
              'type': 'forecast',
              'temperature':
                  (forecast['main'] as Map<String, dynamic>)['temp'] as double,
              'conditions': ((forecast['weather'] as List)[0]
                  as Map<String, dynamic>)['main'] as String,
              'timestamp': DateTime.fromMillisecondsSinceEpoch(
                (forecast['dt'] as int) * 1000,
              ).toIso8601String(),
            });
          }
        }
      } catch (e) {
        developer.log('Error fetching weather forecast: $e', name: _logName);
        // Don't fail if forecast fails, current weather is more important
      }

      return weatherData;
    } catch (e) {
      developer.log('Error collecting weather data: $e', name: _logName);
      return [];
    }
  }

  /// Collect time-based data
  Future<List<dynamic>> collectTimeData() async {
    try {
      // Collect time-based context
      final now = DateTime.now();
      return [
        {
          'timestamp': now.toIso8601String(),
          'hour': now.hour,
          'day_of_week': now.weekday,
          'day_of_month': now.day,
          'month': now.month,
          'year': now.year,
          'is_weekend': now.weekday >= 6,
          'time_of_day': _getTimeOfDay(now.hour),
        }
      ];
    } catch (e) {
      developer.log('Error collecting time data: $e', name: _logName);
      return [];
    }
  }

  /// Get time of day category
  String _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  /// Collect social interaction data from database
  Future<List<dynamic>> collectSocialData() async {
    try {
      final supabase = Supabase.instance.client;

      // Get current user ID from Supabase auth
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        developer.log('No authenticated user, skipping social data collection',
            name: _logName);
        return [];
      }

      final userId = currentUser.id;

      final socialData = <dynamic>[];

      // Query user_respects (user's respects for spots and lists)
      try {
        final respects = await supabase
            .from('user_respects')
            .select('*, spots(*), spot_lists(*)')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(50);

        socialData.addAll(
          respects.map((r) => {'type': 'respect', 'data': r}),
        );
      } catch (e) {
        developer.log('Error querying user_respects: $e', name: _logName);
      }

      // Query user_follows (users this user follows)
      try {
        final follows = await supabase
            .from('user_follows')
            .select('*, following_user:users!user_follows_following_id_fkey(*)')
            .eq('follower_id', userId)
            .limit(50);

        socialData.addAll(
          follows.map((f) => {'type': 'follow', 'data': f}),
        );
      } catch (e) {
        developer.log('Error querying user_follows: $e', name: _logName);
      }

      // TODO: Add queries for comments and shares tables when they are created

      developer.log(
        'Collected social data: ${socialData.length} items',
        name: _logName,
      );

      return socialData;
    } catch (e) {
      developer.log('Error collecting social data: $e', name: _logName);
      return [];
    }
  }

  /// Collect demographic data
  Future<List<dynamic>> collectDemographicData() async {
    try {
      // TODO: Connect to user profile service
      // This would collect:
      // - Age group
      // - Gender
      // - Location demographics
      // - Cultural background
      // - Language preferences

      // For now, return empty list - will be populated when profile service is connected
      return [];
    } catch (e) {
      developer.log('Error collecting demographic data: $e', name: _logName);
      return [];
    }
  }

  /// Collect app usage data from interaction_events table
  Future<List<dynamic>> collectAppUsageData() async {
    try {
      final supabase = Supabase.instance.client;

      // Get current user ID from Supabase auth
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        developer.log(
            'No authenticated user, skipping app usage data collection',
            name: _logName);
        return [];
      }

      final agentId = await _agentIdService.getUserAgentId(currentUser.id);

      // Query interaction_events table
      final events = await supabase
          .from('interaction_events')
          .select('*')
          .eq('agent_id', agentId)
          .order('timestamp', ascending: false)
          .limit(100);

      // Aggregate by event type
      final aggregated = <String, Map<String, dynamic>>{};
      for (final event in events) {
        final type = event['event_type'] as String;
        if (!aggregated.containsKey(type)) {
          aggregated[type] = {
            'event_type': type,
            'count': 0,
            'total_duration': 0,
            'last_occurrence': event['timestamp'],
          };
        }
        aggregated[type]!['count'] = (aggregated[type]!['count'] as int) + 1;
        if (event['parameters']?['duration_ms'] != null) {
          aggregated[type]!['total_duration'] =
              (aggregated[type]!['total_duration'] as int) +
                  (event['parameters']['duration_ms'] as int);
        }
      }

      developer.log(
        'Collected app usage data: ${aggregated.length} event types',
        name: _logName,
      );

      return aggregated.values.toList();
    } catch (e) {
      developer.log('Error collecting app usage data: $e', name: _logName);
      return [];
    }
  }

  /// Collect community interaction data from database
  Future<List<dynamic>> collectCommunityData() async {
    try {
      final supabase = Supabase.instance.client;

      final communityData = <dynamic>[];

      // Query respected lists (lists with respect_count > 0, ordered by respect count)
      try {
        final respectedLists = await supabase
            .from('spot_lists')
            .select('*')
            .gt('respect_count', 0)
            .order('respect_count', ascending: false)
            .limit(20);

        communityData.addAll(
          respectedLists.map((l) => {'type': 'respected_list', 'data': l}),
        );
      } catch (e) {
        developer.log('Error querying respected lists: $e', name: _logName);
      }

      // Query trending spots (spots with respect_count > 0, ordered by respect count)
      try {
        final trendingSpots = await supabase
            .from('spots')
            .select('*')
            .gt('respect_count', 0)
            .order('respect_count', ascending: false)
            .limit(20);

        communityData.addAll(
          trendingSpots.map((s) => {'type': 'trending_spot', 'data': s}),
        );
      } catch (e) {
        developer.log('Error querying trending spots: $e', name: _logName);
      }

      // TODO: Add query for community_interactions table when it is created

      developer.log(
        'Collected community data: ${communityData.length} items',
        name: _logName,
      );

      return communityData;
    } catch (e) {
      developer.log('Error collecting community data: $e', name: _logName);
      return [];
    }
  }

  /// Collect AI2AI communication data
  Future<List<dynamic>> collectAI2AIData() async {
    try {
      // TODO: Connect to AI2AI learning system
      // This would collect:
      // - AI2AI interactions
      // - Personality learning insights
      // - Cross-personality patterns
      // - Collective intelligence data

      // For now, return empty list - will be populated when AI2AI service is connected
      return [];
    } catch (e) {
      developer.log('Error collecting AI2AI data: $e', name: _logName);
      return [];
    }
  }

  /// Collect external context data
  Future<List<dynamic>> collectExternalData() async {
    try {
      // TODO: Connect to external data sources
      // This would collect:
      // - Events data
      // - News/trends
      // - Seasonal data
      // - Cultural events
      // - External API data

      // For now, return empty list - will be populated when external services are connected
      return [];
    } catch (e) {
      developer.log('Error collecting external data: $e', name: _logName);
      return [];
    }
  }
}
