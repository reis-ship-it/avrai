import 'package:avrai_network/avra_network.dart';

class EventModeCandidate {
  final DiscoveredDevice device;
  final String nodeTagKey;
  final bool remoteConnectOk;

  const EventModeCandidate({
    required this.device,
    required this.nodeTagKey,
    required this.remoteConnectOk,
  });
}
