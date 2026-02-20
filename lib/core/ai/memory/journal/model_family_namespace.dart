enum ModelFamily {
  realityModel,
  universeModel,
  worldModel,
}

enum ModelLocality {
  local,
  federated,
  global,
}

class ModelFamilyNamespaceTag {
  final ModelFamily family;
  final ModelLocality locality;
  final String namespaceVersion;

  const ModelFamilyNamespaceTag({
    required this.family,
    required this.locality,
    this.namespaceVersion = 'v1',
  });

  String get namespacePrefix {
    return '${family.name}.${locality.name}.$namespaceVersion';
  }

  String scopedMemoryKey(String key) {
    final normalized = key.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Memory key cannot be empty.');
    }
    return '$namespacePrefix.memory.$normalized';
  }

  String scopedTelemetryKey(String key) {
    final normalized = key.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(key, 'key', 'Telemetry key cannot be empty.');
    }
    return '$namespacePrefix.telemetry.$normalized';
  }

  Map<String, dynamic> toJson() {
    return {
      'family': family.name,
      'locality': locality.name,
      'namespace_version': namespaceVersion,
    };
  }

  factory ModelFamilyNamespaceTag.fromJson(Map<String, dynamic> json) {
    T parse<T extends Enum>(List<T> values, Object? raw, String field) {
      final name = '$raw';
      return values.firstWhere(
        (value) => value.name == name,
        orElse: () => throw FormatException('Unknown $field "$name".'),
      );
    }

    return ModelFamilyNamespaceTag(
      family: parse(ModelFamily.values, json['family'], 'family'),
      locality: parse(ModelLocality.values, json['locality'], 'locality'),
      namespaceVersion: json['namespace_version'] as String? ?? 'v1',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModelFamilyNamespaceTag &&
        other.family == family &&
        other.locality == locality &&
        other.namespaceVersion == namespaceVersion;
  }

  @override
  int get hashCode => Object.hash(family, locality, namespaceVersion);
}

class ModelFamilyNamespaceRegistry {
  final Set<ModelFamilyNamespaceTag> _allowedTags;

  ModelFamilyNamespaceRegistry({
    Iterable<ModelFamilyNamespaceTag> seedTags = const [],
  }) : _allowedTags = seedTags.toSet();

  void register(ModelFamilyNamespaceTag tag) {
    _allowedTags.add(tag);
  }

  bool isAllowed({
    required ModelFamily family,
    required ModelLocality locality,
    String namespaceVersion = 'v1',
  }) {
    return _allowedTags.contains(
      ModelFamilyNamespaceTag(
        family: family,
        locality: locality,
        namespaceVersion: namespaceVersion,
      ),
    );
  }

  String scopedMemoryKey({
    required ModelFamily family,
    required ModelLocality locality,
    required String key,
    String namespaceVersion = 'v1',
  }) {
    final tag = ModelFamilyNamespaceTag(
      family: family,
      locality: locality,
      namespaceVersion: namespaceVersion,
    );
    if (!_allowedTags.contains(tag)) {
      throw StateError(
        'Namespace ${tag.namespacePrefix} is not registered.',
      );
    }
    return tag.scopedMemoryKey(key);
  }

  String scopedTelemetryKey({
    required ModelFamily family,
    required ModelLocality locality,
    required String key,
    String namespaceVersion = 'v1',
  }) {
    final tag = ModelFamilyNamespaceTag(
      family: family,
      locality: locality,
      namespaceVersion: namespaceVersion,
    );
    if (!_allowedTags.contains(tag)) {
      throw StateError(
        'Namespace ${tag.namespacePrefix} is not registered.',
      );
    }
    return tag.scopedTelemetryKey(key);
  }
}
