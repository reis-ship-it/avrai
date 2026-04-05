import 'dart:convert';
import 'dart:math' as math;

import 'package:avrai_core/contracts/air_gap_compression_contract.dart';
import 'package:avrai_core/models/air_gap/air_gap_compression_models.dart';
import 'package:crypto/crypto.dart';

class AirGapCompressionKernel {
  const AirGapCompressionKernel();

  SafeArtifactEnvelope compress({
    required AirGapCompressionContract contract,
    required CompressionBudgetProfile budgetProfile,
  }) {
    final normalizedContract = contract.normalized();
    final normalizedBudget = budgetProfile.normalized();
    _ensureLegalInput(normalizedContract);

    final result = switch (normalizedContract.artifactType) {
      AirGapCompressionArtifactType.semanticTupleBundle =>
        _compressSemanticTupleBundle(normalizedContract, normalizedBudget),
      AirGapCompressionArtifactType.safeEmbeddingVector =>
        _compressSafeEmbeddingVector(normalizedContract, normalizedBudget),
      AirGapCompressionArtifactType.truthEvidenceEnvelope =>
        _compressTruthEvidenceEnvelope(normalizedContract, normalizedBudget),
      AirGapCompressionArtifactType.higherLayerArtifact =>
        _compressHigherLayerArtifact(normalizedContract, normalizedBudget),
    };

    if (result.measuredDistortion > normalizedBudget.maxDistortionBudget) {
      throw AirGapCompressionException(
        'Measured distortion ${result.measuredDistortion.toStringAsFixed(4)} '
        'exceeds budget ${normalizedBudget.maxDistortionBudget.toStringAsFixed(4)} '
        'for ${normalizedContract.contractId}.',
      );
    }

    for (final path in normalizedContract.requiredRetainedPaths) {
      if (!_containsJsonPath(result.compressedArtifact, path)) {
        throw AirGapCompressionException(
          'Compressed artifact for ${normalizedContract.contractId} lost '
          'required path "$path".',
        );
      }
    }

    final audit = <String, dynamic>{
      'rawPayloadForbidden': true,
      'rawPayloadDetected': false,
      'requiredRetainedPaths': normalizedContract.requiredRetainedPaths,
      'measuredDistortion': result.measuredDistortion,
      'nonReconstructable': true,
      'legalArtifactType': normalizedContract.artifactType.name,
      ...result.audit,
    };
    final artifactHash = sha256
        .convert(utf8.encode(_canonicalJson(result.compressedArtifact)))
        .toString();
    return SafeArtifactEnvelope(
      envelopeId: normalizedContract.contractId,
      artifactType: normalizedContract.artifactType,
      compressionMode: result.mode,
      privacyLadderTag: normalizedContract.privacyLadderTag,
      provenanceRefs: normalizedContract.provenanceRefs
          .take(normalizedBudget.maxProvenanceRefs)
          .toList(growable: false),
      detailBudget: normalizedBudget.detailBudget,
      measuredDistortion: result.measuredDistortion,
      nonReconstructable: true,
      artifactHash: artifactHash,
      compressedArtifact: result.compressedArtifact,
      audit: audit,
      metadata: _trimMap(
        normalizedContract.metadata,
        maxEntries: normalizedBudget.maxMetadataEntries,
      ),
    );
  }

  _CompressionResult _compressSemanticTupleBundle(
    AirGapCompressionContract contract,
    CompressionBudgetProfile budget,
  ) {
    final rawTuples = (contract.payload['tuples'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    rawTuples.sort((left, right) {
      final confidenceDiff = ((right['confidence'] as num?)?.toDouble() ?? 0.0)
          .compareTo((left['confidence'] as num?)?.toDouble() ?? 0.0);
      if (confidenceDiff != 0) {
        return confidenceDiff;
      }
      return (left['id']?.toString() ?? '')
          .compareTo(right['id']?.toString() ?? '');
    });

    final retainedTuples =
        rawTuples.take(budget.maxSemanticTuples).map((tuple) {
      return <String, dynamic>{
        'id': tuple['id'],
        'category': tuple['category'],
        'subject': tuple['subject'],
        'predicate': tuple['predicate'],
        'object': tuple['object'],
        'confidence': _roundNum(
          (tuple['confidence'] as num?)?.toDouble() ?? 0.0,
          budget.embeddingPrecision,
        ),
        'extracted_at': tuple['extracted_at'],
      };
    }).toList(growable: false);

    final categoryCounts = <String, int>{};
    for (final tuple in rawTuples) {
      final category = tuple['category']?.toString() ?? 'unknown';
      categoryCounts.update(category, (count) => count + 1, ifAbsent: () => 1);
    }
    final droppedCount = math.max(0, rawTuples.length - retainedTuples.length);
    final distortion =
        rawTuples.isEmpty ? 0.0 : droppedCount / rawTuples.length.toDouble();
    return _CompressionResult(
      mode: AirGapCompressionMode.boundedProjection,
      measuredDistortion: distortion,
      compressedArtifact: <String, dynamic>{
        'tupleCount': rawTuples.length,
        'retainedTupleCount': retainedTuples.length,
        'tuples': retainedTuples,
        'categoryCounts': categoryCounts,
      },
      audit: <String, dynamic>{
        'droppedTupleCount': droppedCount,
      },
    );
  }

  _CompressionResult _compressSafeEmbeddingVector(
    AirGapCompressionContract contract,
    CompressionBudgetProfile budget,
  ) {
    final values = (contract.payload['values'] as List? ?? const <dynamic>[])
        .map((entry) => (entry as num).toDouble())
        .toList(growable: false);
    final retained = values.take(budget.maxEmbeddingDimensions).toList();
    final quantized = retained
        .map((value) => _roundNum(value, budget.embeddingPrecision))
        .toList(growable: false);
    final droppedCount = math.max(0, values.length - retained.length);
    final quantizationError = retained.isEmpty
        ? 0.0
        : retained
                .asMap()
                .entries
                .map((entry) => (entry.value - quantized[entry.key]).abs())
                .reduce((left, right) => left + right) /
            retained.length;
    final droppedRatio =
        values.isEmpty ? 0.0 : droppedCount / values.length.toDouble();
    return _CompressionResult(
      mode: AirGapCompressionMode.quantizedEmbedding,
      measuredDistortion: math.min(1.0, droppedRatio + quantizationError),
      compressedArtifact: <String, dynamic>{
        'embeddingKind':
            contract.payload['embeddingKind']?.toString() ?? 'safe',
        'dimensionCount': values.length,
        'retainedDimensionCount': retained.length,
        'values': quantized,
        'vectorNorm': _roundNum(
          math.sqrt(retained.fold<double>(
            0.0,
            (sum, value) => sum + value * value,
          )),
          budget.embeddingPrecision,
        ),
      },
      audit: <String, dynamic>{
        'droppedDimensionCount': droppedCount,
        'averageQuantizationError':
            _roundNum(quantizationError, budget.embeddingPrecision),
      },
    );
  }

  _CompressionResult _compressTruthEvidenceEnvelope(
    AirGapCompressionContract contract,
    CompressionBudgetProfile budget,
  ) {
    final sourceRefs =
        (contract.payload['sourceRefs'] as List? ?? const <dynamic>[])
            .map((entry) => entry.toString())
            .toList(growable: false);
    final approvals =
        (contract.payload['approvals'] as List? ?? const <dynamic>[])
            .map((entry) => entry.toString())
            .toList(growable: false);
    final rollbackRefs =
        (contract.payload['rollbackRefs'] as List? ?? const <dynamic>[])
            .map((entry) => entry.toString())
            .toList(growable: false);

    final retainedSourceRefs =
        sourceRefs.take(budget.maxSourceRefs).toList(growable: false);
    final retainedApprovals =
        approvals.take(budget.maxProvenanceRefs).toList(growable: false);
    final retainedRollbackRefs =
        rollbackRefs.take(budget.maxProvenanceRefs).toList(growable: false);

    final totalRefs =
        sourceRefs.length + approvals.length + rollbackRefs.length;
    final retainedRefs = retainedSourceRefs.length +
        retainedApprovals.length +
        retainedRollbackRefs.length;
    final distortion = totalRefs == 0
        ? 0.0
        : (totalRefs - retainedRefs) / totalRefs.toDouble();
    return _CompressionResult(
      mode: AirGapCompressionMode.referenceEnvelope,
      measuredDistortion: distortion,
      compressedArtifact: <String, dynamic>{
        'scope': Map<String, dynamic>.from(
          contract.payload['scope'] as Map? ?? const <String, dynamic>{},
        ),
        'traceId': contract.payload['traceId']?.toString() ?? '',
        'evidenceClass':
            contract.payload['evidenceClass']?.toString() ?? 'unknown',
        'privacyLadderTag':
            contract.payload['privacyLadderTag']?.toString() ?? 'redacted',
        'sourceRefs': retainedSourceRefs,
        'approvals': retainedApprovals,
        'rollbackRefs': retainedRollbackRefs,
        'metadata': _trimMap(
          Map<String, dynamic>.from(
            contract.payload['metadata'] as Map? ?? const <String, dynamic>{},
          ),
          maxEntries: budget.maxMetadataEntries,
        ),
      },
      audit: <String, dynamic>{
        'trimmedSourceRefCount': sourceRefs.length - retainedSourceRefs.length,
        'trimmedApprovalCount': approvals.length - retainedApprovals.length,
        'trimmedRollbackRefCount':
            rollbackRefs.length - retainedRollbackRefs.length,
      },
    );
  }

  _CompressionResult _compressHigherLayerArtifact(
    AirGapCompressionContract contract,
    CompressionBudgetProfile budget,
  ) {
    if (contract.metadata['policyApprovedHigherLayerArtifact'] != true) {
      throw AirGapCompressionException(
        'Higher-layer artifacts must be explicitly policy approved before '
        'Air Gap compression.',
      );
    }
    final artifact = Map<String, dynamic>.from(
      contract.payload['artifact'] as Map? ?? const <String, dynamic>{},
    );
    final compressedArtifact = _trimMap(
      artifact,
      maxEntries: budget.maxMetadataEntries,
    );
    return _CompressionResult(
      mode: AirGapCompressionMode.hierarchyPacket,
      measuredDistortion: artifact.isEmpty
          ? 0.0
          : (artifact.length - compressedArtifact.length) / artifact.length,
      compressedArtifact: <String, dynamic>{
        ...compressedArtifact,
        'approvalRef': contract.metadata['approvalRef'],
        'summaryKeys': compressedArtifact.keys.toList()..sort(),
      },
      audit: <String, dynamic>{
        'trimmedArtifactKeyCount': artifact.length - compressedArtifact.length,
      },
    );
  }

  void _ensureLegalInput(AirGapCompressionContract contract) {
    if (_containsForbiddenMarkers(contract.payload)) {
      throw AirGapCompressionException(
        'Raw payload markers are forbidden inputs to the Air Gap '
        'compression kernel.',
      );
    }
  }

  static bool _containsForbiddenMarkers(Object? value) {
    const forbiddenKeys = <String>{
      'raw',
      'rawContent',
      'rawPayload',
      'plaintext',
      'messageBody',
      'gpsTrace',
      'emailBody',
    };
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        if (forbiddenKeys.contains(key)) {
          return true;
        }
        if (_containsForbiddenMarkers(entry.value)) {
          return true;
        }
      }
    }
    if (value is Iterable) {
      for (final item in value) {
        if (_containsForbiddenMarkers(item)) {
          return true;
        }
      }
    }
    return false;
  }

  static Map<String, dynamic> _trimMap(
    Map<String, dynamic> value, {
    required int maxEntries,
  }) {
    final sortedKeys = value.keys.toList()..sort();
    final selectedKeys = sortedKeys.take(maxEntries);
    return <String, dynamic>{
      for (final key in selectedKeys) key: _sanitizeJsonValue(value[key]),
    };
  }

  static Object? _sanitizeJsonValue(Object? value) {
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      for (final key in keys) {
        sanitized[key] = _sanitizeJsonValue(value[key]);
      }
      return sanitized;
    }
    if (value is Iterable) {
      return value.map(_sanitizeJsonValue).toList(growable: false);
    }
    return value;
  }

  static bool _containsJsonPath(Map<String, dynamic> root, String path) {
    Object? cursor = root;
    for (final segment in path.split('.')) {
      if (cursor is Map) {
        if (!cursor.containsKey(segment)) {
          return false;
        }
        cursor = cursor[segment];
        continue;
      }
      if (cursor is List) {
        final index = int.tryParse(segment);
        if (index == null || index < 0 || index >= cursor.length) {
          return false;
        }
        cursor = cursor[index];
        continue;
      }
      return false;
    }
    return cursor != null;
  }

  static double _roundNum(double value, int precision) {
    return double.parse(value.toStringAsFixed(precision));
  }

  static String _canonicalJson(Object? value) =>
      jsonEncode(_canonicalize(value));

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final sortedKeys = value.keys.map((key) => key.toString()).toList()
        ..sort();
      return <String, dynamic>{
        for (final key in sortedKeys) key: _canonicalize(value[key]),
      };
    }
    if (value is Iterable) {
      return value.map(_canonicalize).toList(growable: false);
    }
    return value;
  }
}

class CompressedKnowledgePacketCodec {
  const CompressedKnowledgePacketCodec();

  String encode(CompressedKnowledgePacket packet) {
    return jsonEncode(packet.toJson());
  }

  CompressedKnowledgePacket decode(String encoded) {
    return CompressedKnowledgePacket.fromJson(
      Map<String, dynamic>.from(jsonDecode(encoded) as Map),
    );
  }
}

class _CompressionResult {
  const _CompressionResult({
    required this.mode,
    required this.measuredDistortion,
    required this.compressedArtifact,
    required this.audit,
  });

  final AirGapCompressionMode mode;
  final double measuredDistortion;
  final Map<String, dynamic> compressedArtifact;
  final Map<String, dynamic> audit;
}
