import 'package:avrai_core/models/community.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';

import '../builders/bundle_signature_builder.dart';
import '../builders/community_signature_builder.dart';
import '../builders/event_signature_builder.dart';

class CommunityEventBundleBuilder {
  final BundleSignatureBuilder _bundleSignatureBuilder;
  final CommunitySignatureBuilder _communitySignatureBuilder;
  final EventSignatureBuilder _eventSignatureBuilder;

  const CommunityEventBundleBuilder({
    required BundleSignatureBuilder bundleSignatureBuilder,
    required CommunitySignatureBuilder communitySignatureBuilder,
    required EventSignatureBuilder eventSignatureBuilder,
  })  : _bundleSignatureBuilder = bundleSignatureBuilder,
        _communitySignatureBuilder = communitySignatureBuilder,
        _eventSignatureBuilder = eventSignatureBuilder;

  EntitySignature build({
    required Community community,
    required ExpertiseEvent event,
    DateTime? now,
  }) {
    final communitySignature = _communitySignatureBuilder.build(
      community: community,
      now: now,
    );
    final eventSignature = _eventSignatureBuilder.build(
      event: event,
      now: now,
    );
    return _bundleSignatureBuilder.build(
          BundleSignatureInput(
            bundleId: 'community-event:${community.id}:${event.id}',
            label: '${community.name} + ${event.title}',
            cityCode: event.cityCode ?? community.cityCode,
            localityCode: event.localityCode ?? community.localityCode,
            components: <EntitySignature>[
              communitySignature,
              eventSignature,
            ],
          ),
          now: now,
        ) ??
        eventSignature;
  }
}
