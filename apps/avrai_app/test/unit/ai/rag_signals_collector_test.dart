/// Unit tests for RAGSignalsCollector (RAG Phase 6).
/// Plan: RAG wiring + RAG-as-answer — getRecentSignals, aggregate, fromJson.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/rag_feedback_signals.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('RAGFeedbackSignal', () {
    test('fromJson round-trip preserves data', () {
      final s = RAGFeedbackSignal(
        turnId: 't1',
        userId: 'u1',
        retrievedFactGroups: ['traits', 'places'],
        networkCuesUsed: true,
        searchUsed: false,
        timestamp: DateTime(2025, 1, 1, 12, 0),
        usedBypass: true,
      );
      final json = s.toJson();
      final restored = RAGFeedbackSignal.fromJson(json);
      expect(restored.turnId, s.turnId);
      expect(restored.userId, s.userId);
      expect(restored.retrievedFactGroups, s.retrievedFactGroups);
      expect(restored.networkCuesUsed, s.networkCuesUsed);
      expect(restored.searchUsed, s.searchUsed);
      expect(restored.usedBypass, s.usedBypass);
    });

    test('fromJson defaults usedBypass to false when missing', () {
      final s = RAGFeedbackSignal.fromJson({
        'turnId': 't2',
        'userId': 'u2',
        'retrievedFactGroups': <String>[],
        'networkCuesUsed': false,
        'searchUsed': false,
        'timestamp': DateTime(2025, 1, 1).toIso8601String(),
      });
      expect(s.usedBypass, isFalse);
    });
  });

  group('RAGSignalsCollector', () {
    late RAGSignalsCollector collector;

    setUp(() async {
      collector = RAGSignalsCollector();
      await collector.clear();
    });

    test('record stores signal without throwing', () async {
      await collector.record(
        userId: 'user-1',
        retrievedFactGroups: ['traits', 'places', 'social'],
        networkCuesUsed: true,
        searchUsed: false,
      );
    });

    test('record with searchUsed true', () async {
      await collector.record(
        userId: 'user-2',
        retrievedFactGroups: ['traits', 'places'],
        networkCuesUsed: false,
        searchUsed: true,
      );
    });

    test('getRecentSignals returns stored signals', () async {
      await collector.record(
        userId: 'u-get',
        retrievedFactGroups: ['traits', 'places'],
        networkCuesUsed: true,
        searchUsed: false,
      );
      final signals = collector.getRecentSignals(limit: 10);
      expect(signals.length, 1);
      expect(signals.first.userId, 'u-get');
      expect(signals.first.retrievedFactGroups, ['traits', 'places']);
      expect(signals.first.networkCuesUsed, isTrue);
    });

    test('getRecentSignals respects limit', () async {
      for (var i = 0; i < 5; i++) {
        await collector.record(
          userId: 'u-$i',
          retrievedFactGroups: ['traits'],
          networkCuesUsed: false,
          searchUsed: false,
        );
      }
      final signals = collector.getRecentSignals(limit: 3);
      expect(signals.length, 3);
    });

    test('aggregateForLocalLearning computes counts', () async {
      await collector.record(
        userId: 'u-agg',
        retrievedFactGroups: ['traits', 'places', 'social'],
        networkCuesUsed: true,
        searchUsed: true,
      );
      await collector.record(
        userId: 'u-agg',
        retrievedFactGroups: ['traits', 'places'],
        networkCuesUsed: true,
        searchUsed: false,
      );
      final agg = collector.aggregateForLocalLearning(limit: 100);
      expect(agg.retrievedGroupCounts['traits'], 2);
      expect(agg.retrievedGroupCounts['places'], 2);
      expect(agg.retrievedGroupCounts['social'], 1);
      expect(agg.networkCuesUsedCount, 2);
      expect(agg.searchUsedCount, 1);
      expect(agg.bypassCount, 0);
    });

    test('aggregateForLocalLearning counts bypass when usedBypass true',
        () async {
      await collector.record(
        userId: 'u-byp',
        retrievedFactGroups: [],
        networkCuesUsed: false,
        searchUsed: false,
        usedBypass: true,
      );
      final agg = collector.aggregateForLocalLearning(limit: 100);
      expect(agg.bypassCount, 1);
    });
  });
}
