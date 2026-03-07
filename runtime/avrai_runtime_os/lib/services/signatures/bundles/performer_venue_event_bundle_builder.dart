import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/user/user_vibe.dart';

import '../builders/bundle_signature_builder.dart';
import '../builders/spot_signature_builder.dart';
import '../builders/user_signature_builder.dart';

class PerformerVenueEventBundleBuilder {
  final BundleSignatureBuilder _bundleSignatureBuilder;
  final SpotSignatureBuilder _spotSignatureBuilder;
  final UserSignatureBuilder _userSignatureBuilder;

  const PerformerVenueEventBundleBuilder({
    required BundleSignatureBuilder bundleSignatureBuilder,
    required SpotSignatureBuilder spotSignatureBuilder,
    required UserSignatureBuilder userSignatureBuilder,
  })  : _bundleSignatureBuilder = bundleSignatureBuilder,
        _spotSignatureBuilder = spotSignatureBuilder,
        _userSignatureBuilder = userSignatureBuilder;

  EntitySignature? build({
    required ExpertiseEvent event,
    required UnifiedUser performer,
    required UserVibe performerVibe,
    required PersonalityProfile performerPersonality,
    Spot? venue,
    DateTime? now,
  }) {
    if (venue == null) {
      return null;
    }

    final performerSignature = _userSignatureBuilder.build(
      user: performer,
      personality: performerPersonality,
      userVibe: performerVibe,
      now: now,
    );
    final venueSignature = _spotSignatureBuilder.build(
      spot: venue,
      now: now,
    );
    return _bundleSignatureBuilder.build(
      BundleSignatureInput(
        bundleId: 'performer-venue-event:${event.id}',
        label: '${performer.displayName ?? 'Host'} at ${venue.name}',
        cityCode: event.cityCode ?? venue.cityCode,
        localityCode: event.localityCode ?? venue.localityCode,
        components: <EntitySignature>[
          performerSignature,
          venueSignature,
        ],
      ),
      now: now,
    );
  }
}
