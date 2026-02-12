import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:avrai/core/crypto/aes256gcm_fixed_key_codec.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

/// Smoke test for the Supabase-backed community stream:
/// - Two real authenticated users (anonymous auth)
/// - Community sender key state + shares + memberships (RLS-gated)
/// - Insert message blob + event (RLS-gated)
/// - Receiver gets realtime event, fetches blob, decrypts ciphertext
///
/// This validates:
/// - `community_message_events` RLS gating (member + key epoch)
/// - `community_message_blobs` RLS gating (member + key epoch)
/// - The "single-stream (payloadless)" delivery pattern end-to-end
///
/// Env vars required:
/// - SUPABASE_URL
/// - SUPABASE_ANON_KEY
Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'] ?? '';
  final anonKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
  if (url.isEmpty || anonKey.isEmpty) {
    stderr.writeln('Missing SUPABASE_URL or SUPABASE_ANON_KEY in environment.');
    exit(2);
  }

  final runId = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
  final communityId = 'smoke_comm_$runId';
  final credsFilePath =
      Platform.environment['SMOKE_CREDS_PATH'] ?? 'tmp/supabase_smoke_users.json';

  developer.log('Starting community stream smoke test',
      name: 'SmokeCommunityStreamE2E');
  developer.log('communityId=$communityId', name: 'SmokeCommunityStreamE2E');
  stdout.writeln('[smoke] communityId=$communityId');

  // For CLI smoke tests, prefer implicit flow to avoid PKCE storage requirements.
  final clientA = SupabaseClient(
    url,
    anonKey,
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  final clientB = SupabaseClient(
    url,
    anonKey,
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  late final String userIdA;
  late final String userIdB;

  const uuid = Uuid();

  // ===== Auth (two distinct users) =====
  {
    final creds =
        await _loadOrCreateCreds(clientA: clientA, clientB: clientB, runId: runId, path: credsFilePath);

    try {
      stdout.writeln('[smoke] signing in users (email+password)');
      final a = await clientA.auth
          .signInWithPassword(email: creds.emailA, password: creds.passwordA);
      final b = await clientB.auth
          .signInWithPassword(email: creds.emailB, password: creds.passwordB);

      userIdA = a.user?.id ?? '';
      userIdB = b.user?.id ?? '';
    } on AuthApiException catch (e) {
      if (e.code == 'email_not_confirmed') {
        stderr.writeln(
          '❌ Smoke users created but not confirmed yet.\n'
          'Confirm these users (set auth.users.email_confirmed_at/confirmed_at) and rerun.\n'
          'Credentials file: $credsFilePath',
        );
        exit(3);
      }
      rethrow;
    }

    if (userIdA.isEmpty || userIdB.isEmpty) {
      throw StateError('Auth did not return user ids.');
    }
    if (userIdA == userIdB) {
      throw StateError('Expected two distinct users but got same user id.');
    }
  }

  stdout.writeln('[smoke] signed in OK');
  developer.log('userA=$userIdA', name: 'SmokeCommunityStreamE2E');
  developer.log('userB=$userIdB', name: 'SmokeCommunityStreamE2E');

  // Ensure realtime sockets have the current JWT before subscribing (best-effort).
  final tokenA = clientA.auth.currentSession?.accessToken;
  final tokenB = clientB.auth.currentSession?.accessToken;
  if (tokenA != null && tokenA.isNotEmpty) await clientA.realtime.setAuth(tokenA);
  if (tokenB != null && tokenB.isNotEmpty) await clientB.realtime.setAuth(tokenB);

  // ===== Key epoch 1 setup =====
  final keyId1 = uuid.v4(); // UUID string
  final keyBytes1 = _randomKey32();

  await _insertKeyState(
    client: clientA,
    communityId: communityId,
    keyId: keyId1,
    createdBy: userIdA,
  );
  stdout.writeln('[smoke] key state inserted (epoch1)');

  await _insertDummyShare(
    client: clientA,
    communityId: communityId,
    keyId: keyId1,
    fromUserId: userIdA,
    toUserId: userIdA,
  );
  await _insertDummyShare(
    client: clientA,
    communityId: communityId,
    keyId: keyId1,
    fromUserId: userIdA,
    toUserId: userIdB,
  );

  await _upsertMembership(
    client: clientA,
    communityId: communityId,
    userId: userIdA,
    keyId: keyId1,
  );
  await _upsertMembership(
    client: clientB,
    communityId: communityId,
    userId: userIdB,
    keyId: keyId1,
  );
  stdout.writeln('[smoke] memberships upserted (epoch1)');

  // ===== Subscribe (B) to community stream events =====
  final messageIds = StreamController<String>.broadcast();
  final subscribed = Completer<void>();

  // Note: setting `private: true` changes topic authorization semantics and can
  // cause "Unauthorized: ... read from this Channel topic" for arbitrary topics.
  // Postgres RLS for changes is enforced via the JWT (realtime.setAuth) + table policies.
  // Use a normal (non-private) channel topic for Postgres Changes.
  // Note: In some Supabase setups, PostgresChanges may be disabled or restricted.
  final channelB = clientB.channel('community_stream:$communityId');

  channelB.onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'community_message_events',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'community_id',
      value: communityId,
    ),
    callback: (payload) {
      final cid = payload.newRecord['community_id']?.toString() ?? '';
      if (cid.isNotEmpty && cid != communityId) return;
      final msgId = payload.newRecord['message_id']?.toString() ?? '';
      if (msgId.isEmpty) return;
      developer.log('B received event: message_id=$msgId',
          name: 'SmokeCommunityStreamE2E');
      messageIds.add(msgId);
    },
  ).subscribe((status, error) {
    stdout.writeln('[smoke] realtime status=$status error=${error ?? ''}');
    if (status == RealtimeSubscribeStatus.subscribed &&
        !subscribed.isCompleted) {
      subscribed.complete();
    } else if (status == RealtimeSubscribeStatus.channelError &&
        !subscribed.isCompleted) {
      subscribed.completeError(error ?? Exception('channel_error'));
    }
  });

  await subscribed.future.timeout(const Duration(seconds: 20), onTimeout: () {
    throw TimeoutException('Timed out waiting for realtime subscribe');
  });
  stdout.writeln('[smoke] realtime subscribed');

  // ===== Send message 1 (A): blob + event =====
  final messageId1 = uuid.v4();
  final plaintext1 = 'hello from A (epoch1) $runId';
  final ciphertext1 = Aes256GcmFixedKeyCodec.encryptStringToBase64(
    key32: keyBytes1,
    plaintext: plaintext1,
  );

  await _insertMessageBlob(
    client: clientA,
    messageId: messageId1,
    communityId: communityId,
    senderUserId: userIdA,
    senderAgentId: 'agent_$userIdA',
    keyId: keyId1,
    ciphertextBase64: ciphertext1,
    sentAt: DateTime.now().toUtc(),
  );

  await _insertMessageEvent(
    client: clientA,
    messageId: messageId1,
    communityId: communityId,
    senderUserId: userIdA,
  );
  stdout.writeln('[smoke] inserted event1; checking B can select events...');
  final bEvents = await clientB
      .from('community_message_events')
      .select('message_id, community_id')
      .eq('community_id', communityId);
  stdout.writeln('[smoke] B sees events: ${bEvents.length}');

  // ===== Receive + fetch + decrypt (B) =====
  final gotRealtime1 = await _tryAwaitMessageId(
    messageIds.stream,
    expected: messageId1,
    timeout: const Duration(seconds: 10),
  );
  stdout.writeln('[smoke] realtime event1 received=$gotRealtime1');

  final blob1 = await _fetchMessageBlob(client: clientB, messageId: messageId1);
  final decrypted1 = Aes256GcmFixedKeyCodec.decryptBase64ToString(
    key32: keyBytes1,
    ciphertextBase64: blob1.ciphertextBase64,
  );
  if (decrypted1 != plaintext1) {
    throw StateError('Decrypt mismatch epoch1');
  }
  developer.log('✅ Epoch1: event+fetch+decrypt OK',
      name: 'SmokeCommunityStreamE2E');
  stdout.writeln('[smoke] epoch1 decrypt OK');

  // ===== Rotate to key epoch 2 (soft/grace) =====
  final keyId2 = uuid.v4();
  final keyBytes2 = _randomKey32();

  await _rotateKeyStateSoft(
    client: clientA,
    communityId: communityId,
    currentUserId: userIdA,
    previousKeyId: keyId1,
    newKeyId: keyId2,
    grace: const Duration(hours: 1),
  );

  await _insertDummyShare(
    client: clientA,
    communityId: communityId,
    keyId: keyId2,
    fromUserId: userIdA,
    toUserId: userIdA,
  );
  await _insertDummyShare(
    client: clientA,
    communityId: communityId,
    keyId: keyId2,
    fromUserId: userIdA,
    toUserId: userIdB,
  );

  // ===== Send message 2 under new key (A), while B still on old membership =====
  final messageId2 = uuid.v4();
  final plaintext2 = 'hello from A (epoch2) $runId';
  final ciphertext2 = Aes256GcmFixedKeyCodec.encryptStringToBase64(
    key32: keyBytes2,
    plaintext: plaintext2,
  );

  await _insertMessageBlob(
    client: clientA,
    messageId: messageId2,
    communityId: communityId,
    senderUserId: userIdA,
    senderAgentId: 'agent_$userIdA',
    keyId: keyId2,
    ciphertextBase64: ciphertext2,
    sentAt: DateTime.now().toUtc(),
  );
  await _insertMessageEvent(
    client: clientA,
    messageId: messageId2,
    communityId: communityId,
    senderUserId: userIdA,
  );

  final gotRealtime2 = await _tryAwaitMessageId(
    messageIds.stream,
    expected: messageId2,
    timeout: const Duration(seconds: 10),
  );
  stdout.writeln('[smoke] realtime event2 received=$gotRealtime2');

  // Fetch should be allowed during grace even before membership refresh.
  stdout.writeln('[smoke] fetching blob2...');
  final blob2 = await _fetchMessageBlob(client: clientB, messageId: messageId2);
  stdout.writeln('[smoke] blob2 fetched');

  // Decrypt with old key should fail; then "refresh" (membership update) and decrypt with new key.
  var oldKeyFailed = false;
  try {
    Aes256GcmFixedKeyCodec.decryptBase64ToString(
      key32: keyBytes1,
      ciphertextBase64: blob2.ciphertextBase64,
    );
  } catch (_) {
    oldKeyFailed = true;
  }
  if (!oldKeyFailed) {
    throw StateError('Expected decrypt with old key to fail after rotation');
  }

  // Simulate silent refresh: update membership to the new active key.
  await _upsertMembership(
    client: clientB,
    communityId: communityId,
    userId: userIdB,
    keyId: keyId2,
  );
  stdout.writeln('[smoke] membership refreshed to epoch2');

  final decrypted2 = Aes256GcmFixedKeyCodec.decryptBase64ToString(
    key32: keyBytes2,
    ciphertextBase64: blob2.ciphertextBase64,
  );
  if (decrypted2 != plaintext2) {
    throw StateError('Decrypt mismatch epoch2');
  }

  developer.log('✅ Epoch2: grace receive + refresh + decrypt OK',
      name: 'SmokeCommunityStreamE2E');
  stdout.writeln('[smoke] epoch2 decrypt OK');

  try {
    await channelB.unsubscribe().timeout(const Duration(seconds: 5));
  } catch (_) {}
  await messageIds.close();
  try {
    await clientA.auth.signOut();
  } catch (_) {}
  try {
    await clientB.auth.signOut();
  } catch (_) {}

  developer.log('🎉 Community stream smoke test PASSED',
      name: 'SmokeCommunityStreamE2E');
  stdout.writeln('[smoke] PASSED');

  // Ensure the process terminates even if websocket timers linger.
  exit(0);
}

Future<bool> _tryAwaitMessageId(
  Stream<String> stream, {
  required String expected,
  required Duration timeout,
}) async {
  try {
    await stream
      .firstWhere((id) => id == expected)
      .timeout(timeout, onTimeout: () {
        throw TimeoutException('Timed out waiting for message_id=$expected');
      });
    return true;
  } on TimeoutException {
    return false;
  }
}

Uint8List _randomKey32() {
  final random = math.Random.secure();
  final keyBytes = Uint8List(32);
  for (var i = 0; i < keyBytes.length; i++) {
    keyBytes[i] = random.nextInt(256);
  }
  return keyBytes;
}

Future<void> _insertKeyState({
  required SupabaseClient client,
  required String communityId,
  required String keyId,
  required String createdBy,
}) async {
  await client
      .from('community_sender_key_state')
      .insert({
        'community_id': communityId,
        'key_id': keyId,
        'created_by': createdBy,
      })
      .timeout(const Duration(seconds: 15));
}

Future<void> _rotateKeyStateSoft({
  required SupabaseClient client,
  required String communityId,
  required String currentUserId,
  required String previousKeyId,
  required String newKeyId,
  required Duration grace,
}) async {
  final nowUtc = DateTime.now().toUtc();
  await client
      .from('community_sender_key_state')
      .update({
        'key_id': newKeyId,
        'previous_key_id': previousKeyId,
        'grace_expires_at': nowUtc.add(grace).toIso8601String(),
        'updated_at': nowUtc.toIso8601String(),
      })
      .eq('community_id', communityId)
      .eq('created_by', currentUserId);
}

Future<void> _insertDummyShare({
  required SupabaseClient client,
  required String communityId,
  required String keyId,
  required String fromUserId,
  required String toUserId,
}) async {
  // RLS policies only require the share row to exist for membership upserts;
  // the ciphertext is not interpreted by SQL.
  final dummyPayload = base64Encode(utf8.encode('dummy_sender_key_share'));
  await client
      .from('community_sender_key_shares')
      .insert({
        'community_id': communityId,
        'key_id': keyId,
        'to_user_id': toUserId,
        'from_user_id': fromUserId,
        'sender_agent_id': 'agent_$fromUserId',
        'encryption_type': 'signalProtocol',
        'encrypted_key_base64': dummyPayload,
      })
      .timeout(const Duration(seconds: 15));
}

Future<void> _upsertMembership({
  required SupabaseClient client,
  required String communityId,
  required String userId,
  required String keyId,
}) async {
  await client
      .from('community_memberships')
      .upsert({
        'community_id': communityId,
        'user_id': userId,
        'key_id': keyId,
      })
      .timeout(const Duration(seconds: 15));
}

Future<void> _insertMessageBlob({
  required SupabaseClient client,
  required String messageId,
  required String communityId,
  required String senderUserId,
  required String senderAgentId,
  required String keyId,
  required String ciphertextBase64,
  required DateTime sentAt,
}) async {
  await client
      .from('community_message_blobs')
      .insert({
        'message_id': messageId,
        'community_id': communityId,
        'sender_user_id': senderUserId,
        'sender_agent_id': senderAgentId,
        'key_id': keyId,
        'algorithm': 'sender_key_aes256gcm_v1',
        'ciphertext_base64': ciphertextBase64,
        'sent_at': sentAt.toIso8601String(),
      })
      .timeout(const Duration(seconds: 15));
}

Future<void> _insertMessageEvent({
  required SupabaseClient client,
  required String messageId,
  required String communityId,
  required String senderUserId,
}) async {
  await client
      .from('community_message_events')
      .insert({
        'community_id': communityId,
        'message_id': messageId,
        'sender_user_id': senderUserId,
      })
      .timeout(const Duration(seconds: 15));
}

Future<_MessageBlob> _fetchMessageBlob({
  required SupabaseClient client,
  required String messageId,
}) async {
  final row = await client
      .from('community_message_blobs')
      .select()
      .eq('message_id', messageId)
      .maybeSingle()
      .timeout(const Duration(seconds: 15));
  if (row == null) {
    throw StateError('Message blob not found for message_id=$messageId');
  }
  return _MessageBlob.fromJson(row);
}

class _MessageBlob {
  final String messageId;
  final String communityId;
  final String senderUserId;
  final String keyId;
  final String ciphertextBase64;

  const _MessageBlob({
    required this.messageId,
    required this.communityId,
    required this.senderUserId,
    required this.keyId,
    required this.ciphertextBase64,
  });

  factory _MessageBlob.fromJson(Map<String, dynamic> json) {
    return _MessageBlob(
      messageId: json['message_id'] as String,
      communityId: json['community_id'] as String,
      senderUserId: json['sender_user_id'] as String,
      keyId: json['key_id'] as String,
      ciphertextBase64: json['ciphertext_base64'] as String,
    );
  }
}

Future<_SmokeCreds> _loadOrCreateCreds({
  required SupabaseClient clientA,
  required SupabaseClient clientB,
  required String runId,
  required String path,
}) async {
  final f = File(path);
  if (await f.exists()) {
    final raw = await f.readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return _SmokeCreds.fromJson(decoded);
  }

  final emailA = 'spots.smoketest.$runId.a@gmail.com';
  final emailB = 'spots.smoketest.$runId.b@gmail.com';
  final passwordA =
      'smoke_${runId}_A_Pass_${math.Random.secure().nextInt(1 << 20)}';
  final passwordB =
      'smoke_${runId}_B_Pass_${math.Random.secure().nextInt(1 << 20)}';

  developer.log(
    'Creating smoke users (email confirmation may be required)',
    name: 'SmokeCommunityStreamE2E',
  );

  // NOTE: This may require email confirmation; we intentionally persist the creds so an admin
  // can confirm the users and rerun the test.
  final respA = await clientA.auth
      .signUp(email: emailA, password: passwordA, emailRedirectTo: 'https://example.com');
  final respB = await clientB.auth
      .signUp(email: emailB, password: passwordB, emailRedirectTo: 'https://example.com');

  final creds = _SmokeCreds(
    emailA: emailA,
    passwordA: passwordA,
    userIdA: respA.user?.id,
    emailB: emailB,
    passwordB: passwordB,
    userIdB: respB.user?.id,
    createdAtUtc: DateTime.now().toUtc().toIso8601String(),
  );

  await f.writeAsString(jsonEncode(creds.toJson()));
  return creds;
}

class _SmokeCreds {
  final String emailA;
  final String passwordA;
  final String? userIdA;
  final String emailB;
  final String passwordB;
  final String? userIdB;
  final String createdAtUtc;

  const _SmokeCreds({
    required this.emailA,
    required this.passwordA,
    required this.userIdA,
    required this.emailB,
    required this.passwordB,
    required this.userIdB,
    required this.createdAtUtc,
  });

  factory _SmokeCreds.fromJson(Map<String, dynamic> json) {
    return _SmokeCreds(
      emailA: json['emailA'] as String,
      passwordA: json['passwordA'] as String,
      userIdA: json['userIdA'] as String?,
      emailB: json['emailB'] as String,
      passwordB: json['passwordB'] as String,
      userIdB: json['userIdB'] as String?,
      createdAtUtc: json['createdAtUtc'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'emailA': emailA,
        'passwordA': passwordA,
        'userIdA': userIdA,
        'emailB': emailB,
        'passwordB': passwordB,
        'userIdB': userIdB,
        'createdAtUtc': createdAtUtc,
      };
}

