import 'dart:developer' as developer;
import 'package:health/health.dart';
import 'package:avrai/core/models/user/mood_state.dart';
import 'package:avrai_knot/services/knot/dynamic_knot_service.dart';

/// Service for collecting physiological data from wearables
/// Phase 4: Dynamic Knots with Wearables Integration
/// 
/// Maps wearable data (HR, HRV, activity, stress) to mood/energy/stress levels
/// Falls back to defaults when wearable data is unavailable
class WearableDataService {
  final DynamicKnotService _dynamicKnotService;
  Health? _health;
  bool _isInitialized = false;
  bool _hasPermissions = false;
  
  WearableDataService({
    DynamicKnotService? dynamicKnotService,
  }) : _dynamicKnotService = dynamicKnotService ?? DynamicKnotService();
  
  /// Initialize health data access
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _health = Health();
      
      // Request permissions for required data types
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
      ];
      
      // Check if health data is available on this platform
      final available = await _health!.hasPermissions(types);
      
      if (available == false) {
        // Request permissions
        final authResult = await _health!.requestAuthorization(types);
        _hasPermissions = authResult;
      } else {
        _hasPermissions = available ?? false;
      }
      
      _isInitialized = true;
      
      developer.log(
        'WearableDataService initialized. Permissions: $_hasPermissions',
        name: 'WearableDataService',
      );
    } catch (e, st) {
      developer.log(
        'Error initializing WearableDataService',
        error: e,
        stackTrace: st,
        name: 'WearableDataService',
      );
      _isInitialized = true; // Mark as initialized even on error to prevent retries
      _hasPermissions = false;
    }
  }
  
  /// Get current mood state from wearable data
  /// Falls back to default if no data available
  Future<MoodState> getCurrentMood() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_hasPermissions || _health == null) {
      return _dynamicKnotService.getDefaultMood();
    }
    
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      // Get recent heart rate data
      final heartRateData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: yesterday,
        endTime: now,
      );
      
      // Get HRV data (stress indicator)
      final hrvData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        startTime: yesterday,
        endTime: now,
      );
      
      if (heartRateData.isEmpty && hrvData.isEmpty) {
        return _dynamicKnotService.getDefaultMood();
      }
      
      // Calculate mood from physiological signals
      final mood = _calculateMoodFromPhysiologicalData(
        heartRateData,
        hrvData,
      );
      
      return mood;
    } catch (e, st) {
      developer.log(
        'Error getting mood from wearables',
        error: e,
        stackTrace: st,
        name: 'WearableDataService',
      );
      return _dynamicKnotService.getDefaultMood();
    }
  }
  
  /// Get current energy level from wearable data
  /// Falls back to default if no data available
  Future<EnergyLevel> getCurrentEnergy() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_hasPermissions || _health == null) {
      return _dynamicKnotService.getDefaultEnergy();
    }
    
    try {
      final now = DateTime.now();
      final lastHour = now.subtract(const Duration(hours: 1));
      
      // Get activity data (steps, active energy)
      final stepsData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: lastHour,
        endTime: now,
      );
      
      final activeEnergyData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: lastHour,
        endTime: now,
      );
      
      if (stepsData.isEmpty && activeEnergyData.isEmpty) {
        return _dynamicKnotService.getDefaultEnergy();
      }
      
      // Calculate energy from activity
      final energy = _calculateEnergyFromActivityData(
        stepsData,
        activeEnergyData,
      );
      
      return energy;
    } catch (e, st) {
      developer.log(
        'Error getting energy from wearables',
        error: e,
        stackTrace: st,
        name: 'WearableDataService',
      );
      return _dynamicKnotService.getDefaultEnergy();
    }
  }
  
  /// Get current stress level from wearable data
  /// Falls back to default if no data available
  Future<StressLevel> getCurrentStress() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_hasPermissions || _health == null) {
      return _dynamicKnotService.getDefaultStress();
    }
    
    try {
      final now = DateTime.now();
      final lastHour = now.subtract(const Duration(hours: 1));
      
      // Get HRV data (primary stress indicator)
      final hrvData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        startTime: lastHour,
        endTime: now,
      );
      
      // Get heart rate data (secondary stress indicator)
      final heartRateData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: lastHour,
        endTime: now,
      );
      
      if (hrvData.isEmpty && heartRateData.isEmpty) {
        return _dynamicKnotService.getDefaultStress();
      }
      
      // Calculate stress from HRV and HR
      final stress = _calculateStressFromPhysiologicalData(
        hrvData,
        heartRateData,
      );
      
      return stress;
    } catch (e, st) {
      developer.log(
        'Error getting stress from wearables',
        error: e,
        stackTrace: st,
        name: 'WearableDataService',
      );
      return _dynamicKnotService.getDefaultStress();
    }
  }
  
  /// Calculate mood from heart rate and HRV data
  /// Based on research: calm = low HR + stable HRV, excited = elevated HR, stressed = high HRV variability
  MoodState _calculateMoodFromPhysiologicalData(
    List<HealthDataPoint> heartRateData,
    List<HealthDataPoint> hrvData,
  ) {
    if (heartRateData.isEmpty && hrvData.isEmpty) {
      return _dynamicKnotService.getDefaultMood();
    }
    
    // Calculate average heart rate
    double? avgHeartRate;
    if (heartRateData.isNotEmpty) {
      final hrValues = <double>[];
      for (final dataPoint in heartRateData) {
        final value = dataPoint.value;
        if (value is NumericHealthValue) {
          hrValues.add(value.numericValue.toDouble());
        }
      }
      if (hrValues.isNotEmpty) {
        avgHeartRate = hrValues.reduce((a, b) => a + b) / hrValues.length;
      }
    }
    
    // Calculate HRV variability (stress indicator)
    double? hrvVariability;
    if (hrvData.length > 1) {
      final hrvValues = <double>[];
      for (final dataPoint in hrvData) {
        final value = dataPoint.value;
        if (value is NumericHealthValue) {
          final numValue = value.numericValue;
          hrvValues.add(numValue is double ? numValue : numValue.toDouble());
        }
      }
      if (hrvValues.length > 1) {
        // Calculate standard deviation as variability measure
        final mean = hrvValues.reduce((a, b) => a + b) / hrvValues.length;
        final variance = hrvValues
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
            hrvValues.length;
        hrvVariability = variance;
      }
    }
    
    // Map to mood based on research algorithms
    // Calm: Low HR (60-70), stable HRV
    // Excited: Elevated HR (80+), normal HRV
    // Stressed: Elevated HR, high HRV variability
    // Energetic: Elevated HR, normal HRV, recent activity
    
    MoodType moodType;
    double intensity = 0.5;
    
    if (avgHeartRate != null) {
      if (avgHeartRate < 65 && (hrvVariability == null || hrvVariability < 10)) {
        // Calm: Low HR, stable HRV
        moodType = MoodType.calm;
        intensity = 0.7;
      } else if (avgHeartRate > 85 && (hrvVariability == null || hrvVariability < 15)) {
        // Excited/Energetic: High HR, normal HRV
        moodType = MoodType.excited;
        intensity = 0.8;
      } else if (hrvVariability != null && hrvVariability > 20) {
        // Stressed: High HRV variability
        moodType = MoodType.stressed;
        intensity = (hrvVariability / 50).clamp(0.3, 1.0);
      } else if (avgHeartRate > 75) {
        // Moderate excitement
        moodType = MoodType.energetic;
        intensity = 0.6;
      } else {
        // Default to calm
        moodType = MoodType.calm;
        intensity = 0.5;
      }
    } else {
      // No heart rate data, use default
      return _dynamicKnotService.getDefaultMood();
    }
    
    return MoodState(
      type: moodType,
      intensity: intensity,
      timestamp: DateTime.now(),
    );
  }
  
  /// Calculate energy from activity data (steps, active energy)
  /// High activity = high energy, low activity = low energy
  EnergyLevel _calculateEnergyFromActivityData(
    List<HealthDataPoint> stepsData,
    List<HealthDataPoint> activeEnergyData,
  ) {
    if (stepsData.isEmpty && activeEnergyData.isEmpty) {
      return _dynamicKnotService.getDefaultEnergy();
    }
    
    // Calculate total steps in last hour
    double totalSteps = 0.0;
    if (stepsData.isNotEmpty) {
      for (final dataPoint in stepsData) {
        final value = dataPoint.value;
        if (value is NumericHealthValue) {
          totalSteps += value.numericValue.toDouble();
        }
      }
    }
    
    // Calculate active energy in last hour
    double totalEnergy = 0.0;
    if (activeEnergyData.isNotEmpty) {
      for (final dataPoint in activeEnergyData) {
        final value = dataPoint.value;
        if (value is NumericHealthValue) {
          totalEnergy += value.numericValue.toDouble();
        }
      }
    }
    
    // Map to energy level (0.0-1.0)
    // High activity: >500 steps/hour or >50 calories/hour = high energy
    // Low activity: <100 steps/hour and <10 calories/hour = low energy
    double energyValue;
    if (totalSteps > 500 || totalEnergy > 50) {
      // High energy
      energyValue = ((totalSteps / 1000) + (totalEnergy / 100)).clamp(0.7, 1.0);
    } else if (totalSteps < 100 && totalEnergy < 10) {
      // Low energy
      energyValue = ((totalSteps / 200) + (totalEnergy / 20)).clamp(0.0, 0.4);
    } else {
      // Moderate energy
      energyValue = ((totalSteps / 500) + (totalEnergy / 50)).clamp(0.4, 0.7);
    }
    
    return EnergyLevel(
      value: energyValue,
      timestamp: DateTime.now(),
    );
  }
  
  /// Calculate stress from HRV and heart rate data
  /// High HRV variability + elevated HR = high stress
  /// Low HRV variability + normal HR = low stress
  StressLevel _calculateStressFromPhysiologicalData(
    List<HealthDataPoint> hrvData,
    List<HealthDataPoint> heartRateData,
  ) {
    if (hrvData.isEmpty && heartRateData.isEmpty) {
      return _dynamicKnotService.getDefaultStress();
    }
    
    // Calculate HRV variability (primary stress indicator)
    double? hrvVariability;
    if (hrvData.length > 1) {
      final hrvValues = <double>[];
      for (final dataPoint in hrvData) {
        final value = dataPoint.value;
        if (value is NumericHealthValue) {
          hrvValues.add(value.numericValue.toDouble());
        }
      }
      if (hrvValues.length > 1) {
        final mean = hrvValues.reduce((a, b) => a + b) / hrvValues.length;
        final variance = hrvValues
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
            hrvValues.length;
        hrvVariability = variance;
      }
    }
    
    // Calculate average heart rate
    double? avgHeartRate;
    if (heartRateData.isNotEmpty) {
      final hrValues = <double>[];
      for (final dataPoint in heartRateData) {
        final value = dataPoint.value;
        if (value is NumericHealthValue) {
          hrValues.add(value.numericValue.toDouble());
        }
      }
      if (hrValues.isNotEmpty) {
        avgHeartRate = hrValues.reduce((a, b) => a + b) / hrValues.length;
      }
    }
    
    // Map to stress level (0.0-1.0)
    // High stress: High HRV variability (>20) OR elevated HR (>85) without activity
    // Low stress: Low HRV variability (<10) AND normal HR (60-75)
    double stressValue = 0.0;
    
    if (hrvVariability != null) {
      // Primary indicator: HRV variability
      // Normal HRV variability: 10-20
      // High variability (>20) = stress
      stressValue = (hrvVariability / 50).clamp(0.0, 1.0);
    }
    
    if (avgHeartRate != null) {
      // Secondary indicator: Elevated HR without activity
      // Normal resting HR: 60-75
      // Elevated HR (>85) = possible stress (if not from activity)
      if (avgHeartRate > 85) {
        // Check if this is from activity or stress
        // For now, assume elevated HR contributes to stress
        final hrStress = ((avgHeartRate - 75) / 50).clamp(0.0, 0.5);
        stressValue = (stressValue + hrStress).clamp(0.0, 1.0);
      }
    }
    
    // If no data, return default
    if (hrvVariability == null && avgHeartRate == null) {
      return _dynamicKnotService.getDefaultStress();
    }
    
    return StressLevel(
      value: stressValue,
      timestamp: DateTime.now(),
    );
  }
  
  /// Check if wearable data is available
  bool get isAvailable => _isInitialized && _hasPermissions;
}
