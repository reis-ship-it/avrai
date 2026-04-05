import 'dart:async';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_runtime_os/services/admin/temporal_kernel_admin_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TemporalKernelDiagnosticsCard extends StatefulWidget {
  const TemporalKernelDiagnosticsCard({super.key});

  @override
  State<TemporalKernelDiagnosticsCard> createState() =>
      _TemporalKernelDiagnosticsCardState();
}

class _TemporalKernelDiagnosticsCardState
    extends State<TemporalKernelDiagnosticsCard> {
  TemporalKernelAdminService? _service;
  StreamSubscription<TemporalRuntimeEventSnapshot>? _subscription;
  bool _isLoading = true;
  String? _error;
  TemporalRuntimeEventSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _service = GetIt.instance.isRegistered<TemporalKernelAdminService>()
        ? GetIt.instance<TemporalKernelAdminService>()
        : null;
    _startWatching();
  }

  void _startWatching() {
    final service = _service;
    if (service == null) {
      _showUnavailableState();
      return;
    }

    _subscription?.cancel();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    _subscription = service.watchRuntimeEventSnapshot().listen(
      (snapshot) {
        if (!mounted) {
          return;
        }
        setState(() {
          _snapshot = snapshot;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _error = 'Failed to load temporal kernel diagnostics: $error';
        });
      },
    );
  }

  Future<void> _loadSnapshot() async {
    final service = _service;
    if (service == null) {
      _showUnavailableState();
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final snapshot = await service.getRuntimeEventSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Failed to load temporal kernel diagnostics: $error';
      });
    }
  }

  void _showUnavailableState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _error = 'Temporal kernel diagnostics are not registered.';
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temporal Kernel Diagnostics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live `when` kernel lineage for ordered, buffered, encoded, and decoded runtime events.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _loadSnapshot,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh temporal diagnostics',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorState(context, _error!)
            else if (snapshot != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSummaryChip('Events', snapshot.totalEvents.toString()),
                  _buildSummaryChip(
                      'Peers', snapshot.uniquePeerCount.toString()),
                  _buildSummaryChip(
                    'Ordered',
                    snapshot.orderedCount.toString(),
                  ),
                  _buildSummaryChip(
                    'Buffered',
                    snapshot.bufferedCount.toString(),
                  ),
                  _buildSummaryChip(
                    'Encoded',
                    snapshot.encodedCount.toString(),
                  ),
                  _buildSummaryChip(
                    'Decoded',
                    snapshot.decodedCount.toString(),
                  ),
                  _buildSummaryChip(
                    'Window',
                    '${snapshot.windowEnd.difference(snapshot.windowStart).inMinutes}m',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTopPeers(context, snapshot),
              const SizedBox(height: 16),
              _buildRecentEvents(context, snapshot),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Updated ${_formatTimestamp(snapshot.generatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        error,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
            ),
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTopPeers(
    BuildContext context,
    TemporalRuntimeEventSnapshot snapshot,
  ) {
    if (snapshot.topPeers.isEmpty) {
      return _buildSectionCard(
        context,
        title: 'Top Peers',
        child:
            const Text('No peer-scoped runtime lineage in the current window.'),
      );
    }

    return _buildSectionCard(
      context,
      title: 'Top Peers',
      child: Column(
        children: snapshot.topPeers.take(4).map((peer) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.hub_outlined),
            title: Text(peer.peerId),
            subtitle: Text(
              '${peer.eventCount} events, ${peer.orderedCount} ordered, ${peer.bufferedCount} buffered',
            ),
            trailing: Text(_formatTimestamp(peer.latestOccurredAt)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentEvents(
    BuildContext context,
    TemporalRuntimeEventSnapshot snapshot,
  ) {
    if (snapshot.recentEvents.isEmpty) {
      return _buildSectionCard(
        context,
        title: 'Recent Events',
        child: const Text(
            'No runtime temporal events recorded in the current window.'),
      );
    }

    return _buildSectionCard(
      context,
      title: 'Recent Events',
      child: Column(
        children: snapshot.recentEvents.take(5).map((entry) {
          final event = entry.event;
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(_iconForStage(event.stage)),
            title: Text('${event.eventType} · ${event.stage.name}'),
            subtitle: Text(
              '${event.source}${event.peerId == null ? '' : ' · ${event.peerId}'}',
            ),
            trailing: Text(_formatTimestamp(event.occurredAt)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  IconData _iconForStage(RuntimeTemporalEventStage stage) {
    switch (stage) {
      case RuntimeTemporalEventStage.encoded:
        return Icons.outbound_outlined;
      case RuntimeTemporalEventStage.decoded:
        return Icons.inbox_outlined;
      case RuntimeTemporalEventStage.buffered:
        return Icons.pause_circle_outline;
      case RuntimeTemporalEventStage.ordered:
        return Icons.done_all_outlined;
    }
  }

  String _formatTimestamp(DateTime time) {
    final utc = time.toUtc();
    final hh = utc.hour.toString().padLeft(2, '0');
    final mm = utc.minute.toString().padLeft(2, '0');
    final ss = utc.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss UTC';
  }
}
