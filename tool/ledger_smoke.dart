import 'dart:io';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _LedgerSmokeApp());
}

class _LedgerSmokeApp extends StatefulWidget {
  const _LedgerSmokeApp();

  @override
  State<_LedgerSmokeApp> createState() => _LedgerSmokeAppState();
}

class _LedgerSmokeAppState extends State<_LedgerSmokeApp> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      // Initialize local storage (best-effort; ledger will still work without it).
      try {
        await StorageService.instance.init();
      } catch (e, st) {
        developer.log(
          'Storage init failed (non-fatal)',
          error: e,
          stackTrace: st,
          name: 'LedgerSmoke',
        );
      }

      // Load credentials from environment variables
      // Set SUPABASE_URL and SUPABASE_ANON_KEY before running
      final url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      final anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

      await Supabase.initialize(url: url, anonKey: anonKey, debug: false);
      final client = Supabase.instance.client;

      try {
        await client.auth.signOut();
      } catch (_) {
        // ignore
      }

      // Auth for smoke testing.
      //
      // This Supabase project currently rejects unconfirmed emails and may have anonymous disabled.
      // So we support two paths:
      // 1) If LEDGER_SMOKE_EMAIL + LEDGER_SMOKE_PASSWORD are provided (dart-define), sign in with them.
      // 2) Else, attempt email sign-up (may require out-of-band confirmation).
      const smokeEmail =
          String.fromEnvironment('LEDGER_SMOKE_EMAIL', defaultValue: '');
      const smokePassword =
          String.fromEnvironment('LEDGER_SMOKE_PASSWORD', defaultValue: '');
      if (smokeEmail.isNotEmpty && smokePassword.isNotEmpty) {
        await client.auth.signInWithPassword(
          email: smokeEmail,
          password: smokePassword,
        );
      } else {
        final nonce = (DateTime.now().millisecondsSinceEpoch * 100000 +
                Random().nextInt(99999))
            .toString();
        final email = 'ledger.smoke.bot.$nonce@gmail.com';
        const password = 'TestPassword!123456';
        await client.auth.signUp(email: email, password: password);
        await client.auth.signInWithPassword(email: email, password: password);
      }

      final supabaseService = SupabaseService();
      final currentUser = supabaseService.currentUser;
      if (currentUser == null) {
        throw StateError('Auth failed: no current user after sign-in');
      }

      final ledger = LedgerRecorderServiceV0(
        supabaseService: supabaseService,
        agentIdService: AgentIdService(),
        storage: StorageService.instance,
      );

      final res = await ledger.debugWriteAndVerifyImmediate();
      developer.log(
        'Ledger smoke test result: logicalId=${res.logicalId} insertedRowId=${res.insertedRowId}',
        name: 'LedgerSmoke',
      );

      // Print a minimal one-liner for terminal visibility.
      // ignore: avoid_print
      print('OK logicalId=${res.logicalId} insertedRowId=${res.insertedRowId}');

      // End the run cleanly.
      exit(0);
    } catch (e, st) {
      developer.log('Ledger smoke test FAILED', error: e, stackTrace: st, name: 'LedgerSmoke');
      // ignore: avoid_print
      print('FAIL error=$e');
      exit(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Ledger smoke test running...')),
      ),
    );
  }
}

