import 'package:equatable/equatable.dart';

enum LocalityTokenKind {
  geohashCell,
  learnedCluster,
  cityPrior,
  syntheticBootstrap,
  namedLocalityOverlay,
}

class LocalityToken extends Equatable {
  final LocalityTokenKind kind;
  final String id;
  final int? precision;
  final String? alias;

  const LocalityToken({
    required this.kind,
    required this.id,
    this.precision,
    this.alias,
  });

  factory LocalityToken.geohashCell({
    required String stableKey,
    required int precision,
    String? alias,
  }) {
    return LocalityToken(
      kind: LocalityTokenKind.geohashCell,
      id: stableKey,
      precision: precision,
      alias: alias,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'id': id,
        if (precision != null) 'precision': precision,
        if (alias != null) 'alias': alias,
      };

  factory LocalityToken.fromJson(Map<String, dynamic> json) {
    final kindName =
        (json['kind'] ?? LocalityTokenKind.geohashCell.name).toString();
    return LocalityToken(
      kind: LocalityTokenKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => LocalityTokenKind.geohashCell,
      ),
      id: (json['id'] ?? '').toString(),
      precision: (json['precision'] as num?)?.toInt(),
      alias: (json['alias'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['alias'] as String?,
    );
  }

  @override
  List<Object?> get props => [kind, id, precision, alias];
}
