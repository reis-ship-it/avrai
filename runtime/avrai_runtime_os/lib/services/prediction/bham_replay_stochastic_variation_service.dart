import 'package:avrai_core/avra_core.dart';

class BhamReplayStochasticVariationService {
  const BhamReplayStochasticVariationService();

  ReplayStochasticRunConfig buildRunConfig({
    required ReplayVirtualWorldEnvironment environment,
  }) {
    final runContext = environment.runContext;
    return ReplayStochasticRunConfig(
      runId: runContext.runId,
      replayYear: environment.replayYear,
      globalSeed: _mix(runContext.seed, 'global', environment.environmentId),
      localityPerturbationSeed: _mix(
        runContext.seed,
        'locality',
        environment.environmentId,
      ),
      actorSeed: _mix(runContext.seed, 'actor', environment.environmentId),
      monthSeasonSeed: _mix(
        runContext.seed,
        'month',
        environment.environmentId,
      ),
      metadata: <String, dynamic>{
        'branchId': runContext.branchId,
        'divergencePolicy': runContext.divergencePolicy,
      },
    );
  }

  double roll({
    required ReplayStochasticRunConfig config,
    required String actorId,
    required String channel,
    String? monthKey,
    String? localityAnchor,
    String? entityId,
    int salt = 0,
  }) {
    final hash = _hash(
      <String>[
        config.runId,
        config.replayYear.toString(),
        actorId,
        channel,
        monthKey ?? '',
        localityAnchor ?? '',
        entityId ?? '',
        salt.toString(),
      ],
      seeds: <int>[
        config.globalSeed,
        config.actorSeed,
        config.localityPerturbationSeed,
        config.monthSeasonSeed,
      ],
    );
    return (hash % 1000000) / 1000000.0;
  }

  bool chance({
    required ReplayStochasticRunConfig config,
    required String actorId,
    required String channel,
    required double probability,
    String? monthKey,
    String? localityAnchor,
    String? entityId,
    int salt = 0,
  }) {
    return roll(
          config: config,
          actorId: actorId,
          channel: channel,
          monthKey: monthKey,
          localityAnchor: localityAnchor,
          entityId: entityId,
          salt: salt,
        ) <
        probability.clamp(0.0, 1.0);
  }

  int index({
    required ReplayStochasticRunConfig config,
    required String actorId,
    required String channel,
    required int length,
    String? monthKey,
    String? localityAnchor,
    String? entityId,
    int salt = 0,
  }) {
    if (length <= 0) {
      return 0;
    }
    final hash = _hash(
      <String>[
        config.runId,
        actorId,
        channel,
        monthKey ?? '',
        localityAnchor ?? '',
        entityId ?? '',
        salt.toString(),
      ],
      seeds: <int>[
        config.globalSeed,
        config.actorSeed,
        config.localityPerturbationSeed,
        config.monthSeasonSeed,
      ],
    );
    return hash % length;
  }

  int intInRange({
    required ReplayStochasticRunConfig config,
    required String actorId,
    required String channel,
    required int minInclusive,
    required int maxInclusive,
    String? monthKey,
    String? localityAnchor,
    String? entityId,
    int salt = 0,
  }) {
    if (maxInclusive <= minInclusive) {
      return minInclusive;
    }
    final length = (maxInclusive - minInclusive) + 1;
    return minInclusive +
        index(
          config: config,
          actorId: actorId,
          channel: channel,
          length: length,
          monthKey: monthKey,
          localityAnchor: localityAnchor,
          entityId: entityId,
          salt: salt,
        );
  }

  int score({
    required ReplayStochasticRunConfig config,
    required String actorId,
    required String channel,
    String? monthKey,
    String? localityAnchor,
    String? entityId,
    int salt = 0,
  }) {
    return _hash(
      <String>[
        config.runId,
        actorId,
        channel,
        monthKey ?? '',
        localityAnchor ?? '',
        entityId ?? '',
        salt.toString(),
      ],
      seeds: <int>[
        config.globalSeed,
        config.actorSeed,
        config.localityPerturbationSeed,
        config.monthSeasonSeed,
      ],
    );
  }

  int _mix(int seed, String channel, String environmentId) {
    return _hash(
      <String>[seed.toString(), channel, environmentId],
      seeds: <int>[seed],
    );
  }

  int _hash(List<String> parts, {required List<int> seeds}) {
    var hash = 2166136261;
    for (final seed in seeds) {
      hash ^= seed & 0xFFFFFFFF;
      hash = (hash * 16777619) & 0x7FFFFFFF;
    }
    for (final part in parts) {
      for (final codeUnit in part.codeUnits) {
        hash ^= codeUnit;
        hash = (hash * 16777619) & 0x7FFFFFFF;
      }
    }
    return hash & 0x7FFFFFFF;
  }
}
