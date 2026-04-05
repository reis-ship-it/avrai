import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:avrai_runtime_os/crypto/signal/secure_signal_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:avrai_runtime_os/crypto/aes256gcm_fixed_key_codec.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_protocol_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_session_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_types.dart';
import 'package:avrai_runtime_os/services/community/community_message_store.dart';
import 'package:avrai_runtime_os/services/chat/dm_message_store.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/config/supabase_config.dart';

import '../test/mocks/in_memory_flutter_secure_storage.dart';

/// Two-device Signal smoke over the **real DM transport layer**:
/// - `public.dm_transport_blobs` (canonical transport view; recipient-only read via base RLS)
/// - `public.dm_transport_notifications` (canonical transport view; payloadless notify with message_id)
/// - Realtime subscription still listens on `public.dm_notifications` (base table publication).
///
/// This test is intentionally "scripted": it is meant to be run on **two devices**
/// at the same time, each configured as role A or B.
///
/// ## Required defines (per-device)
/// - `SUPABASE_URL`, `SUPABASE_ANON_KEY`
/// - `SIGNAL_SMOKE_RUN_ID` (same value on both devices)
/// - `SIGNAL_SMOKE_ROLE` ("A" or "B")
/// - `SIGNAL_SMOKE_EMAIL`, `SIGNAL_SMOKE_PASSWORD` (credentials for this device)
///
/// ## Optional defines
/// - `SIGNAL_SMOKE_COMMUNITY_ID` (if set, runs a community stream send/receive path)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const runNative =
      bool.fromEnvironment('RUN_SIGNAL_NATIVE_TESTS', defaultValue: false);
  const runId = String.fromEnvironment('SIGNAL_SMOKE_RUN_ID', defaultValue: '');
  const role = String.fromEnvironment('SIGNAL_SMOKE_ROLE', defaultValue: '');
  const email = String.fromEnvironment('SIGNAL_SMOKE_EMAIL', defaultValue: '');
  const password =
      String.fromEnvironment('SIGNAL_SMOKE_PASSWORD', defaultValue: '');
  const communityId =
      String.fromEnvironment('SIGNAL_SMOKE_COMMUNITY_ID', defaultValue: '');

  testWidgets('Signal two-device DM (real transport) smoke', (tester) async {
    if (!runNative) {
      // ignore: avoid_print
      print('Skipping: RUN_SIGNAL_NATIVE_TESTS != true');
      return;
    }
    if (!SupabaseConfig.isValid) {
      // ignore: avoid_print
      print('Skipping: missing SUPABASE_URL / SUPABASE_ANON_KEY');
      return;
    }
    if (runId.isEmpty || (role != 'A' && role != 'B')) {
      // ignore: avoid_print
      print('Skipping: need SIGNAL_SMOKE_RUN_ID and SIGNAL_SMOKE_ROLE=A|B');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      // ignore: avoid_print
      print('Skipping: need SIGNAL_SMOKE_EMAIL and SIGNAL_SMOKE_PASSWORD');
      return;
    }

    await tester.runAsync(() async {
      const uuid = Uuid();

      // 1) Supabase auth (real device session; required for RLS)
      // ignore: avoid_print
      print('🔎 [signal_2dev:$role] Initializing Supabase...');
      try {
        await Supabase.initialize(
            url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
      } catch (_) {
        // It's OK if already initialized in this process.
      }

      final client = Supabase.instance.client;
      SupabaseService.useClientForTests(client);
      final supabaseService = SupabaseService();

      try {
        await client.auth.signOut();
      } catch (_) {}

      await client.auth.signInWithPassword(email: email, password: password);
      final me = client.auth.currentUser;
      if (me == null) {
        throw StateError('Supabase auth failed: currentUser is null');
      }
      final myUserId = me.id;
      // ignore: avoid_print
      print('✅ [signal_2dev:$role] Signed in as userId=$myUserId');

      // Create an explicit DM invite token for this user. Peer can use this
      // token to fetch our prekey bundle when no shared community exists.
      final myInviteToken = (await client.rpc(
        'create_dm_invite_token_v1',
        params: <String, dynamic>{'expires_in_seconds': 3600},
      ))
          .toString();
      if (myInviteToken.isEmpty) {
        throw StateError('Failed to create DM invite token');
      }

      // 2) Rendezvous over broadcast to learn peer userId + confirm prekey publish.
      final rendezvous = client.channel('signal_smoke_rendezvous:$runId');
      final peerUserIdCompleter = Completer<String>();
      final peerInviteTokenCompleter = Completer<String>();
      final peerPrekeyReadyCompleter = Completer<void>();

      rendezvous.onBroadcast(
        event: 'hello',
        callback: (payload, {String? event, String? type, String? timestamp}) {
          try {
            final p = (payload as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final other = p['user_id']?.toString();
            if (other == null || other.isEmpty || other == myUserId) return;
            if (!peerUserIdCompleter.isCompleted) {
              peerUserIdCompleter.complete(other);
            }
            final inviteToken = p['invite_token']?.toString();
            if (inviteToken != null &&
                inviteToken.isNotEmpty &&
                !peerInviteTokenCompleter.isCompleted) {
              peerInviteTokenCompleter.complete(inviteToken);
            }
          } catch (_) {}
        },
      );
      rendezvous.onBroadcast(
        event: 'prekey_ready',
        callback: (payload, {String? event, String? type, String? timestamp}) {
          try {
            final p = (payload as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            final other = p['user_id']?.toString();
            if (other == null || other.isEmpty || other == myUserId) return;
            if (!peerPrekeyReadyCompleter.isCompleted) {
              peerPrekeyReadyCompleter.complete();
            }
          } catch (_) {}
        },
      );
      rendezvous.subscribe();

      final helloTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        try {
          await rendezvous.sendBroadcastMessage(
            event: 'hello',
            payload: <String, dynamic>{
              'run_id': runId,
              'user_id': myUserId,
              'role': role,
              'invite_token': myInviteToken,
              'ts': DateTime.now().toUtc().toIso8601String(),
            },
          );
        } catch (_) {}
      });

      final peerUserId = await peerUserIdCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException(
              'Timed out waiting for peer rendezvous (hello)');
        },
      );
      final peerInviteToken = await peerInviteTokenCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException(
              'Timed out waiting for peer DM invite token in rendezvous hello');
        },
      );
      // ignore: avoid_print
      print('✅ [signal_2dev:$role] Peer discovered userId=$peerUserId');

      // 3) Initialize Signal stack (with real keyserver) - Phase 26: SecureSignalStorage
      // ignore: avoid_print
      print('🔎 [signal_2dev:$role] Initializing Signal stack...');
      final secureStorage = InMemoryFlutterSecureStorage();
      final secureSignalStorage =
          SecureSignalStorage(secureStorage: secureStorage);

      final rustWrapper = SignalRustWrapperBindings();
      await rustWrapper.initialize();

      final ffi = SignalFFIBindings();
      await ffi.initialize();

      final keyManager = SignalKeyManager(
        secureStorage: secureStorage,
        ffiBindings: ffi,
        supabaseService: supabaseService,
      );
      final sessionManager = SignalSessionManager(
        ffiBindings: ffi,
        keyManager: keyManager,
        storage: secureSignalStorage,
      );

      final storeCallbacks = SignalFFIStoreCallbacks(
        keyManager: keyManager,
        sessionManager: sessionManager,
        ffiBindings: ffi,
        rustWrapper: rustWrapper,
        platformBridge: SignalPlatformBridgeBindings(),
      );
      await storeCallbacks.initialize();

      final signal = SignalProtocolService(
        ffiBindings: ffi,
        storeCallbacks: storeCallbacks,
        keyManager: keyManager,
        sessionManager: sessionManager,
      );

      await signal.initialize();
      await keyManager.cacheDmInviteToken(
        targetUserId: peerUserId,
        token: peerInviteToken,
      );
      await signal.uploadPreKeyBundle(myUserId);

      await rendezvous.sendBroadcastMessage(
        event: 'prekey_ready',
        payload: <String, dynamic>{
          'run_id': runId,
          'user_id': myUserId,
          'role': role,
          'ts': DateTime.now().toUtc().toIso8601String(),
        },
      );

      await peerPrekeyReadyCompleter.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Timed out waiting for peer prekey_ready');
        },
      );
      helloTimer.cancel();

      // 4) Subscribe to DM notifications (real payloadless transport)
      final dmStore = DmMessageStore(supabase: supabaseService);
      final dmNotifyChannel =
          client.channel('signal_smoke_dm_notifications:$runId:$myUserId');
      final receivedPlaintext = StreamController<String>.broadcast();
      final dmSubscribed = Completer<void>();

      dmNotifyChannel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'dm_notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'to_user_id',
          value: myUserId,
        ),
        callback: (payload) async {
          try {
            final messageId = payload.newRecord['message_id']?.toString() ?? '';
            if (messageId.isEmpty) return;

            DmMessageBlob? blob;
            for (var attempt = 0; attempt < 10; attempt++) {
              blob = await dmStore.getDmBlob(messageId);
              if (blob != null) break;
              await Future<void>.delayed(const Duration(milliseconds: 250));
            }
            if (blob == null) return;
            if (!blob.senderAgentId.contains(runId)) return;

            final encrypted = SignalEncryptedMessage.fromBytes(
              blob.toEncryptedMessage().encryptedContent,
            );
            final plaintextBytes = await signal.decryptMessage(
              encrypted: encrypted,
              senderId: blob.fromUserId,
            );
            final plaintext = utf8.decode(plaintextBytes);
            receivedPlaintext.add(plaintext);
            if (LedgerAuditV0.isEnabled) {
              unawaited(LedgerAuditV0.tryAppend(
                domain: LedgerDomainV0.security,
                eventType: 'signal_dm_decrypt_succeeded',
                occurredAt: DateTime.now(),
                entityType: 'dm_message',
                entityId: messageId,
                payload: <String, Object?>{
                  'message_id': messageId,
                  'from_user_id': blob.fromUserId,
                  'to_user_id': blob.toUserId,
                  'encryption_type': blob.encryptionType.name,
                  'plaintext_len': plaintextBytes.length,
                },
              ));
            }
          } catch (e, st) {
            developer.log(
              'DM receive handler failed: $e',
              name: 'SignalTwoDeviceSmoke',
              error: e,
              stackTrace: st,
            );
          }
        },
      );
      dmNotifyChannel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed &&
            !dmSubscribed.isCompleted) {
          dmSubscribed.complete();
        } else if (status == RealtimeSubscribeStatus.channelError &&
            !dmSubscribed.isCompleted) {
          dmSubscribed.completeError(
            error ?? Exception('dm notification channel error'),
          );
        }
      });

      await dmSubscribed.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException(
            'Timed out waiting for DM notification channel subscribe',
          );
        },
      );

      Future<void> sendDm({
        required String toUserId,
        required String plaintext,
      }) async {
        final messageId = uuid.v4();
        final enc = await signal.encryptMessage(
          plaintext: Uint8List.fromList(utf8.encode(plaintext)),
          recipientId: toUserId,
        );

        await dmStore.enqueueDm(
          messageId: messageId,
          fromUserId: myUserId,
          toUserId: toUserId,
          senderAgentId: 'signal_smoke:$runId:$myUserId',
          recipientAgentId: 'signal_smoke:$runId:$toUserId',
          encrypted: EncryptedMessage(
            encryptedContent: enc.toBytes(),
            encryptionType: EncryptionType.signalProtocol,
          ),
          sentAt: DateTime.now().toUtc(),
        );
        if (LedgerAuditV0.isEnabled) {
          unawaited(LedgerAuditV0.tryAppend(
            domain: LedgerDomainV0.security,
            eventType: 'signal_dm_notification_written',
            occurredAt: DateTime.now(),
            entityType: 'dm_message',
            entityId: messageId,
            payload: <String, Object?>{
              'message_id': messageId,
              'to_user_id': toUserId,
            },
          ));
        }
      }

      // 5) DM roundtrip: A sends first; B replies.
      if (role == 'A') {
        // ignore: avoid_print
        print('🔎 [signal_2dev:A] Sending DM → B...');
        await sendDm(
          toUserId: peerUserId,
          plaintext: 'signal_2dev:$runId:hello-1',
        );

        final reply = await receivedPlaintext.stream
            .firstWhere((m) => m == 'signal_2dev:$runId:reply-1')
            .timeout(const Duration(seconds: 90));
        expect(reply, equals('signal_2dev:$runId:reply-1'));
        // ignore: avoid_print
        print('✅ [signal_2dev:A] DM roundtrip OK');
      } else {
        final msg = await receivedPlaintext.stream
            .firstWhere((m) => m == 'signal_2dev:$runId:hello-1')
            .timeout(const Duration(seconds: 90));
        expect(msg, equals('signal_2dev:$runId:hello-1'));
        // ignore: avoid_print
        print('✅ [signal_2dev:B] Received DM from A');

        await sendDm(
          toUserId: peerUserId,
          plaintext: 'signal_2dev:$runId:reply-1',
        );
        // ignore: avoid_print
        print('✅ [signal_2dev:B] Sent reply');
      }

      // 6) Optional: community stream send/receive (real transport), with sender-key
      // distributed via the established Signal DM.
      if (communityId.isNotEmpty) {
        // ignore: avoid_print
        print(
            '🔎 [signal_2dev:$role] Running community stream smoke for communityId=$communityId');

        final communityStore = CommunityMessageStore(supabase: supabaseService);
        final communityChannel =
            client.channel('signal_smoke_community_events:$runId:$communityId');
        final communityBlob = Completer<CommunityMessageBlob>();

        communityChannel.onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'community_message_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'community_id',
            value: communityId,
          ),
          callback: (payload) async {
            try {
              final messageId =
                  payload.newRecord['message_id']?.toString() ?? '';
              if (messageId.isEmpty) return;
              final blob = await communityStore.getMessageBlob(messageId);
              if (blob == null) return;
              if (!blob.senderAgentId.contains(runId)) return;
              if (blob.keyId != 'signal_smoke_key:$runId') return;
              if (!communityBlob.isCompleted) {
                communityBlob.complete(blob);
              }
            } catch (e, st) {
              developer.log(
                'Community receive handler failed: $e',
                name: 'SignalTwoDeviceSmoke',
                error: e,
                stackTrace: st,
              );
            }
          },
        );
        communityChannel.subscribe();

        if (role == 'A') {
          // Sender key distribution to B via Signal DM (base64-encoded 32 bytes).
          final senderKey32 = Uint8List(32);
          for (var i = 0; i < senderKey32.length; i++) {
            senderKey32[i] =
                (i * 37 + runId.codeUnitAt(i % runId.length)) & 0xff;
          }
          final senderKeyBase64 = base64Encode(senderKey32);
          await sendDm(
            toUserId: peerUserId,
            plaintext: 'signal_2dev:$runId:sender_key:$senderKeyBase64',
          );

          // Group payload: minimal JSON wrapped and then base64'd so we can store as text.
          const groupPlaintext = 'signal_2dev:$runId:community:hello';
          final encryptedPayloadBase64 =
              Aes256GcmFixedKeyCodec.encryptStringToBase64(
            key32: senderKey32,
            plaintext: groupPlaintext,
          );

          final messageId = uuid.v4();
          await communityStore.putMessageBlob(
            messageId: messageId,
            communityId: communityId,
            senderUserId: myUserId,
            senderAgentId: 'signal_smoke:$runId:$myUserId',
            keyId: 'signal_smoke_key:$runId',
            algorithm: 'aes256gcm_fixed_key_v1',
            ciphertextBase64: encryptedPayloadBase64,
            sentAt: DateTime.now().toUtc(),
          );
          await client.from('community_message_events').insert({
            'community_id': communityId,
            'message_id': messageId,
            'sender_user_id': myUserId,
          });

          // ignore: avoid_print
          print('✅ [signal_2dev:A] Community message event inserted');
        } else {
          // Wait for sender-key DM first (from A).
          final senderKeyMsg = await receivedPlaintext.stream
              .firstWhere((m) => m.startsWith('signal_2dev:$runId:sender_key:'))
              .timeout(const Duration(seconds: 90));
          final keyBase64 = senderKeyMsg.split(':sender_key:').last;
          final senderKey32 = base64Decode(keyBase64);
          expect(senderKey32.length, equals(32));

          // Now wait for community event + blob; decrypt the embedded ciphertext.
          final blob =
              await communityBlob.future.timeout(const Duration(seconds: 120));
          expect(blob.ciphertextBase64, isNotEmpty);
          final decrypted = Aes256GcmFixedKeyCodec.decryptBase64ToString(
            key32: senderKey32,
            ciphertextBase64: blob.ciphertextBase64,
          );
          expect(decrypted, equals('signal_2dev:$runId:community:hello'));

          // ignore: avoid_print
          print('✅ [signal_2dev:B] Community stream receive OK');
        }
      }

      await receivedPlaintext.close();
      await dmNotifyChannel.unsubscribe();
      await rendezvous.unsubscribe();
    });
  });
}
