import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_auto_install_service.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_provisioning_state_service.dart';
import 'package:avrai_runtime_os/services/local_llm/model_pack_manager.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

import '../../mocks/mock_storage_service.dart';

class _FakeConnectivity implements Connectivity {
  _FakeConnectivity({List<ConnectivityResult>? initial})
      : _current = initial ?? const [ConnectivityResult.none];

  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> _current;

  void emit(List<ConnectivityResult> next) {
    _current = next;
    _controller.add(next);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;
}

class _FakeBatteryFacade implements BatteryFacade {
  _FakeBatteryFacade(this._state);

  BatteryState _state;

  final StreamController<BatteryState> _controller =
      StreamController<BatteryState>.broadcast();

  void emit(BatteryState next) {
    _state = next;
    _controller.add(next);
  }

  @override
  Future<BatteryState> getBatteryState() async => _state;

  @override
  Stream<BatteryState> get onBatteryStateChanged => _controller.stream;
}

class _FakePacks extends LocalLlmModelPackManager {
  LocalLlmModelPackStatus status = const LocalLlmModelPackStatus(
    isInstalled: false,
    activePackId: null,
    activeDir: null,
  );

  bool downloadCalled = false;
  bool progressReported = false;

  @override
  Future<LocalLlmModelPackStatus> getStatus() async => status;

  @override
  Future<void> downloadAndActivate({
    required Uri manifestUrl,
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    downloadCalled = true;
    if (onProgress != null) {
      onProgress(1, 10);
      progressReported = true;
    }
    status = const LocalLlmModelPackStatus(
      isInstalled: true,
      activePackId: 'llama3_1_8b_instruct@1.0.0',
      activeDir: '/tmp/local_llm_packs/active',
    );
  }
}

class _MockBootstrapService extends Mock
    implements LocalLlmPostInstallBootstrapService {}

void main() {
  group('LocalLlmAutoInstallService Wi‑Fi gating', () {
    setUp(() {
      MockGetStorage.reset();
      final sl = GetIt.instance;
      if (sl.isRegistered<LocalLlmPostInstallBootstrapService>()) {
        sl.unregister<LocalLlmPostInstallBootstrapService>();
      }
      final bootstrap = _MockBootstrapService();
      when(() => bootstrap.maybeBootstrapCurrentUser())
          .thenAnswer((_) async {});
      sl.registerSingleton<LocalLlmPostInstallBootstrapService>(bootstrap);
    });

    tearDown(() async {
      await LocalLlmAutoInstallService.resetWifiListenerForTests();
      final sl = GetIt.instance;
      if (sl.isRegistered<LocalLlmPostInstallBootstrapService>()) {
        sl.unregister<LocalLlmPostInstallBootstrapService>();
      }
    });

    test('queues for Wi‑Fi and then downloads when Wi‑Fi becomes available',
        () async {
      final storage = MockGetStorage.getInstance(boxName: 'prefs_wifi_gate');
      final prefs = await SharedPreferencesCompat.getInstance(storage: storage);

      // User has opted in (or defaulted) already.
      await prefs.setBool('offline_llm_enabled_v1', true);
      await prefs.setString(
          'local_llm_manifest_url_v1', 'https://example.com/manifest.json');

      final fakeConnectivity =
          _FakeConnectivity(initial: const [ConnectivityResult.none]);
      final fakeBattery = _FakeBatteryFacade(BatteryState.charging);
      final fakePacks = _FakePacks();
      final provisioning =
          LocalLlmProvisioningStateService(packs: fakePacks, prefs: prefs);

      final service = LocalLlmAutoInstallService(
        connectivity: fakeConnectivity,
        battery: fakeBattery,
        packs: fakePacks,
        provisioning: provisioning,
        prefs: prefs,
        now: () => DateTime(2025, 1, 1, 1, 0), // within idle window
      );

      // Not on Wi‑Fi: should queue and NOT download.
      await service.maybeAutoInstall();
      expect(fakePacks.downloadCalled, isFalse);

      var state = await provisioning.getState();
      expect(state.phase, LocalLlmProvisioningPhase.queuedWifi);

      // Wi‑Fi appears: should download and mark installed.
      fakeConnectivity.emit(const [ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(fakePacks.downloadCalled, isTrue);
      expect(fakePacks.progressReported, isTrue);
      state = await provisioning.getState();
      expect(state.phase, LocalLlmProvisioningPhase.installed);
      expect(state.packStatus.isInstalled, isTrue);
    });
  });
}
