import 'package:avrai_core/models/community.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot.dart';

enum ExploreItemType {
  spot,
  event,
  community,
}

class ExploreItem {
  final String id;
  final ExploreItemType type;
  final String title;
  final String subtitle;
  final String scoreLabel;
  final String reason;
  final double score;
  final double? latitude;
  final double? longitude;
  final bool isLiveNow;
  final String? secondaryMeta;
  final Spot? spot;
  final ExpertiseEvent? event;
  final Community? community;

  const ExploreItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.scoreLabel,
    required this.reason,
    required this.score,
    this.latitude,
    this.longitude,
    this.isLiveNow = false,
    this.secondaryMeta,
    this.spot,
    this.event,
    this.community,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}
