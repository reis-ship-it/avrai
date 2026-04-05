import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_inputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_outputs.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_projection.dart';

class LocalityWhereKernelAdapter extends WhereKernelContract {
  const LocalityWhereKernelAdapter({
    required LocalityWhereProviderContract provider,
  }) : _provider = provider;

  final LocalityWhereProviderContract _provider;

  @override
  Future<WhereState> resolveWhere(WhereKernelInput input) {
    return _provider.resolveWhere(input.toLocality()).then(
          WhereState.fromLocality,
        );
  }

  @override
  Future<WhereState> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'where_kernel_adapter',
  }) {
    return _provider
        .seedHomebase(
          userId: userId,
          agentId: agentId,
          latitude: latitude,
          longitude: longitude,
          cityCode: cityCode,
          source: source,
        )
        .then(WhereState.fromLocality);
  }

  @override
  Future<WhereObservationReceipt?> observeVisit({
    required String userId,
    required WhereVisit visit,
    required String source,
  }) {
    return _provider
        .observeVisit(
          userId: userId,
          visit: visit,
          source: source,
        )
        .then(
          (receipt) => receipt == null
              ? null
              : WhereObservationReceipt.fromLocality(receipt),
        );
  }

  @override
  Future<WhereObservationReceipt> observe(WhereObservation observation) {
    return _provider
        .observe(observation.toLocality())
        .then(WhereObservationReceipt.fromLocality);
  }

  @override
  Future<WhereSyncResult> sync(WhereSyncRequest request) {
    return _provider
        .sync(request.toLocality())
        .then(WhereSyncResult.fromLocality);
  }

  @override
  WhereProjection project(WhereProjectionRequest request) {
    return WhereProjection.fromLocality(
        _provider.project(request.toLocality()));
  }

  @override
  Future<WherePointResolution> resolvePoint(WherePointQuery request) {
    return _provider.resolvePoint(request.toLocality()).then(
          WherePointResolution.fromLocality,
        );
  }

  @override
  Future<bool> observeMeshUpdate({
    required WhereMeshKey key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  }) {
    return _provider.observeMeshUpdate(
      key: key.toLocality(),
      delta12: delta12,
      ttlMs: ttlMs,
      hop: hop,
    );
  }

  @override
  Future<WhereZeroReliabilityReport> evaluateZeroWhereReadiness({
    required String cityProfile,
    String modelFamily = 'reality_kernel',
    int localityCount = 12,
  }) {
    return _provider.evaluateZeroLocalityReadiness(
      cityProfile: cityProfile,
      modelFamily: modelFamily,
      localityCount: localityCount,
    );
  }

  @override
  WhereSnapshot? snapshot(String agentId) {
    final snapshot = _provider.snapshot(agentId);
    return snapshot == null ? null : WhereSnapshot.fromLocality(snapshot);
  }

  @override
  Future<WhereRecoveryResult> recover(WhereRecoveryRequest request) {
    return _provider
        .recover(request.toLocality())
        .then(WhereRecoveryResult.fromLocality);
  }

  @override
  WhereWhySnapshot explainWhy(WhereWhyRequest request) {
    return _provider.explainWhy(request);
  }

  @override
  Future<WhereRealityProjection> projectForRealityModel(
    WhereProjectionRequest request,
  ) {
    return _provider.projectForRealityModel(request.toLocality());
  }

  @override
  Future<KernelGovernanceProjection> projectForGovernance(
    WhereProjectionRequest request,
  ) {
    return _provider.projectForGovernance(request.toLocality());
  }

  @override
  Future<KernelHealthReport> diagnoseWhere() {
    return _provider.diagnoseWhere();
  }
}
