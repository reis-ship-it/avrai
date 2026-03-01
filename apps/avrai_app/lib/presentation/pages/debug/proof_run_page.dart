import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/privacy_protection.dart'
    show AnonymizedVibeData, AnonymizedVibeMetrics;
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_runtime_os/services/ledgers/proof_run_service_v0.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_provisioning_state_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/common/ai_command_processor.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai_network/network/device_discovery.dart'
    show DiscoveredDevice, DeviceType;

class ProofRunPage extends StatefulWidget {
  const ProofRunPage({super.key});

  @override
  State<ProofRunPage> createState() => _ProofRunPageState();
}

class _ProofRunPageState extends State<ProofRunPage> {
  static const String _logName = 'ProofRunPage';

  late final ProofRunServiceV0 _proof;
  late final LocalLlmProvisioningStateService _provisioning;
  late final PersonalityLearning _personalityLearning;
  late final VibeConnectionOrchestrator _orchestrator;

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
  List<String> _simulatedNodeIds = const [];

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
    _provisioning = LocalLlmProvisioningStateService();
    _personalityLearning = sl<PersonalityLearning>();
    _orchestrator = sl<VibeConnectionOrchestrator>();

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

    final userId = _currentUserIdOrNull();
    if (userId == null || userId.isEmpty) {
      setState(() => _error = 'Not authenticated; AI2AI requires auth.');
      return;
    }

    setState(() {
      _error = null;
      _isSimulatingAi2Ai = true;
      _simulatedNodeIds = const [];
    });

    try {
      // Ensure the discovery switch is ON (debugSimulateWalkByHotPath gates on it).
      await StorageService.instance.setBool('discovery_enabled', true);

      final profile =
          await _personalityLearning.getCurrentPersonality(userId) ??
              await _personalityLearning.initializePersonality(userId);

      final now = DateTime.now().toUtc();
      final dims = <String, double>{
        for (final d in VibeConstants.coreDimensions) d: 0.62,
      };
      // Make the simulated peer slightly “different” to trigger learning deltas.
      dims['community_orientation'] = 0.9;
      dims['exploration_eagerness'] = 0.85;

      final peerVibe = AnonymizedVibeData(
        noisyDimensions: dims,
        anonymizedMetrics: AnonymizedVibeMetrics(
          energy: 0.8,
          social: 0.85,
          exploration: 0.9,
        ),
        temporalContextHash: 'proof_run',
        vibeSignature: 'simulated_peer_sig',
        privacyLevel: 'debug',
        anonymizationQuality: 0.95,
        salt: 'proof_run',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      );

      final devices = <DiscoveredDevice>[
        DiscoveredDevice(
          deviceId: 'sim_peer_1',
          deviceName: 'SimulatedPeer1',
          type: DeviceType.bluetooth,
          isSpotsEnabled: true,
          personalityData: peerVibe,
          signalStrength: -55,
          discoveredAt: now,
          metadata: const <String, dynamic>{
            'proof_run': true,
            'simulated': true,
          },
        ),
      ];

      // ignore: invalid_use_of_visible_for_testing_member
      await _orchestrator.debugSimulateWalkByHotPath(
        userId: userId,
        personality: profile,
        devices: devices,
      );

      // ignore: invalid_use_of_visible_for_testing_member
      final nodes = _orchestrator.debugDiscoveredNodesSnapshot();
      final ids = nodes.map((n) => n.nodeId).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _isSimulatingAi2Ai = false;
        _simulatedNodeIds = ids;
      });

      await _markMilestone(
        'proof_ai2ai_encounter_simulated',
        payload: <String, Object?>{
          'simulated': true,
          'transport': 'none_ios_simulator',
          'node_ids': ids,
          'node_count': ids.length,
        },
      );
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

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const AdaptivePlatformPageScaffold(
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

    return AdaptivePlatformPageScaffold(
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
    return PortalSurface(
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
