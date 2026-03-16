import 'dart:async';

import 'package:avrai_admin_app/ui/widgets/replay_simulation_widget_helpers.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ReplayLocalityOverlayCard extends StatefulWidget {
  const ReplayLocalityOverlayCard({super.key});

  @override
  State<ReplayLocalityOverlayCard> createState() =>
      _ReplayLocalityOverlayCardState();
}

class _ReplayLocalityOverlayCardState extends State<ReplayLocalityOverlayCard> {
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
          _error = 'Failed to load locality overlays: $error';
          _isLoading = false;
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
              icon: Icons.map_outlined,
              title: 'Birmingham Locality Overlays',
              subtitle:
                  'Neighborhood-readable locality pressure and contradiction sensitivity for replay inspection.',
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
              ...snapshot.localityOverlays.take(6).map(
                    (overlay) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(overlay.displayName),
                      subtitle: Text(
                        '${overlay.pressureBand} pressure • ${overlay.attentionBand} • ${overlay.primarySignals.join(', ')}',
                      ),
                      trailing: Text(
                        overlay.branchSensitivity.toStringAsFixed(2),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
