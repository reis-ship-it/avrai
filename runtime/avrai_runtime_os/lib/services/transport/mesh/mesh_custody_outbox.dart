import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_payload_protection_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';

class MeshCustodyOutboxEntry {
  const MeshCustodyOutboxEntry({
    required this.entryId,
    required this.receiptId,
    required this.destinationId,
    required this.payloadKind,
    required this.channel,
    required this.queuedAtUtc,
    required this.nextAttemptAtUtc,
    this.geographicScope,
    this.attemptCount = 0,
    this.lastAttemptAtUtc,
    this.lastFailureReason,
    this.sourceRouteReceiptJson,
    this.payload,
    this.payloadContext,
    this.encryptedPayloadBlob,
    this.encryptionKeyId,
    this.encryptionAlgorithm,
    this.encryptionVersion,
  });

  final String entryId;
  final String receiptId;
  final String destinationId;
  final String payloadKind;
  final String channel;
  final String? geographicScope;
  final DateTime queuedAtUtc;
  final DateTime nextAttemptAtUtc;
  final int attemptCount;
  final DateTime? lastAttemptAtUtc;
  final String? lastFailureReason;
  final Map<String, dynamic>? sourceRouteReceiptJson;
  final Map<String, dynamic>? payload;
  final Map<String, dynamic>? payloadContext;
  final String? encryptedPayloadBlob;
  final String? encryptionKeyId;
  final String? encryptionAlgorithm;
  final int? encryptionVersion;

  bool get hasEncryptedPayload =>
      encryptedPayloadBlob != null && encryptedPayloadBlob!.isNotEmpty;

  bool get hasLegacyPayload => payload != null || payloadContext != null;

  MeshCustodyOutboxEntry copyWith({
    DateTime? nextAttemptAtUtc,
    int? attemptCount,
    DateTime? lastAttemptAtUtc,
    String? lastFailureReason,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? payloadContext,
    String? encryptedPayloadBlob,
    String? encryptionKeyId,
    String? encryptionAlgorithm,
    int? encryptionVersion,
  }) {
    return MeshCustodyOutboxEntry(
      entryId: entryId,
      receiptId: receiptId,
      destinationId: destinationId,
      payloadKind: payloadKind,
      channel: channel,
      geographicScope: geographicScope,
      queuedAtUtc: queuedAtUtc,
      nextAttemptAtUtc: nextAttemptAtUtc ?? this.nextAttemptAtUtc,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAtUtc: lastAttemptAtUtc ?? this.lastAttemptAtUtc,
      lastFailureReason: lastFailureReason ?? this.lastFailureReason,
      sourceRouteReceiptJson: sourceRouteReceiptJson,
      payload: payload ?? this.payload,
      payloadContext: payloadContext ?? this.payloadContext,
      encryptedPayloadBlob: encryptedPayloadBlob ?? this.encryptedPayloadBlob,
      encryptionKeyId: encryptionKeyId ?? this.encryptionKeyId,
      encryptionAlgorithm: encryptionAlgorithm ?? this.encryptionAlgorithm,
      encryptionVersion: encryptionVersion ?? this.encryptionVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'entry_id': entryId,
      'receipt_id': receiptId,
      'destination_id': destinationId,
      'payload_kind': payloadKind,
      'channel': channel,
      'geographic_scope': geographicScope,
      'queued_at_utc': queuedAtUtc.toUtc().toIso8601String(),
      'next_attempt_at_utc': nextAttemptAtUtc.toUtc().toIso8601String(),
      'attempt_count': attemptCount,
      'last_attempt_at_utc': lastAttemptAtUtc?.toUtc().toIso8601String(),
      'last_failure_reason': lastFailureReason,
      'source_route_receipt': sourceRouteReceiptJson,
      if (encryptedPayloadBlob != null)
        'encrypted_payload_blob': encryptedPayloadBlob,
      if (encryptionKeyId != null) 'encryption_key_id': encryptionKeyId,
      if (encryptionAlgorithm != null)
        'encryption_algorithm': encryptionAlgorithm,
      if (encryptionVersion != null) 'encryption_version': encryptionVersion,
      if (!hasEncryptedPayload && payload != null) 'payload': payload,
      if (!hasEncryptedPayload && payloadContext != null)
        'payload_context': payloadContext,
    };
  }

  factory MeshCustodyOutboxEntry.fromJson(Map<String, dynamic> json) {
    return MeshCustodyOutboxEntry(
      entryId: json['entry_id'] as String? ?? 'unknown_outbox_entry',
      receiptId: json['receipt_id'] as String? ?? 'unknown_receipt',
      destinationId: json['destination_id'] as String? ?? 'unknown_destination',
      payloadKind: json['payload_kind'] as String? ?? 'mesh_payload',
      channel: json['channel'] as String? ?? 'mesh_ble_forward',
      geographicScope: json['geographic_scope'] as String?,
      queuedAtUtc: DateTime.tryParse(
            json['queued_at_utc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      nextAttemptAtUtc: DateTime.tryParse(
            json['next_attempt_at_utc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
      lastAttemptAtUtc: DateTime.tryParse(
        json['last_attempt_at_utc'] as String? ?? '',
      )?.toUtc(),
      lastFailureReason: json['last_failure_reason'] as String?,
      sourceRouteReceiptJson: json['source_route_receipt'] is Map
          ? Map<String, dynamic>.from(json['source_route_receipt'] as Map)
          : null,
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
      payloadContext: json['payload_context'] is Map
          ? Map<String, dynamic>.from(json['payload_context'] as Map)
          : null,
      encryptedPayloadBlob: json['encrypted_payload_blob'] as String?,
      encryptionKeyId: json['encryption_key_id'] as String?,
      encryptionAlgorithm: json['encryption_algorithm'] as String?,
      encryptionVersion: (json['encryption_version'] as num?)?.toInt(),
    );
  }
}

class MeshCustodyMaterializedEntry {
  const MeshCustodyMaterializedEntry({
    required this.entry,
    required this.payload,
    required this.payloadContext,
  });

  final MeshCustodyOutboxEntry entry;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> payloadContext;
}

class MeshCustodyOutbox {
  MeshCustodyOutbox({
    MeshRuntimeStateStore? store,
    MeshCustodyPayloadProtectionService? payloadProtectionService,
    DateTime Function()? nowUtc,
    Duration defaultRetryBackoff = const Duration(minutes: 2),
  })  : _store = store ?? GetStorageMeshRuntimeStateStore(),
        _payloadProtectionService =
            payloadProtectionService ?? MeshCustodyPayloadProtectionService(),
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
        _defaultRetryBackoff = defaultRetryBackoff;

  static const String _entriesKey = 'mesh_custody_outbox_entries_v1';

  final MeshRuntimeStateStore _store;
  final MeshCustodyPayloadProtectionService _payloadProtectionService;
  final DateTime Function() _nowUtc;
  final Duration _defaultRetryBackoff;

  List<MeshCustodyOutboxEntry> allEntries() => _readEntries();

  int pendingCount({
    String? destinationId,
    String? payloadKind,
  }) {
    return _readEntries()
        .where(
          (entry) =>
              (destinationId == null || entry.destinationId == destinationId) &&
              (payloadKind == null || entry.payloadKind == payloadKind),
        )
        .length;
  }

  List<MeshCustodyOutboxEntry> dueEntries({
    String? destinationId,
    String? payloadKind,
    DateTime? nowUtc,
    int limit = 10,
  }) {
    final now = nowUtc ?? _nowUtc();
    final entries = _readEntries()
        .where((entry) =>
            entry.nextAttemptAtUtc.isBefore(now) ||
            entry.nextAttemptAtUtc.isAtSameMomentAs(now))
        .where(
          (entry) =>
              (destinationId == null || entry.destinationId == destinationId) &&
              (payloadKind == null || entry.payloadKind == payloadKind),
        )
        .toList()
      ..sort((left, right) => left.queuedAtUtc.compareTo(right.queuedAtUtc));
    return entries.take(limit).toList();
  }

  Future<MeshCustodyOutboxEntry> enqueue({
    required String receiptId,
    required String destinationId,
    required String payloadKind,
    required String channel,
    required Map<String, dynamic> payload,
    required Map<String, dynamic> payloadContext,
    TransportRouteReceipt? sourceRouteReceipt,
    String? geographicScope,
    DateTime? nowUtc,
    Duration? retryBackoff,
  }) async {
    final now = nowUtc ?? _nowUtc();
    final entries = _readEntries();
    final existingIndex =
        entries.indexWhere((entry) => entry.receiptId == receiptId);
    final entryId = existingIndex >= 0
        ? entries[existingIndex].entryId
        : 'mesh-custody-${now.microsecondsSinceEpoch}';
    final sealedPayload = await _payloadProtectionService.seal(
      entryId: entryId,
      payload: payload,
      payloadContext: payloadContext,
    );
    final entry = MeshCustodyOutboxEntry(
      entryId: entryId,
      receiptId: receiptId,
      destinationId: destinationId,
      payloadKind: payloadKind,
      channel: channel,
      geographicScope: geographicScope,
      queuedAtUtc:
          existingIndex >= 0 ? entries[existingIndex].queuedAtUtc : now,
      nextAttemptAtUtc: now.add(retryBackoff ?? _defaultRetryBackoff),
      attemptCount:
          existingIndex >= 0 ? entries[existingIndex].attemptCount : 0,
      lastAttemptAtUtc:
          existingIndex >= 0 ? entries[existingIndex].lastAttemptAtUtc : null,
      lastFailureReason:
          existingIndex >= 0 ? entries[existingIndex].lastFailureReason : null,
      sourceRouteReceiptJson: sourceRouteReceipt?.toJson() ??
          (existingIndex >= 0
              ? entries[existingIndex].sourceRouteReceiptJson
              : null),
      encryptedPayloadBlob: sealedPayload.encryptedBlob,
      encryptionKeyId: sealedPayload.encryptionKeyId,
      encryptionAlgorithm: sealedPayload.algorithm,
      encryptionVersion: sealedPayload.version,
    );

    if (existingIndex >= 0) {
      entries[existingIndex] = entry;
    } else {
      entries.add(entry);
    }
    await _writeEntries(entries);
    return entry;
  }

  Future<MeshCustodyMaterializedEntry> materialize(
    MeshCustodyOutboxEntry entry,
  ) async {
    if (entry.hasEncryptedPayload) {
      final opened = await _payloadProtectionService.open(
        entryId: entry.entryId,
        encryptedBlob: entry.encryptedPayloadBlob!,
        encryptionKeyId: entry.encryptionKeyId,
      );
      return MeshCustodyMaterializedEntry(
        entry: entry,
        payload: opened.payload,
        payloadContext: opened.payloadContext,
      );
    }

    final payload = Map<String, dynamic>.from(
      entry.payload ?? const <String, dynamic>{},
    );
    final payloadContext = Map<String, dynamic>.from(
      entry.payloadContext ?? const <String, dynamic>{},
    );
    if (payload.isEmpty && payloadContext.isEmpty) {
      throw StateError(
        'Mesh custody entry ${entry.entryId} has no payload to materialize',
      );
    }

    await _migrateLegacyPayload(
      entry: entry,
      payload: payload,
      payloadContext: payloadContext,
    );
    return MeshCustodyMaterializedEntry(
      entry: entry,
      payload: payload,
      payloadContext: payloadContext,
    );
  }

  Future<void> markRetry({
    required String entryId,
    String? reason,
    Duration? backoff,
    DateTime? nowUtc,
  }) async {
    final now = nowUtc ?? _nowUtc();
    final entries = _readEntries();
    final index = entries.indexWhere((entry) => entry.entryId == entryId);
    if (index < 0) {
      return;
    }
    final entry = entries[index];
    entries[index] = entry.copyWith(
      attemptCount: entry.attemptCount + 1,
      lastAttemptAtUtc: now,
      lastFailureReason: reason ?? entry.lastFailureReason,
      nextAttemptAtUtc: now.add(backoff ?? _defaultRetryBackoff),
    );
    await _writeEntries(entries);
  }

  Future<void> markReleased(String entryId) async {
    final entries = _readEntries()
      ..removeWhere((entry) => entry.entryId == entryId);
    await _writeEntries(entries);
  }

  Future<void> _migrateLegacyPayload({
    required MeshCustodyOutboxEntry entry,
    required Map<String, dynamic> payload,
    required Map<String, dynamic> payloadContext,
  }) async {
    if (entry.hasEncryptedPayload) {
      return;
    }

    final sealedPayload = await _payloadProtectionService.seal(
      entryId: entry.entryId,
      payload: payload,
      payloadContext: payloadContext,
    );
    final entries = _readEntries();
    final index = entries.indexWhere(
      (candidate) => candidate.entryId == entry.entryId,
    );
    if (index < 0) {
      return;
    }

    entries[index] = entries[index].copyWith(
      payload: const <String, dynamic>{},
      payloadContext: const <String, dynamic>{},
      encryptedPayloadBlob: sealedPayload.encryptedBlob,
      encryptionKeyId: sealedPayload.encryptionKeyId,
      encryptionAlgorithm: sealedPayload.algorithm,
      encryptionVersion: sealedPayload.version,
    );
    await _writeEntries(entries);
  }

  List<MeshCustodyOutboxEntry> _readEntries() {
    return (_store.read<List<dynamic>>(_entriesKey) ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (entry) => MeshCustodyOutboxEntry.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
  }

  Future<void> _writeEntries(List<MeshCustodyOutboxEntry> entries) {
    return _store.write(
      _entriesKey,
      entries.map((entry) => entry.toJson()).toList(),
    );
  }
}
