// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_network/avra_network.dart';

class MeshForwardingContext {
  const MeshForwardingContext({
    required this.protocol,
    required this.discovery,
  });

  final AI2AIProtocol protocol;
  final DeviceDiscoveryService discovery;

  static MeshForwardingContext? tryCreate({
    required AI2AIProtocol? protocol,
    required DeviceDiscoveryService? discovery,
  }) {
    if (protocol == null || discovery == null) {
      return null;
    }
    return MeshForwardingContext(
      protocol: protocol,
      discovery: discovery,
    );
  }
}
