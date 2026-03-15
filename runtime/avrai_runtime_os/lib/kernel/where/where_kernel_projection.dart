import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_outputs.dart';

enum WhereProjectionAudience {
  user,
  admin,
  debug,
}

class WhereProjection {
  final String primaryLabel;
  final String confidenceBucket;
  final bool nearBoundary;
  final String activeTokenId;
  final String activeTokenKind;
  final String? activeTokenAlias;
  final Map<String, dynamic> metadata;

  const WhereProjection({
    required this.primaryLabel,
    required this.confidenceBucket,
    required this.nearBoundary,
    required this.activeTokenId,
    required this.activeTokenKind,
    this.activeTokenAlias,
    this.metadata = const <String, dynamic>{},
  });

  factory WhereProjection.fromLocality(LocalityProjection projection) {
    return WhereProjection(
      primaryLabel: projection.primaryLabel,
      confidenceBucket: projection.confidenceBucket,
      nearBoundary: projection.nearBoundary,
      activeTokenId: projection.activeToken.id,
      activeTokenKind: projection.activeToken.kind.name,
      activeTokenAlias: projection.activeToken.alias,
      metadata: Map<String, dynamic>.from(projection.metadata),
    );
  }

  LocalityProjection toLocality() {
    return LocalityProjection(
      primaryLabel: primaryLabel,
      confidenceBucket: confidenceBucket,
      nearBoundary: nearBoundary,
      activeToken: LocalityToken(
        kind: LocalityTokenKind.values.firstWhere(
          (value) => value.name == activeTokenKind,
          orElse: () => LocalityTokenKind.syntheticBootstrap,
        ),
        id: activeTokenId,
        alias: activeTokenAlias,
      ),
      metadata: Map<String, dynamic>.from(metadata),
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
}

class WhereProjectionRequest {
  final WhereProjectionAudience audience;
  final WhereState state;
  final bool includeGeometry;
  final bool includeAttribution;
  final bool includePrediction;

  const WhereProjectionRequest({
    required this.audience,
    required this.state,
    this.includeGeometry = false,
    this.includeAttribution = false,
    this.includePrediction = false,
  });

  LocalityProjectionRequest toLocality() {
    return LocalityProjectionRequest(
      audience: LocalityProjectionAudience.values.firstWhere(
        (value) => value.name == audience.name,
        orElse: () => LocalityProjectionAudience.user,
      ),
      state: state.toLocality(),
      includeGeometry: includeGeometry,
      includeAttribution: includeAttribution,
      includePrediction: includePrediction,
    );
  }
}
