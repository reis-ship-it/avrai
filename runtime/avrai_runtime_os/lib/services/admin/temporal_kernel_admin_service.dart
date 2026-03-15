import 'dart:async';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';

class TemporalRuntimeEventPeerSummary {
  const TemporalRuntimeEventPeerSummary({
    required this.peerId,
    required this.eventCount,
    required this.orderedCount,
    required this.bufferedCount,
    required this.latestOccurredAt,
  });

  final String peerId;
  final int eventCount;
  final int orderedCount;
  final int bufferedCount;
  final DateTime latestOccurredAt;
}

class TemporalRuntimeEventSnapshot {
  const TemporalRuntimeEventSnapshot({
    required this.generatedAt,
    required this.windowStart,
    required this.windowEnd,
    required this.totalEvents,
    required this.encodedCount,
    required this.decodedCount,
    required this.bufferedCount,
    required this.orderedCount,
    required this.uniquePeerCount,
    required this.latestOccurredAt,
    required this.recentEvents,
    required this.topPeers,
  });

  final DateTime generatedAt;
  final DateTime windowStart;
  final DateTime windowEnd;
  final int totalEvents;
  final int encodedCount;
  final int decodedCount;
  final int bufferedCount;
  final int orderedCount;
  final int uniquePeerCount;
  final DateTime? latestOccurredAt;
  final List<RuntimeTemporalEventLookup> recentEvents;
  final List<TemporalRuntimeEventPeerSummary> topPeers;
}

class TemporalKernelAdminService {
  TemporalKernelAdminService({
    required TemporalKernel temporalKernel,
    DateTime Function()? nowProvider,
  })  : _temporalKernel = temporalKernel,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final TemporalKernel _temporalKernel;
  final DateTime Function() _nowProvider;

  Future<TemporalRuntimeEventSnapshot> getRuntimeEventSnapshot({
    String source = 'ai2ai_protocol',
    String? peerId,
    Duration lookbackWindow = const Duration(minutes: 15),
    int limit = 200,
  }) async {
    final now = _nowProvider().toUtc();
    final windowStart = now.subtract(lookbackWindow);
    final events = await _temporalKernel.queryRuntimeEvents(
      RuntimeTemporalEventQuery(
        source: source,
        peerId: peerId,
        occurredAfter: windowStart,
        occurredBefore: now,
        limit: limit,
      ),
    );
    final ordered = events
        .where(
            (entry) => entry.event.stage == RuntimeTemporalEventStage.ordered)
        .length;
    final buffered = events
        .where(
          (entry) => entry.event.stage == RuntimeTemporalEventStage.buffered,
        )
        .length;
    final encoded = events
        .where(
            (entry) => entry.event.stage == RuntimeTemporalEventStage.encoded)
        .length;
    final decoded = events
        .where(
            (entry) => entry.event.stage == RuntimeTemporalEventStage.decoded)
        .length;
    final latestOccurredAt = events.isEmpty
        ? null
        : events
            .map((entry) => entry.event.occurredAt)
            .reduce((left, right) => left.isAfter(right) ? left : right);
    final peerIds =
        events.map((entry) => entry.event.peerId).whereType<String>().toSet();

    final topPeers = peerIds.map((id) => _buildPeerSummary(id, events)).toList()
      ..sort((left, right) {
        final eventCompare = right.eventCount.compareTo(left.eventCount);
        if (eventCompare != 0) {
          return eventCompare;
        }
        return right.latestOccurredAt.compareTo(left.latestOccurredAt);
      });

    return TemporalRuntimeEventSnapshot(
      generatedAt: now,
      windowStart: windowStart,
      windowEnd: now,
      totalEvents: events.length,
      encodedCount: encoded,
      decodedCount: decoded,
      bufferedCount: buffered,
      orderedCount: ordered,
      uniquePeerCount: peerIds.length,
      latestOccurredAt: latestOccurredAt,
      recentEvents: events,
      topPeers: topPeers,
    );
  }

  Stream<TemporalRuntimeEventSnapshot> watchRuntimeEventSnapshot({
    String source = 'ai2ai_protocol',
    String? peerId,
    Duration lookbackWindow = const Duration(minutes: 15),
    Duration refreshInterval = const Duration(seconds: 15),
    int limit = 200,
  }) {
    late final StreamController<TemporalRuntimeEventSnapshot> controller;
    Timer? timer;

    Future<void> emit() async {
      controller.add(
        await getRuntimeEventSnapshot(
          source: source,
          peerId: peerId,
          lookbackWindow: lookbackWindow,
          limit: limit,
        ),
      );
    }

    controller = StreamController<TemporalRuntimeEventSnapshot>.broadcast(
      onListen: () async {
        await emit();
        timer = Timer.periodic(refreshInterval, (_) {
          unawaited(emit());
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }

  TemporalRuntimeEventPeerSummary _buildPeerSummary(
    String peerId,
    List<RuntimeTemporalEventLookup> events,
  ) {
    final peerEvents = events.where((entry) => entry.event.peerId == peerId);
    final entries = peerEvents.toList();
    final latestOccurredAt = entries
        .map((entry) => entry.event.occurredAt)
        .reduce((left, right) => left.isAfter(right) ? left : right);

    return TemporalRuntimeEventPeerSummary(
      peerId: peerId,
      eventCount: entries.length,
      orderedCount: entries
          .where(
              (entry) => entry.event.stage == RuntimeTemporalEventStage.ordered)
          .length,
      bufferedCount: entries
          .where(
            (entry) => entry.event.stage == RuntimeTemporalEventStage.buffered,
          )
          .length,
      latestOccurredAt: latestOccurredAt,
    );
  }
}
