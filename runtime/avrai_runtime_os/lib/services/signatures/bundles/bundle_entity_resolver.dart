import 'package:avrai_core/models/community.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';

class BundleEntityResolver {
  const BundleEntityResolver();

  List<String> performerVenueEventEntityIds(ExpertiseEvent event) {
    return <String>[
      event.id,
      event.host.id,
      if (event.spots.isNotEmpty) event.spots.first.id,
    ];
  }

  List<String> communityEventEntityIds({
    required Community community,
    required ExpertiseEvent event,
  }) {
    return <String>[community.id, event.id];
  }
}
