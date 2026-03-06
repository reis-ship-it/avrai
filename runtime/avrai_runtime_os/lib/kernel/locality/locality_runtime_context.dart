import 'package:avrai_runtime_os/data/datasources/local/spots_local_datasource.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_inference_head.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_memory.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_projection_service.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_sync_coordinator.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';

class LocalityKernelRuntimeContext {
  final AgentIdService agentIdService;
  final GeoHierarchyService geoHierarchyService;
  final SharedPreferencesCompat? prefs;
  final SpotsLocalDataSource spotsLocalDataSource;
  final LocalityMemory memory;
  final LocalityInferenceHead inferenceHead;
  final LocalitySyncCoordinator syncCoordinator;
  final LocalityProjectionService projectionService;
  final LocalityTrainingContract trainingContract;

  const LocalityKernelRuntimeContext({
    required this.agentIdService,
    required this.geoHierarchyService,
    required this.prefs,
    required this.spotsLocalDataSource,
    required this.memory,
    required this.inferenceHead,
    required this.syncCoordinator,
    required this.projectionService,
    required this.trainingContract,
  });
}
