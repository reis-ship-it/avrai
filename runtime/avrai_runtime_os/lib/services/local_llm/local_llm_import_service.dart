import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:avrai_runtime_os/services/ai_infrastructure/model_safety_supervisor.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/security/security_kernel_release_gate_service.dart';

/// Dev/helper flow: import a local GGUF file into the model-pack directory and
/// activate it (no hosting, no manifest URL).
///
/// This is intentionally **not** the primary production path.
class LocalLlmImportService {
  static const String _logName = 'LocalLlmImportService';

  static const String prefsKeyActiveModelDir = 'local_llm_active_model_dir_v1';
  static const String prefsKeyActiveModelId = 'local_llm_active_model_id_v1';
  static const String prefsKeyLastGoodModelDir =
      'local_llm_last_good_model_dir_v1';
  static const String prefsKeyLastGoodModelId =
      'local_llm_last_good_model_id_v1';

  LocalLlmImportService({
    SecurityKernelReleaseGateService? securityReleaseGateService,
  }) : _securityReleaseGateService = securityReleaseGateService;

  final SecurityKernelReleaseGateService? _securityReleaseGateService;

  Future<void> importAndActivateAndroidGguf({
    required File ggufFile,
    String? modelId,
    bool operatorApproved = false,
  }) async {
    if (kIsWeb) throw UnsupportedError('Local import is not supported on web.');
    if (!await ggufFile.exists()) {
      throw Exception('File does not exist');
    }

    final id = (modelId == null || modelId.trim().isEmpty)
        ? p.basenameWithoutExtension(ggufFile.path)
        : modelId.trim();
    final version = 'local_${DateTime.now().millisecondsSinceEpoch}';

    final support = await getApplicationSupportDirectory();
    final root = Directory(p.join(support.path, 'local_llm_packs'));
    final targetDir = Directory(p.join(root.path, id, version));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final dest = File(p.join(targetDir.path, 'model.gguf'));
    await ggufFile.copy(dest.path);

    final prefs = await SharedPreferencesCompat.getInstance();

    final previousActiveDir = prefs.getString(prefsKeyActiveModelDir);
    final previousActiveId = prefs.getString(prefsKeyActiveModelId);
    if (previousActiveDir != null &&
        previousActiveDir.isNotEmpty &&
        previousActiveId != null &&
        previousActiveId.isNotEmpty) {
      await prefs.setString(prefsKeyLastGoodModelDir, previousActiveDir);
      await prefs.setString(prefsKeyLastGoodModelId, previousActiveId);
    }

    final packId = '$id@$version';
    final securityGateService = _securityReleaseGateService;
    if (securityGateService != null) {
      final gateDecision = await securityGateService.evaluateModelPromotion(
        surfaceId: 'chat_local_llm',
        version: packId,
        actorAlias: 'local_llm_import',
        operatorApproved: operatorApproved,
        metadata: <String, dynamic>{
          'model_id': id,
          'activation_source': 'local_llm_import',
        },
      );
      if (!gateDecision.servingAllowed) {
        throw Exception(
          'Security release gate blocked local model import: '
          '${gateDecision.reasonCodes.join(", ")}',
        );
      }
    }
    await prefs.setString(prefsKeyActiveModelDir, targetDir.path);
    await prefs.setString(prefsKeyActiveModelId, packId);

    // Start happiness-gated rollout for the local chat model.
    try {
      if (previousActiveId != null && previousActiveId.isNotEmpty) {
        await ModelSafetySupervisor(
          prefs: prefs,
          securityReleaseGateService: _securityReleaseGateService,
        ).startRolloutCandidate(
          modelType: 'chat_local_llm',
          fromVersion: previousActiveId,
          toVersion: packId,
        );
      }
    } catch (e, st) {
      developer.log(
        'Failed to start rollout candidate (non-fatal)',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}
