// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:avrai_runtime_os/services/admin/admin_god_mode_service.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_admin_diagnostics_bridge.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:get_it/get_it.dart';

/// AI Live Map Page
/// Shows all active AI agents on a live map with their location, data, and predictions
class AILiveMapPage extends StatefulWidget {
  final AdminGodModeService? godModeService;

  const AILiveMapPage({
    super.key,
    this.godModeService,
  });

  @override
  State<AILiveMapPage> createState() => _AILiveMapPageState();
}

class _AILiveMapPageState extends State<AILiveMapPage> {
  List<ActiveAIAgentData> _activeAgents = [];
  Map<String, WherePointResolution> _localityResolutions =
      <String, WherePointResolution>{};
  bool _isLoading = true;
  gmap.GoogleMapController? _mapController;
  ActiveAIAgentData? _selectedAgent;
  Timer? _refreshTimer;
  late final WhereKernelContract? _whereKernel;
  late final LocalityNativeAdminDiagnosticsBridge? _localityDiagnostics;

  @override
  void initState() {
    super.initState();
    _whereKernel = GetIt.instance.isRegistered<WhereKernelContract>()
        ? GetIt.instance<WhereKernelContract>()
        : null;
    _localityDiagnostics =
        GetIt.instance.isRegistered<LocalityNativeAdminDiagnosticsBridge>()
            ? GetIt.instance<LocalityNativeAdminDiagnosticsBridge>()
            : null;
    _loadActiveAgents();
    // Auto-refresh every 30 seconds
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _loadActiveAgents());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadActiveAgents() async {
    if (widget.godModeService == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final agents = await widget.godModeService!.getAllActiveAIAgents();
      final localityResolutions = await _resolveLocalityResolutions(agents);
      setState(() {
        _activeAgents = agents;
        _localityResolutions = localityResolutions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading AI agents: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<Map<String, WherePointResolution>> _resolveLocalityResolutions(
    List<ActiveAIAgentData> agents,
  ) async {
    if (agents.isEmpty) {
      return <String, WherePointResolution>{};
    }

    final diagnostics = _localityDiagnostics;
    if (diagnostics != null) {
      try {
        final occurredAtUtc = DateTime.now().toUtc();
        final report = await diagnostics.diagnose(
          probes: agents
              .map(
                (agent) => LocalityAdminDiagnosticsProbe(
                  latitude: agent.latitude,
                  longitude: agent.longitude,
                  occurredAtUtc: occurredAtUtc,
                ),
              )
              .toList(),
          cityProfile: null,
        );
        if (report.resolutions.isNotEmpty) {
          final entries = <String, WherePointResolution>{};
          for (var i = 0;
              i < agents.length && i < report.resolutions.length;
              i += 1) {
            entries[agents[i].userId] =
                WherePointResolution.fromLocality(report.resolutions[i]);
          }
          return entries;
        }
      } catch (_) {
        // Fall through to kernel point resolution path.
      }
    }

    final kernel = _whereKernel;
    if (kernel == null) {
      return <String, WherePointResolution>{};
    }

    final entries = await Future.wait(
      agents.map((agent) async {
        try {
          final resolution = await kernel.resolvePoint(
            WherePointQuery(
              latitude: agent.latitude,
              longitude: agent.longitude,
              occurredAtUtc: DateTime.now().toUtc(),
              audience: WhereProjectionAudience.admin,
              includeGeometry: true,
              includeAttribution: true,
              includePrediction: true,
            ),
          );
          return MapEntry(agent.userId, resolution);
        } catch (_) {
          return null;
        }
      }),
    );

    return <String, WherePointResolution>{
      for (final entry
          in entries.whereType<MapEntry<String, WherePointResolution>>())
        entry.key: entry.value,
    };
  }

  Set<gmap.Marker> _buildMarkers() {
    return _activeAgents.map((agent) {
      final locality = _localityResolutions[agent.userId];
      return gmap.Marker(
        markerId: gmap.MarkerId(agent.userId),
        position: gmap.LatLng(agent.latitude, agent.longitude),
        icon: gmap.BitmapDescriptor.defaultMarkerWithHue(
          agent.isOnline
              ? gmap.BitmapDescriptor.hueGreen
              : gmap.BitmapDescriptor.hueOrange,
        ),
        infoWindow: gmap.InfoWindow(
          title: 'AI Agent: ${agent.aiSignature.substring(0, 12)}...',
          snippet:
              'Status: ${agent.aiStatus} • ${locality?.projection.primaryLabel ?? 'locality resolving'} • Connections: ${agent.aiConnections}',
        ),
        onTap: () {
          setState(() {
            _selectedAgent = agent;
          });
        },
      );
    }).toSet();
  }

  Set<gmap.Circle> _buildLocalityCircles() {
    final circles = <gmap.Circle>{};
    for (final agent in _activeAgents) {
      final resolution = _localityResolutions[agent.userId];
      if (resolution == null) {
        continue;
      }
      final color = _colorForResolution(resolution);
      circles.add(
        gmap.Circle(
          circleId: gmap.CircleId('locality-${agent.userId}'),
          center: gmap.LatLng(agent.latitude, agent.longitude),
          radius: _radiusForResolution(resolution),
          fillColor: color.withValues(alpha: 0.18),
          strokeColor: color.withValues(alpha: 0.9),
          strokeWidth: 2,
        ),
      );
    }
    return circles;
  }

  gmap.LatLng _getMapCenter() {
    if (_activeAgents.isEmpty) {
      return const gmap.LatLng(37.7749, -122.4194); // Default: San Francisco
    }

    // Calculate center of all agents
    double sumLat = 0;
    double sumLng = 0;
    for (final agent in _activeAgents) {
      sumLat += agent.latitude;
      sumLng += agent.longitude;
    }

    return gmap.LatLng(
      sumLat / _activeAgents.length,
      sumLng / _activeAgents.length,
    );
  }

  int get _nearBoundaryCount => _localityResolutions.values
      .where((resolution) => resolution.projection.nearBoundary)
      .length;

  int get _advisoryCount => _localityResolutions.values.where((resolution) {
        return resolution.projection.metadata['advisoryStatus'] == 'active';
      }).length;

  int get _changingCount => _localityResolutions.values.where((resolution) {
        final predictiveTrend =
            resolution.projection.metadata['predictiveTrend'] as String?;
        return predictiveTrend != null && predictiveTrend != 'stable';
      }).length;

  Color _colorForResolution(WherePointResolution resolution) {
    final metadata = resolution.projection.metadata;
    final advisoryStatus = metadata['advisoryStatus'] as String?;
    final predictiveTrend = metadata['predictiveTrend'] as String?;

    if (advisoryStatus == 'active') {
      return AppColors.error;
    }
    if (resolution.projection.nearBoundary ||
        (predictiveTrend != null && predictiveTrend != 'stable')) {
      return AppColors.warning;
    }
    if (resolution.projection.confidenceBucket == 'high') {
      return AppColors.success;
    }
    return AppColors.grey500;
  }

  double _radiusForResolution(WherePointResolution resolution) {
    final baseRadius = switch (resolution.projection.confidenceBucket) {
      'high' => 120.0,
      'medium' => 180.0,
      _ => 240.0,
    };
    return resolution.projection.nearBoundary ? baseRadius + 90.0 : baseRadius;
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: '',
      showNavigationBar: false,
      body: Stack(
        children: [
          // Map
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : gmap.GoogleMap(
                  initialCameraPosition: gmap.CameraPosition(
                    target: _getMapCenter(),
                    zoom: 10,
                  ),
                  markers: _buildMarkers(),
                  circles: _buildLocalityCircles(),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Agents Live Map',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '${_activeAgents.length} active agents',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.grey500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMetricChip(
                              label: 'Localities',
                              value: '${_localityResolutions.length}',
                            ),
                            _buildMetricChip(
                              label: 'Boundary',
                              value: '$_nearBoundaryCount',
                            ),
                            _buildMetricChip(
                              label: 'Advisory',
                              value: '$_advisoryCount',
                            ),
                            _buildMetricChip(
                              label: 'Changing',
                              value: '$_changingCount',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadActiveAgents,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
          ),

          // Selected Agent Info Panel
          if (_selectedAgent != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedAgent = null;
                          });
                        },
                      ),
                    ),

                    // Agent Info
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildAgentInfo(_selectedAgent!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildAgentInfo(ActiveAIAgentData agent) {
    final topAction = agent.topPredictedAction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              backgroundColor: agent.isOnline
                  ? AppColors.electricGreen.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
              child: Icon(
                Icons.smart_toy,
                color: agent.isOnline
                    ? AppColors.electricGreen
                    : AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Agent',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    agent.aiSignature,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(agent.isOnline ? 'Online' : 'Offline'),
              backgroundColor: agent.isOnline
                  ? AppColors.electricGreen.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Location
        _buildInfoRow('Location',
            '${agent.latitude.toStringAsFixed(4)}, ${agent.longitude.toStringAsFixed(4)}'),
        _buildInfoRow('Last Active',
            DateFormat('MMM d, y • h:mm a').format(agent.lastActive)),

        const Divider(),

        // AI Data
        Text(
          'AI Data',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Status', agent.aiStatus),
        _buildInfoRow('Connections', '${agent.aiConnections}'),
        _buildInfoRow('Current Stage', agent.currentStage),
        if (agent.confidence > 0)
          _buildInfoRow('Prediction Confidence',
              '${(agent.confidence * 100).toStringAsFixed(1)}%'),

        const Divider(),

        // Predictions
        Text(
          'Predicted Next Actions',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (agent.predictedActions.isEmpty)
          Text(
            'No predictions available',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.grey500),
          )
        else
          ...agent.predictedActions.take(5).map((action) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.action,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          action.category,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.grey500),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                        '${(action.probability * 100).toStringAsFixed(0)}%'),
                    backgroundColor:
                        AppColors.electricGreen.withValues(alpha: 0.2),
                  ),
                ],
              ),
            );
          }),

        if (topAction != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.electricGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Most Likely Next Action',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        topAction.action,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Privacy Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.privacy_tip,
                  color: AppColors.electricGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Privacy: Only AI-related data and location (vibe indicators) are shown. No personal information (name, email, phone, home address) is displayed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey700,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
