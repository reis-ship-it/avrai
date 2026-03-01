// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
// Extracted models for continuous learning system.

// Models for continuous learning system

class LearningData {
  final List<dynamic> userActions;
  final List<dynamic> locationData;
  final List<dynamic> weatherData;
  final List<dynamic> timeData;
  final List<dynamic> socialData;
  final List<dynamic> demographicData;
  final List<dynamic> appUsageData;
  final List<dynamic> communityData;
  final List<dynamic> ai2aiData;
  final List<dynamic> externalData;
  final DateTime timestamp;

  LearningData({
    required this.userActions,
    required this.locationData,
    required this.weatherData,
    required this.timeData,
    required this.socialData,
    required this.demographicData,
    required this.appUsageData,
    required this.communityData,
    required this.ai2aiData,
    required this.externalData,
    required this.timestamp,
  });

  static LearningData empty() {
    return LearningData(
      userActions: [],
      locationData: [],
      weatherData: [],
      timeData: [],
      socialData: [],
      demographicData: [],
      appUsageData: [],
      communityData: [],
      ai2aiData: [],
      externalData: [],
      timestamp: DateTime.now(),
    );
  }
}

class LearningEvent {
  final String dimension;
  final double improvement;
  final String dataSource;
  final DateTime timestamp;

  LearningEvent({
    required this.dimension,
    required this.improvement,
    required this.dataSource,
    required this.timestamp,
  });
}

// Data models for UI

class ContinuousLearningStatus {
  final bool isActive;
  final List<String> activeProcesses;
  final Duration uptime;
  final int cyclesCompleted;
  final Duration learningTime;

  ContinuousLearningStatus({
    required this.isActive,
    required this.activeProcesses,
    required this.uptime,
    required this.cyclesCompleted,
    required this.learningTime,
  });
}

class ContinuousLearningMetrics {
  final double totalImprovements;
  final double averageProgress;
  final List<String> topImprovingDimensions;
  final int dimensionsCount;
  final int dataSourcesCount;

  ContinuousLearningMetrics({
    required this.totalImprovements,
    required this.averageProgress,
    required this.topImprovingDimensions,
    required this.dimensionsCount,
    required this.dataSourcesCount,
  });
}

class DataCollectionStatus {
  final Map<String, DataSourceStatus> sourceStatuses;
  final int totalVolume;
  final int activeSourcesCount;

  DataCollectionStatus({
    required this.sourceStatuses,
    required this.totalVolume,
    required this.activeSourcesCount,
  });
}

class DataSourceStatus {
  final bool isActive;
  final int dataVolume;
  final int eventCount;
  final String healthStatus; // 'healthy', 'idle', 'inactive'

  DataSourceStatus({
    required this.isActive,
    required this.dataVolume,
    required this.eventCount,
    required this.healthStatus,
  });
}
