import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/services/debug/proof_run_automation_service.dart';
import 'package:avrai_runtime_os/services/ledgers/proof_run_service_v0.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_provisioning_state_service.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/ai_command_processor.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/widgets/debug/event_planning_telemetry_debug_card.dart';

class ProofRunPage extends StatefulWidget {
  const ProofRunPage({super.key});

  @override
  State<ProofRunPage> createState() => _ProofRunPageState();
}

class _ProofRunPageState extends State<ProofRunPage> {
  static const String _logName = 'ProofRunPage';

  late final ProofRunServiceV0 _proof;
  late final ProofRunAutomationService _automationService;
  late final LocalLlmProvisioningStateService _provisioning;

  String? _activeRunId;
  int _activeStartedAtMs = 0;
  String? _exportDir;
  String? _error;

  LocalLlmProvisioningState? _provState;
  Timer? _provTimer;

  final _chatController = TextEditingController();
  bool _isChatBusy = false;
  String? _lastChatPrompt;
  String? _lastChatResponse;

  bool _isSimulatingAi2Ai = false;
  bool _isRunningSimulatedSmoke = false;
  List<String> _simulatedNodeIds = const [];
  String? _lastSimulatedSmokeSummary;
  bool _isStartingEventPlanningSmoke = false;
  bool _isFinishingEventPlanningSmoke = false;
  final Set<EventPlanningBetaSmokeMilestone>
      _completedEventPlanningMilestones =
      <EventPlanningBetaSmokeMilestone>{};

  @override
  void initState() {
    super.initState();

    if (!kDebugMode) {
      // Should be unreachable due to route gating, but keep safe.
      _error = 'Proof run tooling is debug-only.';
      return;
    }

    final sl = GetIt.instance;
    _proof = sl<ProofRunServiceV0>();
    _automationService = sl<ProofRunAutomationService>();
    _provisioning = LocalLlmProvisioningStateService();

    _refreshActiveRun();
    _startProvisioningPoller();
  }

  @override
  void dispose() {
    _provTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  void _startProvisioningPoller() {
    _provTimer?.cancel();
    _provTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final s = await _provisioning.getState();
        if (!mounted) return;
        setState(() => _provState = s);
      } catch (_) {
        // Ignore.
      }
    });
  }

  void _refreshActiveRun() {
    setState(() {
      _activeRunId = _proof.getActiveRunId();
      _activeStartedAtMs = _proof.getActiveRunStartedAtMs();
    });
  }

  String? _currentUserIdOrNull() {
    final authState = context.read<AuthBloc>().state;
    return authState is Authenticated ? authState.user.id : null;
  }

  Future<void> _startRun() async {
    setState(() => _error = null);
    try {
      final runId = await _proof.startRun(payload: <String, Object?>{
        'platform': 'ios_simulator_or_debug',
      });
      if (!mounted) return;
      setState(() {
        _activeRunId = runId;
        _activeStartedAtMs = _proof.getActiveRunStartedAtMs();
      });
    } catch (e, st) {
      developer.log('Start run failed',
          name: _logName, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _markMilestone(String eventType,
      {Map<String, Object?> payload = const {}}) async {
    final runId = _activeRunId;
    if (runId == null || runId.isEmpty) {
      setState(() => _error = 'Start a proof run first.');
      return;
    }
    setState(() => _error = null);
    try {
      await _proof.recordMilestone(
        runId: runId,
        eventType: eventType,
        payload: payload,
      );
    } catch (e, st) {
      developer.log('Milestone failed',
          name: _logName, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _finishRun() async {
    setState(() => _error = null);
    try {
      await _proof.finishActiveRun(payload: <String, Object?>{
        'notes': 'Finished via ProofRunPage',
      });
      if (!mounted) return;
      _refreshActiveRun();
    } catch (e, st) {
      developer.log('Finish run failed',
          name: _logName, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _exportRun() async {
    final runId = _activeRunId;
    if (runId == null || runId.isEmpty) {
      setState(() => _error = 'Start a proof run first.');
      return;
    }
    setState(() {
      _error = null;
      _exportDir = null;
    });
    try {
      final dir = await _proof.exportRunReceipts(runId: runId);
      if (!mounted) return;
      setState(() => _exportDir = dir.path);
    } catch (e, st) {
      developer.log('Export failed', name: _logName, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _sendAiChat() async {
    final runId = _activeRunId;
    if (runId == null || runId.isEmpty) {
      setState(() => _error = 'Start a proof run first.');
      return;
    }

    final prompt = _chatController.text.trim();
    if (prompt.isEmpty) return;

    final userId = _currentUserIdOrNull();
    if (userId == null || userId.isEmpty) {
      setState(() => _error = 'Not authenticated; AI chat requires auth.');
      return;
    }

    setState(() {
      _error = null;
      _isChatBusy = true;
      _lastChatPrompt = prompt;
      _lastChatResponse = null;
    });

    try {
      final response = await AICommandProcessor.processCommand(
        prompt,
        context,
        userId: userId,
      );

      if (!mounted) return;
      setState(() {
        _isChatBusy = false;
        _lastChatResponse = response;
      });

      await _markMilestone(
        'proof_ai_chat_completed',
        payload: <String, Object?>{
          'prompt_len': prompt.length,
          'response_len': response.length,
        },
      );
    } catch (e, st) {
      developer.log('AI chat failed', name: _logName, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isChatBusy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _simulateAi2AiEncounter() async {
    final runId = _activeRunId;
    if (runId == null || runId.isEmpty) {
      setState(() => _error = 'Start a proof run first.');
      return;
    }

    setState(() {
      _error = null;
      _isSimulatingAi2Ai = true;
      _simulatedNodeIds = const [];
    });

    try {
      final ids = await _automationService.simulateAi2AiEncounter(
        runId: runId,
        userId: _currentUserIdOrNull(),
        scenarioName: 'proof_run_manual_encounter',
      );

      if (!mounted) return;
      setState(() {
        _isSimulatingAi2Ai = false;
        _simulatedNodeIds = ids;
      });
    } catch (e, st) {
      developer.log('AI2AI simulation failed',
          name: _logName, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isSimulatingAi2Ai = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _runSimulatedSmoke() async {
    setState(() {
      _error = null;
      _exportDir = null;
      _isRunningSimulatedSmoke = true;
      _lastSimulatedSmokeSummary = null;
    });

    try {
      final result = await _automationService.runSimulatedHeadlessSmoke(
        SimulatedHeadlessSmokeRequest(
          platformMode: 'debug_ui',
          userId: _currentUserIdOrNull(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _isRunningSimulatedSmoke = false;
        _exportDir = result.exportDirectoryPath.isEmpty
            ? null
            : result.exportDirectoryPath;
        _simulatedNodeIds = result.simulatedNodeIds;
        _lastSimulatedSmokeSummary = [
          'run_id=${result.runId}',
          'wake_runs=${result.backgroundWakeRunCount}',
          'proofs=${result.fieldValidationProofCount}',
          'ambient_candidate=${result.ambientCandidateCount}',
          'ambient_confirmed=${result.ambientConfirmedCount}',
        ].join(' | ');
      });
      _refreshActiveRun();
      if (!result.success && result.failureSummary != null) {
        setState(() => _error = result.failureSummary);
      }
    } catch (e, st) {
      developer.log('Simulated smoke failed',
          name: _logName, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isRunningSimulatedSmoke = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _startEventPlanningSmoke() async {
    setState(() {
      _error = null;
      _exportDir = null;
      _isStartingEventPlanningSmoke = true;
      _completedEventPlanningMilestones.clear();
    });

    try {
      final String runId = await _automationService.startEventPlanningBetaSmoke(
        platformMode: 'ios',
        userId: _currentUserIdOrNull(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _activeRunId = runId;
        _activeStartedAtMs = _proof.getActiveRunStartedAtMs();
        _isStartingEventPlanningSmoke = false;
      });
    } catch (e, st) {
      developer.log('Event planning smoke start failed',
          name: _logName, error: e, stackTrace: st);
      if (!mounted) {
        return;
      }
      setState(() {
        _isStartingEventPlanningSmoke = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _recordEventPlanningSmokeMilestone(
    EventPlanningBetaSmokeMilestone milestone,
  ) async {
    final String? runId = _activeRunId;
    if (runId == null || runId.isEmpty) {
      setState(() => _error = 'Start an event-planning smoke run first.');
      return;
    }

    setState(() => _error = null);
    try {
      await _automationService.recordEventPlanningBetaSmokeMilestone(
        runId: runId,
        milestone: milestone,
        platformMode: 'ios',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _completedEventPlanningMilestones.add(milestone);
      });
    } catch (e, st) {
      developer.log('Event planning smoke milestone failed',
          name: _logName, error: e, stackTrace: st);
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    }
  }

  Future<void> _finishEventPlanningSmoke() async {
    final String? runId = _activeRunId;
    if (runId == null || runId.isEmpty) {
      setState(() => _error = 'Start an event-planning smoke run first.');
      return;
    }

    setState(() {
      _error = null;
      _isFinishingEventPlanningSmoke = true;
    });

    try {
      final String exportDir =
          await _automationService.finishAndExportEventPlanningBetaSmoke(
        runId: runId,
        platformMode: 'ios',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _exportDir = exportDir;
        _isFinishingEventPlanningSmoke = false;
      });
      _refreshActiveRun();
    } catch (e, st) {
      developer.log('Event planning smoke finish failed',
          name: _logName, error: e, stackTrace: st);
      if (!mounted) {
        return;
      }
      setState(() {
        _isFinishingEventPlanningSmoke = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const AppFlowScaffold(
        title: 'Proof Run (debug)',
        showNavigationBar: false,
        constrainBody: false,
        body: Center(child: Text('Proof run tooling is debug-only.')),
      );
    }

    final runId = _activeRunId;
    final startedAt = (_activeStartedAtMs > 0)
        ? DateTime.fromMillisecondsSinceEpoch(_activeStartedAtMs).toLocal()
        : null;
    final prov = _provState;

    return AppFlowScaffold(
      title: 'Proof Run (debug)',
      appBarBackgroundColor: AppColors.surface,
      constrainBody: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _refreshActiveRun,
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Run',
            body: [
              'Active run_id: ${runId ?? '(none)'}',
              if (startedAt != null) 'Started: $startedAt',
            ].join('\n'),
            trailing: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _startRun,
                  child: const Text('Start run'),
                ),
                ElevatedButton(
                  onPressed:
                      _isRunningSimulatedSmoke ? null : _runSimulatedSmoke,
                  child: Text(_isRunningSimulatedSmoke
                      ? 'Running smoke…'
                      : 'Run simulated smoke'),
                ),
                OutlinedButton(
                  onPressed: (runId != null) ? _finishRun : null,
                  child: const Text('Finish'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildBanner(_error!),
            ),
          const SizedBox(height: 12),
          _buildEventPlanningSmokeCard(),
          const SizedBox(height: 12),
          const EventPlanningTelemetryDebugCard(),
          const SizedBox(height: 12),
          _buildCard(
            title: 'Milestones (manual)',
            body: 'These create ledger receipts tied to the active run_id.\n\n'
                'Tip: Use these buttons during the recording so the video and ledger row timestamps match.',
            trailing: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: (runId != null)
                      ? () => _markMilestone('proof_onboarding_completed')
                      : null,
                  child: const Text('Onboarding done'),
                ),
                OutlinedButton(
                  onPressed: (runId != null)
                      ? () => _markMilestone(
                            'proof_offline_ai_provisioning_started',
                          )
                      : null,
                  child: const Text('Offline AI started'),
                ),
                OutlinedButton(
                  onPressed: (runId != null)
                      ? () => _markMilestone(
                            'proof_offline_ai_provisioning_installed',
                          )
                      : null,
                  child: const Text('Offline AI installed'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            title: 'Offline AI provisioning state (read-only)',
            body: _formatProvisioningState(prov),
          ),
          const SizedBox(height: 12),
          _buildCard(
            title: 'AI chat (one message)',
            body: [
              'This uses the same command processor as the in-app AI tab.',
              if (_lastChatPrompt != null) '',
              if (_lastChatPrompt != null) 'Last prompt: $_lastChatPrompt',
              if (_lastChatResponse != null) '',
              if (_lastChatResponse != null)
                'Last response: $_lastChatResponse',
            ].join('\n'),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      labelText: 'Prompt',
                      hintText: 'Ask a short question…',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isChatBusy ? null : _sendAiChat,
                  child: Text(_isChatBusy ? 'Sending…' : 'Send'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            title: 'AI2AI encounter (iOS simulator truth)',
            body: [
              'iOS simulator cannot do real BLE scanning.',
              'This button simulates the AI2AI “walk-by” hot path using the real orchestrator logic, and records a receipt that explicitly says simulated.',
              if (_lastSimulatedSmokeSummary != null) '',
              if (_lastSimulatedSmokeSummary != null)
                'Latest smoke: $_lastSimulatedSmokeSummary',
              if (_simulatedNodeIds.isNotEmpty) '',
              if (_simulatedNodeIds.isNotEmpty)
                'Simulated nodes: ${_simulatedNodeIds.join(', ')}',
            ].join('\n'),
            trailing: ElevatedButton(
              onPressed: _isSimulatingAi2Ai ? null : _simulateAi2AiEncounter,
              child: Text(
                  _isSimulatingAi2Ai ? 'Simulating…' : 'Simulate encounter'),
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            title: 'Export receipts (for bundling)',
            body: [
              'Writes:',
              '- Documents/proof_runs/<run_id>/ledger_rows.jsonl',
              '- Documents/proof_runs/<run_id>/ledger_rows.csv',
              if (_exportDir != null) '',
              if (_exportDir != null) 'Exported to: $_exportDir',
            ].join('\n'),
            trailing: ElevatedButton(
              onPressed: (runId != null) ? _exportRun : null,
              child: const Text('Export'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatProvisioningState(LocalLlmProvisioningState? s) {
    if (s == null) return 'Loading…';
    final phase = s.phase.name;
    final installed = s.packStatus.isInstalled;
    final packId = s.packStatus.activePackId ?? 'unknown';
    final progress = s.progressFraction;
    final pct = (progress != null) ? (progress * 100).round() : null;

    return [
      'phase=$phase',
      'installed=$installed',
      'pack_id=$packId',
      if (pct != null) 'progress=$pct%',
      if (s.lastError != null) 'last_error=${s.lastError}',
    ].join('\n');
  }

  Widget _buildEventPlanningSmokeCard() {
    final String? runId = _activeRunId;
    final bool hasRun = runId != null && runId.isNotEmpty;
    final bool allMilestonesCompleted =
        _completedEventPlanningMilestones.length ==
            EventPlanningBetaSmokeMilestone.values.length;

    return _buildCard(
      title: 'Event Planning Smoke (iOS manual)',
      body: [
        'Scenario: ${ProofRunAutomationService.eventPlanningBetaSmokeScenarioName}',
        'This is the human-run closeout flow for chat handoff -> event truth -> air gap -> publish -> safety -> debrief.',
        if (_completedEventPlanningMilestones.isNotEmpty) '',
        if (_completedEventPlanningMilestones.isNotEmpty)
          'Completed: ${_completedEventPlanningMilestones.map((EventPlanningBetaSmokeMilestone milestone) => milestone.name).join(', ')}',
        if (allMilestonesCompleted)
          'All required milestones recorded. Finish and export the receipt bundle for signoff.',
      ].join('\n'),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ElevatedButton(
                onPressed:
                    _isStartingEventPlanningSmoke ? null : _startEventPlanningSmoke,
                child: Text(
                  _isStartingEventPlanningSmoke
                      ? 'Starting…'
                      : 'Start iOS smoke',
                ),
              ),
              OutlinedButton(
                onPressed: hasRun && !_isFinishingEventPlanningSmoke
                    ? _finishEventPlanningSmoke
                    : null,
                child: Text(
                  _isFinishingEventPlanningSmoke
                      ? 'Finishing…'
                      : 'Finish & export',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EventPlanningBetaSmokeMilestone.values
                .map(
                  (EventPlanningBetaSmokeMilestone milestone) =>
                      FilterChip(
                    label: Text(_labelForEventPlanningMilestone(milestone)),
                    selected:
                        _completedEventPlanningMilestones.contains(milestone),
                    onSelected: hasRun
                        ? (_) => _recordEventPlanningSmokeMilestone(milestone)
                        : null,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _labelForEventPlanningMilestone(
    EventPlanningBetaSmokeMilestone milestone,
  ) {
    return switch (milestone) {
      EventPlanningBetaSmokeMilestone.eventTruthEntered => 'Event truth',
      EventPlanningBetaSmokeMilestone.airGapCrossed => 'Air gap',
      EventPlanningBetaSmokeMilestone.suggestionShown => 'Suggestion',
      EventPlanningBetaSmokeMilestone.publishCompleted => 'Publish',
      EventPlanningBetaSmokeMilestone.safetyChecklistOpened => 'Safety',
      EventPlanningBetaSmokeMilestone.debriefCompleted => 'Debrief',
    };
  }

  Widget _buildBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String body,
    Widget? trailing,
  }) {
    return AppSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
