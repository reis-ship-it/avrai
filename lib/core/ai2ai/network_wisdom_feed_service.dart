import 'dart:developer' as developer;

import 'package:avrai/core/ai2ai/anonymous_communication.dart';

/// Network wisdom feed: aggregates delivered AI2AI messages and learning-derived
/// cues into a user-facing feed (e.g. local trends, event suggestions).
///
/// Data flow: [AnonymousCommunicationProtocol.getDeliveredMessages] for current
/// agent and peers; message types mapped to feed items. All data in-app only.
class NetworkWisdomFeedService {
  static const String _logName = 'NetworkWisdomFeedService';

  final AnonymousCommunicationProtocol _protocol;

  NetworkWisdomFeedService({
    required AnonymousCommunicationProtocol protocol,
  }) : _protocol = protocol;

  /// Build ordered feed items for the current agent, optionally including
  /// messages from/to the given peer agent IDs.
  ///
  /// [currentAgentId] – local user's agent ID.
  /// [peerAgentIds] – optional list of peer agent IDs to include (e.g. from orchestrator).
  /// Returns items sorted by timestamp descending (most recent first).
  Future<List<NetworkWisdomFeedItem>> getFeedItems({
    required String currentAgentId,
    List<String> peerAgentIds = const [],
  }) async {
    try {
      if (currentAgentId.isEmpty) return [];
      final allItems = <NetworkWisdomFeedItem>[];
      final peers = peerAgentIds.isEmpty ? [currentAgentId] : peerAgentIds;
      for (final peerId in peers) {
        if (peerId == currentAgentId) continue;
        final asTarget = await _protocol.getDeliveredMessages(
          senderAgentId: peerId,
          targetAgentId: currentAgentId,
        );
        final asSender = await _protocol.getDeliveredMessages(
          senderAgentId: currentAgentId,
          targetAgentId: peerId,
        );
        for (final m in asTarget) {
          allItems.add(_messageToFeedItem(m, fromNetwork: true));
        }
        for (final m in asSender) {
          allItems.add(_messageToFeedItem(m, fromNetwork: false));
        }
      }
      allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allItems;
    } catch (e, st) {
      developer.log('getFeedItems failed',
          name: _logName, error: e, stackTrace: st);
      return [];
    }
  }

  NetworkWisdomFeedItem _messageToFeedItem(DeliveredAI2AIMessage m,
      {required bool fromNetwork}) {
    final type = m.messageType.name;
    final shortLabel = _shortLabelForType(type, m.decryptedPayload);
    final deepLink = _deepLinkForType(type, m.decryptedPayload);
    return NetworkWisdomFeedItem(
      id: m.messageId,
      type: type,
      shortLabel: shortLabel,
      timestamp: m.timestamp,
      deepLink: deepLink,
      fromNetwork: fromNetwork,
    );
  }

  String _shortLabelForType(String type, Map<String, dynamic> payload) {
    switch (type) {
      case 'recommendationShare':
        final hint =
            payload['hint'] as String? ?? payload['category'] as String?;
        return hint != null
            ? 'Recommendation: $hint'
            : 'Recommendation from network';
      case 'discoverySync':
        return 'Discovery sync';
      case 'trustVerification':
        return 'Trust update';
      case 'reputationUpdate':
        return 'Reputation update';
      case 'userChat':
        return 'Chat activity';
      case 'networkMaintenance':
        return 'Network update';
      case 'emergencyAlert':
        return 'Alert';
      default:
        return 'From the network';
    }
  }

  String? _deepLinkForType(String type, Map<String, dynamic> payload) {
    if (type == 'recommendationShare') {
      final spotId = payload['spot_id'] as String?;
      if (spotId != null && spotId.isNotEmpty) return '/spots/$spotId';
      final eventId = payload['event_id'] as String?;
      if (eventId != null && eventId.isNotEmpty) return '/events/$eventId';
    }
    return null;
  }
}

/// Single item in the network wisdom feed.
class NetworkWisdomFeedItem {
  final String id;
  final String type;
  final String shortLabel;
  final DateTime timestamp;
  final String? deepLink;
  final bool fromNetwork;

  const NetworkWisdomFeedItem({
    required this.id,
    required this.type,
    required this.shortLabel,
    required this.timestamp,
    this.deepLink,
    this.fromNetwork = true,
  });
}
