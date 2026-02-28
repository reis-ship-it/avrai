import 'dart:async';

import 'package:avrai/core/services/admin/admin_auth_service.dart';
import 'package:avrai/core/services/admin/admin_internal_use_agreement_service.dart';
import 'package:avrai/core/services/admin/urk_kernel_control_plane_service.dart';
import 'package:avrai/core/services/admin/urk_user_runtime_observability_threshold_service.dart';
import 'package:avrai/core/services/ai_infrastructure/kernel_governance_telemetry_service.dart';
import 'package:avrai/core/services/infrastructure/feature_flag_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

class UrkKernelConsolePage extends StatefulWidget {
  const UrkKernelConsolePage({
    super.key,
    this.initialDecisionId,
    this.initialView,
  });

  final String? initialDecisionId;
  final String? initialView;

  @override
  State<UrkKernelConsolePage> createState() => _UrkKernelConsolePageState();
}

class _UrkKernelConsolePageState extends State<UrkKernelConsolePage> {
  late Future<List<UrkKernelControlPlaneRecord>> _recordsFuture;
  late Future<UrkUserRuntimeLearningObservabilitySummary>
      _userRuntimeObservabilityFuture;
  late Future<UrkUserRuntimeObservabilityThresholds> _thresholdsFuture;
  late Future<List<UrkUserRuntimeObservabilityThresholdAuditEvent>>
      _thresholdAuditFuture;
  late Future<KernelGovernanceTelemetrySummary> _governanceSummaryFuture;
  late Future<KernelGovernanceTelemetrySummary> _governanceLastHourFuture;
  late Future<List<KernelGovernanceTelemetryEvent>> _governanceRecentFuture;
  late Future<List<AdminInternalUseAgreementRecord>> _agreementEventsFuture;
  Timer? _livePollingTimer;
  bool _isKernelGovernanceEnforced = true;
  bool _isGovernanceToggleBusy = false;
  bool _isThresholdConfigBusy = false;
  bool _isLivePollingEnabled = true;
  DateTime? _lastRefreshedAt;
  _UserRuntimeObservabilityRange _userRuntimeRange =
      _UserRuntimeObservabilityRange.last24h;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _loadRecords();
    _userRuntimeObservabilityFuture = _loadUserRuntimeObservability();
    _thresholdsFuture = _loadObservabilityThresholds();
    _thresholdAuditFuture = _loadThresholdAuditEvents();
    _governanceSummaryFuture = _loadGovernanceSummary();
    _governanceLastHourFuture = _loadGovernanceLastHourSummary();
    _governanceRecentFuture = _loadGovernanceRecent();
    _agreementEventsFuture = _loadAgreementEvents();
    _compactGovernanceTelemetry();
    _loadGovernanceFlag();
    _lastRefreshedAt = DateTime.now().toUtc();
    _startLivePolling();
  }

  Future<List<UrkKernelControlPlaneRecord>> _loadRecords() async {
    final service = GetIt.instance<UrkKernelControlPlaneService>();
    return service.listKernels();
  }

  Future<KernelGovernanceTelemetrySummary> _loadGovernanceSummary() async {
    final telemetry = GetIt.instance<KernelGovernanceTelemetryService>();
    return telemetry.summarize();
  }

  Future<UrkUserRuntimeObservabilityThresholds>
      _loadObservabilityThresholds() async {
    final service = await _buildThresholdOverrideService();
    return service.loadEffective();
  }

  Future<List<UrkUserRuntimeObservabilityThresholdAuditEvent>>
      _loadThresholdAuditEvents() async {
    final service = await _buildThresholdOverrideService();
    return service.listRecentAudit(limit: 8);
  }

  Future<UrkUserRuntimeLearningObservabilitySummary>
      _loadUserRuntimeObservability() async {
    final service = GetIt.instance<UrkKernelControlPlaneService>();
    return service.summarizeUserRuntimeLearning(
        window: _userRuntimeRange.window);
  }

  Future<KernelGovernanceTelemetrySummary>
      _loadGovernanceLastHourSummary() async {
    final telemetry = GetIt.instance<KernelGovernanceTelemetryService>();
    return telemetry.summarize(window: const Duration(hours: 1));
  }

  Future<List<KernelGovernanceTelemetryEvent>> _loadGovernanceRecent() async {
    final telemetry = GetIt.instance<KernelGovernanceTelemetryService>();
    return telemetry.listAll();
  }

  Future<List<AdminInternalUseAgreementRecord>> _loadAgreementEvents() async {
    final prefs = await SharedPreferencesCompat.getInstance();
    final service = AdminInternalUseAgreementService(
      prefs: prefs,
      supabaseService: SupabaseService(),
    );
    return service.listRecent();
  }

  Future<void> _compactGovernanceTelemetry() async {
    try {
      final telemetry = GetIt.instance<KernelGovernanceTelemetryService>();
      await telemetry.compact();
    } catch (_) {
      // Best effort.
    }
  }

  Future<void> _refresh() async {
    unawaited(_compactGovernanceTelemetry());
    final next = _loadRecords();
    setState(() {
      _recordsFuture = next;
      _userRuntimeObservabilityFuture = _loadUserRuntimeObservability();
      _thresholdsFuture = _loadObservabilityThresholds();
      _thresholdAuditFuture = _loadThresholdAuditEvents();
      _governanceSummaryFuture = _loadGovernanceSummary();
      _governanceLastHourFuture = _loadGovernanceLastHourSummary();
      _governanceRecentFuture = _loadGovernanceRecent();
      _agreementEventsFuture = _loadAgreementEvents();
      _lastRefreshedAt = DateTime.now().toUtc();
    });
    await next;
  }

  Future<void> _refreshTelemetryOnly() async {
    unawaited(_compactGovernanceTelemetry());
    if (!mounted) {
      return;
    }
    setState(() {
      _userRuntimeObservabilityFuture = _loadUserRuntimeObservability();
      _governanceSummaryFuture = _loadGovernanceSummary();
      _governanceLastHourFuture = _loadGovernanceLastHourSummary();
      _governanceRecentFuture = _loadGovernanceRecent();
      _agreementEventsFuture = _loadAgreementEvents();
      _lastRefreshedAt = DateTime.now().toUtc();
    });
  }

  Future<UrkUserRuntimeObservabilityThresholdOverrideService>
      _buildThresholdOverrideService() async {
    final prefs = await SharedPreferencesCompat.getInstance();
    return UrkUserRuntimeObservabilityThresholdOverrideService(
      prefs: prefs,
      baseService: const UrkUserRuntimeObservabilityThresholdService(),
    );
  }

  String _resolveAdminActor() {
    try {
      if (GetIt.instance.isRegistered<AdminAuthService>()) {
        final session = GetIt.instance<AdminAuthService>().getCurrentSession();
        final username = session?.username.trim();
        if (username != null && username.isNotEmpty) {
          return 'admin:$username';
        }
      }
    } catch (_) {
      // Best effort.
    }
    return 'admin:console';
  }

  Future<void> _editSelectedRangeThresholds() async {
    final thresholds = await _thresholdsFuture;
    if (!mounted) {
      return;
    }
    final selectedWindow = _userRuntimeRange.toConfigWindow();
    final current = thresholds.forWindow(selectedWindow);
    final next = await _showThresholdEditorDialog(
      current,
      thresholds.validation,
    );
    if (next == null || !mounted) {
      return;
    }

    setState(() {
      _isThresholdConfigBusy = true;
    });
    try {
      final service = await _buildThresholdOverrideService();
      await service.upsertWindowOverride(
        window: selectedWindow,
        entry: next,
        actor: _resolveAdminActor(),
        reason: 'admin_console_manual_threshold_update',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _thresholdsFuture = _loadObservabilityThresholds();
        _thresholdAuditFuture = _loadThresholdAuditEvents();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Saved ${_userRuntimeRange.label} observability thresholds'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save thresholds: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isThresholdConfigBusy = false;
        });
      }
    }
  }

  Future<void> _clearThresholdOverrides() async {
    setState(() {
      _isThresholdConfigBusy = true;
    });
    try {
      final service = await _buildThresholdOverrideService();
      await service.clearOverrides(
        actor: _resolveAdminActor(),
        reason: 'admin_console_reset_to_runtime_defaults',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _thresholdsFuture = _loadObservabilityThresholds();
        _thresholdAuditFuture = _loadThresholdAuditEvents();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Threshold overrides reset to runtime defaults'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset thresholds: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isThresholdConfigBusy = false;
        });
      }
    }
  }

  Future<UrkUserRuntimeObservabilityThresholdEntry?> _showThresholdEditorDialog(
    UrkUserRuntimeObservabilityThresholdEntry current,
    UrkUserRuntimeObservabilityValidationRules validation,
  ) async {
    final warnOptOutCtrl =
        TextEditingController(text: current.warnOptOutRatePct.toString());
    final criticalOptOutCtrl =
        TextEditingController(text: current.criticalOptOutRatePct.toString());
    final warnRejectionCtrl =
        TextEditingController(text: current.warnRejectionRatePct.toString());
    final criticalRejectionCtrl = TextEditingController(
      text: current.criticalRejectionRatePct.toString(),
    );
    String? inlineError;

    final result = await showDialog<UrkUserRuntimeObservabilityThresholdEntry>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(
                  'Edit ${_userRuntimeRange.label} Observability Thresholds'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: warnOptOutCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Warn opt-out %',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: criticalOptOutCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Critical opt-out %',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: warnRejectionCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Warn rejection %',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: criticalRejectionCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Critical rejection %',
                      ),
                    ),
                    if (inlineError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        inlineError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final warnOptOut =
                        double.tryParse(warnOptOutCtrl.text.trim());
                    final criticalOptOut =
                        double.tryParse(criticalOptOutCtrl.text.trim());
                    final warnRejection =
                        double.tryParse(warnRejectionCtrl.text.trim());
                    final criticalRejection =
                        double.tryParse(criticalRejectionCtrl.text.trim());

                    if (warnOptOut == null ||
                        criticalOptOut == null ||
                        warnRejection == null ||
                        criticalRejection == null) {
                      setLocalState(() {
                        inlineError =
                            'All fields must be valid numeric values.';
                      });
                      return;
                    }
                    if (!_inBounds(warnOptOut, validation.warnOptOutRatePct) ||
                        !_inBounds(
                          criticalOptOut,
                          validation.criticalOptOutRatePct,
                        ) ||
                        !_inBounds(
                          warnRejection,
                          validation.warnRejectionRatePct,
                        ) ||
                        !_inBounds(
                          criticalRejection,
                          validation.criticalRejectionRatePct,
                        )) {
                      setLocalState(() {
                        inlineError =
                            'Values must stay within configured bounds: '
                            'warn opt-out ${_boundsLabel(validation.warnOptOutRatePct)}, '
                            'critical opt-out ${_boundsLabel(validation.criticalOptOutRatePct)}, '
                            'warn rejection ${_boundsLabel(validation.warnRejectionRatePct)}, '
                            'critical rejection ${_boundsLabel(validation.criticalRejectionRatePct)}.';
                      });
                      return;
                    }
                    if (validation.requireCriticalGteWarn &&
                        (criticalOptOut < warnOptOut ||
                            criticalRejection < warnRejection)) {
                      setLocalState(() {
                        inlineError =
                            'Critical threshold must be >= warning threshold.';
                      });
                      return;
                    }
                    Navigator.of(context).pop(
                      UrkUserRuntimeObservabilityThresholdEntry(
                        warnOptOutRatePct: warnOptOut,
                        criticalOptOutRatePct: criticalOptOut,
                        warnRejectionRatePct: warnRejection,
                        criticalRejectionRatePct: criticalRejection,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    warnOptOutCtrl.dispose();
    criticalOptOutCtrl.dispose();
    warnRejectionCtrl.dispose();
    criticalRejectionCtrl.dispose();

    return result;
  }

  bool _inBounds(
    double value,
    UrkUserRuntimeObservabilityValueBounds bounds,
  ) {
    return value >= bounds.min && value <= bounds.max;
  }

  String _boundsLabel(UrkUserRuntimeObservabilityValueBounds bounds) {
    return '${bounds.min.toStringAsFixed(1)}-${bounds.max.toStringAsFixed(1)}%';
  }

  void _startLivePolling() {
    _livePollingTimer?.cancel();
    if (!_isLivePollingEnabled) {
      return;
    }
    _livePollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshTelemetryOnly();
    });
  }

  void _setLivePolling(bool enabled) {
    setState(() {
      _isLivePollingEnabled = enabled;
    });
    _startLivePolling();
  }

  void _setUserRuntimeRange(_UserRuntimeObservabilityRange range) {
    if (_userRuntimeRange == range) {
      return;
    }
    setState(() {
      _userRuntimeRange = range;
      _userRuntimeObservabilityFuture = _loadUserRuntimeObservability();
      _lastRefreshedAt = DateTime.now().toUtc();
    });
  }

  Future<void> _loadGovernanceFlag() async {
    try {
      final featureFlags = GetIt.instance<FeatureFlagService>();
      final enabled = await featureFlags.isEnabled(
        GovernanceFeatureFlags.kernelGovernanceEnforce,
        defaultValue: true,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isKernelGovernanceEnforced = enabled;
      });
    } catch (_) {
      // Leave default.
    }
  }

  Future<void> _setGovernanceFlag(bool enabled) async {
    setState(() {
      _isGovernanceToggleBusy = true;
    });
    try {
      final featureFlags = GetIt.instance<FeatureFlagService>();
      await featureFlags.setLocalOverride(
        GovernanceFeatureFlags.kernelGovernanceEnforce,
        enabled,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isKernelGovernanceEnforced = enabled;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Kernel governance enforcement enabled'
                : 'Kernel governance switched to shadow mode',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update enforcement flag: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGovernanceToggleBusy = false;
        });
      }
    }
  }

  Future<void> _clearGovernanceOverride() async {
    setState(() {
      _isGovernanceToggleBusy = true;
    });
    try {
      final featureFlags = GetIt.instance<FeatureFlagService>();
      await featureFlags.clearLocalOverride(
        GovernanceFeatureFlags.kernelGovernanceEnforce,
      );
      await _loadGovernanceFlag();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kernel governance local override cleared'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear override: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGovernanceToggleBusy = false;
        });
      }
    }
  }

  Future<void> _setKernelState({
    required String kernelId,
    required UrkKernelRuntimeState state,
  }) async {
    try {
      final service = GetIt.instance<UrkKernelControlPlaneService>();
      await service.setKernelState(
        kernelId: kernelId,
        desiredState: state,
        actor: 'admin_console',
        reason: 'manual_runtime_governance_state_update',
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('State update blocked: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showLineage(String kernelId) async {
    final service = GetIt.instance<UrkKernelControlPlaneService>();
    final events = await service.getKernelLineage(kernelId, limit: 20);
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kernel Lineage: $kernelId',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (events.isEmpty)
                  const Text('No lineage events yet.')
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final transition = event.fromState == null
                            ? (event.toState?.name ?? '-')
                            : '${event.fromState!.name} -> ${event.toState?.name ?? '-'}';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${event.eventType} • ${event.timestamp.toIso8601String()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text('Actor: ${event.actor}'),
                            Text('Reason: ${event.reason}'),
                            Text('Transition: $transition'),
                            if (event.requestId != null)
                              Text('Request: ${event.requestId}'),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _livePollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'URK Kernel Console',
      actions: [
        IconButton(
          onPressed: () => _setLivePolling(!_isLivePollingEnabled),
          tooltip: _isLivePollingEnabled
              ? 'Pause live updates'
              : 'Resume live updates',
          icon: Icon(
              _isLivePollingEnabled ? Icons.pause_circle : Icons.play_circle),
        ),
        IconButton(
          onPressed: _refresh,
          tooltip: 'Refresh kernels',
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: FutureBuilder<List<UrkKernelControlPlaneRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load control plane data: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final records = snapshot.data;
          if (records == null || records.isEmpty) {
            return const Center(child: Text('No kernel control-plane data.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FutureBuilder<KernelGovernanceTelemetrySummary>(
                future: _governanceSummaryFuture,
                builder: (context, summarySnapshot) {
                  return FutureBuilder<KernelGovernanceTelemetrySummary>(
                    future: _governanceLastHourFuture,
                    builder: (context, lastHourSnapshot) {
                      return _HeaderCard(
                        records: records,
                        governanceSummary: summarySnapshot.data,
                        lastHourSummary: lastHourSnapshot.data,
                        governanceEnforced: _isKernelGovernanceEnforced,
                        governanceToggleBusy: _isGovernanceToggleBusy,
                        onGovernanceChanged: _setGovernanceFlag,
                        onClearGovernanceOverride: _clearGovernanceOverride,
                        livePollingEnabled: _isLivePollingEnabled,
                        onLivePollingChanged: _setLivePolling,
                        lastRefreshedAt: _lastRefreshedAt,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<UrkUserRuntimeLearningObservabilitySummary>(
                future: _userRuntimeObservabilityFuture,
                builder: (context, observabilitySnapshot) {
                  return FutureBuilder<UrkUserRuntimeObservabilityThresholds>(
                    future: _thresholdsFuture,
                    builder: (context, thresholdsSnapshot) {
                      return FutureBuilder<
                          List<UrkUserRuntimeObservabilityThresholdAuditEvent>>(
                        future: _thresholdAuditFuture,
                        builder: (context, auditSnapshot) {
                          return _UserRuntimeObservabilityCard(
                            summary: observabilitySnapshot.data,
                            thresholds: thresholdsSnapshot.data ??
                                UrkUserRuntimeObservabilityThresholds
                                    .defaultThresholds(),
                            auditEvents: auditSnapshot.data ??
                                const <UrkUserRuntimeObservabilityThresholdAuditEvent>[],
                            selectedRange: _userRuntimeRange,
                            onRangeChanged: _setUserRuntimeRange,
                            isThresholdConfigBusy: _isThresholdConfigBusy,
                            onEditThresholds: _editSelectedRangeThresholds,
                            onResetThresholds: _clearThresholdOverrides,
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<KernelGovernanceTelemetryEvent>>(
                future: _governanceRecentFuture,
                builder: (context, recentSnapshot) {
                  return _GovernanceRecentCard(
                    events: recentSnapshot.data ??
                        const <KernelGovernanceTelemetryEvent>[],
                    initialDecisionId: widget.initialDecisionId,
                    initialView: widget.initialView,
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<AdminInternalUseAgreementRecord>>(
                future: _agreementEventsFuture,
                builder: (context, agreementSnapshot) {
                  return _AdminAgreementAuditCard(
                    events: agreementSnapshot.data ??
                        const <AdminInternalUseAgreementRecord>[],
                  );
                },
              ),
              const SizedBox(height: 16),
              ...records.map(
                (record) => _KernelCard(
                  record: record,
                  onStateSelected: (state) => _setKernelState(
                    kernelId: record.kernel.kernelId,
                    state: state,
                  ),
                  onViewLineage: () => _showLineage(record.kernel.kernelId),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserRuntimeObservabilityCard extends StatelessWidget {
  const _UserRuntimeObservabilityCard({
    required this.summary,
    required this.thresholds,
    required this.auditEvents,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.isThresholdConfigBusy,
    required this.onEditThresholds,
    required this.onResetThresholds,
  });

  final UrkUserRuntimeLearningObservabilitySummary? summary;
  final UrkUserRuntimeObservabilityThresholds thresholds;
  final List<UrkUserRuntimeObservabilityThresholdAuditEvent> auditEvents;
  final _UserRuntimeObservabilityRange selectedRange;
  final ValueChanged<_UserRuntimeObservabilityRange> onRangeChanged;
  final bool isThresholdConfigBusy;
  final VoidCallback onEditThresholds;
  final VoidCallback onResetThresholds;

  @override
  Widget build(BuildContext context) {
    final data = summary;
    if (data == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final alerts = _buildAlerts(data, selectedRange, thresholds);
    final selectedThreshold =
        thresholds.forWindow(selectedRange.toConfigWindow());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Runtime Learning Observability',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: isThresholdConfigBusy ? null : onEditThresholds,
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Edit Thresholds'),
                ),
                TextButton.icon(
                  onPressed: isThresholdConfigBusy ? null : onResetThresholds,
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('Reset Defaults'),
                ),
                if (isThresholdConfigBusy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _UserRuntimeObservabilityRange.values
                  .map(
                    (range) => ChoiceChip(
                      label: Text(range.label),
                      selected: selectedRange == range,
                      onSelected: (_) => onRangeChanged(range),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Text(
              'Thresholds (${selectedRange.label}) • opt-out warn/critical ${selectedThreshold.warnOptOutRatePct.toStringAsFixed(1)}%/${selectedThreshold.criticalOptOutRatePct.toStringAsFixed(1)}% • rejection warn/critical ${selectedThreshold.warnRejectionRatePct.toStringAsFixed(1)}%/${selectedThreshold.criticalRejectionRatePct.toStringAsFixed(1)}%',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            if (alerts.isNotEmpty) ...[
              ...alerts.map(
                (alert) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: alert.level.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: alert.level.border),
                  ),
                  child: Text(
                    '${alert.level.label}: ${alert.message}',
                    style: TextStyle(
                      color: alert.level.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            if (alerts.isNotEmpty) const SizedBox(height: 4),
            Text(
              'Accepted: ${data.totalAccepted} • Rejected: ${data.totalRejected} • Opt-out: ${data.totalOptOut}',
            ),
            Text(
              'Acceptance: ${data.acceptanceRatePct.toStringAsFixed(1)}% • Opt-out: ${data.optOutRatePct.toStringAsFixed(1)}%',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Threshold Audit (recent)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            if (auditEvents.isEmpty)
              const Text(
                'No threshold override events yet.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...auditEvents.take(5).map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatAuditEvent(event),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            if (data.buckets.isEmpty)
              const Text('No user-runtime learning activation receipts yet.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Runtime Lane')),
                    DataColumn(label: Text('Privacy Mode')),
                    DataColumn(label: Text('Accepted')),
                    DataColumn(label: Text('Rejected')),
                    DataColumn(label: Text('Opt-out')),
                    DataColumn(label: Text('Acceptance %')),
                    DataColumn(label: Text('Opt-out %')),
                  ],
                  rows: data.buckets
                      .map(
                        (bucket) => DataRow(
                          cells: [
                            DataCell(Text(bucket.runtimeLane)),
                            DataCell(Text(bucket.privacyMode)),
                            DataCell(Text('${bucket.acceptedCount}')),
                            DataCell(Text('${bucket.rejectedCount}')),
                            DataCell(Text('${bucket.optOutCount}')),
                            DataCell(Text(
                                bucket.acceptanceRatePct.toStringAsFixed(1))),
                            DataCell(
                                Text(bucket.optOutRatePct.toStringAsFixed(1))),
                          ],
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatAuditEvent(
    UrkUserRuntimeObservabilityThresholdAuditEvent event,
  ) {
    final ts = event.timestamp.toUtc();
    final hh = ts.hour.toString().padLeft(2, '0');
    final mm = ts.minute.toString().padLeft(2, '0');
    final action = switch (event.action) {
      UrkUserRuntimeObservabilityThresholdAuditAction.windowUpsert =>
        'updated ${event.window == null ? '-' : _windowLabel(event.window!)}',
      UrkUserRuntimeObservabilityThresholdAuditAction.overridesCleared =>
        'reset all overrides',
    };
    return '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} $hh:$mm UTC • ${event.actor} • $action';
  }

  String _windowLabel(UrkUserRuntimeObservabilityWindow window) {
    return switch (window) {
      UrkUserRuntimeObservabilityWindow.last1h => '1h',
      UrkUserRuntimeObservabilityWindow.last6h => '6h',
      UrkUserRuntimeObservabilityWindow.last24h => '24h',
      UrkUserRuntimeObservabilityWindow.last7d => '7d',
    };
  }

  List<_RuntimeObservabilityAlert> _buildAlerts(
    UrkUserRuntimeLearningObservabilitySummary summary,
    _UserRuntimeObservabilityRange range,
    UrkUserRuntimeObservabilityThresholds thresholds,
  ) {
    final thresholdEntry = thresholds.forWindow(range.toConfigWindow());
    final alerts = <_RuntimeObservabilityAlert>[];
    final optOutRate = summary.optOutRatePct;
    final rejectionRate = summary.totalEvents == 0
        ? 0.0
        : (summary.totalRejected / summary.totalEvents) * 100.0;

    if (optOutRate >= thresholdEntry.criticalOptOutRatePct) {
      alerts.add(
        _RuntimeObservabilityAlert(
          level: _RuntimeObservabilityAlertLevel.critical,
          message:
              'Opt-out rate ${optOutRate.toStringAsFixed(1)}% exceeds ${thresholdEntry.criticalOptOutRatePct.toStringAsFixed(1)}% (${range.label}).',
        ),
      );
    } else if (optOutRate >= thresholdEntry.warnOptOutRatePct) {
      alerts.add(
        _RuntimeObservabilityAlert(
          level: _RuntimeObservabilityAlertLevel.warn,
          message:
              'Opt-out rate ${optOutRate.toStringAsFixed(1)}% exceeds ${thresholdEntry.warnOptOutRatePct.toStringAsFixed(1)}% (${range.label}).',
        ),
      );
    }

    if (rejectionRate >= thresholdEntry.criticalRejectionRatePct) {
      alerts.add(
        _RuntimeObservabilityAlert(
          level: _RuntimeObservabilityAlertLevel.critical,
          message:
              'Rejection rate ${rejectionRate.toStringAsFixed(1)}% exceeds ${thresholdEntry.criticalRejectionRatePct.toStringAsFixed(1)}% (${range.label}).',
        ),
      );
    } else if (rejectionRate >= thresholdEntry.warnRejectionRatePct) {
      alerts.add(
        _RuntimeObservabilityAlert(
          level: _RuntimeObservabilityAlertLevel.warn,
          message:
              'Rejection rate ${rejectionRate.toStringAsFixed(1)}% exceeds ${thresholdEntry.warnRejectionRatePct.toStringAsFixed(1)}% (${range.label}).',
        ),
      );
    }
    return alerts;
  }
}

enum _UserRuntimeObservabilityRange {
  last1h(Duration(hours: 1), '1h'),
  last6h(Duration(hours: 6), '6h'),
  last24h(Duration(hours: 24), '24h'),
  last7d(Duration(days: 7), '7d');

  const _UserRuntimeObservabilityRange(this.window, this.label);

  final Duration window;
  final String label;
}

extension on _UserRuntimeObservabilityRange {
  UrkUserRuntimeObservabilityWindow toConfigWindow() => switch (this) {
        _UserRuntimeObservabilityRange.last1h =>
          UrkUserRuntimeObservabilityWindow.last1h,
        _UserRuntimeObservabilityRange.last6h =>
          UrkUserRuntimeObservabilityWindow.last6h,
        _UserRuntimeObservabilityRange.last24h =>
          UrkUserRuntimeObservabilityWindow.last24h,
        _UserRuntimeObservabilityRange.last7d =>
          UrkUserRuntimeObservabilityWindow.last7d,
      };
}

class _RuntimeObservabilityAlert {
  const _RuntimeObservabilityAlert({
    required this.level,
    required this.message,
  });

  final _RuntimeObservabilityAlertLevel level;
  final String message;
}

enum _RuntimeObservabilityAlertLevel {
  warn(
    label: 'Warning',
    background: Color(0xFFFFF4E5),
    border: Color(0xFFFFC107),
    text: Color(0xFF8A6D00),
  ),
  critical(
    label: 'Critical',
    background: Color(0xFFFFEBEE),
    border: Color(0xFFE53935),
    text: Color(0xFFB71C1C),
  );

  const _RuntimeObservabilityAlertLevel({
    required this.label,
    required this.background,
    required this.border,
    required this.text,
  });

  final String label;
  final Color background;
  final Color border;
  final Color text;
}

class _AdminAgreementAuditCard extends StatelessWidget {
  const _AdminAgreementAuditCard({
    required this.events,
  });

  final List<AdminInternalUseAgreementRecord> events;

  Future<void> _exportToClipboard(BuildContext context) async {
    final prefs = await SharedPreferencesCompat.getInstance();
    final service = AdminInternalUseAgreementService(
      prefs: prefs,
      supabaseService: SupabaseService(),
    );
    final payload = service.exportJson(events);
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${events.length} agreement records')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Admin Internal-Use Agreement Audit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed:
                      events.isEmpty ? null : () => _exportToClipboard(context),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Records: ${events.length} (newest first)',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const Text('No agreement records yet.')
            else
              ...events.take(20).map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            label: Text(
                                event.serverAccepted ? 'VERIFIED' : 'FAILED'),
                            backgroundColor: (event.serverAccepted
                                    ? AppColors.success
                                    : AppColors.error)
                                .withValues(alpha: 0.14),
                          ),
                          Text(event.userId),
                          Text(
                            _formatTimestamp(event.timestamp),
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                          Text('nonce:${event.sessionNonce}'),
                          if (event.failureReason != null)
                            Text(
                              'reason:${event.failureReason}',
                              style: const TextStyle(color: AppColors.error),
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

  String _formatTimestamp(DateTime ts) {
    final utc = ts.toUtc();
    final hh = utc.hour.toString().padLeft(2, '0');
    final mm = utc.minute.toString().padLeft(2, '0');
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')} $hh:$mm UTC';
  }
}

enum _GovernanceDecisionFilter {
  all,
  blocked,
  shadowBypass,
  allowed,
}

enum _GovernanceTimeRange {
  last1h,
  last6h,
  last24h,
  last7d,
}

class _GovernanceRecentCard extends StatefulWidget {
  const _GovernanceRecentCard({
    required this.events,
    this.initialDecisionId,
    this.initialView,
  });

  final List<KernelGovernanceTelemetryEvent> events;
  final String? initialDecisionId;
  final String? initialView;

  @override
  State<_GovernanceRecentCard> createState() => _GovernanceRecentCardState();
}

class _GovernanceRecentCardState extends State<_GovernanceRecentCard> {
  static const int _pageSize = 100;
  int _visibleCount = _pageSize;
  _GovernanceDecisionFilter _filter = _GovernanceDecisionFilter.all;
  _GovernanceTimeRange _timeRange = _GovernanceTimeRange.last24h;
  String? _actionFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasHandledInitialDeepLink = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialView == 'incident') {
      _applyIncidentShortcut();
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _visibleCount = _pageSize;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openDeepLinkedDecisionIfPresent();
    });
  }

  @override
  void didUpdateWidget(covariant _GovernanceRecentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length) {
      final currentFiltered = _applyFilters(widget.events);
      _visibleCount = _visibleCount.clamp(
        _pageSize,
        currentFiltered.isEmpty ? _pageSize : currentFiltered.length,
      );
    }
    if (!_hasHandledInitialDeepLink &&
        oldWidget.events.length != widget.events.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openDeepLinkedDecisionIfPresent();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KernelGovernanceTelemetryEvent> _applyFilters(
    List<KernelGovernanceTelemetryEvent> source,
  ) {
    final now = DateTime.now().toUtc();
    final threshold = switch (_timeRange) {
      _GovernanceTimeRange.last1h => now.subtract(const Duration(hours: 1)),
      _GovernanceTimeRange.last6h => now.subtract(const Duration(hours: 6)),
      _GovernanceTimeRange.last24h => now.subtract(const Duration(hours: 24)),
      _GovernanceTimeRange.last7d => now.subtract(const Duration(days: 7)),
    };

    return source.where((event) {
      final rangeMatch = !event.timestamp.isBefore(threshold);
      final statusMatch = switch (_filter) {
        _GovernanceDecisionFilter.all => true,
        _GovernanceDecisionFilter.blocked => !event.servingAllowed,
        _GovernanceDecisionFilter.shadowBypass => event.shadowBypassApplied,
        _GovernanceDecisionFilter.allowed =>
          event.servingAllowed && !event.shadowBypassApplied,
      };
      final actionMatch =
          _actionFilter == null ? true : event.action == _actionFilter;
      final haystack = <String>[
        event.decisionId,
        event.action,
        event.mode,
        event.policyVersion,
        event.correlationId ?? '',
        event.modelType ?? '',
        event.fromVersion ?? '',
        event.toVersion ?? '',
        ...event.reasonCodes,
      ].join(' ').toLowerCase();
      final queryMatch =
          _searchQuery.isEmpty || haystack.contains(_searchQuery);
      return rangeMatch && statusMatch && actionMatch && queryMatch;
    }).toList();
  }

  void _showDecisionDetails(KernelGovernanceTelemetryEvent event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Governance Decision Details',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy Decision ID',
                      onPressed: () =>
                          _copyToClipboard('Decision ID', event.decisionId),
                      icon: const Icon(Icons.copy, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Copy Deep Link',
                      onPressed: () => _copyToClipboard(
                        'Decision Deep Link',
                        '/admin/urk-kernels?decisionId=${event.decisionId}',
                      ),
                      icon: const Icon(Icons.link, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailLine('Action', event.action),
                _detailLine('Decision ID', event.decisionId),
                if (event.correlationId != null)
                  Row(
                    children: [
                      Expanded(
                        child:
                            _detailLine('Correlation ID', event.correlationId!),
                      ),
                      IconButton(
                        tooltip: 'Copy Correlation ID',
                        onPressed: () => _copyToClipboard(
                          'Correlation ID',
                          event.correlationId!,
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                      ),
                    ],
                  ),
                _detailLine('Mode', event.mode),
                _detailLine(
                  'Serving Allowed',
                  event.servingAllowed ? 'true' : 'false',
                ),
                _detailLine('Would Allow', event.wouldAllow ? 'true' : 'false'),
                _detailLine(
                  'Shadow Bypass',
                  event.shadowBypassApplied ? 'true' : 'false',
                ),
                _detailLine('Policy Version', event.policyVersion),
                _detailLine('Timestamp', _formatTimestamp(event.timestamp)),
                if (event.modelType != null)
                  _detailLine('Model Type', event.modelType!),
                if (event.fromVersion != null)
                  _detailLine('From Version', event.fromVersion!),
                if (event.toVersion != null)
                  _detailLine('To Version', event.toVersion!),
                _detailLine(
                  'Reason Codes',
                  event.reasonCodes.isEmpty
                      ? '-'
                      : event.reasonCodes.join(', '),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applyIncidentShortcut() {
    _filter = _GovernanceDecisionFilter.blocked;
    _timeRange = _GovernanceTimeRange.last1h;
    _actionFilter = null;
    _searchController.text = '';
    _searchQuery = '';
    _visibleCount = _pageSize;
  }

  void _openDeepLinkedDecisionIfPresent() {
    if (_hasHandledInitialDeepLink) {
      return;
    }
    final deepLinkId = widget.initialDecisionId?.trim();
    if (deepLinkId == null || deepLinkId.isEmpty) {
      return;
    }
    final match =
        widget.events.where((event) => event.decisionId == deepLinkId);
    if (match.isEmpty) {
      return;
    }
    _hasHandledInitialDeepLink = true;
    _searchController.text = deepLinkId;
    _timeRange = _GovernanceTimeRange.last7d;
    _showDecisionDetails(match.first);
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.textPrimary),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  Future<void> _exportFilteredToClipboard(
    List<KernelGovernanceTelemetryEvent> filtered,
  ) async {
    final telemetry = GetIt.instance<KernelGovernanceTelemetryService>();
    final payload = telemetry.exportEventsJson(filtered);
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${filtered.length} filtered decisions')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = widget.events.map((event) => event.action).toSet().toList()
      ..sort();
    final filtered = _applyFilters(widget.events);
    final visible = filtered.take(_visibleCount).toList();
    final hasMore = filtered.length > visible.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Governance Decisions (newest first)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(_applyIncidentShortcut),
                  icon: const Icon(Icons.warning_amber_rounded, size: 16),
                  label: const Text('Incident Shortcut'),
                ),
                OutlinedButton.icon(
                  onPressed: filtered.isEmpty
                      ? null
                      : () => _exportFilteredToClipboard(filtered),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export Filtered'),
                ),
                if (widget.initialDecisionId != null &&
                    widget.initialDecisionId!.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _openDeepLinkedDecisionIfPresent,
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Open Deep Link'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                isDense: true,
                hintText:
                    'Search decision id, action, reason, model, correlation...',
                prefixIcon: Icon(Icons.search, size: 18),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('1h'),
                  selected: _timeRange == _GovernanceTimeRange.last1h,
                  onSelected: (_) => setState(() {
                    _timeRange = _GovernanceTimeRange.last1h;
                    _visibleCount = _pageSize;
                  }),
                ),
                ChoiceChip(
                  label: const Text('6h'),
                  selected: _timeRange == _GovernanceTimeRange.last6h,
                  onSelected: (_) => setState(() {
                    _timeRange = _GovernanceTimeRange.last6h;
                    _visibleCount = _pageSize;
                  }),
                ),
                ChoiceChip(
                  label: const Text('24h'),
                  selected: _timeRange == _GovernanceTimeRange.last24h,
                  onSelected: (_) => setState(() {
                    _timeRange = _GovernanceTimeRange.last24h;
                    _visibleCount = _pageSize;
                  }),
                ),
                ChoiceChip(
                  label: const Text('7d'),
                  selected: _timeRange == _GovernanceTimeRange.last7d,
                  onSelected: (_) => setState(() {
                    _timeRange = _GovernanceTimeRange.last7d;
                    _visibleCount = _pageSize;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == _GovernanceDecisionFilter.all,
                  onSelected: (_) => setState(() {
                    _filter = _GovernanceDecisionFilter.all;
                    _visibleCount = _pageSize;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Blocked'),
                  selected: _filter == _GovernanceDecisionFilter.blocked,
                  onSelected: (_) => setState(() {
                    _filter = _GovernanceDecisionFilter.blocked;
                    _visibleCount = _pageSize;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Shadow Bypass'),
                  selected: _filter == _GovernanceDecisionFilter.shadowBypass,
                  onSelected: (_) => setState(() {
                    _filter = _GovernanceDecisionFilter.shadowBypass;
                    _visibleCount = _pageSize;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Allowed'),
                  selected: _filter == _GovernanceDecisionFilter.allowed,
                  onSelected: (_) => setState(() {
                    _filter = _GovernanceDecisionFilter.allowed;
                    _visibleCount = _pageSize;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (actions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Action: All'),
                    selected: _actionFilter == null,
                    onSelected: (_) => setState(() {
                      _actionFilter = null;
                      _visibleCount = _pageSize;
                    }),
                  ),
                  ...actions.map(
                    (action) => ChoiceChip(
                      label: Text(action),
                      selected: _actionFilter == action,
                      onSelected: (_) => setState(() {
                        _actionFilter = action;
                        _visibleCount = _pageSize;
                      }),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Text('No governance decisions recorded yet.')
            else
              ...visible.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    onTap: () => _showDecisionDetails(event),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _statusChip(event),
                          Text(
                            '${event.action} • ${event.mode}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Tooltip(
                            message: 'Copy Decision ID',
                            child: InkWell(
                              onTap: () => _copyToClipboard(
                                'Decision ID',
                                event.decisionId,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.copy, size: 14),
                              ),
                            ),
                          ),
                          if (event.modelType != null)
                            Text('model:${event.modelType}'),
                          Text(_formatTimestamp(event.timestamp)),
                          if (event.reasonCodes.isNotEmpty)
                            Text(
                              'reasons: ${event.reasonCodes.take(3).join(", ")}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (hasMore) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() {
                    _visibleCount += _pageSize;
                  }),
                  child: Text(
                      'Load More (${filtered.length - visible.length} remaining)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(KernelGovernanceTelemetryEvent event) {
    final bool blocked = !event.servingAllowed;
    final bool shadowBypass = event.shadowBypassApplied;
    final Color color = blocked
        ? AppColors.error
        : (shadowBypass ? AppColors.warning : AppColors.success);
    final String label =
        blocked ? 'BLOCKED' : (shadowBypass ? 'SHADOW_BYPASS' : 'ALLOWED');
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.14),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatTimestamp(DateTime ts) {
    final utc = ts.toUtc();
    final hh = utc.hour.toString().padLeft(2, '0');
    final mm = utc.minute.toString().padLeft(2, '0');
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')} $hh:$mm UTC';
  }
}

class _HeaderCard extends StatelessWidget {
  final List<UrkKernelControlPlaneRecord> records;
  final KernelGovernanceTelemetrySummary? governanceSummary;
  final KernelGovernanceTelemetrySummary? lastHourSummary;
  final bool governanceEnforced;
  final bool governanceToggleBusy;
  final ValueChanged<bool> onGovernanceChanged;
  final VoidCallback onClearGovernanceOverride;
  final bool livePollingEnabled;
  final ValueChanged<bool> onLivePollingChanged;
  final DateTime? lastRefreshedAt;

  const _HeaderCard({
    required this.records,
    required this.governanceSummary,
    required this.lastHourSummary,
    required this.governanceEnforced,
    required this.governanceToggleBusy,
    required this.onGovernanceChanged,
    required this.onClearGovernanceOverride,
    required this.livePollingEnabled,
    required this.onLivePollingChanged,
    required this.lastRefreshedAt,
  });

  @override
  Widget build(BuildContext context) {
    final byState = <UrkKernelRuntimeState, int>{};
    final byHealth = <UrkKernelHealthStatus, int>{};
    for (final record in records) {
      byState[record.state.state] = (byState[record.state.state] ?? 0) + 1;
      byHealth[record.health.status] =
          (byHealth[record.health.status] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Pathway',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Profile -> Admin -> URK Kernel Console (/admin/urk-kernels)',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statChip('Kernels', '${records.length}'),
                _statChip(
                  'States',
                  byState.entries
                      .map((e) => '${e.key.name}:${e.value}')
                      .join(', '),
                ),
                _statChip(
                  'Health',
                  byHealth.entries
                      .map((e) => '${e.key.name}:${e.value}')
                      .join(', '),
                ),
              ],
            ),
            if (governanceSummary != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statChip(
                    'Gov 24h',
                    '${governanceSummary!.totalDecisions}',
                  ),
                  _statChip(
                    'Denied',
                    '${governanceSummary!.deniedCount}',
                  ),
                  _statChip(
                    'Shadow Bypass',
                    '${governanceSummary!.shadowBypassCount}',
                  ),
                  _statChip(
                    'Top Reason',
                    governanceSummary!.topReasonCodes.isEmpty
                        ? '-'
                        : '${governanceSummary!.topReasonCodes.entries.first.key}:${governanceSummary!.topReasonCodes.entries.first.value}',
                  ),
                ],
              ),
            ],
            if (lastHourSummary != null) ...[
              const SizedBox(height: 8),
              _buildLastHourAlerts(lastHourSummary!),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Live Kernel View (5s polling)'),
              subtitle: Text(
                livePollingEnabled
                    ? 'Enabled${lastRefreshedAt == null ? '' : ' • last sync ${_formatTimestamp(lastRefreshedAt!)}'}'
                    : 'Paused',
              ),
              value: livePollingEnabled,
              onChanged: onLivePollingChanged,
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Kernel Governance Enforcement'),
              subtitle: Text(
                governanceEnforced
                    ? 'Enforce mode: policy denials block actions'
                    : 'Shadow mode: policy denials are logged only',
              ),
              value: governanceEnforced,
              onChanged:
                  governanceToggleBusy ? null : (v) => onGovernanceChanged(v),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed:
                    governanceToggleBusy ? null : onClearGovernanceOverride,
                child: const Text('Clear Local Override'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
    );
  }

  Widget _buildLastHourAlerts(KernelGovernanceTelemetrySummary summary) {
    final total = summary.totalDecisions;
    final blocked = summary.deniedCount;
    final blockedRate = total == 0 ? 0.0 : blocked / total;
    final highBlockedRate = blockedRate >= 0.10;
    final hasShadowBypass = summary.shadowBypassCount > 0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          label: Text(
            '1h blocked: $blocked/$total (${(blockedRate * 100).toStringAsFixed(1)}%)',
          ),
          backgroundColor:
              (highBlockedRate ? AppColors.warning : AppColors.success)
                  .withValues(alpha: 0.14),
          side: BorderSide(
            color: (highBlockedRate ? AppColors.warning : AppColors.success)
                .withValues(
              alpha: 0.4,
            ),
          ),
        ),
        Chip(
          label: Text('1h shadow bypass: ${summary.shadowBypassCount}'),
          backgroundColor:
              (hasShadowBypass ? AppColors.warning : AppColors.success)
                  .withValues(alpha: 0.14),
          side: BorderSide(
            color: (hasShadowBypass ? AppColors.warning : AppColors.success)
                .withValues(
              alpha: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime ts) {
    final utc = ts.toUtc();
    final hh = utc.hour.toString().padLeft(2, '0');
    final mm = utc.minute.toString().padLeft(2, '0');
    final ss = utc.second.toString().padLeft(2, '0');
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')} $hh:$mm:$ss UTC';
  }
}

class _KernelCard extends StatelessWidget {
  final UrkKernelControlPlaneRecord record;
  final ValueChanged<UrkKernelRuntimeState> onStateSelected;
  final VoidCallback onViewLineage;

  const _KernelCard({
    required this.record,
    required this.onStateSelected,
    required this.onViewLineage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(record.kernel.title),
        subtitle: Text(
          '${record.kernel.kernelId} • ${record.kernel.milestoneId} • ${record.kernel.status}',
        ),
        trailing: _stateChip(record.state.state),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _line('Purpose', record.kernel.purpose),
          _line('Prong', record.kernel.prongScope),
          _line('Runtime Scope', record.kernel.runtimeScope.join(', ')),
          _line('Privacy Modes', record.kernel.privacyModes.join(', ')),
          _line('Activation Triggers',
              record.kernel.activationTriggers.join(', ')),
          _line('Dependencies', record.kernel.dependencies.join(', ')),
          _line('Owner / Approver',
              '${record.kernel.owner} / ${record.kernel.approver}'),
          _line(
            'Runtime State',
            '${record.state.state.name} • by ${record.state.updatedBy} • ${record.state.updatedAt.toIso8601String()}',
          ),
          _line(
            'Health',
            '${record.health.status.name} • ${record.health.scorePct.toStringAsFixed(1)}%',
          ),
          _line('Lineage Events', '${record.lineageEventCount}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...UrkKernelRuntimeState.values.map(
                (state) => OutlinedButton(
                  onPressed: state == record.state.state
                      ? null
                      : () => onStateSelected(state),
                  child: Text('Set ${state.name}'),
                ),
              ),
              TextButton(
                onPressed: onViewLineage,
                child: const Text('View Lineage'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.textPrimary),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }

  Widget _stateChip(UrkKernelRuntimeState state) {
    final (bg, fg) = switch (state) {
      UrkKernelRuntimeState.active => (
          AppColors.success.withValues(alpha: 0.18),
          AppColors.success,
        ),
      UrkKernelRuntimeState.shadow => (
          AppColors.primary.withValues(alpha: 0.18),
          AppColors.primary,
        ),
      UrkKernelRuntimeState.paused => (
          AppColors.warning.withValues(alpha: 0.20),
          AppColors.warning,
        ),
      UrkKernelRuntimeState.disabled => (
          AppColors.error.withValues(alpha: 0.18),
          AppColors.error,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        state.name,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
