import 'dart:async';

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_operations_service.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class CommunicationsViewerPage extends StatefulWidget {
  const CommunicationsViewerPage({super.key});

  @override
  State<CommunicationsViewerPage> createState() =>
      _CommunicationsViewerPageState();
}

class _CommunicationsViewerPageState extends State<CommunicationsViewerPage> {
  BhamAdminOperationsService? _service;
  Timer? _refreshTimer;

  bool _isLoading = true;
  String? _error;
  List<AdminCommunicationReadModel> _communications =
      const <AdminCommunicationReadModel>[];
  List<AdminDeliveryFailureReadModel> _failures =
      const <AdminDeliveryFailureReadModel>[];
  List<RouteDeliverySummary> _routes = const <RouteDeliverySummary>[];
  List<DirectMatchOutcomeView> _matches = const <DirectMatchOutcomeView>[];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _service = GetIt.instance<BhamAdminOperationsService>();
      await _load();
      _refreshTimer =
          Timer.periodic(const Duration(seconds: 20), (_) => _load());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Communications oversight is unavailable: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _load() async {
    final service = _service;
    if (service == null) {
      return;
    }
    try {
      final results = await Future.wait<dynamic>([
        service.listCommunicationSummaries(),
        service.listDeliveryFailures(),
        service.summarizeRoutes(),
        service.listDirectMatchOutcomes(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _communications = results[0] as List<AdminCommunicationReadModel>;
        _failures = results[1] as List<AdminDeliveryFailureReadModel>;
        _routes = results[2] as List<RouteDeliverySummary>;
        _matches = results[3] as List<DirectMatchOutcomeView>;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load communications oversight: $error';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Communications Oversight',
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wave 5 Runtime Contracts, Wave 6 Admin Surfaces',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This page is the explicit Wave 6 carry-forward for support threads, route receipts, delivery failures, and direct-match outcomes. Everything here is pseudonymous by default.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _kpiChip('Threads', _communications.length),
                      _kpiChip('Failures', _failures.length),
                      _kpiChip('Route modes', _routes.length),
                      _kpiChip('Matches', _matches.length),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildRoutesCard(context),
          const SizedBox(height: 12),
          _buildCommunicationsCard(context),
          const SizedBox(height: 12),
          _buildFailuresCard(context),
          const SizedBox(height: 12),
          _buildMatchesCard(context),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: const Text('Open AI2AI Mesh Dashboard'),
              subtitle: const Text(
                'Use the mesh dashboard for live exchange overlays and topology.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.ai2ai),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attempted vs winning routes',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_routes.isEmpty)
              const Text('No route data recorded yet.')
            else
              ..._routes.map((route) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_iconForMode(route.mode)),
                    title: Text(route.mode.name),
                    subtitle: Text(
                      '${route.successes}/${route.attempts} successful'
                      '${route.averageLatencyMs == null ? '' : ' • ${route.averageLatencyMs}ms avg'}',
                    ),
                    trailing: Text('${(route.successRate * 100).round()}%'),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Support and thread summaries',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_communications.isEmpty)
              const Text('No communication summaries are available yet.')
            else
              ..._communications.take(12).map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_iconForThread(item.threadKind)),
                    title: Text(item.displayTitle),
                    subtitle: Text(
                      '${item.messageCount} messages'
                      '${item.lastMessagePreview == null ? '' : ' • ${item.lastMessagePreview}'}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatDate(item.lastActivityAtUtc)),
                        if (item.routeReceipt?.winningRoute != null)
                          Text(
                            item.routeReceipt!.winningRoute!.mode.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildFailuresCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Failed and quarantined delivery summaries',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_failures.isEmpty)
              const Text('No delivery failures recorded.')
            else
              ..._failures.take(10).map((failure) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning),
                    title: Text(failure.reason),
                    subtitle: Text(
                      '${failure.threadId} • ${failure.messageId}',
                    ),
                    trailing: Text(_formatDate(failure.recordedAtUtc)),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Direct-match invitation outcomes',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_matches.isEmpty)
              const Text('No direct-match invitations exist yet.')
            else
              ..._matches.take(10).map((match) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      match.chatOpened
                          ? Icons.mark_chat_read
                          : Icons.person_off,
                      color: match.chatOpened
                          ? AppColors.electricGreen
                          : AppColors.warning,
                    ),
                    title: Text(
                      '${match.participantA.displayLabel} ↔ ${match.participantB.displayLabel}',
                    ),
                    subtitle: Text(
                      '${(match.compatibilityScore * 100).toStringAsFixed(1)}% compatibility'
                      '${match.declineMessage == null ? '' : ' • ${match.declineMessage}'}',
                    ),
                    trailing: Text(_formatDate(match.createdAtUtc)),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _kpiChip(String label, int value) {
    return Chip(label: Text('$label: $value'));
  }

  IconData _iconForMode(TransportMode mode) {
    switch (mode) {
      case TransportMode.ble:
        return Icons.bluetooth;
      case TransportMode.localWifi:
        return Icons.wifi;
      case TransportMode.nearbyRelay:
        return Icons.compare_arrows;
      case TransportMode.wormhole:
        return Icons.blur_circular;
      case TransportMode.cloudAssist:
        return Icons.cloud_outlined;
    }
  }

  IconData _iconForThread(ChatThreadKind kind) {
    switch (kind) {
      case ChatThreadKind.admin:
        return Icons.support_agent;
      case ChatThreadKind.event:
        return Icons.event;
      case ChatThreadKind.announcement:
        return Icons.campaign_outlined;
      case ChatThreadKind.club:
        return Icons.groups_2_outlined;
      case ChatThreadKind.community:
        return Icons.groups_outlined;
      case ChatThreadKind.matchedDirect:
        return Icons.favorite_outline;
      case ChatThreadKind.personalAgent:
        return Icons.psychology_alt_outlined;
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final hh = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final mm = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day} $hh:$mm $suffix';
  }
}
