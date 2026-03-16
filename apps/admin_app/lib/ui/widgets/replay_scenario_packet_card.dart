import 'dart:async';

import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/replay_simulation_widget_helpers.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ReplayScenarioPacketCard extends StatefulWidget {
  const ReplayScenarioPacketCard({super.key});

  @override
  State<ReplayScenarioPacketCard> createState() =>
      _ReplayScenarioPacketCardState();
}

class _ReplayScenarioPacketCardState extends State<ReplayScenarioPacketCard> {
  ReplaySimulationAdminService? _service;
  StreamSubscription<ReplaySimulationAdminSnapshot>? _subscription;
  ReplaySimulationAdminSnapshot? _snapshot;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = GetIt.instance.isRegistered<ReplaySimulationAdminService>()
        ? GetIt.instance<ReplaySimulationAdminService>()
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
    _subscription = service.watchSnapshot().listen(
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
          _error = 'Failed to load scenario packets: $error';
        });
      },
    );
  }

  void _showUnavailableState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _error = 'Replay simulation admin service is not registered.';
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
          children: <Widget>[
            ReplaySimulationWidgetHelpers.buildHeader(
              context,
              icon: Icons.schema_outlined,
              title: 'Replay Scenario Packets',
              subtitle:
                  'Structured Birmingham replay scenarios and bounded intervention branches.',
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              ReplaySimulationWidgetHelpers.buildError(context, _error!)
            else if (snapshot != null) ...<Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ReplaySimulationWidgetHelpers.summaryChip(
                    'Scenarios',
                    snapshot.scenarios.length.toString(),
                  ),
                  ReplaySimulationWidgetHelpers.summaryChip(
                    'Comparisons',
                    snapshot.comparisons.length.toString(),
                  ),
                  ReplaySimulationWidgetHelpers.summaryChip(
                    'Receipts',
                    snapshot.receipts.length.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...snapshot.scenarios.take(4).map(
                    (scenario) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            scenario.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scenario.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Localities: ${scenario.seedLocalityCodes.join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Interventions: ${scenario.interventions.map((entry) => entry.kind.name).join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
