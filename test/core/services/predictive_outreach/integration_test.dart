// ignore: dangling_library_doc_comments
/// Integration Tests for Predictive Proactive Outreach System
/// 
/// Tests the complete flow from prediction to outreach delivery.
/// Part of Predictive Proactive Outreach System - Integration Testing

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/core/services/predictive_outreach/background_outreach_scheduler.dart';
import 'package:avrai/core/services/predictive_outreach/outreach_queue_processor.dart';
import 'package:avrai/core/services/predictive_outreach/silent_notification_service.dart';
import 'package:avrai/core/services/predictive_outreach/outreach_history_service.dart';
import 'package:avrai/core/services/predictive_outreach/outreach_preferences_service.dart';
import 'package:avrai/core/services/predictive_outreach/compatibility_cache_service.dart';
import 'package:avrai/core/services/predictive_outreach/predictive_signals_cache_service.dart';
import 'package:avrai/core/services/predictive_outreach/batch_processing_optimization_service.dart';

void main() {
  group('Predictive Outreach Integration Tests', () {
    setUpAll(() async {
      // Initialize dependency injection
      await di.init();
    });

    test('Background scheduler can be started and stopped', () async {
      final scheduler = di.sl<BackgroundOutreachScheduler>();
      
      expect(scheduler.isRunning, false);
      
      scheduler.start();
      expect(scheduler.isRunning, true);
      
      scheduler.stop();
      expect(scheduler.isRunning, false);
    });

    test('Outreach queue processor can process pending messages', () async {
      final processor = di.sl<OutreachQueueProcessor>();
      
      final result = await processor.processPendingMessages(limit: 10);
      
      expect(result, isNotNull);
      expect(result.totalProcessed, greaterThanOrEqualTo(0));
      expect(result.successCount, greaterThanOrEqualTo(0));
      expect(result.failureCount, greaterThanOrEqualTo(0));
    });

    test('Silent notification service can get pending notifications', () async {
      final service = di.sl<SilentNotificationService>();
      
      // Use a test user ID
      final notifications = await service.getPendingNotifications(
        userId: 'test-user-id',
        limit: 10,
      );
      
      expect(notifications, isA<List<OutreachQueueMessage>>());
    });

    test('Outreach history service can check cooldown', () async {
      final service = di.sl<OutreachHistoryService>();
      
      final canSend = await service.canSendOutreach(
        targetUserId: 'test-user-id',
        sourceId: 'test-source-id',
        sourceType: 'community',
        outreachType: 'community_invitation',
      );
      
      expect(canSend, isA<bool>());
    });

    test('Outreach preferences service can get user preferences', () async {
      final service = di.sl<OutreachPreferencesService>();
      
      final preferences = await service.getUserPreferences(
        userId: 'test-user-id',
      );
      
      expect(preferences, isNotNull);
      expect(preferences.userId, 'test-user-id');
      expect(preferences.enabled, isA<bool>());
      expect(preferences.frequency, isA<String>());
    });

    test('Compatibility cache service can cache and retrieve', () async {
      final service = di.sl<CompatibilityCacheService>();
      
      // Cache a compatibility
      final cached = await service.cacheCompatibility(
        userAId: 'user-a',
        userBId: 'user-b',
        compatibilityScore: 0.85,
        knotCompatibility: 0.80,
        quantumCompatibility: 0.90,
      );
      
      expect(cached, true);
      
      // Retrieve cached
      final retrieved = await service.getCachedCompatibility(
        userAId: 'user-a',
        userBId: 'user-b',
      );
      
      expect(retrieved, isNotNull);
      expect(retrieved!.compatibilityScore, 0.85);
    });

    test('Predictive signals cache service can cache and retrieve', () async {
      final service = di.sl<PredictiveSignalsCacheService>();
      
      // Cache a signal
      final cached = await service.cacheSignal(
        userId: 'test-user',
        signalType: PredictiveSignalType.stringPrediction,
        signalData: {'score': 0.75},
        targetTime: DateTime.now().add(const Duration(days: 7)),
      );
      
      expect(cached, true);
      
      // Retrieve cached
      final retrieved = await service.getCachedSignal(
        userId: 'test-user',
        signalType: PredictiveSignalType.stringPrediction,
        targetTime: DateTime.now().add(const Duration(days: 7)),
      );
      
      expect(retrieved, isNotNull);
      expect(retrieved!.signalData['score'], 0.75);
    });

    test('Batch processing optimization service can process', () async {
      final service = di.sl<BatchProcessingOptimizationService>();
      
      final result = await service.processWithOptimization();
      
      expect(result, isNotNull);
      expect(result.totalProcessed, greaterThanOrEqualTo(0));
    });
  });
}
