import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/monitoring/network_activity_monitor.dart';
import 'package:avrai/core/monitoring/ai2ai_network_activity_event.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Security / Network tab for God-Mode dashboard.
///
/// Shows real-time AI2AI network activity (IDs and aggregate only; no PII or message content).
/// Uses AdminPrivacyFilter semantics: display only connection IDs, node IDs, event types.
class AdminSecurityNetworkTab extends StatefulWidget {
  const AdminSecurityNetworkTab({super.key});

  @override
  State<AdminSecurityNetworkTab> createState() =>
      _AdminSecurityNetworkTabState();
}

class _AdminSecurityNetworkTabState extends State<AdminSecurityNetworkTab> {
  NetworkActivityMonitor? _monitor;
  List<AI2AINetworkActivityEvent> _events = [];
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _resolveMonitor();
  }

  void _resolveMonitor() {
    if (!GetIt.instance.isRegistered<NetworkActivityMonitor>()) return;
    final monitor = GetIt.instance.get<NetworkActivityMonitor>();
    if (_monitor == monitor) return;
    _monitor = monitor;
    _events = monitor.getRecentEvents(limit: 100);
    if (!_subscribed) {
      _subscribed = true;
      monitor.eventStream.listen((event) {
        if (mounted) {
          setState(() {
            _events = monitor.getRecentEvents(limit: 100);
          });
        }
      });
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _resolveMonitor();

    return RefreshIndicator(
      onRefresh: () async {
        if (_monitor != null) {
          setState(() {
            _events = _monitor!.getRecentEvents(limit: 100);
          });
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(kSpaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI2AI Network Activity (security-only; no message content)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connection IDs and event types only. For full communications, use the Communications tab.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            if (_monitor == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(kSpaceMd),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Network Activity Monitor not available.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._events.map((e) => _buildEventCard(context, e)),
            if (_events.isEmpty && _monitor != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(kSpaceLg),
                  child: Center(
                    child: Text(
                      'No recent AI2AI network events.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
      BuildContext context, AI2AINetworkActivityEvent event) {
    final color = _colorForEventType(event.eventType);
    return Card(
      margin: const EdgeInsets.only(bottom: kSpaceXs),
      child: Padding(
        padding: const EdgeInsets.all(kSpaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kSpaceXs, vertical: kSpaceXxs),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.eventType,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(event.occurredAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            if (event.connectionId != null ||
                event.remoteNodeId != null ||
                event.reason != null) ...[
              const SizedBox(height: 8),
              if (event.connectionId != null)
                Text('Connection: ${event.connectionId}',
                    style: Theme.of(context).textTheme.bodySmall),
              if (event.remoteNodeId != null)
                Text('Remote node: ${event.remoteNodeId}',
                    style: Theme.of(context).textTheme.bodySmall),
              if (event.reason != null)
                Text('Reason: ${event.reason}',
                    style: Theme.of(context).textTheme.bodySmall),
              if (event.metric != null)
                Text('Metric: ${event.metric}',
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorForEventType(String type) {
    if (type.contains('failure') || type.contains('anomaly')) {
      return AppColors.error;
    }
    if (type.contains('success') || type.contains('established')) {
      return AppColors.success;
    }
    return AppTheme.primaryColor;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
