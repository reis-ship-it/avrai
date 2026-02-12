import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_event_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_op_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipt_signature_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipt_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_receipt_verifier_v0.dart';

void main() {
  test(
      'LedgerReceiptVerifierV0 canonicalization is stable across map key order',
      () async {
    final ed = Ed25519();
    final seed = List<int>.generate(32, (i) => i);
    final kp = await ed.newKeyPairFromSeed(seed);
    final pk = await kp.extractPublicKey();

    final verifier = LedgerReceiptVerifierV0(
      publicKeysB64Override: <String, String>{
        'v1': base64Encode(pk.bytes),
      },
    );

    LedgerReceiptV0 makeReceiptWithPayload(Map<String, Object?> payload) {
      final e = LedgerEventV0(
        id: 'row_1',
        domain: LedgerDomainV0.security,
        ownerUserId: 'user_1',
        ownerAgentId: 'agent_1',
        logicalId: 'logical_1',
        revision: 0,
        supersedesId: null,
        op: LedgerOpV0.assert_,
        eventType: 'debug_smoke_test',
        entityType: 'debug',
        entityId: 'debug_1',
        category: null,
        cityCode: null,
        localityCode: null,
        occurredAt: DateTime.utc(2026, 1, 2, 12, 0, 0, 123),
        atomicTimestampId: null,
        payload: payload,
        createdAt: DateTime.utc(2026, 1, 2, 12, 0, 1, 456),
      );
      return LedgerReceiptV0(event: e, signature: null);
    }

    final r1 = makeReceiptWithPayload(<String, Object?>{'b': 1, 'a': 2});
    final r2 = makeReceiptWithPayload(<String, Object?>{'a': 2, 'b': 1});

    expect(verifier.canonicalJsonForEvent(r1),
        equals(verifier.canonicalJsonForEvent(r2)));
  });

  test(
      'LedgerReceiptVerifierV0 unsigned → signed_existing → verified; mutation fails',
      () async {
    final ed = Ed25519();
    final seed = List<int>.generate(32, (i) => 255 - i);
    final kp = await ed.newKeyPairFromSeed(seed);
    final pk = await kp.extractPublicKey();

    final verifier = LedgerReceiptVerifierV0(
      publicKeysB64Override: <String, String>{
        'v1': base64Encode(pk.bytes),
      },
    );

    final event = LedgerEventV0(
      id: 'row_2',
      domain: LedgerDomainV0.expertise,
      ownerUserId: 'user_2',
      ownerAgentId: 'agent_2',
      logicalId: 'logical_2',
      revision: 0,
      supersedesId: null,
      op: LedgerOpV0.assert_,
      eventType: 'expert_event_created',
      entityType: 'event',
      entityId: 'event_123',
      category: 'Coffee',
      cityCode: 'NYC',
      localityCode: 'manhattan',
      occurredAt: DateTime.utc(2026, 1, 2, 10, 30, 0, 0),
      atomicTimestampId: null,
      payload: <String, Object?>{
        'source': 'client',
        'notes': 'hello',
        'nested': <String, Object?>{'z': 1, 'a': 2},
      },
      createdAt: DateTime.utc(2026, 1, 2, 10, 30, 5, 0),
    );

    final unsigned = LedgerReceiptV0(event: event, signature: null);
    expect(await verifier.verify(unsigned), isFalse);

    // Simulate edge function `sign_existing` by signing the canonical JSON.
    final canonicalJson = verifier.canonicalJsonForEvent(unsigned);
    final sig = await ed.sign(
      utf8.encode(canonicalJson),
      keyPair: kp,
    );

    final sha256Hex = sha256.convert(utf8.encode(canonicalJson)).toString();
    final signature = LedgerReceiptSignatureV0(
      ledgerRowId: event.id!,
      schemaVersion: 0,
      canonAlgo: 'v0_sorted_keys_json',
      canonicalJson: canonicalJson,
      sha256: sha256Hex,
      signatureB64: base64Encode(sig.bytes),
      keyId: 'v1',
      signedAt: DateTime.utc(2026, 1, 2, 10, 30, 6),
    );

    final signed = LedgerReceiptV0(event: event, signature: signature);
    expect(await verifier.verify(signed), isTrue);

    // Mutating the ledger row breaks verification.
    final mutatedEvent = LedgerEventV0(
      id: event.id,
      domain: event.domain,
      ownerUserId: event.ownerUserId,
      ownerAgentId: event.ownerAgentId,
      logicalId: event.logicalId,
      revision: event.revision,
      supersedesId: event.supersedesId,
      op: event.op,
      eventType: event.eventType,
      entityType: event.entityType,
      entityId: event.entityId,
      category: event.category,
      cityCode: event.cityCode,
      localityCode: event.localityCode,
      occurredAt: event.occurredAt,
      atomicTimestampId: event.atomicTimestampId,
      payload: <String, Object?>{
        ...event.payload,
        'notes': 'tampered',
      },
      createdAt: event.createdAt,
    );
    final tampered = LedgerReceiptV0(event: mutatedEvent, signature: signature);
    expect(await verifier.verify(tampered), isFalse);
  });
}
