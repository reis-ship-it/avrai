import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_stochastic_variation_service.dart';

class BhamReplayConnectivityService {
  const BhamReplayConnectivityService({
    BhamReplayStochasticVariationService? stochasticVariationService,
  }) : _stochasticVariationService = stochasticVariationService ??
            const BhamReplayStochasticVariationService();

  final BhamReplayStochasticVariationService _stochasticVariationService;

  List<ReplayConnectivityProfile> buildProfiles({
    required ReplayPopulationProfile populationProfile,
    required ReplayDailyBehaviorBatch dailyBehaviorBatch,
    ReplayStochasticRunConfig? stochasticRunConfig,
  }) {
    final runConfig =
        stochasticRunConfig ?? _defaultRunConfig(populationProfile);
    final agendasByActor = <String, ReplayDailyAgenda>{
      for (final agenda in dailyBehaviorBatch.agendas) agenda.actorId: agenda,
    };

    return populationProfile.actors
        .map(
          (actor) => _buildProfile(
            actor: actor,
            agenda: agendasByActor[actor.actorId],
            runConfig: runConfig,
          ),
        )
        .toList(growable: false);
  }

  ReplayConnectivityProfile _buildProfile({
    required ReplayActorProfile actor,
    ReplayDailyAgenda? agenda,
    required ReplayStochasticRunConfig runConfig,
  }) {
    final routineSurface =
        actor.metadata['defaultRoutineSurface']?.toString() ?? 'career_anchor';
    final careerTrack =
        actor.metadata['careerTrack']?.toString() ?? 'mixed_work';
    final offGraphRoutineBias =
        (actor.metadata['offGraphRoutineBias'] as num?)?.toDouble() ?? 0.5;
    final baseProbability =
        actor.lifecycleState == AgentLifecycleState.deleted ? 0.0 : 0.92;

    final wifiEnabled = actor.lifecycleState != AgentLifecycleState.deleted &&
        _stochasticVariationService.chance(
          config: runConfig,
          actorId: actor.actorId,
          channel: 'connectivity:wifi_enabled',
          probability: baseProbability,
          localityAnchor: actor.localityAnchor,
        );
    final cellularEnabled = _stochasticVariationService.chance(
      config: runConfig,
      actorId: actor.actorId,
      channel: 'connectivity:cellular_enabled',
      probability: 0.95,
      localityAnchor: actor.localityAnchor,
    );
    final bleAvailable = _stochasticVariationService.chance(
      config: runConfig,
      actorId: actor.actorId,
      channel: 'connectivity:ble_available',
      probability: 0.76,
      localityAnchor: actor.localityAnchor,
    );
    final offlinePreference =
        actor.lifecycleState == AgentLifecycleState.deleted ||
            offGraphRoutineBias >= 0.72 ||
            _stochasticVariationService.chance(
              config: runConfig,
              actorId: actor.actorId,
              channel: 'connectivity:offline_preference',
              probability: 0.08,
              localityAnchor: actor.localityAnchor,
            );
    final backgroundSensingEnabled =
        actor.lifecycleState == AgentLifecycleState.active &&
            actor.lifecycleState != AgentLifecycleState.deleted;

    final batteryPressureBand = _batteryPressureFor(
      actor: actor,
      careerTrack: careerTrack,
      runConfig: runConfig,
    );
    final deviceProfile = ReplayDeviceProfile(
      actorId: actor.actorId,
      deviceClass: _deviceClassFor(actor, runConfig),
      wifiEnabled: wifiEnabled,
      cellularEnabled: cellularEnabled,
      bleAvailable: bleAvailable,
      backgroundSensingEnabled: backgroundSensingEnabled,
      offlinePreference: offlinePreference,
      batteryPressureBand: batteryPressureBand,
      metadata: <String, dynamic>{
        'careerTrack': careerTrack,
        'routineSurface': routineSurface,
      },
    );

    final transitions = <ReplayConnectivityStateTransition>[
      _transition(
        actor: actor,
        deviceProfile: deviceProfile,
        scheduleSurface: routineSurface,
        windowLabel: 'home_anchor',
        reason:
            'home and household anchors are Wi-Fi probable unless user settings or lifecycle reduce availability',
        preferredMode: wifiEnabled
            ? ReplayConnectivityMode.wifi
            : cellularEnabled
                ? ReplayConnectivityMode.cellular
                : ReplayConnectivityMode.offline,
      ),
      _transition(
        actor: actor,
        deviceProfile: deviceProfile,
        scheduleSurface: agenda?.weekdayPattern ?? 'weekday_routine',
        windowLabel: 'mobility_window',
        reason:
            'movement through transit, street, and corridor time is cellular or offline biased',
        preferredMode: cellularEnabled
            ? ReplayConnectivityMode.cellular
            : bleAvailable
                ? ReplayConnectivityMode.ble
                : ReplayConnectivityMode.offline,
      ),
      _transition(
        actor: actor,
        deviceProfile: deviceProfile,
        scheduleSurface: agenda?.weekdayPattern ?? routineSurface,
        windowLabel: 'day_anchor',
        reason:
            'work, school, library, civic, and major venue anchors are Wi-Fi probable where enabled',
        preferredMode: wifiEnabled
            ? ReplayConnectivityMode.wifi
            : cellularEnabled
                ? ReplayConnectivityMode.cellular
                : ReplayConnectivityMode.offline,
      ),
      _transition(
        actor: actor,
        deviceProfile: deviceProfile,
        scheduleSurface: agenda?.weekendPattern ?? 'weekend_anchor',
        windowLabel: 'evening_or_weekend',
        reason:
            'evening and weekend activity follows actor routine, nightlife, and recovery patterns',
        preferredMode: _weekendModeFor(
          actor: actor,
          wifiEnabled: wifiEnabled,
          cellularEnabled: cellularEnabled,
          bleAvailable: bleAvailable,
        ),
      ),
    ];

    final modeCounts = <ReplayConnectivityMode, int>{};
    for (final transition in transitions) {
      modeCounts[transition.mode] = (modeCounts[transition.mode] ?? 0) + 1;
    }
    final dominantMode = modeCounts.entries.isEmpty
        ? ReplayConnectivityMode.offline
        : (modeCounts.entries.toList()
              ..sort((left, right) => right.value.compareTo(left.value)))
            .first
            .key;

    return ReplayConnectivityProfile(
      actorId: actor.actorId,
      localityAnchor: actor.localityAnchor,
      dominantMode: dominantMode,
      deviceProfile: deviceProfile,
      transitions: transitions,
      metadata: <String, dynamic>{
        'weekdayPattern': agenda?.weekdayPattern ?? 'weekday_routine',
        'weekendPattern': agenda?.weekendPattern ?? 'weekend_anchor',
        'stochasticRunId': runConfig.runId,
        'cityCode': runConfig.metadata['cityCode']?.toString(),
        'citySlug': runConfig.metadata['citySlug']?.toString(),
        'cityDisplayName': runConfig.metadata['cityDisplayName']?.toString(),
      },
    );
  }

  ReplayStochasticRunConfig _defaultRunConfig(
    ReplayPopulationProfile populationProfile,
  ) {
    final metadata = populationProfile.metadata;
    final citySlug = metadata['citySlug']?.toString();
    final environmentId = metadata['environmentId']?.toString();
    final runStem = _slugify(
      citySlug?.isNotEmpty == true
          ? '${citySlug}_${populationProfile.replayYear}_replay'
          : environmentId?.isNotEmpty == true
              ? environmentId!
              : 'replay_${populationProfile.replayYear}',
    );
    final seedBase = _seedBaseFor(
      replayYear: populationProfile.replayYear,
      citySlug: citySlug,
      environmentId: environmentId,
    );
    return ReplayStochasticRunConfig(
      runId: runStem,
      replayYear: populationProfile.replayYear,
      globalSeed: seedBase,
      localityPerturbationSeed: seedBase * 10 + 1,
      actorSeed: seedBase * 10 + 2,
      monthSeasonSeed: seedBase * 10 + 3,
      metadata: <String, dynamic>{
        'environmentId': environmentId,
        'cityCode': metadata['cityCode']?.toString(),
        'citySlug': citySlug,
        'cityDisplayName': metadata['cityDisplayName']?.toString(),
      },
    );
  }

  int _seedBaseFor({
    required int replayYear,
    required String? citySlug,
    required String? environmentId,
  }) {
    final seedSource = citySlug?.isNotEmpty == true
        ? citySlug!
        : environmentId?.isNotEmpty == true
            ? environmentId!
            : 'replay';
    final normalized = _slugify(seedSource);
    final hash = normalized.codeUnits.fold<int>(
      replayYear,
      (value, codeUnit) => (value * 31 + codeUnit) % 9000,
    );
    return replayYear + hash;
  }

  String _slugify(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'replay' : normalized;
  }

  ReplayConnectivityStateTransition _transition({
    required ReplayActorProfile actor,
    required ReplayDeviceProfile deviceProfile,
    required String scheduleSurface,
    required String windowLabel,
    required String reason,
    required ReplayConnectivityMode preferredMode,
  }) {
    final mode = deviceProfile.offlinePreference &&
            preferredMode != ReplayConnectivityMode.ble
        ? ReplayConnectivityMode.offline
        : preferredMode;
    final reachable = mode != ReplayConnectivityMode.offline ||
        (deviceProfile.offlinePreference == false &&
            deviceProfile.bleAvailable == true);
    return ReplayConnectivityStateTransition(
      transitionId: 'connectivity:${actor.actorId}:$windowLabel',
      actorId: actor.actorId,
      scheduleSurface: scheduleSurface,
      windowLabel: windowLabel,
      localityAnchor: actor.localityAnchor,
      mode: mode,
      reachable: reachable,
      reason: reason,
      metadata: <String, dynamic>{
        'lifecycleState': actor.lifecycleState.name,
      },
    );
  }

  ReplayBatteryPressureBand _batteryPressureFor({
    required ReplayActorProfile actor,
    required String careerTrack,
    required ReplayStochasticRunConfig runConfig,
  }) {
    if (actor.lifecycleState == AgentLifecycleState.deleted) {
      return ReplayBatteryPressureBand.high;
    }
    if (careerTrack.contains('hospitality') ||
        careerTrack.contains('creative') ||
        actor.preferredEntityTypes.contains('club')) {
      return ReplayBatteryPressureBand.high;
    }
    if (_stochasticVariationService.chance(
      config: runConfig,
      actorId: actor.actorId,
      channel: 'connectivity:battery_pressure',
      probability: 0.3,
      localityAnchor: actor.localityAnchor,
    )) {
      return ReplayBatteryPressureBand.moderate;
    }
    return ReplayBatteryPressureBand.low;
  }

  String _deviceClassFor(
    ReplayActorProfile actor,
    ReplayStochasticRunConfig runConfig,
  ) {
    if (actor.workStudentStatus.contains('student')) {
      return _stochasticVariationService.chance(
        config: runConfig,
        actorId: actor.actorId,
        channel: 'connectivity:student_device_pair',
        probability: 0.52,
        localityAnchor: actor.localityAnchor,
      )
          ? 'phone_laptop_pair'
          : 'phone';
    }
    if (actor.workStudentStatus == 'retired') {
      return 'phone_tablet_pair';
    }
    return _stochasticVariationService.chance(
      config: runConfig,
      actorId: actor.actorId,
      channel: 'connectivity:wearable_pair',
      probability: 0.33,
      localityAnchor: actor.localityAnchor,
    )
        ? 'phone_watch_pair'
        : 'phone';
  }

  ReplayConnectivityMode _weekendModeFor({
    required ReplayActorProfile actor,
    required bool wifiEnabled,
    required bool cellularEnabled,
    required bool bleAvailable,
  }) {
    if (actor.preferredEntityTypes.contains('club')) {
      if (cellularEnabled) {
        return ReplayConnectivityMode.cellular;
      }
      if (bleAvailable) {
        return ReplayConnectivityMode.ble;
      }
      return ReplayConnectivityMode.offline;
    }
    if (wifiEnabled) {
      return ReplayConnectivityMode.wifi;
    }
    if (cellularEnabled) {
      return ReplayConnectivityMode.cellular;
    }
    return ReplayConnectivityMode.offline;
  }
}
