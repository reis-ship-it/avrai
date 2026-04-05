import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_bearer_adapter.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_transport_execution_lane.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMeshBearerAdapter extends MeshBearerAdapter {
  const _FakeMeshBearerAdapter(this.result);

  final MeshBearerDispatchResult result;

  @override
  Future<MeshBearerDispatchResult> dispatch(
    MeshBearerDispatchRequest request,
  ) async {
    return result;
  }
}

void main() {
  test('MeshTransportExecutionLane aggregates bearer adapter results', () async {
    final lane = MeshTransportExecutionLane(
      adapters: const <MeshBearerAdapter>[
        _FakeMeshBearerAdapter(
          MeshBearerDispatchResult(
            forwardedRecipients: <String, String>{'peer-a': 'node-a'},
          ),
        ),
        _FakeMeshBearerAdapter(
          MeshBearerDispatchResult(
            failedPeers: <String, Object>{'peer-b': 'failed'},
          ),
        ),
      ],
    );

    final result = await lane.dispatch(
      const MeshBearerDispatchRequest(
        candidatePeerIds: <String>['peer-a', 'peer-b'],
        senderNodeId: 'node-local',
        peerNodeIdByDeviceId: <String, String>{},
        messageType: MeshPacketType.learningInsight,
        payload: <String, dynamic>{'kind': 'test'},
      ),
    );

    expect(result.forwardedRecipients, <String, String>{'peer-a': 'node-a'});
    expect(result.failedPeers.keys, contains('peer-b'));
  });
}
