import 'dart:async';

import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_policy.dart';

class MeshSegmentCredentialRefreshService {
  MeshSegmentCredentialRefreshService({
    StorageService? storageService,
    MeshSegmentRevocationPolicy? revocationPolicy,
    DateTime Function()? nowUtc,
  })  : _revocationPolicy = revocationPolicy,
        _storageService = storageService,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  static const String _credentialsStorageKey =
      'mesh_segment_credentials_inventory_v1';
  static const String _attestationsStorageKey =
      'mesh_segment_attestations_inventory_v1';

  final MeshSegmentRevocationPolicy? _revocationPolicy;
  final StorageService? _storageService;
  final DateTime Function() _nowUtc;
  final Map<String, MeshSegmentCredential> _credentials =
      <String, MeshSegmentCredential>{};
  final Map<String, MeshAnnounceAttestation> _attestations =
      <String, MeshAnnounceAttestation>{};

  void recordIssued({
    MeshSegmentCredential? credential,
    MeshAnnounceAttestation? attestation,
  }) {
    final credentials = _readCredentials();
    final attestations = _readAttestations();
    if (credential != null) {
      credentials[credential.credentialId] = credential;
    }
    if (attestation != null) {
      attestations[attestation.attestationId] = attestation;
    }
    _writeState(credentials: credentials, attestations: attestations);
  }

  int activeCredentialCount({DateTime? nowUtc}) {
    final now = nowUtc?.toUtc() ?? _nowUtc();
    return _readCredentials()
        .values
        .where(
          (entry) =>
              entry.isValidAt(now) &&
              !(_revocationPolicy?.isCredentialRevoked(entry) ?? false),
        )
        .length;
  }

  int expiringSoonCredentialCount({
    Duration threshold = const Duration(minutes: 30),
    DateTime? nowUtc,
  }) {
    final now = nowUtc?.toUtc() ?? _nowUtc();
    return _readCredentials()
        .values
        .where(
          (entry) =>
              entry.expiresAtUtc.isAfter(now) &&
              entry.expiresAtUtc.difference(now) <= threshold &&
              !(_revocationPolicy?.isCredentialRevoked(entry) ?? false),
        )
        .length;
  }

  List<MeshSegmentCredential> allCredentials() {
    final credentials = _readCredentials().values.toList(growable: false)
      ..sort((left, right) => left.credentialId.compareTo(right.credentialId));
    return credentials;
  }

  List<MeshAnnounceAttestation> allAttestations() {
    final attestations = _readAttestations().values.toList(growable: false)
      ..sort(
          (left, right) => left.attestationId.compareTo(right.attestationId));
    return attestations;
  }

  Future<int> refreshExpiringCredentials({
    required MeshSegmentCredential Function(MeshSegmentCredential credential)
        renew,
    Duration threshold = const Duration(minutes: 30),
    DateTime? nowUtc,
  }) async {
    final now = nowUtc?.toUtc() ?? _nowUtc();
    final credentials = _readCredentials();
    final attestations = _readAttestations();
    var refreshed = 0;
    for (final credential in credentials.values.toList(growable: false)) {
      if (_revocationPolicy?.isCredentialRevoked(credential) ?? false) {
        continue;
      }
      if (!credential.expiresAtUtc.isAfter(now)) {
        continue;
      }
      if (credential.expiresAtUtc.difference(now) > threshold) {
        continue;
      }
      credentials[credential.credentialId] = renew(credential);
      refreshed += 1;
    }
    _writeState(credentials: credentials, attestations: attestations);
    return refreshed;
  }

  Future<int> refreshExpiringTrustMaterial({
    Duration threshold = const Duration(minutes: 30),
    DateTime? nowUtc,
  }) async {
    final now = nowUtc?.toUtc() ?? _nowUtc();
    final credentials = _readCredentials();
    final attestations = _readAttestations();
    final refreshedCredentialIds = <String>{};
    var refreshed = 0;

    for (final credential in credentials.values.toList(growable: false)) {
      if (_revocationPolicy?.isCredentialRevoked(credential) ?? false) {
        continue;
      }
      if (!credential.expiresAtUtc.isAfter(now)) {
        continue;
      }
      if (credential.expiresAtUtc.difference(now) > threshold) {
        continue;
      }
      credentials[credential.credentialId] = MeshSegmentCredential(
        credentialId: credential.credentialId,
        segmentProfileId: credential.segmentProfileId,
        principalId: credential.principalId,
        principalKind: credential.principalKind,
        issuedAtUtc: now,
        expiresAtUtc: now.add(const Duration(hours: 2)),
        confidence: credential.confidence,
        freshness: credential.freshness,
      );
      refreshedCredentialIds.add(credential.credentialId);
      refreshed += 1;
    }

    for (final attestation in attestations.values.toList(growable: false)) {
      if (_revocationPolicy?.isAttestationRevoked(attestation) ?? false) {
        continue;
      }
      final shouldRefresh =
          refreshedCredentialIds.contains(attestation.credentialId) ||
              (attestation.expiresAtUtc.isAfter(now) &&
                  attestation.expiresAtUtc.difference(now) <= threshold);
      if (!shouldRefresh) {
        continue;
      }
      attestations[attestation.attestationId] = MeshAnnounceAttestation(
        attestationId: attestation.attestationId,
        segmentProfileId: attestation.segmentProfileId,
        credentialId: attestation.credentialId,
        signerEntityId: attestation.signerEntityId,
        signerEntityKind: attestation.signerEntityKind,
        signedAtUtc: now,
        expiresAtUtc: now.add(const Duration(hours: 2)),
        confidence: attestation.confidence,
        freshness: attestation.freshness,
      );
    }

    _writeState(credentials: credentials, attestations: attestations);
    return refreshed;
  }

  Map<String, MeshSegmentCredential> _readCredentials() {
    final storage = _storageService;
    if (storage != null) {
      try {
        final raw = storage.getObject<Map<dynamic, dynamic>>(
          _credentialsStorageKey,
          box: 'spots_ai',
        );
        if (raw != null) {
          return raw.map(
            (key, value) => MapEntry(
              key.toString(),
              MeshSegmentCredential.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            ),
          );
        }
      } on StateError {
        // Fall back to in-memory inventory until StorageService is initialized.
      }
    }
    return Map<String, MeshSegmentCredential>.from(_credentials);
  }

  Map<String, MeshAnnounceAttestation> _readAttestations() {
    final storage = _storageService;
    if (storage != null) {
      try {
        final raw = storage.getObject<Map<dynamic, dynamic>>(
          _attestationsStorageKey,
          box: 'spots_ai',
        );
        if (raw != null) {
          return raw.map(
            (key, value) => MapEntry(
              key.toString(),
              MeshAnnounceAttestation.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            ),
          );
        }
      } on StateError {
        // Fall back to in-memory inventory until StorageService is initialized.
      }
    }
    return Map<String, MeshAnnounceAttestation>.from(_attestations);
  }

  void _writeState({
    required Map<String, MeshSegmentCredential> credentials,
    required Map<String, MeshAnnounceAttestation> attestations,
  }) {
    _credentials
      ..clear()
      ..addAll(credentials);
    _attestations
      ..clear()
      ..addAll(attestations);
    final storage = _storageService;
    if (storage == null) {
      return;
    }
    try {
      unawaited(storage.setObject(
        _credentialsStorageKey,
        credentials.map((key, value) => MapEntry(key, value.toJson())),
        box: 'spots_ai',
      ));
      unawaited(storage.setObject(
        _attestationsStorageKey,
        attestations.map((key, value) => MapEntry(key, value.toJson())),
        box: 'spots_ai',
      ));
    } on StateError {
      // Fall back to in-memory inventory until StorageService is initialized.
    }
  }
}
