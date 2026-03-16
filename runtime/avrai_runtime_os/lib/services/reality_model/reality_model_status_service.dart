import 'dart:developer' as developer;

import 'package:avrai_core/avra_core.dart';
import 'package:get_it/get_it.dart';

import 'reality_model_port.dart';

class RealityModelStatusSnapshot {
  const RealityModelStatusSnapshot({
    required this.loadedAtUtc,
    required this.available,
    this.contract,
    this.mode = 'unavailable',
    this.boundary = 'unknown',
    this.summary = 'Reality-model contract unavailable.',
    this.errorMessage,
  });

  final DateTime loadedAtUtc;
  final bool available;
  final RealityModelContract? contract;
  final String mode;
  final String boundary;
  final String summary;
  final String? errorMessage;

  bool get isKernelBacked => mode.contains('kernel');

  String get modeLabel => mode
      .split('_')
      .where((entry) => entry.trim().isNotEmpty)
      .map((entry) => '${entry[0].toUpperCase()}${entry.substring(1)}')
      .join(' ');

  String get boundaryLabel => boundary
      .split('_')
      .where((entry) => entry.trim().isNotEmpty)
      .map((entry) => '${entry[0].toUpperCase()}${entry.substring(1)}')
      .join(' ');

  List<String> get supportedDomainLabels {
    return contract?.supportedDomains
            .map((domain) => _labelize(domain.toWireValue()))
            .toList(growable: false) ??
        const <String>[];
  }

  List<String> get rendererLabels {
    return contract?.rendererKinds
            .map((renderer) => _labelize(renderer.toWireValue()))
            .toList(growable: false) ??
        const <String>[];
  }

  String get uncertaintyLabel {
    final value =
        contract?.uncertaintyDisposition.toWireValue() ?? 'never_bluff';
    return _labelize(value);
  }

  static String _labelize(String value) {
    return value
        .split(RegExp(r'[_-]+'))
        .where((entry) => entry.trim().isNotEmpty)
        .map((entry) => '${entry[0].toUpperCase()}${entry.substring(1)}')
        .join(' ');
  }
}

class RealityModelStatusService {
  RealityModelStatusService({
    RealityModelPort? realityModelPort,
  }) : _realityModelPort = realityModelPort ??
            (GetIt.instance.isRegistered<RealityModelPort>()
                ? GetIt.instance<RealityModelPort>()
                : null);

  static const String _logName = 'RealityModelStatusService';

  final RealityModelPort? _realityModelPort;

  Future<RealityModelStatusSnapshot> loadStatus() async {
    final port = _realityModelPort;
    if (port == null) {
      return RealityModelStatusSnapshot(
        loadedAtUtc: DateTime.now().toUtc(),
        available: false,
        summary: 'Reality-model port is not registered in this environment.',
      );
    }

    try {
      final contract = await port.getActiveContract();
      final normalized = contract.normalized();
      final mode =
          (normalized.metadata['mode'] as String?)?.trim().isNotEmpty == true
              ? (normalized.metadata['mode'] as String).trim()
              : 'unspecified';
      final boundary =
          (normalized.metadata['boundary'] as String?)?.trim().isNotEmpty ==
                  true
              ? (normalized.metadata['boundary'] as String).trim()
              : 'reality_model_port';
      final summary =
          'Active contract ${normalized.contractId} (${normalized.version}) is running in $mode mode with ${normalized.maxEvidenceRefs} bounded evidence refs.';
      return RealityModelStatusSnapshot(
        loadedAtUtc: DateTime.now().toUtc(),
        available: true,
        contract: normalized,
        mode: mode,
        boundary: boundary,
        summary: summary,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load reality-model contract status: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return RealityModelStatusSnapshot(
        loadedAtUtc: DateTime.now().toUtc(),
        available: false,
        summary: 'Reality-model contract status failed to load.',
        errorMessage: error.toString(),
      );
    }
  }
}
