import 'package:avrai_runtime_os/services/admin/temporal_kernel_admin_service.dart';

class RuntimeTemporalContext {
  const RuntimeTemporalContext({
    required this.totalEvents,
    required this.orderedCount,
    required this.bufferedCount,
    required this.uniquePeerCount,
    required this.topPeerId,
    required this.latestOccurredAt,
    required this.summary,
  });

  final int totalEvents;
  final int orderedCount;
  final int bufferedCount;
  final int uniquePeerCount;
  final String? topPeerId;
  final DateTime? latestOccurredAt;
  final String summary;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'totalEvents': totalEvents,
      'orderedCount': orderedCount,
      'bufferedCount': bufferedCount,
      'uniquePeerCount': uniquePeerCount,
      if (topPeerId != null) 'topPeerId': topPeerId,
      if (latestOccurredAt != null)
        'latestOccurredAt': latestOccurredAt!.toUtc().toIso8601String(),
      'summary': summary,
    };
  }

  factory RuntimeTemporalContext.empty() {
    return const RuntimeTemporalContext(
      totalEvents: 0,
      orderedCount: 0,
      bufferedCount: 0,
      uniquePeerCount: 0,
      topPeerId: null,
      latestOccurredAt: null,
      summary: 'No recent runtime temporal lineage was available.',
    );
  }
}

class RuntimeTemporalContextService {
  RuntimeTemporalContextService({
    required TemporalKernelAdminService temporalKernelAdminService,
  }) : _temporalKernelAdminService = temporalKernelAdminService;

  final TemporalKernelAdminService _temporalKernelAdminService;

  Future<RuntimeTemporalContext> buildContext({
    String source = 'ai2ai_protocol',
    Duration lookbackWindow = const Duration(minutes: 15),
  }) async {
    final snapshot = await _temporalKernelAdminService.getRuntimeEventSnapshot(
      source: source,
      lookbackWindow: lookbackWindow,
    );
    final topPeerId =
        snapshot.topPeers.isEmpty ? null : snapshot.topPeers.first.peerId;
    final latestOccurredAt = snapshot.latestOccurredAt;
    final summary = snapshot.totalEvents == 0
        ? 'No recent runtime temporal lineage was available.'
        : 'Recent runtime lineage shows ${snapshot.totalEvents} events, '
            '${snapshot.orderedCount} ordered, ${snapshot.bufferedCount} buffered, '
            'across ${snapshot.uniquePeerCount} peers'
            '${topPeerId == null ? '' : '; top peer is $topPeerId'}'
            '${latestOccurredAt == null ? '' : '; latest event at ${latestOccurredAt.toUtc().toIso8601String()}'}'
            '.';

    return RuntimeTemporalContext(
      totalEvents: snapshot.totalEvents,
      orderedCount: snapshot.orderedCount,
      bufferedCount: snapshot.bufferedCount,
      uniquePeerCount: snapshot.uniquePeerCount,
      topPeerId: topPeerId,
      latestOccurredAt: latestOccurredAt,
      summary: summary,
    );
  }
}
