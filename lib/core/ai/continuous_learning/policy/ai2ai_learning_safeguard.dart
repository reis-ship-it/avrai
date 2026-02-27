import 'dart:developer' as developer;

import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_network/network/ai2ai_protocol.dart' show MessageType;
import 'package:avrai_network/network/rate_limiter.dart';
import 'package:get_it/get_it.dart';

class Ai2AiLearningSafeguard {
  static const Duration _minimumLearningInterval = Duration(minutes: 20);
  static const double _minimumLearningQuality = 0.65;

  const Ai2AiLearningSafeguard._();

  static Future<bool> passesPreChecks({
    required Map<String, dynamic> payload,
    required Map<String, AtomicTimestamp> lastLearningByPeer,
    required RateLimiter? rateLimiter,
    required String logName,
  }) async {
    final source = payload['source'] as String?;
    if (source != 'ai2ai') {
      return true;
    }

    final peerId = payload['peer_id'] as String?;
    if (peerId != null) {
      final last = lastLearningByPeer[peerId];
      if (last != null) {
        final intervalOk = await _passesMinimumInterval(
          peerId: peerId,
          lastLearningAt: last,
          logName: logName,
        );
        if (!intervalOk) {
          return false;
        }
      }
    }

    final learningQuality = payload['learning_quality'] as double? ?? 0.0;
    if (learningQuality < _minimumLearningQuality) {
      developer.log(
        'AI2AI learning rejected: quality ${(learningQuality * 100).toStringAsFixed(1)}% '
        'below ${(_minimumLearningQuality * 100).toStringAsFixed(1)}% threshold',
        name: logName,
      );
      return false;
    }

    if (peerId != null && rateLimiter != null) {
      final allowed = await rateLimiter.checkRateLimit(
        peerAgentId: peerId,
        limitType: RateLimitType.message,
        messageType: MessageType.learningInsight,
      );
      if (!allowed) {
        developer.log(
          'AI2AI learning rate limited for peer: $peerId',
          name: logName,
        );
        return false;
      }
    }

    return true;
  }

  static Future<void> recordLearningTime({
    required String peerId,
    required Map<String, AtomicTimestamp> lastLearningByPeer,
    required String logName,
  }) async {
    try {
      if (GetIt.instance.isRegistered<AtomicClockService>()) {
        final atomicClock = GetIt.instance<AtomicClockService>();
        lastLearningByPeer[peerId] = await atomicClock.getAtomicTimestamp();
      } else {
        final now = DateTime.now();
        lastLearningByPeer[peerId] = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: now,
          localTime: now.toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: false,
        );
      }

      developer.log(
        'Recorded AI2AI learning time for peer: $peerId',
        name: logName,
      );
    } catch (e) {
      developer.log(
        'Error recording AI2AI learning time: $e',
        name: logName,
      );
    }
  }

  static Future<bool> _passesMinimumInterval({
    required String peerId,
    required AtomicTimestamp lastLearningAt,
    required String logName,
  }) async {
    try {
      if (GetIt.instance.isRegistered<AtomicClockService>()) {
        final atomicClock = GetIt.instance<AtomicClockService>();
        final atomicTimeNow = await atomicClock.getAtomicTimestamp();
        final elapsed = atomicTimeNow.difference(lastLearningAt);
        if (elapsed < _minimumLearningInterval) {
          developer.log(
            'AI2AI learning throttled: 20-min interval not met for peer $peerId '
            '(last learning: ${elapsed.inMinutes} minutes ago)',
            name: logName,
          );
          return false;
        }
        return true;
      }

      final elapsed = DateTime.now().difference(lastLearningAt.deviceTime);
      if (elapsed < _minimumLearningInterval) {
        developer.log(
          'AI2AI learning throttled: 20-min interval not met for peer $peerId',
          name: logName,
        );
        return false;
      }
      return true;
    } catch (e) {
      developer.log(
        'Error checking AI2AI learning interval: $e, using fallback',
        name: logName,
      );
      final elapsed = DateTime.now().difference(lastLearningAt.deviceTime);
      return elapsed >= _minimumLearningInterval;
    }
  }
}
