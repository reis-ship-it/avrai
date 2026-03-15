import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_pull_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_source_puller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePuller extends BhamReplayAutomatedSourcePuller {
  const _FakePuller(this._sourceName);

  final String _sourceName;

  @override
  String get pullerId => 'fake';

  @override
  bool supports(ReplaySourcePullPlan plan) => plan.sourceName == _sourceName;

  @override
  Future<ReplaySourceDataset> pull({
    required ReplaySourcePullPlan plan,
  }) async {
    return ReplaySourceDataset(
      sourceName: plan.sourceName,
      records: <Map<String, dynamic>>[
        <String, dynamic>{'record_id': 'record-1', 'entity_type': 'event'},
      ],
    );
  }
}

void main() {
  test('pulls automated plans and skips unsupported/manual sources', () async {
    final service = BhamReplayAutomatedPullService(
      pullers: const <BhamReplayAutomatedSourcePuller>[
        _FakePuller('U.S. Census ACS'),
      ],
    );

    final result = await service.pullPlans(
      replayYear: 2023,
      plans: const <ReplaySourcePullPlan>[
        ReplaySourcePullPlan(
          sourceName: 'U.S. Census ACS',
          replayYear: 2023,
          acquisitionMode: ReplaySourceAcquisitionMode.automated,
          rawOutputKey: 'u_s_census_acs',
        ),
        ReplaySourcePullPlan(
          sourceName: 'OpenGov',
          replayYear: 2023,
          acquisitionMode: ReplaySourceAcquisitionMode.manualImport,
          rawOutputKey: 'opengov',
        ),
      ],
    );

    expect(result.pack.datasets.length, 1);
    expect(result.pulledSources, contains('U.S. Census ACS'));
    expect(result.skippedSources, contains('OpenGov'));
  });

  test('pulls api-key-required sources when a matching puller exists', () async {
    final service = BhamReplayAutomatedPullService(
      pullers: const <BhamReplayAutomatedSourcePuller>[
        _FakePuller('BEA / U.S. Census Bureau Economic Series'),
      ],
    );

    final result = await service.pullPlans(
      replayYear: 2023,
      plans: const <ReplaySourcePullPlan>[
        ReplaySourcePullPlan(
          sourceName: 'BEA / U.S. Census Bureau Economic Series',
          replayYear: 2023,
          acquisitionMode: ReplaySourceAcquisitionMode.apiKeyRequired,
          rawOutputKey: 'bea_u_s_census_bureau_economic_series',
        ),
      ],
    );

    expect(result.pack.datasets.length, 1);
    expect(
      result.pulledSources,
      contains('BEA / U.S. Census Bureau Economic Series'),
    );
    expect(result.skippedSources, isEmpty);
  });

  test('captures source failures without aborting the batch', () async {
    final service = BhamReplayAutomatedPullService(
      pullers: const <BhamReplayAutomatedSourcePuller>[
        _FakePuller('U.S. Census ACS'),
        _ThrowingPuller('OpenStreetMap POI Data'),
      ],
    );

    final result = await service.pullPlans(
      replayYear: 2023,
      plans: const <ReplaySourcePullPlan>[
        ReplaySourcePullPlan(
          sourceName: 'U.S. Census ACS',
          replayYear: 2023,
          acquisitionMode: ReplaySourceAcquisitionMode.automated,
          rawOutputKey: 'u_s_census_acs',
        ),
        ReplaySourcePullPlan(
          sourceName: 'OpenStreetMap POI Data',
          replayYear: 2023,
          acquisitionMode: ReplaySourceAcquisitionMode.automated,
          rawOutputKey: 'openstreetmap_poi_data',
        ),
      ],
    );

    expect(result.pulledSources, contains('U.S. Census ACS'));
    expect(result.skippedSources, contains('OpenStreetMap POI Data'));
    expect(
      result.failedSources['OpenStreetMap POI Data'],
      contains('simulated pull failure'),
    );
  });
}

class _ThrowingPuller extends BhamReplayAutomatedSourcePuller {
  const _ThrowingPuller(this._sourceName);

  final String _sourceName;

  @override
  String get pullerId => 'throwing';

  @override
  bool supports(ReplaySourcePullPlan plan) => plan.sourceName == _sourceName;

  @override
  Future<ReplaySourceDataset> pull({
    required ReplaySourcePullPlan plan,
  }) async {
    throw StateError('simulated pull failure');
  }
}
