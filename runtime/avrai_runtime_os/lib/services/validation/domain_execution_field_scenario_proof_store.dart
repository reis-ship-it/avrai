import 'dart:convert';

import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';

class DomainExecutionFieldScenarioProofStore {
  DomainExecutionFieldScenarioProofStore({
    StorageService? storageService,
    DateTime Function()? nowUtc,
    List<DomainExecutionFieldScenarioProof>? seededProofs,
  })  : _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
        _storageService = storageService,
        _memoryProofs = List<DomainExecutionFieldScenarioProof>.from(
          seededProofs ?? const <DomainExecutionFieldScenarioProof>[],
        );

  static const int _maxStoredProofs = 32;
  static const String _storageKey = 'domain_execution_field_scenario_proofs_v1';

  final DateTime Function() _nowUtc;
  final StorageService? _storageService;
  final List<DomainExecutionFieldScenarioProof> _memoryProofs;

  List<DomainExecutionFieldScenarioProof> recentProofs({int limit = 8}) {
    final proofs = _readProofs();
    final normalizedLimit = limit.clamp(0, proofs.length);
    if (normalizedLimit == 0) {
      return const <DomainExecutionFieldScenarioProof>[];
    }
    return proofs.take(normalizedLimit).toList(growable: false);
  }

  DomainExecutionFieldScenarioProof? latestForScenario(
    DomainExecutionFieldScenario scenario,
  ) {
    for (final proof in _readProofs()) {
      if (proof.scenario == scenario) {
        return proof;
      }
    }
    return null;
  }

  Future<void> record(DomainExecutionFieldScenarioProof proof) async {
    final proofs = _readProofs().toList(growable: true);
    proofs.removeWhere((entry) => entry.scenario == proof.scenario);
    proofs.insert(0, proof);
    if (proofs.length > _maxStoredProofs) {
      proofs.removeRange(_maxStoredProofs, proofs.length);
    }
    _memoryProofs
      ..clear()
      ..addAll(proofs);
    final storage = _storageService;
    if (storage == null) {
      return;
    }
    try {
      await storage.setObject(
        _storageKey,
        proofs.map((entry) => entry.toJson()).toList(growable: false),
        box: 'spots_ai',
      );
    } on StateError {
      // Fall back to in-memory storage until StorageService is initialized.
    }
  }

  String exportProofBundle(DomainExecutionFieldScenarioProof proof) {
    return const JsonEncoder.withIndent('  ').convert(proof.toJson());
  }

  String exportRecentProofBundles({int limit = 8}) {
    final payload = <String, dynamic>{
      'exported_at_utc': _nowUtc().toIso8601String(),
      'proofs': recentProofs(limit: limit)
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  List<DomainExecutionFieldScenarioProof> _readProofs() {
    final storage = _storageService;
    if (storage != null) {
      try {
        final raw = storage.getObject<List<dynamic>>(_storageKey, box: 'spots_ai');
        if (raw != null) {
          return raw
              .whereType<Map>()
              .map(
                (entry) => DomainExecutionFieldScenarioProof.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false);
        }
      } on StateError {
        // Fall back to in-memory storage until StorageService is initialized.
      }
    }
    return List<DomainExecutionFieldScenarioProof>.from(_memoryProofs);
  }
}
