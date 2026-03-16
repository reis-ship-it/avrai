import 'dart:async';

import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/replay_simulation_widget_helpers.dart';
import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_constants.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ReplayScenarioComparisonCard extends StatefulWidget {
  const ReplayScenarioComparisonCard({super.key});

  @override
  State<ReplayScenarioComparisonCard> createState() =>
      _ReplayScenarioComparisonCardState();
}

class _ReplayScenarioComparisonCardState
    extends State<ReplayScenarioComparisonCard> {
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
          _error = 'Failed to load scenario comparisons: $error';
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
              icon: Icons.compare_arrows_outlined,
              title: 'Replay Branch Comparisons',
              subtitle:
                  'Baseline vs intervention deltas for attendance, movement, delivery, and safety stress.',
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              ReplaySimulationWidgetHelpers.buildError(context, _error!)
            else if (snapshot != null)
              ...snapshot.comparisons.take(3).map(
                    (comparison) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            comparison.summary,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...comparison.branchDiffs.take(2).map(
                                (diff) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${diff.branchRunId.split(':').last}: attendance ${_signed(diff.attendanceDelta)}, movement ${_signed(diff.movementDelta)}, focus ${displayNameForBhamLocality(_dominantLocality(diff))}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _dominantLocality(ReplayScenarioBranchDiff diff) {
    if (diff.localityPressureDeltas.isEmpty) {
      return bhamLocalityDisplayNames.keys.first;
    }
    return diff.localityPressureDeltas.entries
        .reduce(
          (left, right) => left.value.abs() >= right.value.abs() ? left : right,
        )
        .key;
  }

  String _signed(double value) {
    final pct = (value * 100).toStringAsFixed(1);
    return value >= 0 ? '+$pct%' : '$pct%';
  }
}
