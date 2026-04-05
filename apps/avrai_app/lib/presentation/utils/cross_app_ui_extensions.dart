import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';

extension CrossAppDataSourceUIExtension on CrossAppDataSource {
  String get displayName {
    switch (this) {
      case CrossAppDataSource.calendar:
        return 'Calendar';
      case CrossAppDataSource.health:
        return 'Health & Fitness';
      case CrossAppDataSource.media:
        return 'Music & Media';
      case CrossAppDataSource.appUsage:
        return 'App Usage';
      case CrossAppDataSource.location:
        return 'Location History';
      case CrossAppDataSource.contacts:
        return 'Contacts & Network';
      case CrossAppDataSource.browserHistory:
        return 'Browser History';
      case CrossAppDataSource.external:
        return 'External Source';
    }
  }

  String get description {
    switch (this) {
      case CrossAppDataSource.calendar:
        return 'Learn from your schedule and event types';
      case CrossAppDataSource.health:
        return 'Understand your activity and energy levels';
      case CrossAppDataSource.media:
        return 'Detect your mood from what you listen to';
      case CrossAppDataSource.appUsage:
        return 'Learn from your app usage patterns';
      case CrossAppDataSource.location:
        return 'Learn from your location history';
      case CrossAppDataSource.contacts:
        return 'Understand your social circles';
      case CrossAppDataSource.browserHistory:
        return 'Learn from your browsing habits';
      case CrossAppDataSource.external:
        return 'Learn from external sources';
    }
  }
}
