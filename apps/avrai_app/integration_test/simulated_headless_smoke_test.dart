import 'dart:developer' as developer;
import 'dart:io';

import 'package:avrai/configs/firebase_options.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_runtime_os/config/supabase_config.dart';
import 'package:avrai/services/debug/proof_run_automation_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);
const MethodChannel _appLinksMethodChannel = MethodChannel(
  'com.llfbandit.app_links/messages',
);
const MethodChannel _appLinksEventChannel = MethodChannel(
  'com.llfbandit.app_links/events',
);
const MethodChannel _batteryMethodChannel = MethodChannel(
  'dev.fluttercommunity.plus/battery',
);
const MethodChannel _batteryEventChannel = MethodChannel(
  'dev.fluttercommunity.plus/charging',
);
const MethodChannel _connectivityMethodChannel = MethodChannel(
  'dev.fluttercommunity.plus/connectivity',
);
const MethodChannel _connectivityEventChannel = MethodChannel(
  'dev.fluttercommunity.plus/connectivity_status',
);

Directory? _hostSmokeDocumentsRoot;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('runs simulated headless smoke via automation service', (
    tester,
  ) async {
    const platformMode = String.fromEnvironment(
      'SIMULATED_SMOKE_PLATFORM',
      defaultValue: 'unknown',
    );

    try {
      await _initializeSmokeRuntime();

      final service = di.sl<ProofRunAutomationService>();
      final result = await service.runSimulatedHeadlessSmoke(
        const SimulatedHeadlessSmokeRequest(platformMode: platformMode),
      );

      binding.reportData = result.toJson();
      expect(result.success, isTrue, reason: result.failureSummary);
      expect(result.runId, isNotEmpty);
      expect(result.exportDirectoryPath, isNotEmpty);
      expect(Directory(result.exportDirectoryPath).existsSync(), isTrue);
    } catch (error, stackTrace) {
      final failure = <String, Object?>{
        'success': false,
        'platform_mode': platformMode,
        'failure_summary': error.toString(),
      };
      binding.reportData = failure;
      developer.log(
        'Simulated headless smoke integration run failed',
        name: 'simulated_headless_smoke_test',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  });
}

Future<void> _initializeSmokeRuntime() async {
  await _configureHostSmokeFallbacks();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // The smoke lane is allowed to proceed when Firebase is already initialized
    // or unavailable in the current simulator environment.
  }
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url.isNotEmpty
          ? SupabaseConfig.url
          : 'https://example.supabase.co',
      anonKey: SupabaseConfig.anonKey.isNotEmpty
          ? SupabaseConfig.anonKey
          : 'smoke',
      debug: false,
    );
  } catch (_) {
    // The Supabase singleton may already be initialized from an earlier launch
    // in the same simulator session. Reuse it when available.
  }
  await di.init();
}

Future<void> _configureHostSmokeFallbacks() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return;
  }

  SharedPreferences.setMockInitialValues(const <String, Object>{});

  _hostSmokeDocumentsRoot ??= await Directory.systemTemp.createTemp(
    'simulated_smoke_docs_',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationSupportDirectory':
          case 'getTemporaryDirectory':
          case 'getLibraryDirectory':
          case 'getExternalStorageDirectory':
            return _hostSmokeDocumentsRoot!.path;
          case 'getExternalStorageDirectories':
            return <String>[_hostSmokeDocumentsRoot!.path];
          default:
            return _hostSmokeDocumentsRoot!.path;
        }
      });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        _appLinksMethodChannel,
        (methodCall) async => null,
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_appLinksEventChannel, (methodCall) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              _appLinksEventChannel.name,
              const StandardMethodCodec().encodeSuccessEnvelope(null),
              (ByteData? data) {},
            );
        return null;
      });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_batteryMethodChannel, (methodCall) async {
        switch (methodCall.method) {
          case 'getBatteryLevel':
            return 100;
          case 'isInBatterySaveMode':
            return false;
          case 'getBatteryState':
            return 'full';
          default:
            return null;
        }
      });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_batteryEventChannel, (methodCall) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              _batteryEventChannel.name,
              const StandardMethodCodec().encodeSuccessEnvelope('full'),
              (ByteData? data) {},
            );
        return null;
      });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_connectivityMethodChannel, (methodCall) async {
        switch (methodCall.method) {
          case 'check':
            return <String>['wifi'];
          default:
            return null;
        }
      });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_connectivityEventChannel, (methodCall) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              _connectivityEventChannel.name,
              const StandardMethodCodec().encodeSuccessEnvelope(<String>[
                'wifi',
              ]),
              (ByteData? data) {},
            );
        return null;
      });
}
