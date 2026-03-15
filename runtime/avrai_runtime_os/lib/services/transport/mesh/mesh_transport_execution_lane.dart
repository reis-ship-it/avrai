import 'package:avrai_runtime_os/services/transport/mesh/mesh_bearer_adapter.dart';

class MeshTransportExecutionResult {
  const MeshTransportExecutionResult({
    required this.forwardedRecipients,
    required this.failedPeers,
  });

  final Map<String, String> forwardedRecipients;
  final Map<String, Object> failedPeers;
}

class MeshTransportExecutionLane {
  const MeshTransportExecutionLane({
    required List<MeshBearerAdapter> adapters,
  }) : _adapters = adapters;

  final List<MeshBearerAdapter> _adapters;

  Future<MeshTransportExecutionResult> dispatch(
    MeshBearerDispatchRequest request,
  ) async {
    final forwardedRecipients = <String, String>{};
    final failedPeers = <String, Object>{};
    for (final adapter in _adapters) {
      final result = await adapter.dispatch(request);
      forwardedRecipients.addAll(result.forwardedRecipients);
      failedPeers.addAll(result.failedPeers);
    }
    return MeshTransportExecutionResult(
      forwardedRecipients: forwardedRecipients,
      failedPeers: failedPeers,
    );
  }
}
