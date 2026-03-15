import 'dart:async';

import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_models.dart';
import 'package:avrai_runtime_os/services/admin/bham_admin_operations_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class ClubsCommunitiesViewerPage extends StatefulWidget {
  const ClubsCommunitiesViewerPage({super.key});

  @override
  State<ClubsCommunitiesViewerPage> createState() =>
      _ClubsCommunitiesViewerPageState();
}

class _ClubsCommunitiesViewerPageState
    extends State<ClubsCommunitiesViewerPage> {
  BhamAdminOperationsService? _service;
  Timer? _refreshTimer;

  bool _isLoading = true;
  String? _error;
  DiscoveryEntityType? _selectedType;
  CreationModerationState? _selectedState;
  List<AdminExplorerItem> _items = const <AdminExplorerItem>[];

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
          Timer.periodic(const Duration(seconds: 25), (_) => _load());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Creation explorer is unavailable: $error';
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
      final items = await service.listCreationExplorer();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load creation explorer: $error';
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
      title: 'Creation Explorer',
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

    final filtered = _items.where((item) {
      if (_selectedType != null && item.entity.type != _selectedType) {
        return false;
      }
      if (_selectedState != null && item.moderationState != _selectedState) {
        return false;
      }
      return true;
    }).toList();

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
                    'Public creation explorer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Wave 6 operator explorer for lists, clubs, communities, and events. Public creation stays live by default; moderation state is layered on top instead of hiding the object path.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Total: ${_items.length}')),
                      Chip(
                          label: Text(
                              'Flagged: ${_items.where((item) => item.moderationState == CreationModerationState.flagged).length}')),
                      Chip(
                          label: Text(
                              'Quarantined: ${_items.where((item) => item.moderationState == CreationModerationState.quarantined).length}')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Object type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedType == null,
                onSelected: (_) => setState(() => _selectedType = null),
              ),
              ...const <DiscoveryEntityType>[
                DiscoveryEntityType.list,
                DiscoveryEntityType.club,
                DiscoveryEntityType.community,
                DiscoveryEntityType.event,
              ].map(
                (type) => ChoiceChip(
                  label: Text(type.name),
                  selected: _selectedType == type,
                  onSelected: (_) => setState(() => _selectedType = type),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Moderation state',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedState == null,
                onSelected: (_) => setState(() => _selectedState = null),
              ),
              ...CreationModerationState.values.map(
                (state) => ChoiceChip(
                  label: Text(state.name),
                  selected: _selectedState == state,
                  onSelected: (_) => setState(() => _selectedState = state),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No creation objects match the current filters.'),
              ),
            )
          else
            ...filtered.take(50).map(
                  (item) => Card(
                    child: ListTile(
                      leading: Icon(_iconForType(item.entity.type)),
                      title: Text(item.title),
                      subtitle: Text(
                          '${item.subtitle} • ${_formatDate(item.createdAtUtc)}'),
                      trailing: Chip(
                        label: Text(item.moderationState.name),
                        backgroundColor: _colorForState(item.moderationState)
                            .withValues(alpha: 0.12),
                      ),
                      onTap: item.entity.type == DiscoveryEntityType.club
                          ? () => context
                              .go(AdminRoutePaths.clubDetail(item.entity.id))
                          : null,
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.gpp_maybe_outlined),
              title: const Text('Open Moderation Operations'),
              subtitle: const Text(
                'Use the moderation queue to flag, pause, quarantine, remove, or restore explorer objects.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminRoutePaths.moderation),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(DiscoveryEntityType type) {
    switch (type) {
      case DiscoveryEntityType.spot:
        return Icons.place_outlined;
      case DiscoveryEntityType.list:
        return Icons.list_alt_outlined;
      case DiscoveryEntityType.event:
        return Icons.event_outlined;
      case DiscoveryEntityType.club:
        return Icons.workspace_premium_outlined;
      case DiscoveryEntityType.community:
        return Icons.groups_outlined;
    }
  }

  Color _colorForState(CreationModerationState state) {
    switch (state) {
      case CreationModerationState.active:
        return AppColors.electricGreen;
      case CreationModerationState.flagged:
        return AppColors.warning;
      case CreationModerationState.paused:
        return AppColors.warning;
      case CreationModerationState.quarantined:
        return AppColors.error;
      case CreationModerationState.removed:
        return AppColors.grey500;
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }
}
