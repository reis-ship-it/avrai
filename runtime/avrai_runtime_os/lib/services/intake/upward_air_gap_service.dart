import 'dart:convert';

import 'package:crypto/crypto.dart' show sha256;
import 'package:avrai_runtime_os/services/intake/intake_models.dart';

/// Issues receipt-backed, bounded artifacts for upward hierarchy crossings.
///
/// `issuedAtUtc` is the mint time of the receipt itself, not the original
/// observed/event time of the source signal.
class UpwardAirGapService {
  const UpwardAirGapService({
    this.artifactVersion = '0.1',
    this.defaultTtl = const Duration(days: 7),
  });

  final String artifactVersion;
  final Duration defaultTtl;

  List<String> validateArtifact({
    required UpwardAirGapArtifact artifact,
    required DateTime nowUtc,
    required String destinationCeiling,
    required String requiredNextStage,
  }) {
    final violations = <String>[];
    final normalizedPayload = _normalizePayload(artifact.sanitizedPayload);
    final canonicalJson = jsonEncode(normalizedPayload);
    final expectedContentSha256 =
        sha256.convert(utf8.encode(canonicalJson)).toString();
    final expectedReceiptId =
        'upward-airgap:${artifact.sourceKind}:${artifact.issuedAtUtc.microsecondsSinceEpoch}:'
        '${expectedContentSha256.substring(0, 12)}';
    final normalizedAllowedNextStages =
        List<String>.from(artifact.allowedNextStages)..sort();

    if (!artifact.expiresAtUtc.toUtc().isAfter(nowUtc.toUtc())) {
      violations.add(
          'artifact expired at ${artifact.expiresAtUtc.toUtc().toIso8601String()}');
    }
    if (artifact.destinationCeiling != destinationCeiling) {
      violations.add(
        'destination ceiling `${artifact.destinationCeiling}` does not match `$destinationCeiling`',
      );
    }
    if (!normalizedAllowedNextStages.contains(requiredNextStage)) {
      violations.add(
        'allowedNextStages missing required stage `$requiredNextStage`',
      );
    }
    if (artifact.contentSha256 != expectedContentSha256) {
      violations.add('contentSha256 does not match sanitizedPayload');
    }
    if (artifact.receiptId != expectedReceiptId) {
      violations.add('receiptId does not match issued payload digest');
    }
    if (artifact.attestation['contentSha256']?.toString() !=
        artifact.contentSha256) {
      violations.add('attestation contentSha256 does not match artifact');
    }
    if (artifact.attestation['destinationCeiling']?.toString() !=
        artifact.destinationCeiling) {
      violations.add('attestation destinationCeiling does not match artifact');
    }
    final attestedNextStages = (artifact.attestation['allowedNextStages']
                as List? ??
            const <dynamic>[])
        .map((value) => value.toString())
        .toList()
      ..sort();
    if (attestedNextStages.length != normalizedAllowedNextStages.length ||
        !_listsEqual(attestedNextStages, normalizedAllowedNextStages)) {
      violations.add('attestation allowedNextStages does not match artifact');
    }

    return violations;
  }

  UpwardAirGapArtifact issueArtifact({
    required String originPlane,
    required String sourceKind,
    required String sourceScope,
    required String destinationCeiling,
    required DateTime issuedAtUtc,
    required Map<String, dynamic> sanitizedPayload,
    String? pseudonymousActorRef,
    Duration? ttl,
    List<String> allowedNextStages = const <String>[
      'governed_upward_learning_review',
    ],
  }) {
    final normalizedPayload = _normalizePayload(sanitizedPayload);
    final canonicalJson = jsonEncode(normalizedPayload);
    final contentSha256 = sha256.convert(utf8.encode(canonicalJson)).toString();
    final receiptId =
        'upward-airgap:$sourceKind:${issuedAtUtc.microsecondsSinceEpoch}:'
        '${contentSha256.substring(0, 12)}';
    final expiresAtUtc = issuedAtUtc.add(ttl ?? defaultTtl);
    final nextStages = List<String>.from(allowedNextStages)..sort();

    return UpwardAirGapArtifact(
      receiptId: receiptId,
      artifactVersion: artifactVersion,
      originPlane: originPlane,
      sourceKind: sourceKind,
      sourceScope: sourceScope,
      destinationCeiling: destinationCeiling,
      issuedAtUtc: issuedAtUtc,
      expiresAtUtc: expiresAtUtc,
      contentSha256: contentSha256,
      allowedNextStages: nextStages,
      sanitizedPayload: normalizedPayload,
      attestation: <String, dynamic>{
        'issuer': 'upward_air_gap_service',
        'artifactVersion': artifactVersion,
        'issuedAtUtc': issuedAtUtc.toIso8601String(),
        'expiresAtUtc': expiresAtUtc.toIso8601String(),
        'contentSha256': contentSha256,
        'destinationCeiling': destinationCeiling,
        'allowedNextStages': nextStages,
      },
      pseudonymousActorRef: pseudonymousActorRef,
    );
  }

  Map<String, dynamic> _normalizePayload(Map<String, dynamic> payload) {
    final keys = payload.keys.toList()..sort();
    final normalized = <String, dynamic>{};
    for (final key in keys) {
      final value = payload[key];
      if (value == null) {
        continue;
      }
      normalized[key] = _normalizeValue(value);
    }
    return normalized;
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(
        value.map(
          (key, nestedValue) => MapEntry(key.toString(), nestedValue),
        ),
      );
      return _normalizePayload(map);
    }
    if (value is List) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    return value;
  }

  bool _listsEqual(List<String> left, List<String> right) {
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
}
