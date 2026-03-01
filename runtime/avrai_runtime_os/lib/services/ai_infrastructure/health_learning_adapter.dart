import 'dart:developer' as developer;

import 'package:health/health.dart';

import 'package:avrai_runtime_os/services/device/wearable_data_service.dart';
import 'package:avrai_core/models/user/mood_state.dart';

/// Adapter that bridges WearableDataService to the AI learning system
///
/// Transforms health/fitness data into learning signals:
/// - Activity patterns (active vs sedentary)
/// - Sleep quality (well-rested vs tired)
/// - Stress levels (relaxed vs stressed)
/// - Workout patterns (fitness enthusiast vs casual)
/// - Time-of-day energy patterns
///
/// All data is processed locally on-device per avrai privacy philosophy.
class HealthLearningAdapter {
  static const String _logName = 'HealthLearningAdapter';

  final WearableDataService _wearableDataService;
  Health? _health;
  bool _isInitialized = false;

  HealthLearningAdapter({
    required WearableDataService wearableDataService,
  }) : _wearableDataService = wearableDataService;

  /// Initialize the adapter
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _wearableDataService.initialize();
      _health = Health();
      _isInitialized = true;

      developer.log(
        'HealthLearningAdapter initialized',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Error initializing HealthLearningAdapter',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      _isInitialized = true;
    }
  }

  /// Check if health learning is available
  bool get isAvailable => _wearableDataService.isAvailable;

  /// Collect health data for AI learning
  ///
  /// Returns a comprehensive map of health signals that the AI can learn from.
  Future<Map<String, dynamic>> collectHealthData() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_wearableDataService.isAvailable) {
      developer.log('Wearable data not available', name: _logName);
      return {'has_data': false};
    }

    try {
      // Get current state from wearable service
      final mood = await _wearableDataService.getCurrentMood();
      final energy = await _wearableDataService.getCurrentEnergy();
      final stress = await _wearableDataService.getCurrentStress();

      // Get historical data for pattern analysis
      final sleepData = await _getSleepData();
      final activityData = await _getActivityData();
      final workoutData = await _getWorkoutData();

      // Aggregate into learning signals
      return {
        'has_data': true,
        // Current state
        'current_mood': {
          'type': mood.type.name,
          'intensity': mood.intensity,
        },
        'current_energy': {
          'value': energy.value,
          'level': _categorizeEnergy(energy.value),
        },
        'current_stress': {
          'value': stress.value,
          'level': _categorizeStress(stress.value),
        },
        // Sleep analysis
        'sleep': sleepData,
        // Activity analysis
        'activity': activityData,
        // Workout patterns
        'workouts': workoutData,
        // Derived learning signals
        'learning_signals': _deriveLearningSignals(
          mood: mood,
          energy: energy,
          stress: stress,
          sleepData: sleepData,
          activityData: activityData,
          workoutData: workoutData,
        ),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, st) {
      developer.log(
        'Error collecting health data',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return {'has_data': false, 'error': e.toString()};
    }
  }

  /// Get sleep data from HealthKit/Health Connect
  Future<Map<String, dynamic>> _getSleepData() async {
    if (_health == null) return {'has_data': false};

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final sleepTypes = [
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
      ];

      final sleepData = await _health!.getHealthDataFromTypes(
        types: sleepTypes,
        startTime: yesterday,
        endTime: now,
      );

      if (sleepData.isEmpty) {
        return {'has_data': false};
      }

      // Calculate total sleep time and quality
      Duration totalInBed = Duration.zero;
      Duration totalAsleep = Duration.zero;
      Duration totalAwake = Duration.zero;

      for (final dataPoint in sleepData) {
        final value = dataPoint.value;
        if (value is NumericHealthValue) {
          final minutes = value.numericValue.toInt();
          final duration = Duration(minutes: minutes);

          switch (dataPoint.type) {
            case HealthDataType.SLEEP_IN_BED:
              totalInBed += duration;
              break;
            case HealthDataType.SLEEP_ASLEEP:
              totalAsleep += duration;
              break;
            case HealthDataType.SLEEP_AWAKE:
              totalAwake += duration;
              break;
            default:
              break;
          }
        }
      }

      // Calculate sleep efficiency (time asleep / time in bed)
      final efficiency = totalInBed.inMinutes > 0
          ? totalAsleep.inMinutes / totalInBed.inMinutes
          : 0.0;

      return {
        'has_data': true,
        'total_in_bed_hours': totalInBed.inMinutes / 60,
        'total_asleep_hours': totalAsleep.inMinutes / 60,
        'total_awake_hours': totalAwake.inMinutes / 60,
        'sleep_efficiency': efficiency,
        'quality': _categorizeSleepQuality(totalAsleep.inMinutes, efficiency),
      };
    } catch (e) {
      developer.log('Error getting sleep data: $e', name: _logName);
      return {'has_data': false};
    }
  }

  /// Get activity data from HealthKit/Health Connect
  Future<Map<String, dynamic>> _getActivityData() async {
    if (_health == null) return {'has_data': false};

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      // Get steps
      final stepsData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: yesterday,
        endTime: now,
      );

      // Get active energy
      final energyData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: yesterday,
        endTime: now,
      );

      if (stepsData.isEmpty && energyData.isEmpty) {
        return {'has_data': false};
      }

      // Calculate totals
      int totalSteps = 0;
      double totalCalories = 0.0;

      for (final dataPoint in stepsData) {
        final value = dataPoint.value;
        if (value is NumericHealthValue) {
          totalSteps += value.numericValue.toInt();
        }
      }

      for (final dataPoint in energyData) {
        final value = dataPoint.value;
        if (value is NumericHealthValue) {
          totalCalories += value.numericValue.toDouble();
        }
      }

      return {
        'has_data': true,
        'steps_today': totalSteps,
        'calories_burned': totalCalories,
        'activity_level': _categorizeActivityLevel(totalSteps),
        'is_active_day': totalSteps > 7500,
      };
    } catch (e) {
      developer.log('Error getting activity data: $e', name: _logName);
      return {'has_data': false};
    }
  }

  /// Get workout data from HealthKit/Health Connect
  Future<Map<String, dynamic>> _getWorkoutData() async {
    if (_health == null) return {'has_data': false};

    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      // Get workout data
      final workoutData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: weekAgo,
        endTime: now,
      );

      if (workoutData.isEmpty) {
        return {'has_data': false, 'workouts_this_week': 0};
      }

      // Analyze workouts
      final workoutTypes = <String, int>{};
      int totalWorkouts = workoutData.length;
      Duration totalDuration = Duration.zero;

      for (final dataPoint in workoutData) {
        final value = dataPoint.value;
        if (value is WorkoutHealthValue) {
          final type = value.workoutActivityType.name;
          workoutTypes[type] = (workoutTypes[type] ?? 0) + 1;
          totalDuration += value.totalEnergyBurned != null
              ? Duration(minutes: value.totalEnergyBurned!.toInt())
              : Duration.zero;
        }
      }

      // Find preferred workout type
      String? preferredType;
      int maxCount = 0;
      for (final entry in workoutTypes.entries) {
        if (entry.value > maxCount) {
          maxCount = entry.value;
          preferredType = entry.key;
        }
      }

      return {
        'has_data': true,
        'workouts_this_week': totalWorkouts,
        'workout_types': workoutTypes,
        'preferred_workout_type': preferredType,
        'total_workout_hours': totalDuration.inMinutes / 60,
        'fitness_level': _categorizeFitnessLevel(totalWorkouts),
      };
    } catch (e) {
      developer.log('Error getting workout data: $e', name: _logName);
      return {'has_data': false};
    }
  }

  /// Derive learning signals from health data
  ///
  /// These signals tell the AI:
  /// - When user needs calm/relaxing spots
  /// - When user is energetic and wants active spots
  /// - When user is a fitness enthusiast
  /// - Time-of-day energy patterns
  Map<String, dynamic> _deriveLearningSignals({
    required MoodState mood,
    required EnergyLevel energy,
    required StressLevel stress,
    required Map<String, dynamic> sleepData,
    required Map<String, dynamic> activityData,
    required Map<String, dynamic> workoutData,
  }) {
    return {
      // Spot preference signals
      'prefers_calm_spots': stress.value > 0.6 || energy.value < 0.3,
      'prefers_active_spots': energy.value > 0.7 && stress.value < 0.4,
      'needs_energizing': energy.value < 0.4 && sleepData['quality'] == 'poor',
      'needs_relaxation': stress.value > 0.7,

      // Personality learning signals
      'is_fitness_oriented': workoutData['workouts_this_week'] != null &&
          (workoutData['workouts_this_week'] as int) >= 3,
      'is_active_lifestyle': activityData['activity_level'] == 'very_active' ||
          activityData['activity_level'] == 'active',
      'is_well_rested':
          sleepData['quality'] == 'excellent' || sleepData['quality'] == 'good',

      // Time-based signals
      'current_energy_level': _categorizeEnergy(energy.value),
      'current_stress_level': _categorizeStress(stress.value),
      'current_mood': mood.type.name,

      // Recommendation signals
      'suggest_coffee_shop': energy.value < 0.5,
      'suggest_gym_or_outdoor': energy.value > 0.7 &&
          workoutData['workouts_this_week'] != null &&
          (workoutData['workouts_this_week'] as int) >= 2,
      'suggest_quiet_venue':
          stress.value > 0.5 || mood.type == MoodType.stressed,
      'suggest_social_venue':
          mood.type == MoodType.excited || mood.type == MoodType.energetic,
    };
  }

  /// Categorize energy level
  String _categorizeEnergy(double value) {
    if (value < 0.3) return 'low';
    if (value < 0.5) return 'moderate_low';
    if (value < 0.7) return 'moderate';
    if (value < 0.85) return 'high';
    return 'very_high';
  }

  /// Categorize stress level
  String _categorizeStress(double value) {
    if (value < 0.2) return 'relaxed';
    if (value < 0.4) return 'mild';
    if (value < 0.6) return 'moderate';
    if (value < 0.8) return 'high';
    return 'very_high';
  }

  /// Categorize sleep quality
  String _categorizeSleepQuality(int asleepMinutes, double efficiency) {
    final hours = asleepMinutes / 60;

    if (hours >= 7 && efficiency > 0.85) return 'excellent';
    if (hours >= 6 && efficiency > 0.75) return 'good';
    if (hours >= 5 && efficiency > 0.65) return 'fair';
    return 'poor';
  }

  /// Categorize activity level based on steps
  String _categorizeActivityLevel(int steps) {
    if (steps < 2500) return 'sedentary';
    if (steps < 5000) return 'lightly_active';
    if (steps < 7500) return 'moderately_active';
    if (steps < 10000) return 'active';
    return 'very_active';
  }

  /// Categorize fitness level based on workouts per week
  String _categorizeFitnessLevel(int workoutsPerWeek) {
    if (workoutsPerWeek == 0) return 'inactive';
    if (workoutsPerWeek <= 1) return 'occasional';
    if (workoutsPerWeek <= 3) return 'regular';
    if (workoutsPerWeek <= 5) return 'active';
    return 'very_active';
  }

  /// Get health patterns for long-term learning
  ///
  /// Analyzes 30-day health data to identify patterns.
  Future<Map<String, dynamic>> getHealthPatterns() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_health == null || !_wearableDataService.isAvailable) {
      return {'has_data': false};
    }

    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get 30-day step data
      final stepsData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: monthAgo,
        endTime: now,
      );

      if (stepsData.isEmpty) {
        return {'has_data': false};
      }

      // Analyze by day of week
      final dayOfWeekSteps = <int, List<int>>{
        1: [],
        2: [],
        3: [],
        4: [],
        5: [],
        6: [],
        7: [],
      };

      for (final dataPoint in stepsData) {
        final day = dataPoint.dateFrom.weekday;
        final value = dataPoint.value;
        if (value is NumericHealthValue) {
          dayOfWeekSteps[day]!.add(value.numericValue.toInt());
        }
      }

      // Calculate averages by day
      final dayAverages = <int, double>{};
      for (final entry in dayOfWeekSteps.entries) {
        if (entry.value.isNotEmpty) {
          dayAverages[entry.key] =
              entry.value.reduce((a, b) => a + b) / entry.value.length;
        }
      }

      // Find most and least active days
      int? mostActiveDay;
      int? leastActiveDay;
      double maxSteps = 0;
      double minSteps = double.infinity;

      for (final entry in dayAverages.entries) {
        if (entry.value > maxSteps) {
          maxSteps = entry.value;
          mostActiveDay = entry.key;
        }
        if (entry.value < minSteps) {
          minSteps = entry.value;
          leastActiveDay = entry.key;
        }
      }

      return {
        'has_data': true,
        'day_averages': dayAverages,
        'most_active_day': mostActiveDay,
        'least_active_day': leastActiveDay,
        'is_weekend_warrior':
            (dayAverages[6] ?? 0) > (dayAverages[3] ?? 0) * 1.5,
        'consistent_activity': _isConsistentActivity(dayAverages),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, st) {
      developer.log(
        'Error getting health patterns',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return {'has_data': false};
    }
  }

  /// Check if activity is consistent across the week
  bool _isConsistentActivity(Map<int, double> dayAverages) {
    if (dayAverages.isEmpty) return false;

    final values = dayAverages.values.toList();
    if (values.isEmpty) return false;

    final avg = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) /
            values.length;

    // Low variance means consistent activity
    return variance < avg * 0.3;
  }
}
