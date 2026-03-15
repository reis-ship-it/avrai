import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_supabase_upload_index_service.dart';
import 'package:avrai_runtime_os/services/prediction/replay_supabase_storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReplaySupabaseStorageGateway implements ReplaySupabaseStorageGateway {
  final List<Map<String, dynamic>> uploads = <Map<String, dynamic>>[];
  final Map<String, List<Map<String, dynamic>>> upserts =
      <String, List<Map<String, dynamic>>>{};

  @override
  Future<void> uploadObject({
    required String bucket,
    required String objectPath,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploads.add(<String, dynamic>{
      'bucket': bucket,
      'objectPath': objectPath,
      'byteLength': bytes.length,
      'contentType': contentType,
    });
  }

  @override
  Future<void> upsertRows({
    required String table,
    required List<Map<String, dynamic>> rows,
    String? onConflict,
  }) async {
    upserts[table] = <Map<String, dynamic>>[
      ...rows.map((row) => Map<String, dynamic>.from(row)),
    ];
  }
}

void main() {
  test('buildUploadManifest uses partitions for large replay artifacts', () async {
    const service = BhamReplaySupabaseUploadIndexService();

    final exportManifest = ReplayStorageExportManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      status: 'accepted_as_monte_carlo_base_year',
      exportRoot: '/tmp/replay_export',
      projectIsolationMode: 'shared_project_isolated_namespace',
      replaySchema: 'replay_simulation',
      entries: const <ReplayStorageExportEntry>[
        ReplayStorageExportEntry(
          artifactRef: '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
          sourcePath: '/tmp/source/45.json',
          bucket: 'replay-world-snapshots',
          objectPath: '2023/world/45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
          byteSize: 1024,
        ),
        ReplayStorageExportEntry(
          artifactRef: '57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json',
          sourcePath: '/tmp/source/57.json',
          bucket: 'replay-world-snapshots',
          objectPath: '2023/world/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json',
          byteSize: 256,
        ),
      ],
    );

    final partitionManifest = ReplayStoragePartitionManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      partitionRoot: '/tmp/replay_partitions',
      maxRecordsPerChunk: 1000,
      entries: const <ReplayStoragePartitionEntry>[
        ReplayStoragePartitionEntry(
          artifactRef: '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
          section: 'items',
          chunkIndex: 0,
          recordCount: 1000,
          objectPath:
              '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json/items/chunk-0000.ndjson',
          byteSize: 128,
        ),
      ],
    );

    final manifest = service.buildUploadManifest(
      exportManifest: exportManifest,
      partitionManifest: partitionManifest,
      dryRun: true,
    );

    expect(manifest.entries, hasLength(2));
    expect(
      manifest.entries
          .where((entry) => entry.artifactRef == '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json')
          .single
          .representation,
      'partitioned_ndjson',
    );
    expect(
      manifest.entries
          .where((entry) => entry.artifactRef == '57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json')
          .single
          .representation,
      'single_object',
    );
    expect(
      (manifest.metadata['plannedIndexedTables'] as Map?) ?? const <String, dynamic>{},
      isEmpty,
      reason: 'planned table counts are computed during upload/index dry-run, not buildUploadManifest',
    );
  });

  test('uploadAndIndex writes replay-only uploads and index rows', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('bham_replay_upload_index_test');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final exportRoot = Directory('${tempDir.path}/export')..createSync();
    final partitionRoot = Directory('${tempDir.path}/partitions')..createSync();

    final calibrationFile = File(
      '${exportRoot.path}/replay-world-snapshots/2023/world/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json',
    )..parent.createSync(recursive: true);
    calibrationFile.writeAsStringSync(jsonEncode(<String, dynamic>{'passed': true}));

    final realismFile = File(
      '${exportRoot.path}/replay-world-snapshots/2023/world/54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.json',
    )..parent.createSync(recursive: true);
    realismFile.writeAsStringSync(jsonEncode(<String, dynamic>{'ready': true}));

    final trainingFile = File(
      '${exportRoot.path}/replay-training-exports/2023/training/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json',
    )..parent.createSync(recursive: true);
    trainingFile.writeAsStringSync(jsonEncode(<String, dynamic>{'status': 'ready'}));

    final populationFile = File(
      '${exportRoot.path}/replay-world-snapshots/2023/world/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json',
    )..parent.createSync(recursive: true);
    populationFile.writeAsStringSync(
      jsonEncode(
        const ReplayPopulationProfile(
          replayYear: 2023,
          totalPopulation: 100,
          totalHousingUnits: 50,
          estimatedOccupiedHousingUnits: 45,
          agentEligiblePopulation: 80,
          estimatedActiveAgentPopulation: 60,
          estimatedDormantAgentPopulation: 10,
          estimatedDeletedAgentPopulation: 5,
          dependentMobilityPopulation: 20,
          modeledActorCount: 1,
          localityPopulationCounts: <String, int>{'Downtown': 100},
          households: <ReplayHouseholdProfile>[],
          actors: <ReplayActorProfile>[
            ReplayActorProfile(
              actorId: 'actor-1',
              localityAnchor: 'Downtown',
              representedPopulationCount: 100,
              populationRole: SimulatedPopulationRole.humanWithAgent,
              lifecycleState: AgentLifecycleState.active,
              ageBand: '25-34',
              lifeStage: 'working_adult',
              householdType: 'single',
              workStudentStatus: 'working',
              hasPersonalAgent: true,
              preferredEntityTypes: <String>['venue'],
              kernelBundle: ReplayAgentKernelBundle(
                actorId: 'actor-1',
                attachedKernelIds: <String>['when', 'where'],
                readyKernelIds: <String>['when', 'where'],
                higherAgentInterfaces: <String>['locality'],
              ),
            ),
          ],
          eligibilityRecords: <ReplayAgentEligibilityRecord>[],
          lifecycleTransitions: <AgentLifecycleTransition>[],
        ).toJson(),
      ),
    );

    final kernelCoverageFile = File(
      '${exportRoot.path}/replay-world-snapshots/2023/world/59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.json',
    )..parent.createSync(recursive: true);
    kernelCoverageFile.writeAsStringSync(
      jsonEncode(
        const ReplayActorKernelCoverageReport(
          environmentId: 'env-1',
          replayYear: 2023,
          requiredKernelIds: <String>['when', 'where'],
          actorCount: 1,
          actorsWithFullBundle: 1,
          records: <ReplayActorKernelCoverageRecord>[
            ReplayActorKernelCoverageRecord(
              actorId: 'actor-1',
              localityAnchor: 'Downtown',
              hasFullBundle: true,
              attachedKernelIds: <String>['when', 'where'],
              readyKernelIds: <String>['when', 'where'],
              activationCountByKernel: <String, int>{'when': 2},
              higherAgentGuidanceCount: 1,
            ),
          ],
          traces: <ReplayKernelActivationTrace>[
            ReplayKernelActivationTrace(
              traceId: 'trace-1',
              actorId: 'actor-1',
              contextType: 'action',
              contextId: 'action-1',
              activatedKernelIds: <String>['when'],
              higherAgentGuidanceIds: <String>['locality-1'],
            ),
          ],
        ).toJson(),
      ),
    );

    final connectivityFile = File(
      '${exportRoot.path}/replay-world-snapshots/2023/world/60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json',
    )..parent.createSync(recursive: true);
    connectivityFile.writeAsStringSync(
      jsonEncode(<String, dynamic>{
        'profiles': <Map<String, dynamic>>[
          const ReplayConnectivityProfile(
            actorId: 'actor-1',
            localityAnchor: 'Downtown',
            dominantMode: ReplayConnectivityMode.wifi,
            deviceProfile: ReplayDeviceProfile(
              actorId: 'actor-1',
              deviceClass: 'phone',
              wifiEnabled: true,
              cellularEnabled: true,
              bleAvailable: true,
              backgroundSensingEnabled: true,
              offlinePreference: false,
              batteryPressureBand: ReplayBatteryPressureBand.moderate,
            ),
            transitions: <ReplayConnectivityStateTransition>[
              ReplayConnectivityStateTransition(
                transitionId: 'transition-1',
                actorId: 'actor-1',
                scheduleSurface: 'workday',
                windowLabel: 'morning',
                localityAnchor: 'Downtown',
                mode: ReplayConnectivityMode.wifi,
                reachable: true,
                reason: 'office wifi',
              ),
            ],
          ).toJson(),
        ],
      }),
    );

    final exchangeFile = File(
      '${exportRoot.path}/replay-exchange-logs/2023/exchange/62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
    )..parent.createSync(recursive: true);
    exchangeFile.writeAsStringSync(
      jsonEncode(<String, dynamic>{
        'threads': <Map<String, dynamic>>[
          const ReplayExchangeThread(
            threadId: 'thread-1',
            kind: ReplayExchangeThreadKind.personalAgent,
            localityAnchor: 'Downtown',
            associatedEntityId: null,
            participantActorIds: <String>['actor-1'],
          ).toJson(),
        ],
        'participations': <Map<String, dynamic>>[
          const ReplayExchangeParticipation(
            actorId: 'actor-1',
            threadId: 'thread-1',
            participationState: 'active',
            accessGranted: true,
            messageCount: 3,
          ).toJson(),
        ],
        'events': <Map<String, dynamic>>[
          const ReplayExchangeEvent(
            eventId: 'exchange-1',
            threadId: 'thread-1',
            kind: ReplayExchangeThreadKind.personalAgent,
            monthKey: '2023-01',
            localityAnchor: 'Downtown',
            senderActorId: 'actor-1',
            recipientActorIds: <String>[],
            interactionType: 'message',
            connectivityReceipt: ReplayConnectivityReceipt(
              receiptId: 'receipt-1',
              actorId: 'actor-1',
              preferredMode: ReplayConnectivityMode.wifi,
              actualMode: ReplayConnectivityMode.wifi,
              reachable: true,
              queuedOffline: false,
              reason: 'connected',
            ),
            activatedKernelIds: <String>['when'],
            higherAgentGuidanceIds: <String>['locality-1'],
          ).toJson(),
        ],
        'ai2aiRecords': <Map<String, dynamic>>[
          const ReplayAi2AiExchangeRecord(
            recordId: 'ai2ai-1',
            actorId: 'actor-1',
            threadId: 'thread-1',
            monthKey: '2023-01',
            localityAnchor: 'Downtown',
            routeMode: ReplayConnectivityMode.wifi,
            status: 'delivered',
            queuedOffline: false,
          ).toJson(),
        ],
      }),
    );

    final movementFile = File(
      '${exportRoot.path}/replay-world-snapshots/2023/world/67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json',
    )..parent.createSync(recursive: true);
    movementFile.writeAsStringSync(
      jsonEncode(
        const ReplayPhysicalMovementReport(
          environmentId: 'env-1',
          replayYear: 2023,
          trackedLocations: <ReplayTrackedLocationRecord>[
            ReplayTrackedLocationRecord(
              locationRecordId: 'location-1',
              actorId: 'actor-1',
              monthKey: '2023-01',
              localityAnchor: 'Downtown',
              trackingState: ReplayLocationTrackingState.tracked,
              locationKind: 'venue_visit',
              physicalRef: 'node:venue-1',
            ),
          ],
          untrackedWindows: <ReplayUntrackedLocationWindow>[
            ReplayUntrackedLocationWindow(
              windowId: 'window-1',
              actorId: 'actor-1',
              monthKey: '2023-01',
              localityAnchor: 'Downtown',
              windowLabel: 'home_cycle',
              reason: 'offgraph life',
            ),
          ],
          movements: <ReplayMovementRecord>[
            ReplayMovementRecord(
              movementId: 'movement-1',
              actorId: 'actor-1',
              monthKey: '2023-01',
              originPhysicalRef: 'home:Downtown:single',
              destinationPhysicalRef: 'node:venue-1',
              originLocalityAnchor: 'Downtown',
              destinationLocalityAnchor: 'Downtown',
              mode: ReplayMovementMode.walk,
              tracked: true,
            ),
          ],
          flights: <ReplayFlightRecord>[
            ReplayFlightRecord(
              flightId: 'flight-1',
              actorId: 'actor-1',
              monthKey: '2023-02',
              airportNodeId: 'airport:bhm',
              airportPhysicalRef: 'node:airport:bhm',
              destinationRegion: 'atlanta',
              reason: 'work travel',
            ),
          ],
        ).toJson(),
      ),
    );

    final partitionFile = File(
      '${partitionRoot.path}/45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json/items/chunk-0000.ndjson',
    )..parent.createSync(recursive: true);
    partitionFile.writeAsStringSync('{"ok":true}\n');

    final exportManifest = ReplayStorageExportManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      status: 'accepted_as_monte_carlo_base_year',
      exportRoot: exportRoot.path,
      projectIsolationMode: 'shared_project_isolated_namespace',
      replaySchema: 'replay_simulation',
      entries: const <ReplayStorageExportEntry>[
        ReplayStorageExportEntry(
          artifactRef: '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
          sourcePath: '/tmp/source/45.json',
          bucket: 'replay-world-snapshots',
          objectPath: '2023/world/45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
          byteSize: 1024,
        ),
        ReplayStorageExportEntry(
          artifactRef: '54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.json',
          sourcePath: '/tmp/source/54.json',
          bucket: 'replay-world-snapshots',
          objectPath: '2023/world/54_BHAM_REPLAY_REALISM_GATE_REPORT_2023.json',
          byteSize: 256,
        ),
        ReplayStorageExportEntry(
          artifactRef: '57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json',
          sourcePath: '/tmp/source/57.json',
          bucket: 'replay-world-snapshots',
          objectPath: '2023/world/57_BHAM_REPLAY_CALIBRATION_REPORT_2023.json',
          byteSize: 256,
        ),
        ReplayStorageExportEntry(
          artifactRef: '58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json',
          sourcePath: '/tmp/source/58.json',
          bucket: 'replay-training-exports',
          objectPath: '2023/training/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json',
          byteSize: 256,
        ),
        ReplayStorageExportEntry(
          artifactRef: '50_BHAM_REPLAY_POPULATION_PROFILE_2023.json',
          sourcePath: '/tmp/source/50.json',
          bucket: 'replay-world-snapshots',
          objectPath: '2023/world/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json',
          byteSize: 256,
        ),
        ReplayStorageExportEntry(
          artifactRef: '59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.json',
          sourcePath: '/tmp/source/59.json',
          bucket: 'replay-world-snapshots',
          objectPath: '2023/world/59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.json',
          byteSize: 256,
        ),
        ReplayStorageExportEntry(
          artifactRef: '60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json',
          sourcePath: '/tmp/source/60.json',
          bucket: 'replay-world-snapshots',
          objectPath: '2023/world/60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json',
          byteSize: 256,
        ),
        ReplayStorageExportEntry(
          artifactRef: '62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
          sourcePath: '/tmp/source/62.json',
          bucket: 'replay-exchange-logs',
          objectPath: '2023/exchange/62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
          byteSize: 256,
        ),
        ReplayStorageExportEntry(
          artifactRef: '67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json',
          sourcePath: '/tmp/source/67.json',
          bucket: 'replay-world-snapshots',
          objectPath: '2023/world/67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json',
          byteSize: 256,
        ),
      ],
    );
    final partitionManifest = ReplayStoragePartitionManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      partitionRoot: partitionRoot.path,
      maxRecordsPerChunk: 1000,
      entries: const <ReplayStoragePartitionEntry>[
        ReplayStoragePartitionEntry(
          artifactRef: '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
          section: 'items',
          chunkIndex: 0,
          recordCount: 1,
          objectPath:
              '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json/items/chunk-0000.ndjson',
          byteSize: 12,
        ),
      ],
    );

    final fakeGateway = _FakeReplaySupabaseStorageGateway();
    final service = BhamReplaySupabaseUploadIndexService(
      gatewayFactory: ({required client, required schema}) => fakeGateway,
    );
    final uploadManifest = service.buildUploadManifest(
      exportManifest: exportManifest,
      partitionManifest: partitionManifest,
      dryRun: false,
    );

    final result = await service.uploadAndIndex(
      uploadManifest: uploadManifest,
      exportManifest: exportManifest,
      partitionManifest: partitionManifest,
      replayUrl: 'https://replay.example.supabase.co',
      replayServiceRoleKey: 'service-role',
      dryRun: false,
    );

    expect(result.dryRun, isFalse);
    expect(fakeGateway.uploads, hasLength(uploadManifest.entries.length));
    expect(fakeGateway.upserts.keys, containsAll(<String>[
      'replay_runs',
      'replay_artifacts',
      'replay_artifact_partitions',
      'replay_lineage',
      'replay_calibration_reports',
      'replay_realism_gate_reports',
      'replay_training_exports',
      'replay_actor_profiles',
      'replay_actor_kernel_bundles',
      'replay_kernel_activation_traces',
      'replay_actor_connectivity_profiles',
      'replay_actor_connectivity_transitions',
      'replay_actor_tracked_locations',
      'replay_actor_untracked_windows',
      'replay_actor_movements',
      'replay_actor_flights',
      'replay_exchange_threads',
      'replay_exchange_participations',
      'replay_exchange_events',
      'replay_ai2ai_exchange_records',
    ]));
    expect(
      (result.metadata['indexedTables'] as Map<String, dynamic>)['replay_runs'],
      1,
    );
    expect(
      (result.metadata['indexedTables'] as Map<String, dynamic>)['replay_actor_profiles'],
      1,
    );
    expect(
      (result.metadata['indexedTables'] as Map<String, dynamic>)['replay_exchange_events'],
      1,
    );
  });
}
