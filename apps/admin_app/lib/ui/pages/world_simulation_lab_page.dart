import 'package:avrai_admin_app/navigation/admin_route_paths.dart';
import 'package:avrai_admin_app/theme/colors.dart';
import 'package:avrai_admin_app/ui/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class WorldSimulationLabPage extends StatefulWidget {
  const WorldSimulationLabPage({
    super.key,
    this.replaySimulationService,
    this.signatureHealthService,
    this.signatureHealthSnapshot,
    this.initialFocus,
    this.initialAttention,
  });

  final ReplaySimulationAdminService? replaySimulationService;
  final SignatureHealthAdminService? signatureHealthService;
  final SignatureHealthSnapshot? signatureHealthSnapshot;
  final String? initialFocus;
  final String? initialAttention;

  @override
  State<WorldSimulationLabPage> createState() => _WorldSimulationLabPageState();
}

class _SyntheticHumanKernelHistoryPoint {
  const _SyntheticHumanKernelHistoryPoint({
    required this.recordedAt,
    required this.headline,
    required this.summary,
    required this.totalActivations,
    required this.contradictionCount,
    required this.receiptCount,
  });

  final DateTime recordedAt;
  final String headline;
  final String summary;
  final int totalActivations;
  final int contradictionCount;
  final int receiptCount;
}

class _HigherAgentHandoffHistoryPoint {
  const _HigherAgentHandoffHistoryPoint({
    required this.recordedAt,
    required this.headline,
    required this.summary,
    required this.status,
    required this.contradictionCount,
    required this.requestPreviewCount,
  });

  final DateTime recordedAt;
  final String headline;
  final String summary;
  final String status;
  final int contradictionCount;
  final int requestPreviewCount;
}

class _LocalityHierarchyHistoryPoint {
  const _LocalityHierarchyHistoryPoint({
    required this.recordedAt,
    required this.headline,
    required this.summary,
    required this.risk,
    required this.effectiveness,
    required this.contradictionCount,
  });

  final DateTime recordedAt;
  final String headline;
  final String summary;
  final String risk;
  final String effectiveness;
  final int contradictionCount;
}

class _RealismProvenanceHistoryPoint {
  const _RealismProvenanceHistoryPoint({
    required this.recordedAt,
    required this.headline,
    required this.summary,
    required this.sidecarRefs,
    required this.trainingArtifactFamilies,
    this.cityPackStructuralRef,
  });

  final DateTime recordedAt;
  final String headline;
  final String summary;
  final List<String> sidecarRefs;
  final List<String> trainingArtifactFamilies;
  final String? cityPackStructuralRef;
}

class _RealismProvenanceDelta {
  const _RealismProvenanceDelta({
    required this.headline,
    required this.details,
  });

  final String headline;
  final List<String> details;
}

class _WorldSimulationLabPageState extends State<WorldSimulationLabPage> {
  static const String _allExecutedRerunTargetsValue = '__all_targets__';
  static const String _baseExecutedRerunTargetValue = '__base_run__';
  static const List<String> _labTargetActionValues = <String>[
    'keep_iterating',
    'watch_closely',
    'candidate_for_bounded_review',
  ];

  final TextEditingController _rationaleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _environmentNameController =
      TextEditingController();
  final TextEditingController _environmentCityCodeController =
      TextEditingController();
  final TextEditingController _environmentReplayYearController =
      TextEditingController(text: '${DateTime.now().year}');
  final TextEditingController _environmentDescriptionController =
      TextEditingController();
  final TextEditingController _environmentLocalitiesController =
      TextEditingController();
  final TextEditingController _variantLabelController = TextEditingController();
  final TextEditingController _variantHypothesisController =
      TextEditingController();
  final TextEditingController _variantLocalitiesController =
      TextEditingController();
  final TextEditingController _variantNotesController = TextEditingController();
  final TextEditingController _rerunNotesController = TextEditingController();

  ReplaySimulationAdminService? _replaySimulationService;
  SignatureHealthAdminService? _signatureHealthService;
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isRegisteringEnvironment = false;
  bool _isSavingVariant = false;
  bool _isUpdatingVariantTarget = false;
  bool _isQueueingRerun = false;
  bool _isUpdatingBasisDecision = false;
  bool _isRevalidatingBasis = false;
  bool _isRefreshingLatestStateEvidence = false;
  bool _isRunningRefreshCadenceCheck = false;
  bool _isApplyingBasisRecoveryDecision = false;
  String? _updatingFamilyRestageReviewItemId;
  String? _updatingRerunRequestId;
  String? _updatingTargetActionTargetKey;
  String? _error;
  String _executedRerunTimelineFocus = _allExecutedRerunTargetsValue;

  List<ReplaySimulationAdminEnvironmentDescriptor> _replayEnvironments =
      const <ReplaySimulationAdminEnvironmentDescriptor>[];
  List<ReplaySimulationLabVariantDraft> _variants =
      const <ReplaySimulationLabVariantDraft>[];
  String? _selectedReplayEnvironmentId;
  String? _selectedVariantId;
  ReplaySimulationAdminSnapshot? _replaySnapshot;
  List<ReplaySimulationLabOutcomeRecord> _labHistory =
      const <ReplaySimulationLabOutcomeRecord>[];
  List<ReplaySimulationLabRerunRequest> _rerunRequests =
      const <ReplaySimulationLabRerunRequest>[];
  List<ReplaySimulationLabRerunJob> _rerunJobs =
      const <ReplaySimulationLabRerunJob>[];
  List<ReplaySimulationLabFamilyRestageReviewItem> _familyRestageReviewItems =
      const <ReplaySimulationLabFamilyRestageReviewItem>[];
  ReplaySimulationLabOutcomeRecord? _lastRecordedOutcome;
  ReplaySimulationLabRuntimeState? _labRuntimeState;
  SignatureHealthSnapshot? _signatureHealthSnapshot;
  String? _signatureHealthError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _rationaleController.dispose();
    _notesController.dispose();
    _environmentNameController.dispose();
    _environmentCityCodeController.dispose();
    _environmentReplayYearController.dispose();
    _environmentDescriptionController.dispose();
    _environmentLocalitiesController.dispose();
    _variantLabelController.dispose();
    _variantHypothesisController.dispose();
    _variantLocalitiesController.dispose();
    _variantNotesController.dispose();
    _rerunNotesController.dispose();
    super.dispose();
  }

  String? _foundationMetadataString(
    Map<String, dynamic> metadata,
    String key,
  ) {
    final value = metadata[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  List<String> _foundationMetadataStringList(
    Map<String, dynamic> metadata,
    String key,
  ) {
    return (metadata[key] as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  String _livingCityPackMetadataLabel(String value) {
    switch (value.trim()) {
      case 'versioned_living_city_pack':
        return 'versioned living city-pack';
      case 'replay_grounded_seed_basis':
        return 'replay-grounded seed basis';
      case 'awaiting_latest_avrai_evidence_refresh':
        return 'awaiting latest AVRAI evidence refresh';
      case 'staged_latest_avrai_evidence_refresh':
        return 'staged latest AVRAI evidence refresh';
      case 'staged_latest_avrai_evidence_refresh_blocked':
        return 'staged latest AVRAI evidence refresh blocked';
      case 'staged_latest_avrai_evidence_refresh_ready_for_review':
        return 'staged latest AVRAI evidence refresh ready for review';
      case 'latest_avrai_evidence_refreshed_ready_for_staging':
        return 'latest AVRAI evidence refreshed and ready for staging';
      case 'latest_avrai_evidence_refreshed_blocked':
        return 'latest AVRAI evidence refreshed but still blocked';
      case 'blocked_pending_latest_state_evidence':
        return 'blocked pending latest-state evidence';
      case 'ready_for_bounded_basis_review':
        return 'ready for bounded basis review';
      case 'promoted_to_served_basis':
        return 'promoted to served basis';
      case 'served_basis_revalidated_current':
        return 'served basis revalidated current';
      case 'restage_required_before_served_basis_reuse':
        return 'restage required before served-basis reuse';
      case 'ready_for_bounded_served_basis_restore':
        return 'ready for bounded served-basis restore';
      case 'restored_to_served_basis_after_review':
        return 'restored to served basis after review';
      case 'awaiting_basis_review_decision':
        return 'awaiting basis review decision';
      case 'promoted':
        return 'promoted';
      case 'rejected':
        return 'rejected';
      case 'not_reviewed':
        return 'not reviewed';
      case 'restage_required_confirmed':
        return 'restage required confirmed';
      case 'restored_after_review':
        return 'restored after review';
      case 'not_revalidated':
        return 'not revalidated';
      case 'current':
        return 'current';
      case 'expired':
        return 'expired';
      case 'latest_state_basis_served':
        return 'latest-state basis served';
      case 'latest_state_basis_served_revalidated':
        return 'latest-state basis served and revalidated';
      case 'latest_state_basis_served_expired':
        return 'latest-state served basis expired';
      case 'expired_basis_ready_for_restore_review':
        return 'expired basis ready for restore review';
      case 'latest_state_basis_restored_after_review':
        return 'latest-state basis restored after review';
      case 'expired_basis_restage_required_confirmed':
        return 'expired basis restage required confirmed';
      case 'latest_state_basis_rejected':
        return 'latest-state basis rejected';
      case 'expired_latest_state_served_basis':
        return 'expired latest-state served basis';
      case 'served_basis_updated_from_latest_state_receipts':
        return 'served basis updated from latest-state receipts';
      case 'served_basis_still_supported_by_current_receipts':
        return 'served basis still supported by current receipts';
      case 'promoted_served_basis_expired_pending_restage':
        return 'promoted served basis expired pending restage';
      case 'expired_basis_supported_by_current_receipts_pending_restore_review':
        return 'expired basis supported by current receipts pending restore review';
      case 'served_basis_restored_from_revalidated_receipts':
        return 'served basis restored from revalidated receipts';
      case 'prior_served_basis_restored_after_rejection':
        return 'prior served basis restored after rejection';
      case 'refresh_receipts_required_before_served_basis_change':
        return 'refresh receipts required before served basis changes';
      case 'ready_for_served_basis_review_with_receipts':
        return 'ready for served-basis review with receipts';
      case 'awaiting_first_refresh_receipts':
        return 'awaiting first refresh receipts';
      case 'within_refresh_window':
        return 'within refresh window';
      case 'due_for_refresh':
        return 'due for refresh';
      case 'overdue_for_refresh':
        return 'overdue for refresh';
      case 'not_checked':
        return 'not checked';
      case 'executed_initial_refresh':
        return 'executed initial refresh';
      case 'executed_due_refresh':
        return 'executed due refresh';
      case 'executed_overdue_refresh':
        return 'executed overdue refresh';
      case 'skipped_within_refresh_window':
        return 'skipped within refresh window';
      case 'queued_for_family_restage_review':
        return 'queued for family restage review';
      case 'restage_intake_requested':
        return 'restage intake requested';
      case 'restage_intake_review_approved':
        return 'restage intake review approved';
      case 'restage_intake_review_held':
        return 'restage intake review held';
      case 'queued_for_family_restage_follow_up_review':
        return 'queued for family restage follow-up review';
      case 'queued_for_family_restage_resolution_review':
        return 'queued for family restage resolution review';
      case 'queued_for_family_restage_execution_review':
        return 'queued for family restage execution review';
      case 'queued_for_family_restage_application_review':
        return 'queued for family restage application review';
      case 'queued_for_family_restage_apply_review':
        return 'queued for family restage apply review';
      case 'queued_for_family_restage_served_basis_update_review':
        return 'queued for family restage served basis update review';
      case 'approved_for_bounded_family_restage_execution':
        return 'approved for bounded family restage execution';
      case 'approved_for_bounded_family_restage_application':
        return 'approved for bounded family restage application';
      case 'approved_for_bounded_family_restage_apply_to_served_basis':
        return 'approved for bounded family restage apply to served basis';
      case 'approved_for_bounded_family_restage_served_basis_update':
        return 'approved for bounded family restage served basis update';
      case 'approved_for_bounded_family_restage_served_basis_mutation':
        return 'approved for bounded family restage served basis mutation';
      case 'held_for_more_family_restage_resolution_evidence':
        return 'held for more family restage resolution evidence';
      case 'held_for_more_family_restage_execution_evidence':
        return 'held for more family restage execution evidence';
      case 'held_for_more_family_restage_application_evidence':
        return 'held for more family restage application evidence';
      case 'held_for_more_family_restage_apply_evidence':
        return 'held for more family restage apply evidence';
      case 'held_for_more_family_restage_served_basis_update_evidence':
        return 'held for more family restage served basis update evidence';
      case 'watch_family_before_restage':
        return 'watch family before restage';
      case 'selected_current_evidence':
        return 'selected current evidence';
      case 'seed_placeholder':
        return 'seed placeholder';
      case 'selected_current_evidence_degraded':
        return 'selected current evidence degraded';
      default:
        return value.replaceAll('_', ' ').trim();
    }
  }

  String _hydrateEvidenceFamilyLabel(String value) {
    switch (value.trim()) {
      case 'app_observations':
        return 'app observations';
      case 'runtime_os_locality_state':
        return 'runtime/OS locality state';
      case 'governed_reality_model_outputs':
        return 'governed reality-model outputs';
      default:
        return value.replaceAll('_', ' ').trim();
    }
  }

  Future<void> _init() async {
    try {
      _replaySimulationService = widget.replaySimulationService ??
          ReplaySimulationAdminService(
            intakeRepository:
                GetIt.instance.isRegistered<UniversalIntakeRepository>()
                    ? GetIt.instance<UniversalIntakeRepository>()
                    : null,
          );
      _signatureHealthService = widget.signatureHealthService ??
          (GetIt.instance.isRegistered<SignatureHealthAdminService>()
              ? GetIt.instance<SignatureHealthAdminService>()
              : null);
      _signatureHealthSnapshot = widget.signatureHealthSnapshot;
      _replayEnvironments =
          await _replaySimulationService?.listAvailableEnvironments() ??
              const <ReplaySimulationAdminEnvironmentDescriptor>[];
      _selectedReplayEnvironmentId = _resolveReplayEnvironmentId(
        currentSelection: _selectedReplayEnvironmentId,
        environments: _replayEnvironments,
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'World Simulation Lab is unavailable in this environment.';
        _isLoading = false;
      });
    }
  }

  Future<void> _load() async {
    final service = _replaySimulationService;
    if (service == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await service.getSnapshot(
        environmentId: _selectedReplayEnvironmentId,
      );
      final history = await service.listLabOutcomes(
        environmentId: _selectedReplayEnvironmentId,
        limit: 24,
      );
      final variants = await service.listLabVariants(
        environmentId: _selectedReplayEnvironmentId,
      );
      final rerunRequests = await service.listLabRerunRequests(
        environmentId: _selectedReplayEnvironmentId,
        limit: 12,
      );
      final rerunJobs = _selectedReplayEnvironmentId == null
          ? const <ReplaySimulationLabRerunJob>[]
          : await service.listLabRerunJobs(
              environmentId: _selectedReplayEnvironmentId!,
              limit: 24,
            );
      final familyRestageReviewItems = _selectedReplayEnvironmentId == null
          ? const <ReplaySimulationLabFamilyRestageReviewItem>[]
          : await service.listLabFamilyRestageReviewItems(
              environmentId: _selectedReplayEnvironmentId!,
              limit: 12,
            );
      final runtimeState = _selectedReplayEnvironmentId == null
          ? null
          : await service.getLabRuntimeState(
              environmentId: _selectedReplayEnvironmentId!,
            );
      SignatureHealthSnapshot? signatureSnapshot = _signatureHealthSnapshot;
      String? signatureError;
      final signatureService = _signatureHealthService;
      if (signatureService != null) {
        try {
          signatureSnapshot = await signatureService.getSnapshot();
          signatureError = null;
        } catch (error) {
          signatureError = error.toString();
        }
      }
      if (!mounted) return;
      setState(() {
        _replaySnapshot = snapshot;
        _labHistory = history;
        _variants = variants;
        _rerunRequests = rerunRequests;
        _rerunJobs = rerunJobs;
        _familyRestageReviewItems = familyRestageReviewItems;
        _executedRerunTimelineFocus = _resolveExecutedRerunTimelineFocus(
          currentSelection: _executedRerunTimelineFocus,
          jobs: rerunJobs,
        );
        _labRuntimeState = runtimeState;
        _selectedVariantId = _resolveVariantId(
          currentSelection: runtimeState?.activeVariantId ?? _selectedVariantId,
          variants: variants,
        );
        _lastRecordedOutcome = history.isEmpty ? null : history.first;
        _signatureHealthSnapshot = signatureSnapshot;
        _signatureHealthError = signatureError;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load world simulation lab: $error';
        _isLoading = false;
      });
    }
  }

  String? _resolveReplayEnvironmentId({
    required String? currentSelection,
    required List<ReplaySimulationAdminEnvironmentDescriptor> environments,
  }) {
    if (environments.isEmpty) {
      return null;
    }
    if (currentSelection != null &&
        environments.any((entry) => entry.environmentId == currentSelection)) {
      return currentSelection;
    }
    final initialFocus = widget.initialFocus;
    if (initialFocus != null &&
        environments.any((entry) => entry.environmentId == initialFocus)) {
      return initialFocus;
    }
    return environments.first.environmentId;
  }

  String? _worldSimulationLabAttentionLabel(String? raw) {
    return switch (raw) {
      'served_basis_recovery:restore_review' =>
        'Review restore-or-restage posture',
      'served_basis_recovery:restage_required' =>
        'Inspect confirmed restage posture',
      'family_restage_intake_review' =>
        'Inspect family restage intake follow-up',
      _ => null,
    };
  }

  bool _showWorldSimulationLabHandoff(String? environmentId) {
    return environmentId != null &&
        environmentId == widget.initialFocus &&
        _worldSimulationLabAttentionLabel(widget.initialAttention) != null;
  }

  String? _resolveVariantId({
    required String? currentSelection,
    required List<ReplaySimulationLabVariantDraft> variants,
  }) {
    if (variants.isEmpty) {
      return null;
    }
    if (currentSelection == null || currentSelection.isEmpty) {
      return null;
    }
    if (variants.any((entry) => entry.variantId == currentSelection)) {
      return currentSelection;
    }
    return variants.first.variantId;
  }

  String _displayNameForEnvironmentId(String? environmentId) {
    if (environmentId == null || environmentId.isEmpty) {
      return 'Simulation environment';
    }
    for (final environment in _replayEnvironments) {
      if (environment.environmentId == environmentId) {
        return environment.displayName;
      }
    }
    return environmentId;
  }

  Future<void> _onReplayEnvironmentSelected(String? environmentId) async {
    if (environmentId == null ||
        environmentId == _selectedReplayEnvironmentId) {
      return;
    }
    setState(() {
      _selectedReplayEnvironmentId = environmentId;
      _lastRecordedOutcome = null;
      _selectedVariantId = null;
    });
    await _load();
  }

  Future<void> _onVariantSelected(String? variantId) async {
    if (variantId == _selectedVariantId) {
      return;
    }
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    setState(() {
      _isUpdatingVariantTarget = true;
      _error = null;
    });
    try {
      final runtimeState = await service.setActiveLabVariantTarget(
        environmentId: environmentId,
        variantId: variantId,
      );
      final variants =
          await service.listLabVariants(environmentId: environmentId);
      if (!mounted) return;
      setState(() {
        _variants = variants;
        _labRuntimeState = runtimeState;
        _selectedVariantId = _resolveVariantId(
          currentSelection: runtimeState.activeVariantId,
          variants: variants,
        );
        _isUpdatingVariantTarget = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to update next run target: $error';
        _isUpdatingVariantTarget = false;
      });
    }
  }

  Future<void> _recordOutcome(
      ReplaySimulationLabDisposition disposition) async {
    final service = _replaySimulationService;
    if (service == null) {
      return;
    }
    final rationale = _rationaleController.text.trim();
    if (disposition == ReplaySimulationLabDisposition.denied &&
        rationale.isEmpty) {
      setState(() {
        _error =
            'Denied lab outcomes need a rationale so the daemon can learn from the rejection.';
      });
      return;
    }

    final notes = _notesController.text
        .split('\n')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);

    setState(() {
      _isRecording = true;
      _error = null;
    });

    try {
      final outcome = await service.recordLabOutcome(
        environmentId: _selectedReplayEnvironmentId,
        disposition: disposition,
        operatorRationale: rationale,
        operatorNotes: notes,
        variantId: _activeVariant?.variantId,
        variantLabel: _activeVariant?.label,
      );
      if (!mounted) return;
      _rationaleController.clear();
      _notesController.clear();
      setState(() {
        _lastRecordedOutcome = outcome;
        _isRecording = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to record lab outcome: $error';
        _isRecording = false;
      });
    }
  }

  Future<void> _registerEnvironment() async {
    final service = _replaySimulationService;
    if (service == null) {
      return;
    }
    final displayName = _environmentNameController.text.trim();
    final cityCode = _environmentCityCodeController.text.trim();
    final replayYear =
        int.tryParse(_environmentReplayYearController.text.trim());
    final localities = _parseLocalityDisplayNames(
      _environmentLocalitiesController.text,
    );
    if (displayName.isEmpty ||
        cityCode.isEmpty ||
        replayYear == null ||
        localities.isEmpty) {
      setState(() {
        _error =
            'Environment registration needs a name, city code, replay year, and at least one locality entry.';
      });
      return;
    }

    setState(() {
      _isRegisteringEnvironment = true;
      _error = null;
    });
    try {
      final registration = await service.registerLabEnvironment(
        displayName: displayName,
        cityCode: cityCode,
        replayYear: replayYear,
        description: _environmentDescriptionController.text.trim(),
        localityDisplayNames: localities,
      );
      _environmentNameController.clear();
      _environmentCityCodeController.clear();
      _environmentDescriptionController.clear();
      _environmentLocalitiesController.clear();
      _environmentReplayYearController.text = '${DateTime.now().year}';
      final environments = await service.listAvailableEnvironments();
      if (!mounted) return;
      setState(() {
        _replayEnvironments = environments;
        _selectedReplayEnvironmentId = registration.environmentId;
        _selectedVariantId = null;
        _isRegisteringEnvironment = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to register simulation environment: $error';
        _isRegisteringEnvironment = false;
      });
    }
  }

  Future<void> _saveVariant() async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    final label = _variantLabelController.text.trim();
    if (label.isEmpty) {
      setState(() {
        _error = 'Variant scaffolding needs a label before it can be saved.';
      });
      return;
    }
    setState(() {
      _isSavingVariant = true;
      _error = null;
    });
    try {
      final variant = await service.saveLabVariant(
        environmentId: environmentId,
        label: label,
        hypothesis: _variantHypothesisController.text.trim(),
        localityCodes: _parseSimpleLines(_variantLocalitiesController.text),
        operatorNotes: _parseSimpleLines(_variantNotesController.text),
      );
      final runtimeState = await service.setActiveLabVariantTarget(
        environmentId: environmentId,
        variantId: variant.variantId,
      );
      _variantLabelController.clear();
      _variantHypothesisController.clear();
      _variantLocalitiesController.clear();
      _variantNotesController.clear();
      final variants =
          await service.listLabVariants(environmentId: environmentId);
      if (!mounted) return;
      setState(() {
        _variants = variants;
        _labRuntimeState = runtimeState;
        _selectedVariantId = runtimeState.activeVariantId;
        _isSavingVariant = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save simulation variant: $error';
        _isSavingVariant = false;
      });
    }
  }

  Future<void> _queueRerunRequest() async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    setState(() {
      _isQueueingRerun = true;
      _error = null;
    });
    try {
      await service.createLabRerunRequest(
        environmentId: environmentId,
        variantId: _selectedVariantId,
        requestNotes: _parseSimpleLines(_rerunNotesController.text),
      );
      if (!mounted) return;
      _rerunNotesController.clear();
      setState(() {
        _isQueueingRerun = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to queue rerun request: $error';
        _isQueueingRerun = false;
      });
    }
  }

  Future<void> _executeRerunRequest(
    ReplaySimulationLabRerunRequest request,
  ) async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    setState(() {
      _updatingRerunRequestId = request.requestId;
      _error = null;
    });
    try {
      await service.executeLabRerunRequest(
        environmentId: environmentId,
        requestId: request.requestId,
      );
      if (!mounted) return;
      setState(() {
        _updatingRerunRequestId = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to execute rerun request: $error';
        _updatingRerunRequestId = null;
      });
    }
  }

  Future<void> _applyBasisDecision({
    required bool promote,
  }) async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    setState(() {
      _isUpdatingBasisDecision = true;
      _error = null;
    });
    try {
      if (promote) {
        await service.promoteStagedLatestStateBasis(
          environmentId: environmentId,
        );
      } else {
        await service.rejectStagedLatestStateBasis(
          environmentId: environmentId,
        );
      }
      if (!mounted) return;
      setState(() {
        _isUpdatingBasisDecision = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isUpdatingBasisDecision = false;
        _error = 'Failed to apply basis decision: $error';
      });
    }
  }

  Future<void> _revalidateServedBasis() async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    setState(() {
      _isRevalidatingBasis = true;
      _error = null;
    });
    try {
      await service.revalidatePromotedServedBasis(
        environmentId: environmentId,
      );
      if (!mounted) return;
      setState(() {
        _isRevalidatingBasis = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRevalidatingBasis = false;
        _error = 'Failed to revalidate served basis: $error';
      });
    }
  }

  Future<void> _refreshLatestStateEvidence() async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    setState(() {
      _isRefreshingLatestStateEvidence = true;
      _error = null;
    });
    try {
      await service.refreshLatestStateEvidenceBundle(
        environmentId: environmentId,
      );
      if (!mounted) return;
      setState(() {
        _isRefreshingLatestStateEvidence = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshingLatestStateEvidence = false;
        _error = 'Failed to refresh latest-state evidence: $error';
      });
    }
  }

  Future<void> _runRefreshCadenceCheck() async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    setState(() {
      _isRunningRefreshCadenceCheck = true;
      _error = null;
    });
    try {
      await service.runScheduledLatestStateRefreshCheck(
        environmentId: environmentId,
      );
      if (!mounted) return;
      setState(() {
        _isRunningRefreshCadenceCheck = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRunningRefreshCadenceCheck = false;
        _error = 'Failed to run refresh cadence check: $error';
      });
    }
  }

  Future<void> _applyBasisRecoveryDecision({
    required bool restore,
  }) async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    setState(() {
      _isApplyingBasisRecoveryDecision = true;
      _error = null;
    });
    try {
      if (restore) {
        await service.restoreExpiredServedBasis(
          environmentId: environmentId,
        );
      } else {
        await service.confirmExpiredServedBasisRestageRequired(
          environmentId: environmentId,
        );
      }
      if (!mounted) return;
      setState(() {
        _isApplyingBasisRecoveryDecision = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isApplyingBasisRecoveryDecision = false;
        _error = 'Failed to apply basis recovery decision: $error';
      });
    }
  }

  Future<void> _requestFamilyRestageIntakeReview(
    ReplaySimulationLabFamilyRestageReviewItem item,
  ) async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    setState(() {
      _updatingFamilyRestageReviewItemId = item.itemId;
      _error = null;
    });
    try {
      await service.requestLabFamilyRestageIntake(
        environmentId: environmentId,
        evidenceFamily: item.evidenceFamily,
      );
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
        _error = 'Failed to request family restage intake: $error';
      });
    }
  }

  Future<void> _deferFamilyRestageReview(
    ReplaySimulationLabFamilyRestageReviewItem item,
  ) async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    setState(() {
      _updatingFamilyRestageReviewItemId = item.itemId;
      _error = null;
    });
    try {
      await service.deferLabFamilyRestageReview(
        environmentId: environmentId,
        evidenceFamily: item.evidenceFamily,
      );
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
        _error = 'Failed to defer family restage review: $error';
      });
    }
  }

  Future<void> _resolveFamilyRestageIntakeReview(
    ReplaySimulationLabFamilyRestageReviewItem item, {
    required bool approve,
  }) async {
    final replayService = _replaySimulationService;
    final signatureService = _signatureHealthService;
    final environmentId = _selectedReplayEnvironmentId;
    final reviewItemId = item.restageIntakeReviewItemId?.trim();
    if (replayService == null ||
        signatureService == null ||
        environmentId == null ||
        reviewItemId == null ||
        reviewItemId.isEmpty) {
      setState(() {
        _error =
            'Family restage intake review is unavailable until the bounded intake review item is ready.';
      });
      return;
    }
    setState(() {
      _updatingFamilyRestageReviewItemId = item.itemId;
      _error = null;
    });
    try {
      final result = await signatureService.resolveReviewItem(
        reviewItemId: reviewItemId,
        resolution: approve
            ? SignatureHealthReviewResolution.approved
            : SignatureHealthReviewResolution.rejected,
      );
      final artifactRef = result.familyRestageIntakeOutcomeJsonPath ??
          result.familyRestageIntakeOutcomeReadmePath ??
          reviewItemId;
      await replayService.recordLabFamilyRestageIntakeReviewResolution(
        environmentId: environmentId,
        evidenceFamily: item.evidenceFamily,
        resolutionStatus: approve ? 'approved' : 'held',
        resolutionArtifactRef: artifactRef,
      );
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
        _error = 'Failed to resolve family restage intake review: $error';
      });
    }
  }

  Future<void> _resolveFamilyRestageFollowUpReview(
    ReplaySimulationLabFamilyRestageReviewItem item, {
    required bool approve,
  }) async {
    final replayService = _replaySimulationService;
    final signatureService = _signatureHealthService;
    final environmentId = _selectedReplayEnvironmentId;
    final reviewItemId = item.followUpReviewItemId?.trim();
    if (replayService == null ||
        signatureService == null ||
        environmentId == null ||
        reviewItemId == null ||
        reviewItemId.isEmpty) {
      setState(() {
        _error =
            'Family restage follow-up review is unavailable until the bounded follow-up review item is ready.';
      });
      return;
    }
    setState(() {
      _updatingFamilyRestageReviewItemId = item.itemId;
      _error = null;
    });
    try {
      final result = await signatureService.resolveReviewItem(
        reviewItemId: reviewItemId,
        resolution: approve
            ? SignatureHealthReviewResolution.approved
            : SignatureHealthReviewResolution.rejected,
      );
      final artifactRef = result.familyRestageFollowUpOutcomeJsonPath ??
          result.familyRestageFollowUpOutcomeReadmePath ??
          reviewItemId;
      await replayService.recordLabFamilyRestageFollowUpReviewResolution(
        environmentId: environmentId,
        evidenceFamily: item.evidenceFamily,
        resolutionStatus: approve ? 'approved' : 'held',
        resolutionArtifactRef: artifactRef,
      );
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
        _error = 'Failed to resolve family restage follow-up review: $error';
      });
    }
  }

  Future<void> _resolveFamilyRestageResolutionReview(
    ReplaySimulationLabFamilyRestageReviewItem item, {
    required bool approve,
  }) async {
    final replayService = _replaySimulationService;
    final signatureService = _signatureHealthService;
    final environmentId = _selectedReplayEnvironmentId;
    final reviewItemId = item.restageResolutionReviewItemId?.trim();
    if (replayService == null ||
        signatureService == null ||
        environmentId == null ||
        reviewItemId == null ||
        reviewItemId.isEmpty) {
      setState(() {
        _error =
            'Family restage resolution review is unavailable until the bounded resolution review item is ready.';
      });
      return;
    }
    setState(() {
      _updatingFamilyRestageReviewItemId = item.itemId;
      _error = null;
    });
    try {
      final result = await signatureService.resolveReviewItem(
        reviewItemId: reviewItemId,
        resolution: approve
            ? SignatureHealthReviewResolution.approved
            : SignatureHealthReviewResolution.rejected,
      );
      final artifactRef = result.familyRestageResolutionOutcomeJsonPath ??
          result.familyRestageResolutionOutcomeReadmePath ??
          reviewItemId;
      await replayService.recordLabFamilyRestageResolutionReviewResolution(
        environmentId: environmentId,
        evidenceFamily: item.evidenceFamily,
        resolutionStatus: approve ? 'approved' : 'held',
        resolutionArtifactRef: artifactRef,
      );
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
        _error = 'Failed to resolve family restage resolution review: $error';
      });
    }
  }

  Future<void> _resolveFamilyRestageExecutionReview(
    ReplaySimulationLabFamilyRestageReviewItem item, {
    required bool approve,
  }) async {
    final replayService = _replaySimulationService;
    final signatureService = _signatureHealthService;
    final environmentId = _selectedReplayEnvironmentId;
    final reviewItemId = item.restageExecutionReviewItemId?.trim();
    if (replayService == null ||
        signatureService == null ||
        environmentId == null ||
        reviewItemId == null ||
        reviewItemId.isEmpty) {
      setState(() {
        _error =
            'Family restage execution review is unavailable until the bounded execution review item is ready.';
      });
      return;
    }
    setState(() {
      _updatingFamilyRestageReviewItemId = item.itemId;
      _error = null;
    });
    try {
      final result = await signatureService.resolveReviewItem(
        reviewItemId: reviewItemId,
        resolution: approve
            ? SignatureHealthReviewResolution.approved
            : SignatureHealthReviewResolution.rejected,
      );
      final artifactRef = result.familyRestageExecutionOutcomeJsonPath ??
          result.familyRestageExecutionOutcomeReadmePath ??
          reviewItemId;
      await replayService.recordLabFamilyRestageExecutionReviewResolution(
        environmentId: environmentId,
        evidenceFamily: item.evidenceFamily,
        resolutionStatus: approve ? 'approved' : 'held',
        resolutionArtifactRef: artifactRef,
      );
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
        _error = 'Failed to resolve family restage execution review: $error';
      });
    }
  }

  Future<void> _resolveFamilyRestageApplicationReview(
    ReplaySimulationLabFamilyRestageReviewItem item, {
    required bool approve,
  }) async {
    final replayService = _replaySimulationService;
    final signatureService = _signatureHealthService;
    final environmentId = _selectedReplayEnvironmentId;
    final reviewItemId = item.restageApplicationReviewItemId?.trim();
    if (replayService == null ||
        signatureService == null ||
        environmentId == null ||
        reviewItemId == null ||
        reviewItemId.isEmpty) {
      setState(() {
        _error =
            'Family restage application review is unavailable until the bounded application review item is ready.';
      });
      return;
    }
    setState(() {
      _updatingFamilyRestageReviewItemId = item.itemId;
      _error = null;
    });
    try {
      final result = await signatureService.resolveReviewItem(
        reviewItemId: reviewItemId,
        resolution: approve
            ? SignatureHealthReviewResolution.approved
            : SignatureHealthReviewResolution.rejected,
      );
      final artifactRef = result.familyRestageApplicationOutcomeJsonPath ??
          result.familyRestageApplicationOutcomeReadmePath ??
          reviewItemId;
      await replayService.recordLabFamilyRestageApplicationReviewResolution(
        environmentId: environmentId,
        evidenceFamily: item.evidenceFamily,
        resolutionStatus: approve ? 'approved' : 'held',
        resolutionArtifactRef: artifactRef,
      );
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
        _error = 'Failed to resolve family restage application review: $error';
      });
    }
  }

  Future<void> _resolveFamilyRestageApplyReview(
    ReplaySimulationLabFamilyRestageReviewItem item, {
    required bool approve,
  }) async {
    final replayService = _replaySimulationService;
    final signatureService = _signatureHealthService;
    final environmentId = _selectedReplayEnvironmentId;
    final reviewItemId = item.restageApplyReviewItemId?.trim();
    if (replayService == null ||
        signatureService == null ||
        environmentId == null ||
        reviewItemId == null ||
        reviewItemId.isEmpty) {
      setState(() {
        _error =
            'Family restage apply review is unavailable until the bounded apply review item is ready.';
      });
      return;
    }
    setState(() {
      _updatingFamilyRestageReviewItemId = item.itemId;
      _error = null;
    });
    try {
      final result = await signatureService.resolveReviewItem(
        reviewItemId: reviewItemId,
        resolution: approve
            ? SignatureHealthReviewResolution.approved
            : SignatureHealthReviewResolution.rejected,
      );
      final artifactRef = result.familyRestageApplyOutcomeJsonPath ??
          result.familyRestageApplyOutcomeReadmePath ??
          reviewItemId;
      await replayService.recordLabFamilyRestageApplyReviewResolution(
        environmentId: environmentId,
        evidenceFamily: item.evidenceFamily,
        resolutionStatus: approve ? 'approved' : 'held',
        resolutionArtifactRef: artifactRef,
      );
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
        _error = 'Failed to resolve family restage apply review: $error';
      });
    }
  }

  Future<void> _resolveFamilyRestageServedBasisUpdateReview(
    ReplaySimulationLabFamilyRestageReviewItem item, {
    required bool approve,
  }) async {
    final replayService = _replaySimulationService;
    final signatureService = _signatureHealthService;
    final environmentId = _selectedReplayEnvironmentId;
    final reviewItemId = item.restageServedBasisUpdateReviewItemId?.trim();
    if (replayService == null ||
        signatureService == null ||
        environmentId == null ||
        reviewItemId == null ||
        reviewItemId.isEmpty) {
      setState(() {
        _error =
            'Family restage served-basis update review is unavailable until the bounded served-basis update review item is ready.';
      });
      return;
    }
    setState(() {
      _updatingFamilyRestageReviewItemId = item.itemId;
      _error = null;
    });
    try {
      final result = await signatureService.resolveReviewItem(
        reviewItemId: reviewItemId,
        resolution: approve
            ? SignatureHealthReviewResolution.approved
            : SignatureHealthReviewResolution.rejected,
      );
      final artifactRef =
          result.familyRestageServedBasisUpdateOutcomeJsonPath ??
              result.familyRestageServedBasisUpdateOutcomeReadmePath ??
              reviewItemId;
      await replayService
          .recordLabFamilyRestageServedBasisUpdateReviewResolution(
        environmentId: environmentId,
        evidenceFamily: item.evidenceFamily,
        resolutionStatus: approve ? 'approved' : 'held',
        resolutionArtifactRef: artifactRef,
      );
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingFamilyRestageReviewItemId = null;
        _error =
            'Failed to resolve family restage served-basis update review: $error';
      });
    }
  }

  Map<String, String> _parseLocalityDisplayNames(String raw) {
    final mappings = <String, String>{};
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final separatorIndex = trimmed.indexOf('|');
      if (separatorIndex <= 0 || separatorIndex == trimmed.length - 1) {
        continue;
      }
      final code = trimmed.substring(0, separatorIndex).trim();
      final displayName = trimmed.substring(separatorIndex + 1).trim();
      if (code.isEmpty || displayName.isEmpty) {
        continue;
      }
      mappings[code] = displayName;
    }
    return mappings;
  }

  List<String> _parseSimpleLines(String raw) {
    return raw
        .split('\n')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  ReplaySimulationLabVariantDraft? get _activeVariant {
    final variantId = _selectedVariantId;
    if (variantId == null) {
      return null;
    }
    for (final variant in _variants) {
      if (variant.variantId == variantId) {
        return variant;
      }
    }
    return null;
  }

  ReplaySimulationLabTargetActionDecision? _targetActionDecisionFor(
    String? variantId,
  ) {
    final runtimeState = _labRuntimeState;
    if (runtimeState == null) {
      return null;
    }
    for (final decision in runtimeState.targetActionDecisions) {
      final entryVariantId = decision.variantId?.trim();
      if (_sameTargetVariantId(entryVariantId, variantId)) {
        return decision;
      }
    }
    return null;
  }

  bool _sameTargetVariantId(String? leftVariantId, String? rightVariantId) {
    final left = leftVariantId?.trim();
    final right = rightVariantId?.trim();
    final leftIsBase = left == null || left.isEmpty;
    final rightIsBase = right == null || right.isEmpty;
    if (leftIsBase && rightIsBase) {
      return true;
    }
    return left == right;
  }

  ReplaySimulationLabOutcomeRecord? _latestOutcomeForTarget(String? variantId) {
    for (final entry in _labHistory) {
      final entryVariantId = entry.variantId?.trim();
      if ((variantId == null || variantId.isEmpty) &&
          (entryVariantId == null || entryVariantId.isEmpty)) {
        return entry;
      }
      if (entryVariantId == variantId) {
        return entry;
      }
    }
    return null;
  }

  Map<ReplaySimulationLabDisposition, int> _labOutcomeCounts() {
    final counts = <ReplaySimulationLabDisposition, int>{
      ReplaySimulationLabDisposition.accepted: 0,
      ReplaySimulationLabDisposition.denied: 0,
      ReplaySimulationLabDisposition.draft: 0,
    };
    for (final entry in _labHistory) {
      counts.update(
        entry.disposition,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }

  ReplaySimulationLabOutcomeRecord? _latestOutcomeByDisposition(
    ReplaySimulationLabDisposition disposition,
  ) {
    for (final entry in _labHistory) {
      if (entry.disposition == disposition) {
        return entry;
      }
    }
    return null;
  }

  String _daemonLearningPosture() {
    if (_labHistory.isEmpty) {
      return 'No labeled outcomes exist yet. Record draft, denied, or accepted outcomes so the supervisor daemon can learn what should be iterated, rejected, or considered for governed learning.';
    }
    final counts = _labOutcomeCounts();
    final latest = _labHistory.first;
    final accepted = counts[ReplaySimulationLabDisposition.accepted] ?? 0;
    final denied = counts[ReplaySimulationLabDisposition.denied] ?? 0;
    final drafts = counts[ReplaySimulationLabDisposition.draft] ?? 0;
    if (latest.disposition == ReplaySimulationLabDisposition.denied) {
      return 'Rejected evidence is the newest supervisor input. Keep iterating this environment before proposing another learning candidate.';
    }
    if (latest.disposition == ReplaySimulationLabDisposition.accepted &&
        latest.shareWithRealityModelAllowed) {
      return 'Accepted evidence is currently strongest, and the latest run is share-ready. The supervisor should keep this environment eligible for governed learning review only.';
    }
    if (accepted > denied && accepted > drafts) {
      return 'Accepted evidence currently outweighs denied and draft outcomes, but the lab should still preserve all contrary evidence for bounded review posture.';
    }
    if (drafts >= accepted && drafts >= denied) {
      return 'Draft outcomes currently dominate. The supervisor should treat this environment as an active iteration lane, not as a stable promotion candidate.';
    }
    return 'Accepted, denied, and draft outcomes are mixed. The supervisor should preserve the full comparison history and avoid collapsing it into a single simplistic recommendation.';
  }

  String _variantLearningTakeaway(
    List<ReplaySimulationLabOutcomeRecord> entries,
  ) {
    if (entries.isEmpty) {
      return 'No labeled outcomes yet for this run.';
    }
    final accepted = entries
        .where(
          (entry) =>
              entry.disposition == ReplaySimulationLabDisposition.accepted,
        )
        .length;
    final denied = entries
        .where(
          (entry) => entry.disposition == ReplaySimulationLabDisposition.denied,
        )
        .length;
    final drafts = entries
        .where(
          (entry) => entry.disposition == ReplaySimulationLabDisposition.draft,
        )
        .length;
    final latest = entries.first;
    if (latest.disposition == ReplaySimulationLabDisposition.denied) {
      return 'Latest evidence is denied. Preserve it as rejection memory and iterate.';
    }
    if (latest.disposition == ReplaySimulationLabDisposition.accepted &&
        latest.shareWithRealityModelAllowed) {
      return 'Latest evidence is accepted and share-ready. Keep it bounded as a governed learning candidate only.';
    }
    if (denied > accepted && denied >= drafts) {
      return 'Denied evidence dominates this run so far.';
    }
    if (accepted > denied && accepted >= drafts) {
      return 'Accepted evidence currently dominates this run.';
    }
    return 'Draft evidence currently dominates this run.';
  }

  String _variantRunTrend(
    List<ReplaySimulationLabOutcomeRecord> entries,
  ) {
    if (entries.isEmpty) {
      return 'No recorded runs yet.';
    }
    if (entries.length == 1) {
      return 'Only one labeled run exists so far.';
    }
    final latest = entries[0];
    final previous = entries[1];
    if (latest.disposition == previous.disposition) {
      return switch (latest.disposition) {
        ReplaySimulationLabDisposition.accepted =>
          'Run-to-run trend: stable accepted evidence across the latest two runs.',
        ReplaySimulationLabDisposition.denied =>
          'Run-to-run trend: repeated denials across the latest two runs.',
        ReplaySimulationLabDisposition.draft =>
          'Run-to-run trend: repeated draft outcomes across the latest two runs.',
      };
    }
    if (latest.disposition == ReplaySimulationLabDisposition.accepted &&
        previous.disposition == ReplaySimulationLabDisposition.denied) {
      return 'Run-to-run trend: improved from denial to accepted evidence.';
    }
    if (latest.disposition == ReplaySimulationLabDisposition.denied &&
        previous.disposition == ReplaySimulationLabDisposition.accepted) {
      return 'Run-to-run trend: regressed from accepted evidence back to denial.';
    }
    if (latest.disposition == ReplaySimulationLabDisposition.draft) {
      return 'Run-to-run trend: latest run moved back into draft iteration.';
    }
    return 'Run-to-run trend: mixed disposition shift across the latest two runs.';
  }

  List<ReplaySimulationLabRerunJob> _rerunJobsForTarget(String? variantId) {
    final normalizedVariantId = variantId?.trim();
    final jobs = _rerunJobs.where((job) {
      final jobVariantId = job.variantId?.trim();
      if (normalizedVariantId == null || normalizedVariantId.isEmpty) {
        return jobVariantId == null || jobVariantId.isEmpty;
      }
      return jobVariantId == normalizedVariantId;
    }).toList(growable: false)
      ..sort((left, right) {
        final leftTime = left.completedAt ?? left.startedAt;
        final rightTime = right.completedAt ?? right.startedAt;
        return rightTime.compareTo(leftTime);
      });
    return jobs;
  }

  int _totalKernelActivations(Map<String, int> counts) {
    return counts.values.fold<int>(0, (sum, value) => sum + value);
  }

  _SyntheticHumanKernelHistoryPoint? _historyPointFromOutcome(
    ReplaySimulationLabOutcomeRecord outcome,
    ReplaySimulationSyntheticHumanKernelEntry currentEntry,
  ) {
    for (final entry in outcome.syntheticHumanKernelEntries) {
      if (entry.actorId != currentEntry.actorId) {
        continue;
      }
      return _SyntheticHumanKernelHistoryPoint(
        recordedAt: outcome.recordedAt,
        headline:
            '${outcome.disposition.displayLabel} outcome • ${outcome.recordedAt.toUtc().toIso8601String().split('T').first}',
        summary:
            'Kernel activity: ${_topKernelActivitySummary(entry.activationCountByKernel)} • guidance ${entry.higherAgentGuidanceCount} • contradictions ${outcome.contradictionCount} • receipts ${outcome.receiptCount}',
        totalActivations:
            _totalKernelActivations(entry.activationCountByKernel),
        contradictionCount: outcome.contradictionCount,
        receiptCount: outcome.receiptCount,
      );
    }
    return null;
  }

  _SyntheticHumanKernelHistoryPoint? _historyPointFromRerunJob(
    ReplaySimulationLabRerunJob job,
    ReplaySimulationSyntheticHumanKernelEntry currentEntry,
  ) {
    for (final entry in job.syntheticHumanKernelEntries) {
      if (entry.actorId != currentEntry.actorId) {
        continue;
      }
      final timestamp = job.completedAt ?? job.startedAt;
      return _SyntheticHumanKernelHistoryPoint(
        recordedAt: timestamp,
        headline:
            '${_rerunStatusLabel(job.jobStatus)} rerun • ${timestamp.toUtc().toIso8601String().split('T').first}',
        summary:
            'Kernel activity: ${_topKernelActivitySummary(entry.activationCountByKernel)} • guidance ${entry.higherAgentGuidanceCount} • contradictions ${job.contradictionCount} • receipts ${job.receiptCount}',
        totalActivations:
            _totalKernelActivations(entry.activationCountByKernel),
        contradictionCount: job.contradictionCount,
        receiptCount: job.receiptCount,
      );
    }
    return null;
  }

  List<_SyntheticHumanKernelHistoryPoint> _syntheticHumanKernelHistoryFor(
    ReplaySimulationSyntheticHumanKernelEntry currentEntry,
  ) {
    final points = <_SyntheticHumanKernelHistoryPoint>[];
    for (final outcome in _labHistory) {
      final point = _historyPointFromOutcome(outcome, currentEntry);
      if (point != null) {
        points.add(point);
      }
    }
    for (final job in _rerunJobs) {
      final point = _historyPointFromRerunJob(job, currentEntry);
      if (point != null) {
        points.add(point);
      }
    }
    points.sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    return points.take(4).toList(growable: false);
  }

  String _kernelActivationHistorySummary(
    List<_SyntheticHumanKernelHistoryPoint> points,
  ) {
    if (points.isEmpty) {
      return 'No persisted lane-history samples exist yet.';
    }
    if (points.length == 1) {
      return 'Only one persisted lane-history sample is available so far.';
    }
    final latest = points[0];
    final previous = points[1];
    if (latest.contradictionCount < previous.contradictionCount &&
        latest.totalActivations >= previous.totalActivations) {
      return 'Latest lane sample is improving: contradiction pressure fell while kernel activity held.';
    }
    if (latest.contradictionCount > previous.contradictionCount) {
      return 'Latest lane sample is regressing: contradiction pressure rose across the last two persisted samples.';
    }
    if (latest.receiptCount > previous.receiptCount &&
        latest.totalActivations >= previous.totalActivations) {
      return 'Latest lane sample is gaining evidence without losing kernel activity.';
    }
    return 'Latest lane sample is mixed across the last two persisted samples.';
  }

  _LocalityHierarchyHistoryPoint? _localityHistoryPointFromOutcome(
    ReplaySimulationLabOutcomeRecord outcome,
    ReplaySimulationLocalityHierarchyNodeSummary currentNode,
  ) {
    for (final node in outcome.localityHierarchyNodes) {
      if (node.localityCode != currentNode.localityCode) {
        continue;
      }
      return _LocalityHierarchyHistoryPoint(
        recordedAt: outcome.recordedAt,
        headline:
            '${outcome.disposition.displayLabel} outcome • ${outcome.recordedAt.toUtc().toIso8601String().split('T').first}',
        summary:
            'Risk ${node.risk} • effectiveness ${node.effectiveness} • contradictions ${node.contradictionCount} • branch sensitivity ${(node.branchSensitivity * 100).round()}%',
        risk: node.risk,
        effectiveness: node.effectiveness,
        contradictionCount: node.contradictionCount,
      );
    }
    return null;
  }

  _LocalityHierarchyHistoryPoint? _localityHistoryPointFromRerunJob(
    ReplaySimulationLabRerunJob job,
    ReplaySimulationLocalityHierarchyNodeSummary currentNode,
  ) {
    for (final node in job.localityHierarchyNodes) {
      if (node.localityCode != currentNode.localityCode) {
        continue;
      }
      final timestamp = job.completedAt ?? job.startedAt;
      return _LocalityHierarchyHistoryPoint(
        recordedAt: timestamp,
        headline:
            '${_rerunStatusLabel(job.jobStatus)} rerun • ${timestamp.toUtc().toIso8601String().split('T').first}',
        summary:
            'Risk ${node.risk} • effectiveness ${node.effectiveness} • contradictions ${node.contradictionCount} • branch sensitivity ${(node.branchSensitivity * 100).round()}%',
        risk: node.risk,
        effectiveness: node.effectiveness,
        contradictionCount: node.contradictionCount,
      );
    }
    return null;
  }

  List<_LocalityHierarchyHistoryPoint> _localityHierarchyHistoryFor(
    ReplaySimulationLocalityHierarchyNodeSummary currentNode,
  ) {
    final points = <_LocalityHierarchyHistoryPoint>[];
    for (final outcome in _labHistory) {
      final point = _localityHistoryPointFromOutcome(outcome, currentNode);
      if (point != null) {
        points.add(point);
      }
    }
    for (final job in _rerunJobs) {
      final point = _localityHistoryPointFromRerunJob(job, currentNode);
      if (point != null) {
        points.add(point);
      }
    }
    points.sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    return points.take(4).toList(growable: false);
  }

  String _localityHierarchyHistorySummary(
    List<_LocalityHierarchyHistoryPoint> points,
  ) {
    if (points.isEmpty) {
      return 'No persisted locality-history samples exist yet.';
    }
    if (points.length == 1) {
      return 'Only one persisted locality-history sample is available so far.';
    }
    final latest = points[0];
    final previous = points[1];
    if (latest.contradictionCount < previous.contradictionCount &&
        latest.risk == previous.risk &&
        latest.effectiveness == previous.effectiveness) {
      return 'Latest locality sample is easing: contradiction pressure fell while posture remained bounded.';
    }
    if (latest.contradictionCount > previous.contradictionCount ||
        latest.risk != previous.risk) {
      return 'Latest locality sample shows changed pressure or risk compared with the prior persisted sample.';
    }
    if (latest.effectiveness != previous.effectiveness) {
      return 'Latest locality sample changed effectiveness posture compared with the prior persisted sample.';
    }
    return 'Latest locality sample is stable across the last two persisted samples.';
  }

  bool _sameHigherAgentHandoffTarget(
    ReplaySimulationHigherAgentHandoffItem left,
    ReplaySimulationHigherAgentHandoffItem right,
  ) {
    return left.scope == right.scope && left.targetLabel == right.targetLabel;
  }

  _HigherAgentHandoffHistoryPoint? _handoffHistoryPointFromOutcome(
    ReplaySimulationLabOutcomeRecord outcome,
    ReplaySimulationHigherAgentHandoffItem currentItem,
  ) {
    for (final item in outcome.higherAgentHandoffItems) {
      if (!_sameHigherAgentHandoffTarget(item, currentItem)) {
        continue;
      }
      return _HigherAgentHandoffHistoryPoint(
        recordedAt: outcome.recordedAt,
        headline:
            '${outcome.disposition.displayLabel} outcome • ${outcome.recordedAt.toUtc().toIso8601String().split('T').first}',
        summary:
            'Status ${item.status} • contradictions ${outcome.contradictionCount} • request previews ${outcome.requestPreviewCount}',
        status: item.status,
        contradictionCount: outcome.contradictionCount,
        requestPreviewCount: outcome.requestPreviewCount,
      );
    }
    return null;
  }

  _HigherAgentHandoffHistoryPoint? _handoffHistoryPointFromRerunJob(
    ReplaySimulationLabRerunJob job,
    ReplaySimulationHigherAgentHandoffItem currentItem,
  ) {
    for (final item in job.higherAgentHandoffItems) {
      if (!_sameHigherAgentHandoffTarget(item, currentItem)) {
        continue;
      }
      final timestamp = job.completedAt ?? job.startedAt;
      return _HigherAgentHandoffHistoryPoint(
        recordedAt: timestamp,
        headline:
            '${_rerunStatusLabel(job.jobStatus)} rerun • ${timestamp.toUtc().toIso8601String().split('T').first}',
        summary:
            'Status ${item.status} • contradictions ${job.contradictionCount} • request previews ${job.requestPreviewCount}',
        status: item.status,
        contradictionCount: job.contradictionCount,
        requestPreviewCount: job.requestPreviewCount,
      );
    }
    return null;
  }

  List<_HigherAgentHandoffHistoryPoint> _higherAgentHandoffHistoryFor(
    ReplaySimulationHigherAgentHandoffItem currentItem,
  ) {
    final points = <_HigherAgentHandoffHistoryPoint>[];
    for (final outcome in _labHistory) {
      final point = _handoffHistoryPointFromOutcome(outcome, currentItem);
      if (point != null) {
        points.add(point);
      }
    }
    for (final job in _rerunJobs) {
      final point = _handoffHistoryPointFromRerunJob(job, currentItem);
      if (point != null) {
        points.add(point);
      }
    }
    points.sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    return points.take(4).toList(growable: false);
  }

  String _higherAgentHandoffHistorySummary(
    List<_HigherAgentHandoffHistoryPoint> points,
  ) {
    if (points.isEmpty) {
      return 'No persisted handoff-lineage samples exist yet.';
    }
    if (points.length == 1) {
      return 'Only one persisted handoff-lineage sample is available so far.';
    }
    final latest = points[0];
    final previous = points[1];
    if (latest.status == previous.status &&
        latest.contradictionCount == previous.contradictionCount) {
      return 'Latest handoff posture is stable across the last two persisted samples.';
    }
    if (latest.contradictionCount > previous.contradictionCount) {
      return 'Latest handoff posture is under more contradiction pressure than the previous sample.';
    }
    if (latest.contradictionCount < previous.contradictionCount) {
      return 'Latest handoff posture is improving with lower contradiction pressure than the previous sample.';
    }
    return 'Latest handoff posture shifted across the last two persisted samples.';
  }

  int _provenanceMetadataCount(
    ReplaySimulationRealismProvenanceSummary provenance,
    String key,
  ) {
    final value = provenance.metadata[key];
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _realismProvenancePointSummary(
    ReplaySimulationRealismProvenanceSummary provenance,
  ) {
    return 'Mode ${provenance.simulationMode} • sidecars ${provenance.sidecarRefs.length} • artifact families ${provenance.trainingArtifactFamilies.length} • scenarios ${_provenanceMetadataCount(provenance, 'scenarioCount')} • overlays ${_provenanceMetadataCount(provenance, 'overlayCount')}';
  }

  _RealismProvenanceHistoryPoint _realismProvenanceHistoryPointFromOutcome(
    ReplaySimulationLabOutcomeRecord outcome,
  ) {
    return _RealismProvenanceHistoryPoint(
      recordedAt: outcome.recordedAt,
      headline:
          '${outcome.disposition.displayLabel} outcome • ${outcome.recordedAt.toUtc().toIso8601String().split('T').first}',
      summary: _realismProvenancePointSummary(outcome.realismProvenance),
      sidecarRefs: outcome.realismProvenance.sidecarRefs,
      trainingArtifactFamilies:
          outcome.realismProvenance.trainingArtifactFamilies,
      cityPackStructuralRef: outcome.realismProvenance.cityPackStructuralRef,
    );
  }

  _RealismProvenanceHistoryPoint _realismProvenanceHistoryPointFromRerunJob(
    ReplaySimulationLabRerunJob job,
  ) {
    final timestamp = job.completedAt ?? job.startedAt;
    return _RealismProvenanceHistoryPoint(
      recordedAt: timestamp,
      headline:
          '${_rerunStatusLabel(job.jobStatus)} rerun • ${timestamp.toUtc().toIso8601String().split('T').first}',
      summary: _realismProvenancePointSummary(job.realismProvenance),
      sidecarRefs: job.realismProvenance.sidecarRefs,
      trainingArtifactFamilies: job.realismProvenance.trainingArtifactFamilies,
      cityPackStructuralRef: job.realismProvenance.cityPackStructuralRef,
    );
  }

  List<_RealismProvenanceHistoryPoint> _realismProvenanceHistory() {
    final points = <_RealismProvenanceHistoryPoint>[
      for (final outcome in _labHistory)
        _realismProvenanceHistoryPointFromOutcome(outcome),
      for (final job in _rerunJobs)
        _realismProvenanceHistoryPointFromRerunJob(job),
    ];
    points.sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    return points.take(4).toList(growable: false);
  }

  bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  String _realismProvenanceHistorySummary(
    List<_RealismProvenanceHistoryPoint> points,
  ) {
    if (points.isEmpty) {
      return 'No persisted provenance-history samples exist yet.';
    }
    if (points.length == 1) {
      return 'Only one persisted provenance-history sample is available so far.';
    }
    final latest = points[0];
    final previous = points[1];
    final latestCarriesMoreRefs =
        latest.sidecarRefs.length > previous.sidecarRefs.length ||
            latest.trainingArtifactFamilies.length >
                previous.trainingArtifactFamilies.length;
    final latestCarriesFewerRefs =
        latest.sidecarRefs.length < previous.sidecarRefs.length ||
            latest.trainingArtifactFamilies.length <
                previous.trainingArtifactFamilies.length;
    if (latestCarriesMoreRefs) {
      return 'Latest provenance expanded with additional sidecars or artifact families compared with the prior persisted sample.';
    }
    if (latestCarriesFewerRefs) {
      return 'Latest provenance narrowed the attached sidecars or artifact families compared with the prior persisted sample.';
    }
    if (!_sameStringList(latest.sidecarRefs, previous.sidecarRefs) ||
        !_sameStringList(
          latest.trainingArtifactFamilies,
          previous.trainingArtifactFamilies,
        ) ||
        latest.cityPackStructuralRef != previous.cityPackStructuralRef) {
      return 'Latest provenance changed attached sidecars, artifact families, or city-pack identity compared with the prior persisted sample.';
    }
    return 'Latest provenance is stable across the last two persisted samples.';
  }

  List<String> _stringListDifference(List<String> left, List<String> right) {
    final rightSet = right.toSet();
    return left.where((entry) => !rightSet.contains(entry)).toList(
          growable: false,
        );
  }

  _RealismProvenanceDelta? _latestRealismProvenanceDelta(
    List<_RealismProvenanceHistoryPoint> points,
  ) {
    if (points.length < 2) {
      return null;
    }
    final latest = points[0];
    final previous = points[1];
    final addedSidecars =
        _stringListDifference(latest.sidecarRefs, previous.sidecarRefs);
    final removedSidecars =
        _stringListDifference(previous.sidecarRefs, latest.sidecarRefs);
    final addedFamilies = _stringListDifference(
      latest.trainingArtifactFamilies,
      previous.trainingArtifactFamilies,
    );
    final removedFamilies = _stringListDifference(
      previous.trainingArtifactFamilies,
      latest.trainingArtifactFamilies,
    );
    final details = <String>[
      if (addedSidecars.isNotEmpty)
        'Added sidecars: ${addedSidecars.join(' • ')}',
      if (removedSidecars.isNotEmpty)
        'Removed sidecars: ${removedSidecars.join(' • ')}',
      if (addedFamilies.isNotEmpty)
        'Added artifact families: ${addedFamilies.join(' • ')}',
      if (removedFamilies.isNotEmpty)
        'Removed artifact families: ${removedFamilies.join(' • ')}',
      if (latest.cityPackStructuralRef != previous.cityPackStructuralRef)
        'City-pack structural ref: ${previous.cityPackStructuralRef ?? 'none'} -> ${latest.cityPackStructuralRef ?? 'none'}',
    ];
    if (details.isEmpty) {
      return const _RealismProvenanceDelta(
        headline:
            'Latest provenance delta is stable across the last two persisted samples.',
        details: <String>[],
      );
    }
    return _RealismProvenanceDelta(
      headline:
          'Latest provenance delta highlights what changed between the latest two persisted samples.',
      details: details,
    );
  }

  String _variantRuntimeExecutionSummary(
    List<ReplaySimulationLabRerunJob> jobs,
  ) {
    if (jobs.isEmpty) {
      return 'Executed reruns: none yet for this target.';
    }
    final latest = jobs.first;
    final latestDate = (latest.completedAt ?? latest.startedAt)
        .toUtc()
        .toIso8601String()
        .split('T')
        .first;
    final statusLabel = _rerunStatusLabel(latest.jobStatus);
    if (latest.jobStatus == 'failed') {
      return 'Latest executed rerun: $statusLabel on $latestDate. Preserve the failure before the next rerun.';
    }
    if (latest.jobStatus == 'running') {
      return 'Latest executed rerun: $statusLabel since $latestDate.';
    }
    if (latest.jobStatus == 'completed') {
      return 'Latest executed rerun: $statusLabel on $latestDate with ${latest.contradictionCount} contradictions, ${latest.receiptCount} receipts, and ${latest.requestPreviewCount} request previews.';
    }
    return 'Latest executed rerun: $statusLabel on $latestDate.';
  }

  String _runtimeDeltaFragment({
    required String label,
    required int latest,
    required int previous,
  }) {
    final delta = latest - previous;
    if (delta == 0) {
      return '$label stable';
    }
    final direction = delta > 0 ? 'up' : 'down';
    return '$label $direction ${delta.abs()}';
  }

  String _variantRuntimeExecutionTrend(
    List<ReplaySimulationLabRerunJob> jobs,
  ) {
    final completedJobs = jobs
        .where((job) => job.jobStatus == 'completed')
        .toList(growable: false);
    if (completedJobs.isEmpty) {
      return 'Runtime delta: no completed reruns exist yet.';
    }
    if (completedJobs.length == 1) {
      return 'Runtime delta: only one completed rerun exists so far.';
    }
    final latest = completedJobs[0];
    final previous = completedJobs[1];
    final deltas = <String>[
      _runtimeDeltaFragment(
        label: 'contradictions',
        latest: latest.contradictionCount,
        previous: previous.contradictionCount,
      ),
      _runtimeDeltaFragment(
        label: 'receipts',
        latest: latest.receiptCount,
        previous: previous.receiptCount,
      ),
      _runtimeDeltaFragment(
        label: 'overlays',
        latest: latest.overlayCount,
        previous: previous.overlayCount,
      ),
      _runtimeDeltaFragment(
        label: 'request previews',
        latest: latest.requestPreviewCount,
        previous: previous.requestPreviewCount,
      ),
    ];
    return 'Runtime delta vs prior executed rerun: ${deltas.join(', ')}.';
  }

  String _rerunTargetLabel(String? variantId) {
    if (variantId == null || variantId.isEmpty) {
      return 'Base run';
    }
    for (final variant in _variants) {
      if (variant.variantId == variantId) {
        return variant.label;
      }
    }
    return variantId;
  }

  String _executedRerunTimelineFocusValueForTarget(String? variantId) {
    if (variantId == null || variantId.isEmpty) {
      return _baseExecutedRerunTargetValue;
    }
    return variantId;
  }

  List<String?> _orderedExecutedRerunTargetKeys([
    List<ReplaySimulationLabRerunJob>? jobsOverride,
  ]) {
    final jobs = jobsOverride ?? _rerunJobs;
    final groupedJobs = <String?, List<ReplaySimulationLabRerunJob>>{};
    for (final job in jobs) {
      final entries = groupedJobs.putIfAbsent(
        job.variantId,
        () => <ReplaySimulationLabRerunJob>[],
      );
      entries.add(job);
    }
    return <String?>[
      null,
      ..._variants.map((entry) => entry.variantId),
      ...groupedJobs.keys.where(
        (entry) =>
            entry != null &&
            !_variants.any((variant) => variant.variantId == entry),
      ),
    ].where(groupedJobs.containsKey).toList(growable: false);
  }

  List<String> _availableExecutedRerunTimelineFocusValues({
    List<ReplaySimulationLabRerunJob>? jobs,
  }) {
    return <String>[
      _allExecutedRerunTargetsValue,
      ..._orderedExecutedRerunTargetKeys(jobs).map(
        _executedRerunTimelineFocusValueForTarget,
      ),
    ];
  }

  String _resolveExecutedRerunTimelineFocus({
    required String currentSelection,
    List<ReplaySimulationLabRerunJob>? jobs,
  }) {
    final available = _availableExecutedRerunTimelineFocusValues(jobs: jobs);
    if (available.contains(currentSelection)) {
      return currentSelection;
    }
    return _allExecutedRerunTargetsValue;
  }

  String _executedRerunTimelineFocusLabel(String value) {
    if (value == _allExecutedRerunTargetsValue) {
      return 'All targets';
    }
    if (value == _baseExecutedRerunTargetValue) {
      return 'Base run';
    }
    return _rerunTargetLabel(value);
  }

  String _executedRerunTimelineFocusSummary() {
    if (_executedRerunTimelineFocus == _allExecutedRerunTargetsValue) {
      return 'Showing all targets.';
    }
    return 'Focused target: ${_executedRerunTimelineFocusLabel(_executedRerunTimelineFocus)}';
  }

  String _labTargetActionLabel(String action) {
    return switch (action) {
      'keep_iterating' => 'Keep iterating',
      'watch_closely' => 'Watch closely',
      'candidate_for_bounded_review' => 'Candidate for bounded review',
      _ => action,
    };
  }

  String _completedRerunCountLabel(List<ReplaySimulationLabRerunJob> jobs) {
    final completedCount =
        jobs.where((job) => job.jobStatus == 'completed').length;
    return 'Completed reruns: $completedCount';
  }

  String _variantRuntimeExecutionSeverityCode(
    List<ReplaySimulationLabRerunJob> jobs,
  ) {
    final completedJobs = jobs
        .where((job) => job.jobStatus == 'completed')
        .toList(growable: false);
    if (completedJobs.isEmpty) {
      return 'no_evidence';
    }
    if (completedJobs.length == 1) {
      return 'low_confidence';
    }
    final latest = completedJobs[0];
    final previous = completedJobs[1];
    final contradictionDelta =
        latest.contradictionCount - previous.contradictionCount;
    final receiptDelta = latest.receiptCount - previous.receiptCount;
    final overlayDelta = latest.overlayCount - previous.overlayCount;
    final previewDelta =
        latest.requestPreviewCount - previous.requestPreviewCount;
    if (contradictionDelta == 0 &&
        receiptDelta == 0 &&
        overlayDelta == 0 &&
        previewDelta == 0) {
      return 'stable';
    }
    var score = 0;
    if (contradictionDelta < 0) {
      score += 2;
    } else if (contradictionDelta > 0) {
      score -= 2;
    }
    if (receiptDelta > 0) {
      score += 1;
    } else if (receiptDelta < 0) {
      score -= 1;
    }
    if (previewDelta > 0) {
      score += 1;
    } else if (previewDelta < 0) {
      score -= 1;
    }
    if (score >= 3) {
      return 'improving';
    }
    if (score <= -3) {
      return 'regressing';
    }
    return 'mixed';
  }

  String _variantRuntimeExecutionSeverity(
    List<ReplaySimulationLabRerunJob> jobs,
  ) {
    return switch (_variantRuntimeExecutionSeverityCode(jobs)) {
      'no_evidence' => 'Trend severity: No runtime evidence yet.',
      'low_confidence' =>
        'Trend severity: Low confidence; only one completed rerun exists.',
      'stable' => 'Trend severity: Stable within current runtime bounds.',
      'improving' => 'Trend severity: Improving within bounded runtime drift.',
      'regressing' => 'Trend severity: Regression risk is increasing.',
      _ => 'Trend severity: Mixed drift; operator review still required.',
    };
  }

  String _targetActionDecisionSummary(
    ReplaySimulationLabTargetActionDecision decision,
  ) {
    final updated =
        decision.updatedAt.toUtc().toIso8601String().split('T').first;
    final mode =
        decision.acceptedSuggestion ? 'accepted suggestion' : 'override';
    return 'Operator action: ${_labTargetActionLabel(decision.selectedAction)} • $mode on $updated';
  }

  String _targetActionRoutingSummary({
    required String selectedAction,
    bool? acceptedSuggestion,
    DateTime? updatedAt,
  }) {
    final updated = updatedAt?.toUtc().toIso8601String().split('T').first;
    final suffix = updated == null
        ? ''
        : acceptedSuggestion == null
            ? ' • recorded on $updated'
            : acceptedSuggestion
                ? ' • accepted suggestion on $updated'
                : ' • override on $updated';
    return 'Default next action: ${_labTargetActionLabel(selectedAction)}.$suffix';
  }

  String _targetActionRoutingGuidance(String selectedAction) {
    return switch (selectedAction) {
      'keep_iterating' =>
        'Routing: keep this target in rerun iteration until contradiction pressure and denial memory improve.',
      'watch_closely' =>
        'Routing: keep this target on a closely watched rerun lane before bounded review.',
      'candidate_for_bounded_review' =>
        'Routing: this target is ready for bounded review by default. Queue another rerun only if you want one more runtime check before review.',
      _ => 'Routing: no bounded next-step guidance has been recorded yet.',
    };
  }

  String _targetActionDecisionReason(
    ReplaySimulationLabTargetActionDecision decision,
  ) {
    if (decision.suggestedReason.trim().isEmpty) {
      return 'Decision basis at action time: runtime-derived guidance was preserved without an extra note.';
    }
    return 'Decision basis at action time: ${decision.suggestedReason}';
  }

  String _queueRerunButtonLabel(String? selectedAction) {
    return switch (selectedAction) {
      'keep_iterating' => 'Queue iteration rerun',
      'watch_closely' => 'Queue watch rerun',
      'candidate_for_bounded_review' => 'Queue review-check rerun',
      _ => 'Queue rerun request',
    };
  }

  bool _showsBoundedReviewRouting(String? selectedAction) {
    return selectedAction == 'candidate_for_bounded_review';
  }

  String _rerunRequestTargetActionSummary(
      ReplaySimulationLabRerunRequest request) {
    final selectedAction = request.targetActionSelected;
    if (selectedAction == null || selectedAction.trim().isEmpty) {
      return 'No target action was recorded when this rerun was queued.';
    }
    return _targetActionRoutingSummary(
      selectedAction: selectedAction,
      acceptedSuggestion: request.targetActionAcceptedSuggestion,
      updatedAt: request.targetActionUpdatedAt,
    );
  }

  String _rerunRequestTargetActionReason(
      ReplaySimulationLabRerunRequest request) {
    final selectedAction = request.targetActionSelected;
    if (selectedAction == null || selectedAction.trim().isEmpty) {
      return 'Routing basis: this rerun was queued without a persisted target action.';
    }
    final decisionBasis = request.targetActionSuggestedReason?.trim();
    if (decisionBasis == null || decisionBasis.isEmpty) {
      return _targetActionRoutingGuidance(selectedAction);
    }
    return 'Routing basis: $decisionBasis';
  }

  String _variantRuntimeSuggestedActionCode(
    String? variantId,
    List<ReplaySimulationLabRerunJob> jobs,
  ) {
    if (jobs.isEmpty) {
      return 'keep_iterating';
    }
    final severity = _variantRuntimeExecutionSeverityCode(jobs);
    final latestJob = jobs.first;
    if (latestJob.jobStatus == 'failed' || severity == 'regressing') {
      return 'keep_iterating';
    }
    final latestOutcome = _latestOutcomeForTarget(variantId);
    if (latestOutcome?.disposition == ReplaySimulationLabDisposition.denied) {
      return 'keep_iterating';
    }
    if (severity == 'no_evidence' || severity == 'low_confidence') {
      return 'watch_closely';
    }
    if (severity == 'mixed') {
      return 'watch_closely';
    }
    if (latestOutcome?.disposition == ReplaySimulationLabDisposition.draft) {
      return 'watch_closely';
    }
    return 'candidate_for_bounded_review';
  }

  String _variantRuntimeSuggestedAction(
    String? variantId,
    List<ReplaySimulationLabRerunJob> jobs,
  ) {
    return 'Suggested action: ${_labTargetActionLabel(_variantRuntimeSuggestedActionCode(variantId, jobs))}.';
  }

  String _variantRuntimeSuggestedActionReason(
    String? variantId,
    List<ReplaySimulationLabRerunJob> jobs,
  ) {
    final severity = _variantRuntimeExecutionSeverityCode(jobs);
    final latestOutcome = _latestOutcomeForTarget(variantId);
    final latestDisposition = latestOutcome?.disposition.displayLabel;
    final latestJob = jobs.isEmpty ? null : jobs.first;
    if (jobs.isEmpty) {
      return 'Reason: no executed reruns exist yet for this target.';
    }
    if (latestJob?.jobStatus == 'failed') {
      return 'Reason: the latest executed rerun failed, so this lane needs another bounded rerun before review.';
    }
    if (severity == 'regressing') {
      return 'Reason: runtime contradictions are worsening or confidence signals are weakening.';
    }
    if (latestOutcome?.disposition == ReplaySimulationLabDisposition.denied) {
      return 'Reason: the latest labeled outcome is $latestDisposition, so denial memory still blocks bounded review.';
    }
    if (severity == 'no_evidence' || severity == 'low_confidence') {
      return 'Reason: there is not enough completed runtime evidence yet to promote beyond close watch.';
    }
    if (severity == 'mixed') {
      return 'Reason: runtime drift is mixed, so this target needs more iteration before any bounded review.';
    }
    if (latestOutcome?.disposition == ReplaySimulationLabDisposition.draft) {
      return 'Reason: runtime trend is acceptable, but the latest labeled outcome is still draft-only.';
    }
    return 'Reason: runtime trend is bounded and the latest labeled outcome is no longer blocked by denial memory.';
  }

  Future<void> _applyTargetActionDecision(
    String? variantId, {
    required String suggestedAction,
    required String suggestedReason,
    required String selectedAction,
  }) async {
    final service = _replaySimulationService;
    final environmentId = _selectedReplayEnvironmentId;
    if (service == null || environmentId == null) {
      return;
    }
    final targetKey = _executedRerunTimelineFocusValueForTarget(variantId);
    setState(() {
      _updatingTargetActionTargetKey = targetKey;
      _error = null;
    });
    try {
      final runtimeState = await service.recordLabTargetActionDecision(
        environmentId: environmentId,
        variantId: variantId,
        suggestedAction: suggestedAction,
        suggestedReason: suggestedReason,
        selectedAction: selectedAction,
      );
      if (!mounted) return;
      setState(() {
        _labRuntimeState = runtimeState;
        _updatingTargetActionTargetKey = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to persist target action: $error';
        _updatingTargetActionTargetKey = null;
      });
    }
  }

  String _jobTimelineMetricSummary(ReplaySimulationLabRerunJob job) {
    return 'Contradictions ${job.contradictionCount} • Receipts ${job.receiptCount} • Overlays ${job.overlayCount} • Request previews ${job.requestPreviewCount}';
  }

  String _jobTimelineDate(ReplaySimulationLabRerunJob job) {
    final value = (job.completedAt ?? job.startedAt)
        .toUtc()
        .toIso8601String()
        .split('T')
        .first;
    return value;
  }

  List<Widget> _buildExecutedRerunTimelineTiles(ThemeData theme) {
    final orderedKeys = _orderedExecutedRerunTargetKeys();
    if (orderedKeys.isEmpty) {
      return <Widget>[
        Text(
          'No executed rerun jobs exist yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ];
    }
    final filteredKeys =
        _executedRerunTimelineFocus == _allExecutedRerunTargetsValue
            ? orderedKeys
            : orderedKeys
                .where(
                  (variantId) =>
                      _executedRerunTimelineFocusValueForTarget(variantId) ==
                      _executedRerunTimelineFocus,
                )
                .toList(growable: false);
    return filteredKeys.map((variantId) {
      final jobs = _rerunJobsForTarget(variantId);
      final suggestedActionWire =
          _variantRuntimeSuggestedActionCode(variantId, jobs);
      final suggestedReason =
          _variantRuntimeSuggestedActionReason(variantId, jobs).replaceFirst(
        'Reason: ',
        '',
      );
      final decision = _targetActionDecisionFor(variantId);
      final targetKey = _executedRerunTimelineFocusValueForTarget(variantId);
      final isUpdatingAction = _updatingTargetActionTargetKey == targetKey;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: variantId == _selectedVariantId
                ? AppColors.primary
                : AppColors.grey300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _rerunTargetLabel(variantId),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  _completedRerunCountLabel(jobs),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (variantId == _selectedVariantId) ...[
              const SizedBox(height: 4),
              Text(
                'Selected as the next run target.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _variantRuntimeExecutionSummary(jobs),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _variantRuntimeExecutionTrend(jobs),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _variantRuntimeExecutionSeverity(jobs),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _variantRuntimeSuggestedAction(variantId, jobs),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _variantRuntimeSuggestedActionReason(variantId, jobs),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (decision != null) ...[
              const SizedBox(height: 4),
              Text(
                _targetActionDecisionSummary(decision),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _targetActionDecisionReason(decision),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (jobs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    key: Key(
                      'worldSimulationLabAcceptSuggestedActionButton_$targetKey',
                    ),
                    onPressed: isUpdatingAction
                        ? null
                        : () => _applyTargetActionDecision(
                              variantId,
                              suggestedAction: suggestedActionWire,
                              suggestedReason: suggestedReason,
                              selectedAction: suggestedActionWire,
                            ),
                    child: Text(
                      isUpdatingAction
                          ? 'Updating action...'
                          : 'Use suggested action',
                    ),
                  ),
                  ..._labTargetActionValues
                      .where((value) => value != suggestedActionWire)
                      .map(
                        (action) => OutlinedButton(
                          key: Key(
                            'worldSimulationLabOverrideActionButton_${action}_$targetKey',
                          ),
                          onPressed: isUpdatingAction
                              ? null
                              : () => _applyTargetActionDecision(
                                    variantId,
                                    suggestedAction: suggestedActionWire,
                                    suggestedReason: suggestedReason,
                                    selectedAction: action,
                                  ),
                          child: Text(
                            'Override: ${_labTargetActionLabel(action)}',
                          ),
                        ),
                      ),
                ],
              ),
            ],
            if (jobs.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...jobs.take(4).map(
                    (job) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_rerunStatusLabel(job.jobStatus)} • ${_jobTimelineDate(job)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _jobTimelineMetricSummary(job),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      );
    }).toList(growable: false);
  }

  List<Widget> _buildRerunRequestTiles(ThemeData theme) {
    if (_rerunRequests.isEmpty) {
      return <Widget>[
        Text(
          'No rerun requests have been queued yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ];
    }
    return _rerunRequests.take(6).map((request) {
      final isUpdating = _updatingRerunRequestId == request.requestId;
      final statusLabel = _rerunStatusLabel(request.requestStatus);
      final lineageSummary = request.lineageOutcomeJsonPath == null
          ? 'No prior labeled outcome exists yet for this target.'
          : 'Lineage: ${request.lineageDisposition ?? 'unknown'} on ${request.lineageRecordedAt?.toUtc().toIso8601String().split('T').first ?? 'unknown'}';
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.variantLabel ?? 'Base run rerun',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '$statusLabel • requested ${request.requestedAt.toUtc().toIso8601String().split('T').first}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (request.startedAt != null || request.completedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                _rerunStatusTimeline(request),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              lineageSummary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if ((request.targetActionSelected?.trim() ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _rerunRequestTargetActionSummary(request),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _rerunRequestTargetActionReason(request),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (request.latestJobStatus != null) ...[
              const SizedBox(height: 4),
              Text(
                _rerunLatestJobSummary(request),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (request.requestNotes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${request.requestNotes.join(' • ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (request.requestStatus == 'queued') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed:
                        isUpdating ? null : () => _executeRerunRequest(request),
                    child: Text(
                      isUpdating ? 'Executing...' : 'Execute rerun',
                    ),
                  ),
                  if (_showsBoundedReviewRouting(request.targetActionSelected))
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go(AdminRoutePaths.realitySystemReality),
                      icon: const Icon(Icons.psychology_alt_outlined),
                      label: const Text('Open bounded review'),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }).toList(growable: false);
  }

  String _rerunStatusLabel(String raw) {
    return switch (raw) {
      'queued' => 'Queued',
      'running' => 'Running',
      'completed' => 'Completed',
      'failed' => 'Failed',
      _ => raw,
    };
  }

  String _rerunStatusTimeline(ReplaySimulationLabRerunRequest request) {
    if (request.completedAt != null) {
      return 'Completed ${request.completedAt!.toUtc().toIso8601String().split('T').first} after starting ${request.startedAt?.toUtc().toIso8601String().split('T').first ?? 'unknown'}.';
    }
    if (request.startedAt != null) {
      return 'Started ${request.startedAt!.toUtc().toIso8601String().split('T').first}.';
    }
    return 'Awaiting execution.';
  }

  String _rerunLatestJobSummary(ReplaySimulationLabRerunRequest request) {
    final jobStatus = _rerunStatusLabel(request.latestJobStatus ?? 'unknown');
    final started =
        request.latestJobStartedAt?.toUtc().toIso8601String().split('T').first;
    final completed = request.latestJobCompletedAt
        ?.toUtc()
        .toIso8601String()
        .split('T')
        .first;
    final snapshot =
        request.latestJobSnapshotJsonPath == null ? '' : ' • snapshot ready';
    if (completed != null) {
      return 'Latest runtime job: $jobStatus • completed $completed$snapshot';
    }
    if (started != null) {
      return 'Latest runtime job: $jobStatus • started $started';
    }
    return 'Latest runtime job: $jobStatus';
  }

  String _daemonLearningTrend() {
    if (_labHistory.isEmpty) {
      return 'No daemon feedback trend exists yet.';
    }
    if (_labHistory.length == 1) {
      return 'Only one labeled outcome exists so far. The supervisor should preserve it, but not overfit to a single run.';
    }
    final latest = _labHistory[0];
    final previous = _labHistory[1];
    if (latest.disposition == previous.disposition) {
      return switch (latest.disposition) {
        ReplaySimulationLabDisposition.accepted =>
          'Recent trend: two accepted outcomes in a row. Preserve them as bounded positive evidence, but keep contradictory history visible before any governed learning review.',
        ReplaySimulationLabDisposition.denied =>
          'Recent trend: two denied outcomes in a row. The supervisor should treat this as accumulating rejection memory and keep the environment in active iteration.',
        ReplaySimulationLabDisposition.draft =>
          'Recent trend: two draft outcomes in a row. The supervisor should treat this as an unresolved experiment lane, not as stable evidence.',
      };
    }
    if (latest.disposition == ReplaySimulationLabDisposition.accepted &&
        previous.disposition == ReplaySimulationLabDisposition.denied) {
      return 'Recent trend: an accepted outcome followed a denial. Preserve both signals so the supervisor keeps the rejection memory alongside the newer positive evidence.';
    }
    if (latest.disposition == ReplaySimulationLabDisposition.denied &&
        previous.disposition == ReplaySimulationLabDisposition.accepted) {
      return 'Recent trend: accepted evidence regressed into a denial. The supervisor should prioritize the newer failure memory without erasing the earlier accepted run.';
    }
    if (latest.disposition == ReplaySimulationLabDisposition.draft) {
      return 'Recent trend: the newest run is still draft-only. The supervisor should treat the lane as exploratory until it receives a bounded acceptance or denial.';
    }
    return 'Recent trend: outcomes are mixed. Preserve the full labeled sequence instead of collapsing it into a single simplified recommendation.';
  }

  ReplaySimulationLabVariantDraft? _variantDraftForOutcome(
    ReplaySimulationLabOutcomeRecord entry,
  ) {
    final variantId = entry.variantId;
    if (variantId == null || variantId.isEmpty) {
      return null;
    }
    for (final variant in _variants) {
      if (variant.variantId == variantId) {
        return variant;
      }
    }
    return null;
  }

  String _daemonRetentionGuidance(
    ReplaySimulationLabOutcomeRecord entry,
    ReplaySimulationLabVariantDraft? variant,
  ) {
    final localityFocus = variant == null || variant.localityCodes.isEmpty
        ? null
        : variant.localityCodes.join(', ');
    switch (entry.disposition) {
      case ReplaySimulationLabDisposition.denied:
        if (localityFocus != null) {
          return 'Retain this as rejection memory for ${variant!.label}, especially around $localityFocus, before any new learning proposal.';
        }
        return 'Retain this as rejection memory for the base simulation environment and keep it visible during the next iteration.';
      case ReplaySimulationLabDisposition.accepted:
        if (entry.shareWithRealityModelAllowed) {
          return 'Retain this as bounded positive evidence only. It may support governed learning review, but contradictory denials must stay visible.';
        }
        return 'Retain this as positive local evidence only. The run is not share-ready yet, so it should not be treated as a governed learning candidate.';
      case ReplaySimulationLabDisposition.draft:
        if (localityFocus != null) {
          return 'Retain this as iteration memory for $localityFocus only. Draft outcomes should shape the next run, not act as promotion evidence.';
        }
        return 'Retain this as iteration memory only. Draft outcomes should not count as approval or denial.';
    }
  }

  Color _dispositionAccent(ReplaySimulationLabDisposition disposition) {
    return switch (disposition) {
      ReplaySimulationLabDisposition.accepted => AppColors.success,
      ReplaySimulationLabDisposition.denied => AppColors.error,
      ReplaySimulationLabDisposition.draft => AppColors.warning,
    };
  }

  List<Widget> _buildDaemonFeedbackTimelineTiles(ThemeData theme) {
    if (_labHistory.isEmpty) {
      return <Widget>[
        Text(
          'No world-simulation lab outcomes recorded yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ];
    }
    return _labHistory.take(8).map((entry) {
      final variant = _variantDraftForOutcome(entry);
      final accent = _dispositionAccent(entry.disposition);
      final focusLocalities = variant?.localityCodes ?? const <String>[];
      final notes = entry.operatorNotes.isNotEmpty
          ? entry.operatorNotes
          : (variant?.operatorNotes ?? const <String>[]);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  switch (entry.disposition) {
                    ReplaySimulationLabDisposition.accepted =>
                      Icons.check_circle_outline,
                    ReplaySimulationLabDisposition.denied =>
                      Icons.block_outlined,
                    ReplaySimulationLabDisposition.draft =>
                      Icons.edit_note_outlined,
                  },
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.variantLabel == null
                            ? '${entry.disposition.displayLabel} • ${_displayNameForEnvironmentId(entry.environmentId)}'
                            : '${entry.disposition.displayLabel} • ${entry.variantLabel}',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.recordedAt.toUtc().toIso8601String().replaceFirst('T', ' ').split('.').first} UTC',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.operatorRationale.isEmpty
                  ? 'No rationale recorded.'
                  : entry.operatorRationale,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              _daemonRetentionGuidance(entry, variant),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (variant?.hypothesis.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                'Variant hypothesis: ${variant!.hypothesis}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (focusLocalities.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Focus localities: ${focusLocalities.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${notes.join(' • ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Evidence posture: ${entry.trainingGrade} • ${entry.suggestedTrainingUse}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }).toList(growable: false);
  }

  List<Widget> _buildVariantComparisonTiles(ThemeData theme) {
    final variantById = <String?, ReplaySimulationLabVariantDraft?>{
      null: null,
      for (final variant in _variants) variant.variantId: variant,
    };
    final grouped = <String?, List<ReplaySimulationLabOutcomeRecord>>{};
    for (final entry in _labHistory) {
      final entries = grouped.putIfAbsent(
        entry.variantId,
        () => <ReplaySimulationLabOutcomeRecord>[],
      );
      entries.add(entry);
    }
    final orderedKeys = <String?>[
      null,
      ..._variants.map((entry) => entry.variantId),
    ].where((entry) => grouped.containsKey(entry) || entry != null).toList();
    if (orderedKeys.isEmpty) {
      return <Widget>[
        Text(
          'No variants or variant-linked outcomes recorded yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ];
    }
    return orderedKeys.map((variantId) {
      final entries =
          grouped[variantId] ?? const <ReplaySimulationLabOutcomeRecord>[];
      final rerunJobs = _rerunJobsForTarget(variantId);
      final variant = variantById[variantId];
      final accepted = entries
          .where(
            (entry) =>
                entry.disposition == ReplaySimulationLabDisposition.accepted,
          )
          .length;
      final denied = entries
          .where(
            (entry) =>
                entry.disposition == ReplaySimulationLabDisposition.denied,
          )
          .length;
      final drafts = entries
          .where(
            (entry) =>
                entry.disposition == ReplaySimulationLabDisposition.draft,
          )
          .length;
      final latest = entries.isEmpty ? null : entries.first;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: variantId == _selectedVariantId
                ? AppColors.primary
                : AppColors.grey300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    variant?.label ?? 'Base run',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  'A:$accepted D:$denied R:$drafts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (variantId == _selectedVariantId) ...[
              const SizedBox(height: 4),
              Text(
                'Selected as the next run target.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
            if (variant?.hypothesis.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                variant!.hypothesis,
                style: theme.textTheme.bodySmall,
              ),
            ] else if (latest?.operatorRationale.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                latest!.operatorRationale,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (variant?.localityCodes.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                'Focus localities: ${variant!.localityCodes.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (variant?.operatorNotes.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${variant!.operatorNotes.join(' • ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              latest == null
                  ? 'Latest outcome: none recorded.'
                  : 'Latest outcome: ${latest.disposition.displayLabel} on ${latest.recordedAt.toUtc().toIso8601String().split('T').first}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _variantLearningTakeaway(entries),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _variantRunTrend(entries),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _variantRuntimeExecutionSummary(rerunJobs),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _variantRuntimeExecutionTrend(rerunJobs),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }).toList(growable: false);
  }

  SignatureHealthLearningOutcomeItem? _selectedReplayLearningOutcome() {
    final snapshot = _signatureHealthSnapshot;
    final replay = _replaySnapshot;
    if (snapshot == null || replay == null) {
      return null;
    }
    for (final item in snapshot.learningOutcomeItems) {
      if (item.environmentId == replay.environmentId) {
        return item;
      }
    }
    return null;
  }

  List<SignatureHealthPropagationTarget> _preferredPropagationTargets(
    SignatureHealthLearningOutcomeItem learningOutcome,
  ) {
    final prioritizedTargets = learningOutcome.propagationTargets
        .where(
          (target) =>
              target.hierarchyDomainDeltaSummary != null ||
              target.personalAgentPersonalizationSummary != null,
        )
        .take(10)
        .toList(growable: false);
    if (prioritizedTargets.isNotEmpty) {
      return prioritizedTargets;
    }
    if (learningOutcome.propagationTargets.isEmpty) {
      return const <SignatureHealthPropagationTarget>[];
    }
    return <SignatureHealthPropagationTarget>[
      learningOutcome.propagationTargets.first,
    ];
  }

  Widget _buildPropagationTargetSummary(
    ThemeData theme,
    SignatureHealthPropagationTarget target,
  ) {
    final delta = target.hierarchyDomainDeltaSummary;
    final personalization = target.personalAgentPersonalizationSummary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(target.targetId, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          target.reason,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (delta != null) ...[
          const SizedBox(height: 4),
          Text(
            'Domain propagation delta • ${delta.domainId}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(delta.summary, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            'Bounded use: ${delta.boundedUse}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Domain delta: ${delta.jsonPath ?? 'missing'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (delta.downstreamConsumerSummary != null) ...[
            const SizedBox(height: 4),
            Text(
              'Domain consumer • ${delta.downstreamConsumerSummary!.consumerId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              delta.downstreamConsumerSummary!.summary,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Targeted systems: ${delta.downstreamConsumerSummary!.targetedSystems.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
        if (personalization != null) ...[
          const SizedBox(height: 4),
          Text(
            'Personal-agent personalization • ${personalization.domainId}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(personalization.summary, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            'Personalization mode: ${personalization.personalizationMode}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bounded use: ${personalization.boundedUse}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Personalization delta: ${personalization.jsonPath ?? 'missing'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  String _topKernelActivitySummary(Map<String, int> counts) {
    final activeEntries = counts.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    if (activeEntries.isEmpty) {
      return 'No kernel activations recorded.';
    }
    return activeEntries
        .take(3)
        .map((entry) => '${entry.key}:${entry.value}')
        .join(' • ');
  }

  String _listSummary(List<String> values, {String fallback = 'none'}) {
    if (values.isEmpty) {
      return fallback;
    }
    return values.join(' • ');
  }

  Color _severityAccent(String severity) {
    return switch (severity) {
      'critical' => AppColors.error,
      'high' => AppColors.error,
      'medium' => AppColors.warning,
      'low' => AppColors.success,
      _ => AppColors.textSecondary,
    };
  }

  List<Widget> _buildSyntheticHumanKernelExplorerTiles(ThemeData theme) {
    final explorer = _replaySnapshot?.syntheticHumanKernelExplorer;
    if (explorer == null || explorer.entries.isEmpty) {
      return <Widget>[
        Text(
          'No synthetic-human kernel coverage is recorded for this simulation yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ];
    }
    return <Widget>[
      Text(
        explorer.summary,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _metricChip('Representative lanes', '${explorer.modeledActorCount}'),
          _metricChip('Full ready bundles', '${explorer.actorsWithFullBundle}'),
          _metricChip(
            'Required kernels',
            '${explorer.requiredKernelIds.length}',
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...explorer.entries.map(
        (entry) {
          final history = _syntheticHumanKernelHistoryFor(entry);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: entry.readyKernelIds.length >=
                        explorer.requiredKernelIds.length
                    ? AppColors.success.withValues(alpha: 0.4)
                    : AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.displayName, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  entry.summary,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metricChip('Locality', entry.localityAnchor),
                    _metricChip(
                        'Attached', '${entry.attachedKernelIds.length}'),
                    _metricChip('Ready', '${entry.readyKernelIds.length}'),
                    _metricChip(
                      'Higher-agent guidance',
                      '${entry.higherAgentGuidanceCount}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Top kernel activity: ${_topKernelActivitySummary(entry.activationCountByKernel)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _kernelActivationHistorySummary(history),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kernel activation history',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  ...history.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            point.headline,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            point.summary,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Attached kernels: ${_listSummary(entry.attachedKernelIds)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready kernels: ${_listSummary(entry.readyKernelIds)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Missing required kernels: ${_listSummary(entry.missingKernelIds)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: entry.missingKernelIds.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Attached but not ready: ${_listSummary(entry.notReadyKernelIds)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: entry.notReadyKernelIds.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.warning,
                  ),
                ),
                if (entry.traceSummary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Bundle trace',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  ...entry.traceSummary.map(
                    (trace) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $trace',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildLocalityHierarchyHealthTiles(ThemeData theme) {
    final health = _replaySnapshot?.localityHierarchyHealth;
    if (health == null || health.nodes.isEmpty) {
      return <Widget>[
        Text(
          'No locality-hierarchy health view is available for this simulation yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ];
    }
    return <Widget>[
      Text(
        health.summary,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _metricChip('Stable lanes', '${health.stableLocalityCount}'),
          _metricChip('Escalating lanes', '${health.escalatingLocalityCount}'),
          if (health.strongestLocalityLabel != null)
            _metricChip('Strongest locality', health.strongestLocalityLabel!),
          if (health.stressedLocalityLabel != null)
            _metricChip('Most stressed', health.stressedLocalityLabel!),
        ],
      ),
      const SizedBox(height: 12),
      ...health.nodes.take(5).map(
        (node) {
          final history = _localityHierarchyHistoryFor(node);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _severityAccent(node.risk).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.displayName, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(node.summary, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metricChip('Pressure', node.pressureBand),
                    _metricChip('Attention', node.attentionBand),
                    _metricChip('Effectiveness', node.effectiveness),
                    _metricChip('Risk', node.risk),
                    _metricChip('Contradictions', '${node.contradictionCount}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Primary signals: ${node.primarySignals.isEmpty ? 'none recorded' : node.primarySignals.join(' • ')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _localityHierarchyHistorySummary(history),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hierarchy history',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  ...history.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            point.headline,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            point.summary,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (node.traceSummary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Hierarchy trace',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  ...node.traceSummary.map(
                    (trace) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $trace',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildHigherAgentHandoffTiles(ThemeData theme) {
    final handoffView = _replaySnapshot?.higherAgentHandoffView;
    if (handoffView == null || handoffView.items.isEmpty) {
      return <Widget>[
        Text(
          'No higher-agent handoff view is recorded yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ];
    }
    return <Widget>[
      Text(
        handoffView.summary,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 12),
      ...handoffView.items.map(
        (item) {
          final history = _higherAgentHandoffHistoryFor(item);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.targetLabel, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  item.summary,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metricChip('Scope', item.scope),
                    _metricChip('Status', item.status),
                  ],
                ),
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _higherAgentHandoffHistorySummary(history),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Handoff lineage',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  ...history.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            point.headline,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            point.summary,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (item.guidance.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...item.guidance.map(
                    (guidance) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $guidance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
                if (item.traceSummary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Trace context',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  ...item.traceSummary.map(
                    (trace) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $trace',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildWeakSpotTiles(ThemeData theme) {
    final weakSpots =
        _replaySnapshot?.weakSpots ?? const <ReplaySimulationWeakSpotSummary>[];
    if (weakSpots.isEmpty) {
      return <Widget>[
        Text(
          'No explicit simulation weak spots are recorded yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ];
    }
    return weakSpots.map((spot) {
      final accent = _severityAccent(spot.severity);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(spot.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Severity: ${spot.severity}',
              style: theme.textTheme.bodySmall?.copyWith(color: accent),
            ),
            const SizedBox(height: 8),
            Text(spot.summary, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              'Recommended action: ${spot.recommendedAction}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (spot.metadata.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Trace anchor: ${spot.metadata.entries.map((entry) => '${entry.key}=${entry.value}').join(' • ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final replay = _replaySnapshot;
    final theme = Theme.of(context);
    final learningOutcome = _selectedReplayLearningOutcome();
    final queueTargetDecision = _targetActionDecisionFor(_selectedVariantId);
    final queueSelectedAction = queueTargetDecision?.selectedAction;

    return AppFlowScaffold(
      title: 'World Simulation Lab',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pre-training simulation workbench',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Boot any registered simulation environment or city-pack simulation, compare failure modes, and record accepted or denied outcomes before any training-intake action. The supervisor daemon should learn from every labeled outcome, but only accepted outcomes may move toward learning candidacy.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            Chip(label: Text('Pre-training')),
                            Chip(label: Text('Operator-labeled outcomes')),
                            Chip(label: Text('Daemon learns from all')),
                            Chip(label: Text('Promotion still fail-closed')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Card(
                    color: AppColors.error.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Register Simulation Environment',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seed a generic simulation environment for any city or place without waiting for a hardcoded adapter. Locality entries use `code|Display Name`, one per line.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key(
                            'worldSimulationLabRegisterDisplayNameField',
                          ),
                          controller: _environmentNameController,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: const Key(
                                  'worldSimulationLabRegisterCityCodeField',
                                ),
                                controller: _environmentCityCodeController,
                                decoration: const InputDecoration(
                                  labelText: 'City code',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 160,
                              child: TextField(
                                key: const Key(
                                  'worldSimulationLabRegisterReplayYearField',
                                ),
                                controller: _environmentReplayYearController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Replay year',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _environmentDescriptionController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key(
                            'worldSimulationLabRegisterLocalitiesField',
                          ),
                          controller: _environmentLocalitiesController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Localities',
                            hintText:
                                'downtown|Downtown\nwaterfront|Waterfront District',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              key: const Key(
                                'worldSimulationLabRegisterEnvironmentButton',
                              ),
                              onPressed: _isRegisteringEnvironment
                                  ? null
                                  : _registerEnvironment,
                              icon: const Icon(Icons.add_location_alt_outlined),
                              label: Text(
                                _isRegisteringEnvironment
                                    ? 'Registering'
                                    : 'Register environment',
                              ),
                            ),
                            if (_replayEnvironments.isNotEmpty)
                              Chip(
                                label: Text(
                                  'Registered environments: ${_replayEnvironments.length}',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (replay == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No simulation environments are registered yet.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Simulation Environment',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          if (_replayEnvironments.length > 1) ...[
                            DropdownButtonFormField<String>(
                              key: const Key(
                                  'worldSimulationLabEnvironmentSelector'),
                              initialValue: _selectedReplayEnvironmentId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Simulation environment',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: _replayEnvironments.map((environment) {
                                return DropdownMenuItem<String>(
                                  value: environment.environmentId,
                                  child: Text(
                                    '${environment.displayName} (${environment.cityCode.toUpperCase()} ${environment.replayYear})',
                                  ),
                                );
                              }).toList(growable: false),
                              onChanged: _isRecording
                                  ? null
                                  : _onReplayEnvironmentSelected,
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            '${_displayNameForEnvironmentId(replay.environmentId)} is active for simulation iteration. Use this page to inspect the run, annotate operator judgment, and leave a durable lab receipt before training.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (_activeVariant != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Next run target: ${_activeVariant!.label}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ] else if (_labRuntimeState != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Next run target: Base run',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (_showWorldSimulationLabHandoff(
                              replay.environmentId)) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'World Simulation Lab handoff',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_worldSimulationLabAttentionLabel(widget.initialAttention)} for ${_displayNameForEnvironmentId(replay.environmentId)}. Restore/restage and family-intake follow-up decisions remain lab-only here; shared review surfaces only route into this context.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _metricChip(
                                  'City', replay.cityCode.toUpperCase()),
                              _metricChip(
                                  'Replay year', '${replay.replayYear}'),
                              _metricChip(
                                'Simulation mode',
                                replay.foundation.simulationMode,
                              ),
                              _metricChip(
                                'Training grade',
                                replay.learningReadiness.trainingGrade,
                              ),
                              _metricChip(
                                'Scenarios',
                                '${replay.scenarios.length}',
                              ),
                              _metricChip(
                                'Comparisons',
                                '${replay.comparisons.length}',
                              ),
                              _metricChip(
                                'Receipts',
                                '${replay.receipts.length}',
                              ),
                              _metricChip(
                                'Contradictions',
                                '${replay.contradictions.length}',
                              ),
                              _metricChip(
                                'Overlays',
                                '${replay.localityOverlays.length}',
                              ),
                              _metricChip(
                                'Request previews',
                                '${replay.learningReadiness.requestPreviews.length}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            replay.learningReadiness
                                    .shareWithRealityModelAllowed
                                ? 'This run is strong enough to share forward later, but this lab page is still for operator iteration first.'
                                : 'This run remains pre-training only. Use denial or draft labeling to teach the daemon what should not advance yet.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: replay.learningReadiness
                                      .shareWithRealityModelAllowed
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('worldSimulationLabDaemonLearningCard'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daemon Learning Snapshot',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _daemonLearningPosture(),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _daemonLearningTrend(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _metricChip(
                                'Outcomes',
                                '${_labHistory.length}',
                              ),
                              _metricChip(
                                'Accepted',
                                '${_labOutcomeCounts()[ReplaySimulationLabDisposition.accepted] ?? 0}',
                              ),
                              _metricChip(
                                'Denied',
                                '${_labOutcomeCounts()[ReplaySimulationLabDisposition.denied] ?? 0}',
                              ),
                              _metricChip(
                                'Drafts',
                                '${_labOutcomeCounts()[ReplaySimulationLabDisposition.draft] ?? 0}',
                              ),
                              _metricChip(
                                'Variants',
                                '${_variants.length}',
                              ),
                            ],
                          ),
                          if (_activeVariant != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Active variant under review: ${_activeVariant!.label}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (_latestOutcomeByDisposition(
                                  ReplaySimulationLabDisposition.denied) !=
                              null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Latest denial memory',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _latestOutcomeByDisposition(
                                ReplaySimulationLabDisposition.denied,
                              )!
                                      .operatorRationale
                                      .isEmpty
                                  ? 'No denial rationale recorded.'
                                  : _latestOutcomeByDisposition(
                                      ReplaySimulationLabDisposition.denied,
                                    )!
                                      .operatorRationale,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (_latestOutcomeByDisposition(
                                  ReplaySimulationLabDisposition.accepted) !=
                              null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Latest accepted evidence',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _latestOutcomeByDisposition(
                                ReplaySimulationLabDisposition.accepted,
                              )!
                                      .operatorRationale
                                      .isEmpty
                                  ? 'No acceptance rationale recorded.'
                                  : _latestOutcomeByDisposition(
                                      ReplaySimulationLabDisposition.accepted,
                                    )!
                                      .operatorRationale,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('worldSimulationLabKernelExplorerCard'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Synthetic Human Kernel Explorer',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._buildSyntheticHumanKernelExplorerTiles(theme),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('worldSimulationLabLocalityHierarchyCard'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Locality Hierarchy Health',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._buildLocalityHierarchyHealthTiles(theme),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('worldSimulationLabHigherAgentCard'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Higher-Agent Handoff View',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._buildHigherAgentHandoffTiles(theme),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('worldSimulationLabRealismProvenanceCard'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              final history = _realismProvenanceHistory();
                              final latestDelta =
                                  _latestRealismProvenanceDelta(history);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Realism Provenance Panel',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _metricChip(
                                        'Population model',
                                        replay.realismProvenance
                                                .populationModelKind ??
                                            'unknown',
                                      ),
                                      _metricChip(
                                        'User layer',
                                        replay.realismProvenance
                                                .modeledUserLayerKind ??
                                            'unknown',
                                      ),
                                      _metricChip(
                                        'Sidecars',
                                        '${replay.realismProvenance.sidecarRefs.length}',
                                      ),
                                      _metricChip(
                                        'Artifact families',
                                        '${replay.realismProvenance.trainingArtifactFamilies.length}',
                                      ),
                                      _metricChip(
                                        'Simulation mode',
                                        replay.realismProvenance.simulationMode,
                                      ),
                                      _metricChip(
                                        'Scenario seeds',
                                        '${replay.realismProvenance.metadata['scenarioCount'] ?? 0}',
                                      ),
                                      _metricChip(
                                        'Locality overlays',
                                        '${replay.realismProvenance.metadata['overlayCount'] ?? 0}',
                                      ),
                                    ],
                                  ),
                                  if (history.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _realismProvenanceHistorySummary(history),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (latestDelta != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        latestDelta.headline,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (latestDelta.details.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Latest provenance delta',
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        ...latestDelta.details.map(
                                          (detail) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              '• $detail',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Provenance history',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    ...history.map(
                                      (point) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              point.headline,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              point.summary,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            if (point.cityPackStructuralRef !=
                                                    null &&
                                                point.cityPackStructuralRef!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'City pack: ${point.cityPackStructuralRef}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if (point
                                                .sidecarRefs.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Sidecars: ${point.sidecarRefs.join(' • ')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if (point.trainingArtifactFamilies
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Artifact families: ${point.trainingArtifactFamilies.join(' • ')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Text(
                                    replay.realismProvenance
                                                    .cityPackStructuralRef ==
                                                null ||
                                            replay.realismProvenance
                                                .cityPackStructuralRef!.isEmpty
                                        ? 'No city-pack structural ref is attached yet.'
                                        : 'City-pack structural ref: ${replay.realismProvenance.cityPackStructuralRef}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    replay.realismProvenance
                                                    .campaignDefaultsRef ==
                                                null ||
                                            replay.realismProvenance
                                                .campaignDefaultsRef!.isEmpty
                                        ? 'No campaign defaults ref recorded.'
                                        : 'Campaign defaults: ${replay.realismProvenance.campaignDefaultsRef}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    replay.realismProvenance
                                                    .localityExpectationProfileRef ==
                                                null ||
                                            replay
                                                .realismProvenance
                                                .localityExpectationProfileRef!
                                                .isEmpty
                                        ? 'No locality expectation profile recorded.'
                                        : 'Locality expectations: ${replay.realismProvenance.localityExpectationProfileRef}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    replay.realismProvenance
                                                    .worldHealthProfileRef ==
                                                null ||
                                            replay.realismProvenance
                                                .worldHealthProfileRef!.isEmpty
                                        ? 'No world health profile recorded.'
                                        : 'World health profile: ${replay.realismProvenance.worldHealthProfileRef}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    replay.realismProvenance.sidecarRefs.isEmpty
                                        ? 'No realism sidecars recorded.'
                                        : 'Realism sidecars: ${replay.realismProvenance.sidecarRefs.join(' • ')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    replay.realismProvenance.intakeFlowRefs
                                            .isEmpty
                                        ? 'No realism intake flows recorded.'
                                        : 'Realism intake flows: ${replay.realismProvenance.intakeFlowRefs.join(' • ')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    replay.realismProvenance
                                            .trainingArtifactFamilies.isEmpty
                                        ? 'No realism artifact families recorded.'
                                        : 'Training artifact families: ${replay.realismProvenance.trainingArtifactFamilies.join(' • ')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('worldSimulationLabWeakSpotsCard'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weak Spots Before Training Summary',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._buildWeakSpotTiles(theme),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Queue Next Rerun',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Promote the current target into a concrete rerun request with lineage so the next simulation run stays anchored to prior evidence.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (queueSelectedAction != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _targetActionRoutingSummary(
                                selectedAction: queueSelectedAction,
                                acceptedSuggestion:
                                    queueTargetDecision?.acceptedSuggestion,
                                updatedAt: queueTargetDecision?.updatedAt,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _targetActionRoutingGuidance(
                                queueSelectedAction,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _targetActionDecisionReason(
                                queueTargetDecision!,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_showsBoundedReviewRouting(
                                queueSelectedAction)) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => context.go(
                                      AdminRoutePaths.realitySystemReality,
                                    ),
                                    icon: const Icon(
                                      Icons.psychology_alt_outlined,
                                    ),
                                    label: const Text('Open bounded review'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => context
                                        .go(AdminRoutePaths.commandCenter),
                                    icon: const Icon(Icons.dashboard_outlined),
                                    label: const Text('Open command center'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'Current target: ${_activeVariant?.label ?? 'Base run'}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _latestOutcomeForTarget(_selectedVariantId) == null
                                ? 'Lineage basis: no labeled outcome exists yet for this target.'
                                : 'Lineage basis: ${_latestOutcomeForTarget(_selectedVariantId)!.disposition.displayLabel} on ${_latestOutcomeForTarget(_selectedVariantId)!.recordedAt.toUtc().toIso8601String().split('T').first}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key(
                              'worldSimulationLabRerunNotesField',
                            ),
                            controller: _rerunNotesController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Rerun notes',
                              hintText:
                                  'Optional notes, one per line, describing what the next run should re-check.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            key: const Key(
                              'worldSimulationLabQueueRerunButton',
                            ),
                            onPressed:
                                _isQueueingRerun ? null : _queueRerunRequest,
                            icon: const Icon(Icons.replay_outlined),
                            label: Text(
                              _isQueueingRerun
                                  ? 'Queueing rerun'
                                  : _queueRerunButtonLabel(
                                      queueSelectedAction,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Recent rerun requests',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ..._buildRerunRequestTiles(theme),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Post-Learning Chain',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (learningOutcome == null)
                            Text(
                              _signatureHealthError == null
                                  ? 'No governed reality-model learning outcome is currently linked to this simulation environment.'
                                  : 'Governed learning-chain visibility is unavailable: $_signatureHealthError',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            )
                          else ...[
                            Text(
                              learningOutcome.summary,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Learning pathway: ${learningOutcome.learningPathway}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (learningOutcome.adminEvidenceRefreshSummary !=
                                null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Admin Evidence Refresh',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                learningOutcome
                                    .adminEvidenceRefreshSummary!.summary,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Admin evidence refresh: ${learningOutcome.adminEvidenceRefreshSummary!.jsonPath ?? 'missing'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (learningOutcome.supervisorFeedbackSummary !=
                                null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Supervisor Feedback',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                learningOutcome
                                    .supervisorFeedbackSummary!.feedbackSummary,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bounded recommendation: ${learningOutcome.supervisorFeedbackSummary!.boundedRecommendation}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (_preferredPropagationTargets(learningOutcome)
                                .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Governed propagation chain',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              ..._preferredPropagationTargets(learningOutcome)
                                  .map(
                                (target) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildPropagationTargetSummary(
                                      theme, target),
                                ),
                              ),
                              if (learningOutcome.propagationTargets.length >
                                  _preferredPropagationTargets(learningOutcome)
                                      .length)
                                Text(
                                  'Additional governed targets: ${learningOutcome.propagationTargets.length - _preferredPropagationTargets(learningOutcome).length}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Variant Scaffolding',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create lightweight simulation variants so outcomes can be compared across intervention ideas before any training-intake decision.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_variants.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              key: const Key(
                                'worldSimulationLabVariantSelector',
                              ),
                              initialValue: _selectedVariantId,
                              decoration: const InputDecoration(
                                labelText: 'Active variant',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: <DropdownMenuItem<String?>>[
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Base run'),
                                ),
                                ..._variants.map(
                                  (variant) => DropdownMenuItem<String?>(
                                    value: variant.variantId,
                                    child: Text(variant.label),
                                  ),
                                ),
                              ],
                              onChanged:
                                  (_isSavingVariant || _isUpdatingVariantTarget)
                                      ? null
                                      : _onVariantSelected,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isUpdatingVariantTarget
                                  ? 'Updating next run target...'
                                  : 'The selected variant persists as the next run target for this environment.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key(
                              'worldSimulationLabVariantLabelField',
                            ),
                            controller: _variantLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Variant label',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key(
                              'worldSimulationLabVariantHypothesisField',
                            ),
                            controller: _variantHypothesisController,
                            minLines: 2,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Hypothesis',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key(
                              'worldSimulationLabVariantLocalitiesField',
                            ),
                            controller: _variantLocalitiesController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Focus localities',
                              hintText: 'waterfront\ndowntown',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key(
                              'worldSimulationLabVariantNotesField',
                            ),
                            controller: _variantNotesController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Variant notes',
                              hintText:
                                  'Operator notes, one per line, about the intervention mix.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            key: const Key(
                              'worldSimulationLabSaveVariantButton',
                            ),
                            onPressed: _isSavingVariant ? null : _saveVariant,
                            icon: const Icon(Icons.alt_route_outlined),
                            label: Text(
                              _isSavingVariant
                                  ? 'Saving variant'
                                  : 'Save variant scaffold',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              final foundationMetadata =
                                  replay.foundation.metadata;
                              final supportedPlaceRef =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'supportedPlaceRef',
                              );
                              final refreshMode = _foundationMetadataString(
                                foundationMetadata,
                                'cityPackRefreshMode',
                              );
                              final currentBasisStatus =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'currentBasisStatus',
                              );
                              final hydrationStatus = _foundationMetadataString(
                                foundationMetadata,
                                'latestStateHydrationStatus',
                              );
                              final promotionReadiness =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStatePromotionReadiness',
                              );
                              final decisionStatus = _foundationMetadataString(
                                foundationMetadata,
                                'latestStateDecisionStatus',
                              );
                              final revalidationStatus =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRevalidationStatus',
                              );
                              final recoveryDecisionStatus =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRecoveryDecisionStatus',
                              );
                              final freshnessPosture =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'hydrationFreshnessPosture',
                              );
                              final refreshCadenceHours =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRefreshCadenceHours',
                              );
                              final refreshCadenceStatus =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRefreshCadenceStatus',
                              );
                              final refreshReferenceAt =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRefreshReferenceAt',
                              );
                              final refreshExecutionStatus =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRefreshExecutionStatus',
                              );
                              final refreshExecutionReceiptRef =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRefreshExecutionReceiptRef',
                              );
                              final refreshExecutionCheckedAt =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRefreshExecutionCheckedAt',
                              );
                              final hydrationEvidenceFamilies =
                                  _foundationMetadataStringList(
                                foundationMetadata,
                                'hydrationEvidenceFamilies',
                              );
                              final latestStateEvidenceRefs =
                                  _foundationMetadataStringList(
                                foundationMetadata,
                                'latestStateEvidenceRefs',
                              );
                              final latestStateEvidenceSelectionSummaries =
                                  _foundationMetadataStringList(
                                foundationMetadata,
                                'latestStateEvidenceSelectionSummaries',
                              );
                              final latestStateEvidenceAgingSummaries =
                                  _foundationMetadataStringList(
                                foundationMetadata,
                                'latestStateEvidenceAgingSummaries',
                              );
                              final latestStateEvidenceAgingTrendSummaries =
                                  _foundationMetadataStringList(
                                foundationMetadata,
                                'latestStateEvidenceAgingTrendSummaries',
                              );
                              final latestStateEvidencePolicyActionSummaries =
                                  _foundationMetadataStringList(
                                foundationMetadata,
                                'latestStateEvidencePolicyActionSummaries',
                              );
                              final latestStateEvidenceRestageTargetSummaries =
                                  _foundationMetadataStringList(
                                foundationMetadata,
                                'latestStateEvidenceRestageTargetSummaries',
                              );
                              final latestStateRefreshPolicySummaries =
                                  _foundationMetadataStringList(
                                foundationMetadata,
                                'latestStateRefreshPolicySummaries',
                              );
                              final promotionBlockedReasons =
                                  _foundationMetadataStringList(
                                foundationMetadata,
                                'latestStatePromotionBlockedReasons',
                              );
                              final refreshReceiptRef =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRefreshReceiptRef',
                              );
                              final revalidationReceiptRef =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRevalidationReceiptRef',
                              );
                              final decisionArtifactRef =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateDecisionArtifactRef',
                              );
                              final revalidationArtifactRef =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRevalidationArtifactRef',
                              );
                              final recoveryDecisionArtifactRef =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRecoveryDecisionArtifactRef',
                              );
                              final decisionRationale =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateDecisionRationale',
                              );
                              final recoveryDecisionRationale =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'latestStateRecoveryDecisionRationale',
                              );
                              final servedBasisRef = _foundationMetadataString(
                                foundationMetadata,
                                'servedBasisRef',
                              );
                              final priorServedBasisRef =
                                  _foundationMetadataString(
                                foundationMetadata,
                                'priorServedBasisRef',
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Simulation Basis',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    replay.foundation.intakeFlowRefs.isEmpty
                                        ? 'No intake-flow refs attached to this run.'
                                        : 'Intake flows: ${replay.foundation.intakeFlowRefs.join(', ')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if ((replay.foundation
                                              .metadata['cityPackStructuralRef']
                                              ?.toString()
                                              .trim() ??
                                          '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'City-pack structural ref: ${replay.foundation.metadata['cityPackStructuralRef']}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (supportedPlaceRef != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Supported place: $supportedPlaceRef',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (refreshMode != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Refresh mode: ${_livingCityPackMetadataLabel(refreshMode)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (currentBasisStatus != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Current basis: ${_livingCityPackMetadataLabel(currentBasisStatus)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (hydrationStatus != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hydration status: ${_livingCityPackMetadataLabel(hydrationStatus)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (promotionReadiness != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Promotion readiness: ${_livingCityPackMetadataLabel(promotionReadiness)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (decisionStatus != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Decision status: ${_livingCityPackMetadataLabel(decisionStatus)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (revalidationStatus != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Revalidation status: ${_livingCityPackMetadataLabel(revalidationStatus)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (recoveryDecisionStatus != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Recovery decision: ${_livingCityPackMetadataLabel(recoveryDecisionStatus)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (hydrationEvidenceFamilies.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Latest-state evidence families: ${hydrationEvidenceFamilies.map(_hydrateEvidenceFamilyLabel).join(' • ')}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (latestStateEvidenceSelectionSummaries
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Evidence selection: ${latestStateEvidenceSelectionSummaries.join(' • ')}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (latestStateEvidenceAgingSummaries
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Evidence aging: ${latestStateEvidenceAgingSummaries.join(' • ')}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (latestStateEvidenceAgingTrendSummaries
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Evidence aging trend: ${latestStateEvidenceAgingTrendSummaries.join(' • ')}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (latestStateEvidencePolicyActionSummaries
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Evidence policy action: ${latestStateEvidencePolicyActionSummaries.join(' • ')}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (latestStateEvidenceRestageTargetSummaries
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Evidence restage target: ${latestStateEvidenceRestageTargetSummaries.join(' • ')}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (_familyRestageReviewItems.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Family restage review lane: ${_familyRestageReviewItems.length} queued item${_familyRestageReviewItems.length == 1 ? '' : 's'}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    for (final item
                                        in _familyRestageReviewItems.take(3))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_hydrateEvidenceFamilyLabel(item.evidenceFamily)}: ${item.restageTargetSummary}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Restage review status: ${_livingCityPackMetadataLabel(item.queueStatus)}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Queue artifact: ${item.itemJsonPath}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            if ((item.queueDecisionArtifactRef ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Queue decision artifact: ${item.queueDecisionArtifactRef}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.queueDecisionRationale ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Queue decision rationale: ${item.queueDecisionRationale}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageIntakeQueueJsonPath ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Restage intake queue artifact: ${item.restageIntakeQueueJsonPath}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageIntakeReviewItemId ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Restage intake review item: ${item.restageIntakeReviewItemId}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageIntakeResolutionStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Restage intake resolution: ${_livingCityPackMetadataLabel(item.restageIntakeResolutionStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageIntakeResolutionArtifactRef ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Restage intake resolution artifact: ${item.restageIntakeResolutionArtifactRef}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageIntakeResolutionRationale ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Restage intake resolution rationale: ${item.restageIntakeResolutionRationale}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.followUpQueueStatus ?? '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family follow-up queue: ${_livingCityPackMetadataLabel(item.followUpQueueStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.followUpQueueJsonPath ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family follow-up queue artifact: ${item.followUpQueueJsonPath}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.followUpReviewItemId ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family follow-up review item: ${item.followUpReviewItemId}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.followUpResolutionStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family follow-up resolution: ${_livingCityPackMetadataLabel(item.followUpResolutionStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.followUpResolutionArtifactRef ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family follow-up resolution artifact: ${item.followUpResolutionArtifactRef}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.followUpResolutionRationale ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family follow-up resolution rationale: ${item.followUpResolutionRationale}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageResolutionQueueStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family resolution queue: ${_livingCityPackMetadataLabel(item.restageResolutionQueueStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageResolutionQueueJsonPath ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family resolution queue artifact: ${item.restageResolutionQueueJsonPath}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageResolutionReviewItemId ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family resolution review item: ${item.restageResolutionReviewItemId}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageResolutionResolutionStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family resolution outcome: ${_livingCityPackMetadataLabel(item.restageResolutionResolutionStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageResolutionResolutionArtifactRef ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family resolution outcome artifact: ${item.restageResolutionResolutionArtifactRef}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageResolutionResolutionRationale ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family resolution outcome rationale: ${item.restageResolutionResolutionRationale}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageExecutionQueueStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family execution queue: ${_livingCityPackMetadataLabel(item.restageExecutionQueueStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageExecutionQueueJsonPath ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family execution queue artifact: ${item.restageExecutionQueueJsonPath}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageExecutionReviewItemId ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family execution review item: ${item.restageExecutionReviewItemId}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageExecutionResolutionStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family execution outcome: ${_livingCityPackMetadataLabel(item.restageExecutionResolutionStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageExecutionResolutionArtifactRef ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family execution outcome artifact: ${item.restageExecutionResolutionArtifactRef}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageExecutionResolutionRationale ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family execution outcome rationale: ${item.restageExecutionResolutionRationale}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplicationQueueStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family application queue: ${_livingCityPackMetadataLabel(item.restageApplicationQueueStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplicationQueueJsonPath ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family application queue artifact: ${item.restageApplicationQueueJsonPath}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplicationReviewItemId ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family application review item: ${item.restageApplicationReviewItemId}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplicationResolutionStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family application outcome: ${_livingCityPackMetadataLabel(item.restageApplicationResolutionStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplicationResolutionArtifactRef ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family application outcome artifact: ${item.restageApplicationResolutionArtifactRef}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplicationResolutionRationale ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family application outcome rationale: ${item.restageApplicationResolutionRationale}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplyQueueStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family apply queue: ${_livingCityPackMetadataLabel(item.restageApplyQueueStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplyQueueJsonPath ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family apply queue artifact: ${item.restageApplyQueueJsonPath}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplyReviewItemId ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family apply review item: ${item.restageApplyReviewItemId}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplyResolutionStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family apply outcome: ${_livingCityPackMetadataLabel(item.restageApplyResolutionStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplyResolutionArtifactRef ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family apply outcome artifact: ${item.restageApplyResolutionArtifactRef}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageApplyResolutionRationale ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family apply outcome rationale: ${item.restageApplyResolutionRationale}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageServedBasisUpdateQueueStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family served-basis update queue: ${_livingCityPackMetadataLabel(item.restageServedBasisUpdateQueueStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageServedBasisUpdateQueueJsonPath ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family served-basis update queue artifact: ${item.restageServedBasisUpdateQueueJsonPath}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageServedBasisUpdateReviewItemId ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family served-basis update review item: ${item.restageServedBasisUpdateReviewItemId}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageServedBasisUpdateResolutionStatus ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family served-basis update outcome: ${_livingCityPackMetadataLabel(item.restageServedBasisUpdateResolutionStatus ?? '')}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageServedBasisUpdateResolutionArtifactRef ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family served-basis update outcome artifact: ${item.restageServedBasisUpdateResolutionArtifactRef}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            if ((item.restageServedBasisUpdateResolutionRationale ??
                                                    '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Family served-basis update outcome rationale: ${item.restageServedBasisUpdateResolutionRationale}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                OutlinedButton(
                                                  key: Key(
                                                    'worldSimulationLabRequestFamilyRestageIntakeButton_${item.evidenceFamily}',
                                                  ),
                                                  onPressed:
                                                      _updatingFamilyRestageReviewItemId ==
                                                              item.itemId
                                                          ? null
                                                          : () =>
                                                              _requestFamilyRestageIntakeReview(
                                                                item,
                                                              ),
                                                  child: Text(
                                                    _updatingFamilyRestageReviewItemId ==
                                                            item.itemId
                                                        ? 'Applying...'
                                                        : 'Request restage intake',
                                                  ),
                                                ),
                                                OutlinedButton(
                                                  key: Key(
                                                    'worldSimulationLabDeferFamilyRestageReviewButton_${item.evidenceFamily}',
                                                  ),
                                                  onPressed:
                                                      _updatingFamilyRestageReviewItemId ==
                                                              item.itemId
                                                          ? null
                                                          : () =>
                                                              _deferFamilyRestageReview(
                                                                item,
                                                              ),
                                                  child: const Text(
                                                    'Defer to watch',
                                                  ),
                                                ),
                                                if (item.queueStatus ==
                                                        'restage_intake_requested' &&
                                                    (item.restageIntakeReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabApproveFamilyRestageIntakeReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageIntakeReview(
                                                                  item,
                                                                  approve: true,
                                                                ),
                                                    child: Text(
                                                      _updatingFamilyRestageReviewItemId ==
                                                              item.itemId
                                                          ? 'Applying...'
                                                          : 'Approve intake review',
                                                    ),
                                                  ),
                                                if (item.queueStatus ==
                                                        'restage_intake_requested' &&
                                                    (item.restageIntakeReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabHoldFamilyRestageIntakeReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageIntakeReview(
                                                                  item,
                                                                  approve:
                                                                      false,
                                                                ),
                                                    child: const Text(
                                                      'Hold intake review',
                                                    ),
                                                  ),
                                                if ((item.followUpQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_follow_up_review' &&
                                                    (item.followUpReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabApproveFamilyRestageFollowUpReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageFollowUpReview(
                                                                  item,
                                                                  approve: true,
                                                                ),
                                                    child: Text(
                                                      _updatingFamilyRestageReviewItemId ==
                                                              item.itemId
                                                          ? 'Applying...'
                                                          : 'Approve follow-up review',
                                                    ),
                                                  ),
                                                if ((item.followUpQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_follow_up_review' &&
                                                    (item.followUpReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabHoldFamilyRestageFollowUpReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageFollowUpReview(
                                                                  item,
                                                                  approve:
                                                                      false,
                                                                ),
                                                    child: const Text(
                                                      'Hold follow-up review',
                                                    ),
                                                  ),
                                                if ((item.restageResolutionQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_resolution_review' &&
                                                    (item.restageResolutionReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabApproveFamilyRestageResolutionReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageResolutionReview(
                                                                  item,
                                                                  approve: true,
                                                                ),
                                                    child: Text(
                                                      _updatingFamilyRestageReviewItemId ==
                                                              item.itemId
                                                          ? 'Applying...'
                                                          : 'Approve resolution review',
                                                    ),
                                                  ),
                                                if ((item.restageResolutionQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_resolution_review' &&
                                                    (item.restageResolutionReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabHoldFamilyRestageResolutionReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageResolutionReview(
                                                                  item,
                                                                  approve:
                                                                      false,
                                                                ),
                                                    child: const Text(
                                                      'Hold resolution review',
                                                    ),
                                                  ),
                                                if ((item.restageExecutionQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_execution_review' &&
                                                    (item.restageExecutionReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabApproveFamilyRestageExecutionReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageExecutionReview(
                                                                  item,
                                                                  approve: true,
                                                                ),
                                                    child: Text(
                                                      _updatingFamilyRestageReviewItemId ==
                                                              item.itemId
                                                          ? 'Applying...'
                                                          : 'Approve execution review',
                                                    ),
                                                  ),
                                                if ((item.restageExecutionQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_execution_review' &&
                                                    (item.restageExecutionReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabHoldFamilyRestageExecutionReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageExecutionReview(
                                                                  item,
                                                                  approve:
                                                                      false,
                                                                ),
                                                    child: const Text(
                                                      'Hold execution review',
                                                    ),
                                                  ),
                                                if ((item.restageApplicationQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_application_review' &&
                                                    (item.restageApplicationReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabApproveFamilyRestageApplicationReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageApplicationReview(
                                                                  item,
                                                                  approve: true,
                                                                ),
                                                    child: Text(
                                                      _updatingFamilyRestageReviewItemId ==
                                                              item.itemId
                                                          ? 'Applying...'
                                                          : 'Approve application review',
                                                    ),
                                                  ),
                                                if ((item.restageApplicationQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_application_review' &&
                                                    (item.restageApplicationReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabHoldFamilyRestageApplicationReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageApplicationReview(
                                                                  item,
                                                                  approve:
                                                                      false,
                                                                ),
                                                    child: const Text(
                                                      'Hold application review',
                                                    ),
                                                  ),
                                                if ((item.restageApplyQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_apply_review' &&
                                                    (item.restageApplyReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabApproveFamilyRestageApplyReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageApplyReview(
                                                                  item,
                                                                  approve: true,
                                                                ),
                                                    child: Text(
                                                      _updatingFamilyRestageReviewItemId ==
                                                              item.itemId
                                                          ? 'Applying...'
                                                          : 'Approve apply review',
                                                    ),
                                                  ),
                                                if ((item.restageApplyQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_apply_review' &&
                                                    (item.restageApplyReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabHoldFamilyRestageApplyReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageApplyReview(
                                                                  item,
                                                                  approve:
                                                                      false,
                                                                ),
                                                    child: const Text(
                                                      'Hold apply review',
                                                    ),
                                                  ),
                                                if ((item.restageServedBasisUpdateQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_served_basis_update_review' &&
                                                    (item.restageServedBasisUpdateReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabApproveFamilyRestageServedBasisUpdateReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageServedBasisUpdateReview(
                                                                  item,
                                                                  approve: true,
                                                                ),
                                                    child: Text(
                                                      _updatingFamilyRestageReviewItemId ==
                                                              item.itemId
                                                          ? 'Applying...'
                                                          : 'Approve served-basis update review',
                                                    ),
                                                  ),
                                                if ((item.restageServedBasisUpdateQueueStatus ??
                                                            '') ==
                                                        'queued_for_family_restage_served_basis_update_review' &&
                                                    (item.restageServedBasisUpdateReviewItemId ??
                                                            '')
                                                        .isNotEmpty)
                                                  OutlinedButton(
                                                    key: Key(
                                                      'worldSimulationLabHoldFamilyRestageServedBasisUpdateReviewButton_${item.evidenceFamily}',
                                                    ),
                                                    onPressed:
                                                        _updatingFamilyRestageReviewItemId ==
                                                                item.itemId
                                                            ? null
                                                            : () =>
                                                                _resolveFamilyRestageServedBasisUpdateReview(
                                                                  item,
                                                                  approve:
                                                                      false,
                                                                ),
                                                    child: const Text(
                                                      'Hold served-basis update review',
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  if (latestStateRefreshPolicySummaries
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Refresh policy: ${latestStateRefreshPolicySummaries.join(' • ')}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (freshnessPosture != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Freshness posture: ${_livingCityPackMetadataLabel(freshnessPosture)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (refreshCadenceHours != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Refresh cadence: ${refreshCadenceHours}h',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (refreshCadenceStatus != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Refresh cadence status: ${_livingCityPackMetadataLabel(refreshCadenceStatus)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (refreshReferenceAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Refresh reference: $refreshReferenceAt',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (refreshExecutionStatus != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Refresh execution: ${_livingCityPackMetadataLabel(refreshExecutionStatus)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (refreshExecutionCheckedAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Refresh execution checked at: $refreshExecutionCheckedAt',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (refreshExecutionReceiptRef != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Refresh execution receipt artifact: $refreshExecutionReceiptRef',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (refreshReceiptRef != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Refresh receipt artifact: $refreshReceiptRef',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (revalidationReceiptRef != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Revalidation receipt artifact: $revalidationReceiptRef',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (promotionBlockedReasons.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Promotion blockers: ${promotionBlockedReasons.join(' • ')}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (decisionArtifactRef != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Decision artifact: $decisionArtifactRef',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (revalidationArtifactRef != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Revalidation artifact: $revalidationArtifactRef',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (recoveryDecisionArtifactRef != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Recovery decision artifact: $recoveryDecisionArtifactRef',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (decisionRationale != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Decision rationale: $decisionRationale',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (recoveryDecisionRationale != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Recovery rationale: $recoveryDecisionRationale',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (servedBasisRef != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Served basis artifact: $servedBasisRef',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    key: const Key(
                                      'worldSimulationLabRefreshLatestStateEvidenceButton',
                                    ),
                                    onPressed: _isRefreshingLatestStateEvidence
                                        ? null
                                        : _refreshLatestStateEvidence,
                                    child: Text(
                                      _isRefreshingLatestStateEvidence
                                          ? 'Refreshing latest-state evidence...'
                                          : 'Refresh latest-state evidence',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    key: const Key(
                                      'worldSimulationLabRunRefreshCadenceCheckButton',
                                    ),
                                    onPressed: _isRunningRefreshCadenceCheck
                                        ? null
                                        : _runRefreshCadenceCheck,
                                    child: Text(
                                      _isRunningRefreshCadenceCheck
                                          ? 'Running refresh cadence check...'
                                          : 'Run refresh cadence check',
                                    ),
                                  ),
                                  if (currentBasisStatus ==
                                      'staged_latest_state_basis') ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton(
                                          key: const Key(
                                            'worldSimulationLabRejectBasisButton',
                                          ),
                                          onPressed: _isUpdatingBasisDecision
                                              ? null
                                              : () => _applyBasisDecision(
                                                    promote: false,
                                                  ),
                                          child: const Text(
                                            'Reject staged basis',
                                          ),
                                        ),
                                        FilledButton(
                                          key: const Key(
                                            'worldSimulationLabPromoteBasisButton',
                                          ),
                                          onPressed: _isUpdatingBasisDecision ||
                                                  promotionReadiness !=
                                                      'ready_for_bounded_basis_review'
                                              ? null
                                              : () => _applyBasisDecision(
                                                    promote: true,
                                                  ),
                                          child: Text(
                                            _isUpdatingBasisDecision
                                                ? 'Applying...'
                                                : 'Promote served basis',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (currentBasisStatus ==
                                          'latest_state_served_basis' ||
                                      currentBasisStatus ==
                                          'expired_latest_state_served_basis') ...[
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      key: const Key(
                                        'worldSimulationLabRevalidateBasisButton',
                                      ),
                                      onPressed: _isRevalidatingBasis
                                          ? null
                                          : _revalidateServedBasis,
                                      child: Text(
                                        _isRevalidatingBasis
                                            ? 'Revalidating...'
                                            : 'Revalidate served basis',
                                      ),
                                    ),
                                  ],
                                  if (currentBasisStatus ==
                                      'expired_latest_state_served_basis') ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        OutlinedButton(
                                          key: const Key(
                                            'worldSimulationLabRequireRestageButton',
                                          ),
                                          onPressed:
                                              _isApplyingBasisRecoveryDecision
                                                  ? null
                                                  : () =>
                                                      _applyBasisRecoveryDecision(
                                                        restore: false,
                                                      ),
                                          child: const Text(
                                            'Require restage',
                                          ),
                                        ),
                                        FilledButton(
                                          key: const Key(
                                            'worldSimulationLabRestoreBasisButton',
                                          ),
                                          onPressed:
                                              _isApplyingBasisRecoveryDecision ||
                                                      promotionReadiness !=
                                                          'ready_for_bounded_served_basis_restore'
                                                  ? null
                                                  : () =>
                                                      _applyBasisRecoveryDecision(
                                                        restore: true,
                                                      ),
                                          child: Text(
                                            _isApplyingBasisRecoveryDecision
                                                ? 'Applying...'
                                                : 'Restore served basis',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (priorServedBasisRef != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Prior served basis: $priorServedBasisRef',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (latestStateEvidenceRefs.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Latest-state evidence refs: ${latestStateEvidenceRefs.join(' • ')}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    replay.foundation.sidecarRefs.isEmpty
                                        ? 'No sidecar refs recorded.'
                                        : 'Sidecars: ${replay.foundation.sidecarRefs.join(' • ')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (replay
                                      .learningReadiness.reasons.isNotEmpty)
                                    ...replay.learningReadiness.reasons
                                        .take(4)
                                        .map(
                                          (reason) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              '• $reason',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                ],
                              );
                            },
                          ),
                          if (replay.scenarios.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Scenario seeds',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            ...replay.scenarios.take(3).map(
                                  (scenario) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          scenario.name,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          scenario.description,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Lab Outcome',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accepted and denied outcomes are both supervisor-daemon learning inputs. Denied outcomes remain labeled rejection evidence and do not become training candidates.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('worldSimulationLabRationaleField'),
                            controller: _rationaleController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Operator rationale',
                              hintText:
                                  'Why is this run acceptable, draft-only, or denied?',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('worldSimulationLabNotesField'),
                            controller: _notesController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Operator notes',
                              hintText:
                                  'Optional notes, one per line, for future reruns or daemon feedback.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                key: const Key('worldSimulationLabDraftButton'),
                                onPressed: _isRecording
                                    ? null
                                    : () => _recordOutcome(
                                          ReplaySimulationLabDisposition.draft,
                                        ),
                                icon: const Icon(Icons.edit_note_outlined),
                                label: Text(
                                  _isRecording ? 'Recording' : 'Record draft',
                                ),
                              ),
                              OutlinedButton.icon(
                                key:
                                    const Key('worldSimulationLabDeniedButton'),
                                onPressed: _isRecording
                                    ? null
                                    : () => _recordOutcome(
                                          ReplaySimulationLabDisposition.denied,
                                        ),
                                icon: const Icon(Icons.block_outlined),
                                label: const Text('Record denied'),
                              ),
                              ElevatedButton.icon(
                                key: const Key(
                                    'worldSimulationLabAcceptedButton'),
                                onPressed: _isRecording
                                    ? null
                                    : () => _recordOutcome(
                                          ReplaySimulationLabDisposition
                                              .accepted,
                                        ),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Accept for learning'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _isRecording ? null : _load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh simulation'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => context
                                    .go(AdminRoutePaths.realitySystemReality),
                                icon: const Icon(Icons.psychology_alt_outlined),
                                label: const Text('Reality oversight'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_lastRecordedOutcome != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latest Lab Receipt',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_lastRecordedOutcome!.disposition.displayLabel} • ${_lastRecordedOutcome!.recordedAt.toUtc().toIso8601String()}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (_lastRecordedOutcome!.variantLabel != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Variant: ${_lastRecordedOutcome!.variantLabel}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              _lastRecordedOutcome!.operatorRationale.isEmpty
                                  ? 'No rationale recorded.'
                                  : _lastRecordedOutcome!.operatorRationale,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lab root: ${_lastRecordedOutcome!.labRoot}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Variant Comparison',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ..._buildVariantComparisonTiles(theme),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('worldSimulationLabExecutedRerunsCard'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Executed Rerun Timeline',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Inspect the recent executed rerun history for each base run or variant, including real runtime deltas over time instead of only labeled operator outcomes.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_availableExecutedRerunTimelineFocusValues()
                                  .length >
                              1) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              key: const Key(
                                'worldSimulationLabExecutedRerunsFilter',
                              ),
                              initialValue: _executedRerunTimelineFocus,
                              decoration: const InputDecoration(
                                labelText: 'Focus target',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items:
                                  _availableExecutedRerunTimelineFocusValues()
                                      .map(
                                        (value) => DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            _executedRerunTimelineFocusLabel(
                                                value),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _executedRerunTimelineFocus = value;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _executedRerunTimelineFocusSummary(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          ..._buildExecutedRerunTimelineTiles(theme),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('worldSimulationLabDaemonFeedbackCard'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daemon Feedback Timeline',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Newest first. This is the supervisor-facing memory chain the daemon should retain across accepted, denied, and draft runs.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._buildDaemonFeedbackTimelineTiles(theme),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: AppColors.grey100,
    );
  }
}
