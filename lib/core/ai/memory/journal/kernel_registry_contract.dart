enum KernelKind {
  purpose,
  safety,
  truth,
  recovery,
  learning,
  exploration,
  federation,
  resource,
  humanOverride,
}

class KernelManifest {
  final String kernelId;
  final KernelKind kind;
  final String version;
  final String signature;
  final DateTime issuedAt;
  final DateTime validUntil;
  final Map<String, Object?> policy;

  const KernelManifest({
    required this.kernelId,
    required this.kind,
    required this.version,
    required this.signature,
    required this.issuedAt,
    required this.validUntil,
    this.policy = const {},
  });

  bool get isSigned => signature.trim().isNotEmpty;

  bool isValidAt(DateTime when) {
    final at = when.toUtc();
    return isSigned &&
        !at.isBefore(issuedAt.toUtc()) &&
        at.isBefore(validUntil.toUtc());
  }
}

class KernelRegistryContract {
  final Map<KernelKind, KernelManifest> _manifests = {};

  void register(KernelManifest manifest) {
    if (!manifest.isSigned) {
      throw ArgumentError('Kernel manifest must be signed');
    }
    if (!manifest.validUntil.isAfter(manifest.issuedAt)) {
      throw ArgumentError('Kernel manifest validity window is invalid');
    }
    _manifests[manifest.kind] = manifest;
  }

  KernelManifest read(KernelKind kind, {DateTime? now}) {
    final manifest = _manifests[kind];
    if (manifest == null) {
      throw StateError('Kernel manifest not registered: $kind');
    }

    final at = now ?? DateTime.now().toUtc();
    if (!manifest.isValidAt(at)) {
      throw StateError('Kernel manifest not valid at requested time: $kind');
    }

    return manifest;
  }

  Map<KernelKind, KernelManifest> snapshot({DateTime? now}) {
    final at = now ?? DateTime.now().toUtc();
    final valid = <KernelKind, KernelManifest>{};
    _manifests.forEach((kind, manifest) {
      if (manifest.isValidAt(at)) {
        valid[kind] = manifest;
      }
    });
    return Map<KernelKind, KernelManifest>.unmodifiable(valid);
  }
}
