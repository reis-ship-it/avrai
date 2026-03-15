import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_why_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_projection.dart';

class WhereState {
  final String activeTokenId;
  final String? activeTokenAlias;
  final String activeTokenKind;
  final List<double> embedding;
  final double confidence;
  final double boundaryTension;
  final String reliabilityTier;
  final DateTime freshness;
  final int evidenceCount;
  final double evolutionRate;
  final String? parentTokenId;
  final String? topAlias;
  final String advisoryStatus;
  final Map<String, double> sourceMix;

  const WhereState({
    required this.activeTokenId,
    required this.activeTokenKind,
    required this.embedding,
    required this.confidence,
    required this.boundaryTension,
    required this.reliabilityTier,
    required this.freshness,
    required this.evidenceCount,
    required this.evolutionRate,
    required this.advisoryStatus,
    required this.sourceMix,
    this.activeTokenAlias,
    this.parentTokenId,
    this.topAlias,
  });

  factory WhereState.fromLocality(LocalityState state) {
    return WhereState(
      activeTokenId: state.activeToken.id,
      activeTokenAlias: state.activeToken.alias,
      activeTokenKind: state.activeToken.kind.name,
      embedding: List<double>.from(state.embedding),
      confidence: state.confidence,
      boundaryTension: state.boundaryTension,
      reliabilityTier: state.reliabilityTier.name,
      freshness: state.freshness,
      evidenceCount: state.evidenceCount,
      evolutionRate: state.evolutionRate,
      parentTokenId: state.parentToken?.id,
      topAlias: state.topAlias,
      advisoryStatus: state.advisoryStatus.name,
      sourceMix: <String, double>{
        'local': state.sourceMix.local,
        'mesh': state.sourceMix.mesh,
        'federated': state.sourceMix.federated,
        'geometry': state.sourceMix.geometry,
        'synthetic_prior': state.sourceMix.syntheticPrior,
      },
    );
  }

  LocalityState toLocality() {
    return LocalityState(
      activeToken: LocalityToken(
        kind: LocalityTokenKind.values.firstWhere(
          (value) => value.name == activeTokenKind,
          orElse: () => LocalityTokenKind.syntheticBootstrap,
        ),
        id: activeTokenId,
        alias: activeTokenAlias,
      ),
      embedding: embedding.length == 12
          ? List<double>.from(embedding)
          : List<double>.filled(12, 0.5),
      confidence: confidence,
      boundaryTension: boundaryTension,
      reliabilityTier: LocalityReliabilityTier.values.firstWhere(
        (value) => value.name == reliabilityTier,
        orElse: () => LocalityReliabilityTier.zeroLocality,
      ),
      freshness: freshness,
      evidenceCount: evidenceCount,
      evolutionRate: evolutionRate,
      parentToken: parentTokenId == null
          ? null
          : LocalityToken(
              kind: LocalityTokenKind.cityPrior,
              id: parentTokenId!,
            ),
      topAlias: topAlias,
      advisoryStatus: LocalityAdvisoryStatus.values.firstWhere(
        (value) => value.name == advisoryStatus,
        orElse: () => LocalityAdvisoryStatus.inactive,
      ),
      sourceMix: LocalitySourceMix(
        local: sourceMix['local'] ?? 0.0,
        mesh: sourceMix['mesh'] ?? 0.0,
        federated: sourceMix['federated'] ?? 0.0,
        geometry: sourceMix['geometry'] ?? 0.0,
        syntheticPrior: sourceMix['synthetic_prior'] ?? 0.0,
      ),
    );
  }

  LocalityToken get activeToken => LocalityToken(
        kind: LocalityTokenKind.values.firstWhere(
          (value) => value.name == activeTokenKind,
          orElse: () => LocalityTokenKind.syntheticBootstrap,
        ),
        id: activeTokenId,
        alias: activeTokenAlias,
      );

  LocalityToken? get parentToken => parentTokenId == null
      ? null
      : LocalityToken(
          kind: LocalityTokenKind.cityPrior,
          id: parentTokenId!,
        );
}

class WhereObservationReceipt {
  final WhereState state;
  final bool cloudUpdated;
  final bool meshForwarded;

  const WhereObservationReceipt({
    required this.state,
    this.cloudUpdated = false,
    this.meshForwarded = false,
  });

  factory WhereObservationReceipt.fromLocality(LocalityUpdateReceipt receipt) {
    return WhereObservationReceipt(
      state: WhereState.fromLocality(receipt.state),
      cloudUpdated: receipt.cloudUpdated,
      meshForwarded: receipt.meshForwarded,
    );
  }
}

class WhereSyncResult {
  final bool synced;
  final String message;

  const WhereSyncResult({
    required this.synced,
    required this.message,
  });

  factory WhereSyncResult.fromLocality(LocalitySyncResult result) {
    return WhereSyncResult(
      synced: result.synced,
      message: result.message,
    );
  }
}

class WherePointResolution {
  final WhereState state;
  final WhereProjection projection;
  final String? cityCode;
  final String? localityCode;
  final String? displayName;

  const WherePointResolution({
    required this.state,
    required this.projection,
    this.cityCode,
    this.localityCode,
    this.displayName,
  });

  factory WherePointResolution.fromLocality(
      LocalityPointResolution resolution) {
    return WherePointResolution(
      state: WhereState.fromLocality(resolution.state),
      projection: WhereProjection.fromLocality(resolution.projection),
      cityCode: resolution.cityCode,
      localityCode: resolution.localityCode,
      displayName: resolution.displayName,
    );
  }
}

class WhereSnapshot {
  final String agentId;
  final WhereState state;
  final DateTime savedAtUtc;

  const WhereSnapshot({
    required this.agentId,
    required this.state,
    required this.savedAtUtc,
  });

  factory WhereSnapshot.fromLocality(LocalityKernelSnapshot snapshot) {
    return WhereSnapshot(
      agentId: snapshot.agentId,
      state: WhereState.fromLocality(snapshot.state),
      savedAtUtc: snapshot.savedAtUtc,
    );
  }
}

class WhereRecoveryResult {
  final WhereState state;
  final bool recoveredFromSnapshot;

  const WhereRecoveryResult({
    required this.state,
    required this.recoveredFromSnapshot,
  });

  factory WhereRecoveryResult.fromLocality(LocalityRecoveryResult result) {
    return WhereRecoveryResult(
      state: WhereState.fromLocality(result.state),
      recoveredFromSnapshot: result.recoveredFromSnapshot,
    );
  }
}

typedef WhereZeroReliabilityReport = LocalityZeroReliabilityReport;
typedef WhereWhySnapshot = WhySnapshot;
