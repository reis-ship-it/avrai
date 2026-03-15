import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatRuntimeRecoveryService {
  static const String _logName = 'WhatRuntimeRecoveryService';
  static const String _persistedEnvelopeKey =
      'avrai_what_kernel_persisted_envelope_v1';
  static const String _lastRecoverySummaryKey =
      'avrai_what_kernel_last_recovery_summary_v1';

  final WhatKernelContract _kernel;
  final SharedPreferences _prefs;
  final AgentIdService? _agentIdService;
  final SupabaseService? _supabaseService;

  const WhatRuntimeRecoveryService({
    required WhatKernelContract kernel,
    required SharedPreferences prefs,
    AgentIdService? agentIdService,
    SupabaseService? supabaseService,
  })  : _kernel = kernel,
        _prefs = prefs,
        _agentIdService = agentIdService,
        _supabaseService = supabaseService;

  Future<WhatRecoveryResult?> recoverForCurrentUserIfAvailable() async {
    final userId = _supabaseService?.currentUser?.id;
    if (userId == null || userId.isEmpty || _agentIdService == null) {
      developer.log(
        'Skipping what recovery because current agent context is unavailable',
        name: _logName,
      );
      return null;
    }
    final agentId = await _agentIdService.getUserAgentId(userId);
    return recoverForAgent(agentId);
  }

  Future<WhatRecoveryResult?> recoverForAgent(String agentId) async {
    final snapshot = _kernel.snapshotWhat(agentId);
    final persistedEnvelope = _readPersistedEnvelope();
    if (snapshot != null && persistedEnvelope == null) {
      await _persistSnapshot(snapshot);
      developer.log(
        'Existing what snapshot found for $agentId; recovery skipped',
        name: _logName,
      );
      return null;
    }

    final result = await _kernel.recoverWhat(
      WhatRecoveryRequest(
        agentId: agentId,
        persistedEnvelope: persistedEnvelope,
      ),
    );
    final refreshedSnapshot = _kernel.snapshotWhat(agentId);
    if (refreshedSnapshot != null) {
      await _persistSnapshot(refreshedSnapshot);
    }
    await _prefs.setString(
      _lastRecoverySummaryKey,
      jsonEncode(<String, Object?>{
        'agentId': agentId,
        'restoredCount': result.restoredCount,
        'droppedCount': result.droppedCount,
        'schemaVersion': result.schemaVersion,
        'savedAtUtc': result.savedAtUtc.toIso8601String(),
      }),
    );
    developer.log(
      'What recovery completed for $agentId: '
      'restored=${result.restoredCount}, dropped=${result.droppedCount}',
      name: _logName,
    );
    return result;
  }

  Future<void> persistSnapshotForCurrentUserIfAvailable() async {
    final userId = _supabaseService?.currentUser?.id;
    if (userId == null || userId.isEmpty || _agentIdService == null) {
      return;
    }
    final agentId = await _agentIdService.getUserAgentId(userId);
    final snapshot = _kernel.snapshotWhat(agentId);
    if (snapshot != null) {
      await _persistSnapshot(snapshot);
    }
  }

  Map<String, dynamic>? _readPersistedEnvelope() {
    final raw = _prefs.getString(_persistedEnvelopeKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to decode persisted what envelope: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _persistSnapshot(WhatKernelSnapshot snapshot) {
    return _prefs.setString(
      _persistedEnvelopeKey,
      jsonEncode(<String, dynamic>{
        'schemaVersion': snapshot.schemaVersion,
        'savedAtUtc': snapshot.savedAtUtc.toIso8601String(),
        'snapshots': <String, dynamic>{
          snapshot.agentId: snapshot.toJson(),
        },
      }),
    );
  }
}
