import 'package:avrai_core/avra_core.dart';

class BhamReplayPlaceGraphService {
  const BhamReplayPlaceGraphService();

  ReplayPlaceGraph buildGraph({
    required Map<String, dynamic> consolidatedArtifact,
    required ReplayVirtualWorldEnvironment environment,
  }) {
    final citySlug = environment.metadata['citySlug']?.toString();
    final cityCode = environment.metadata['cityCode']?.toString();
    final cityDisplayName = environment.metadata['cityDisplayName']?.toString();
    final observations = _observations(consolidatedArtifact);
    final identityById = <String, ReplayEntityIdentity>{};
    final sourceRefsById = <String, Set<String>>{};
    final localityById = <String, String>{};
    final eventIdsByLocality = <String, List<String>>{};
    final communityIdsByLocality = <String, List<String>>{};
    final observationsById = <String, List<ReplayNormalizedObservation>>{};

    for (final observation in observations) {
      final subjectId = observation.subjectIdentity.normalizedEntityId;
      identityById.putIfAbsent(subjectId, () => observation.subjectIdentity);
      sourceRefsById.putIfAbsent(subjectId, () => <String>{});
      sourceRefsById[subjectId]!.addAll(observation.sourceRefs);
      final locality = observation.subjectIdentity.localityAnchor ??
          observation.normalizedFields['locality_anchor']?.toString() ??
          'unanchored';
      localityById[subjectId] = locality;
      observationsById.putIfAbsent(
          subjectId, () => <ReplayNormalizedObservation>[]);
      observationsById[subjectId]!.add(observation);
      if (observation.subjectIdentity.entityType == 'event') {
        eventIdsByLocality.putIfAbsent(locality, () => <String>[]);
        eventIdsByLocality[locality]!.add(subjectId);
      }
      if (observation.subjectIdentity.entityType == 'community') {
        communityIdsByLocality.putIfAbsent(locality, () => <String>[]);
        communityIdsByLocality[locality]!.add(subjectId);
      }
    }

    final venueProfiles = <ReplayVenueProfile>[];
    final clubProfiles = <ReplayClubProfile>[];
    final communityProfiles = <ReplayCommunityProfile>[];
    final eventProfiles = <ReplayEventProfile>[];
    final organizationProfiles = <ReplayOrganizationProfile>[];
    final directNodes = <ReplayPlaceGraphNode>[];
    final inferredNodes = <ReplayPlaceGraphNode>[];
    final venueCategoryCounts = <String, int>{};
    final organizationTypeCounts = <String, int>{};
    final communityCategoryCounts = <String, int>{};
    final eventCategoryCounts = <String, int>{};
    final clubCategoryCounts = <String, int>{};

    final sortedIds = identityById.keys.toList()..sort();
    for (final subjectId in sortedIds) {
      final identity = identityById[subjectId]!;
      final locality = localityById[subjectId] ?? 'unanchored';
      final rows =
          observationsById[subjectId] ?? const <ReplayNormalizedObservation>[];
      final sample = rows.first;
      final sourceRefs = (sourceRefsById[subjectId] ?? <String>{}).toList()
        ..sort();
      final associatedEventIds =
          List<String>.from(eventIdsByLocality[locality] ?? const <String>[]);
      final associatedCommunityIds = List<String>.from(
        communityIdsByLocality[locality] ?? const <String>[],
      );
      final category =
          _categoryFor(identity.entityType, sample.normalizedFields);
      final capacityBand = _capacityBand(category, sample.normalizedFields);
      final recurrenceAffinity = _recurrenceAffinity(
          identity.entityType, category, associatedEventIds.length);
      final demandBand = _demandPressureBand(
        identity.entityType,
        category,
        associatedEventIds.length,
        associatedCommunityIds.length,
      );
      final node = ReplayPlaceGraphNode(
        nodeId: 'place-graph:${identity.normalizedEntityId}',
        identity: identity,
        nodeType: identity.entityType,
        localityAnchor: locality,
        statusInReplayYear: _statusFor(identity.entityType),
        sourceRefs: sourceRefs,
        associatedEntityIds: <String>[
          ...associatedEventIds.take(12),
          ...associatedCommunityIds.take(12),
        ],
        venueCategory:
            _isVenueLike(identity.entityType, category) ? category : null,
        neighborhood: locality,
        capacityBand: capacityBand,
        recurrenceAffinity: recurrenceAffinity,
        demandPressureBand: demandBand,
        metadata: <String, dynamic>{
          'observationCount': rows.length,
          'nodeKind': 'direct',
        },
      );
      directNodes.add(node);

      if (_isVenueLike(identity.entityType, category)) {
        venueProfiles.add(
          ReplayVenueProfile(
            identity: identity,
            localityAnchor: locality,
            venueCategory: category,
            capacityBand: capacityBand,
            recurrenceAffinity: recurrenceAffinity,
            demandPressureBand: demandBand,
            sourceRefs: sourceRefs,
            metadata: <String, dynamic>{
              'entityType': identity.entityType,
              'inferred': false,
            },
          ),
        );
        venueCategoryCounts[category] =
            (venueCategoryCounts[category] ?? 0) + 1;
      }

      final organizationType =
          _organizationTypeFor(identity.entityType, sample.normalizedFields);
      final organizationId = _organizationIdFor(
              sample.normalizedFields, locality) ??
          (_shouldMaterializeOrganization(identity.entityType, category)
              ? 'organization:${_slugify('$locality-$category-${identity.canonicalName}')}'
              : null);
      final organizationName =
          _organizationNameFor(sample.normalizedFields, identity.canonicalName);
      if (organizationId != null) {
        organizationProfiles.add(
          ReplayOrganizationProfile(
            organizationId: organizationId,
            canonicalName: organizationName,
            organizationType: organizationType,
            localityAnchor: locality,
            sourceRefs: sourceRefs,
            associatedEntityIds: <String>[
              identity.normalizedEntityId,
              ...associatedEventIds.take(8),
              ...associatedCommunityIds.take(8),
            ],
            metadata: <String, dynamic>{
              'inferred':
                  _organizationIdFor(sample.normalizedFields, locality) == null,
            },
          ),
        );
        organizationTypeCounts[organizationType] =
            (organizationTypeCounts[organizationType] ?? 0) + 1;
      }

      if (identity.entityType == 'community') {
        final communityCategory =
            sample.normalizedFields['category']?.toString() ??
                sample.normalizedFields['organization_type']?.toString() ??
                'unknown';
        communityProfiles.add(
          ReplayCommunityProfile(
            identity: identity,
            localityAnchor: locality,
            communityCategory: communityCategory,
            organizationIds: organizationId == null
                ? const <String>[]
                : <String>[organizationId],
            eventIds: associatedEventIds.take(8).toList(growable: false),
            metadata: <String, dynamic>{
              'demandPressureBand': demandBand,
            },
          ),
        );
        communityCategoryCounts[communityCategory] =
            (communityCategoryCounts[communityCategory] ?? 0) + 1;
      }

      final directClubCategory =
          _clubCategoryFor(identity.entityType, category);
      if (directClubCategory != null) {
        final clubIdentity = identity.entityType == 'club'
            ? identity
            : ReplayEntityIdentity(
                normalizedEntityId:
                    'club:${_slugify('$locality-$directClubCategory-${identity.canonicalName}')}',
                entityType: 'club',
                canonicalName:
                    '${identity.canonicalName} ${_clubDisplaySuffix(directClubCategory)}',
                localityAnchor: locality,
              );
        clubProfiles.add(
          ReplayClubProfile(
            identity: clubIdentity,
            localityAnchor: locality,
            clubCategory: directClubCategory,
            hostOrganizationId: organizationId,
            venueIds: _isVenueLike(identity.entityType, category)
                ? <String>[identity.normalizedEntityId]
                : const <String>[],
            eventIds: associatedEventIds.take(8).toList(growable: false),
            sourceRefs: sourceRefs,
            metadata: <String, dynamic>{
              'inferred': identity.entityType != 'club',
            },
          ),
        );
        clubCategoryCounts[directClubCategory] =
            (clubCategoryCounts[directClubCategory] ?? 0) + 1;
        if (identity.entityType != 'club') {
          inferredNodes.add(
            ReplayPlaceGraphNode(
              nodeId: 'place-graph:${clubIdentity.normalizedEntityId}',
              identity: clubIdentity,
              nodeType: 'club',
              localityAnchor: locality,
              statusInReplayYear: 'active_structural',
              sourceRefs: sourceRefs,
              associatedEntityIds: <String>[
                identity.normalizedEntityId,
                ...associatedEventIds.take(6),
              ],
              venueCategory: directClubCategory,
              neighborhood: locality,
              capacityBand: capacityBand,
              recurrenceAffinity: recurrenceAffinity,
              demandPressureBand: demandBand,
              metadata: <String, dynamic>{
                'nodeKind': 'inferred_club',
              },
            ),
          );
        }
      }

      if (identity.entityType == 'event') {
        final eventCategory = _eventCategoryFor(sample.normalizedFields);
        eventProfiles.add(
          ReplayEventProfile(
            identity: identity,
            localityAnchor: locality,
            startsAtIso: sample.normalizedFields['starts_at']?.toString() ??
                sample.replayEnvelope.eventStartAt?.referenceTime
                    .toUtc()
                    .toIso8601String() ??
                sample.replayEnvelope.observedAt.referenceTime
                    .toUtc()
                    .toIso8601String(),
            recurrenceClass: _recurrenceClassFor(sample.normalizedFields),
            attendanceBand:
                _attendanceBandFor(sample.normalizedFields, locality),
            sourceRefs: sourceRefs,
            venueId: _venueIdFor(sample.normalizedFields),
            organizationId: organizationId,
            metadata: <String, dynamic>{
              'eventCategory': eventCategory,
              'inferred': false,
            },
          ),
        );
        eventCategoryCounts[eventCategory] =
            (eventCategoryCounts[eventCategory] ?? 0) + 1;
      }

      if (_shouldGenerateRecurringEvents(
          identity.entityType, category, recurrenceAffinity)) {
        final generatedEvents = _buildGeneratedEventsForNode(
          identity: identity,
          locality: locality,
          category: category,
          sourceRefs: sourceRefs,
          recurrenceAffinity: recurrenceAffinity,
          attendanceBand: _attendanceBandFor(sample.normalizedFields, locality),
          venueId: _isVenueLike(identity.entityType, category)
              ? identity.normalizedEntityId
              : _venueIdFor(sample.normalizedFields),
          organizationId: organizationId,
        );
        for (final generated in generatedEvents) {
          eventProfiles.add(generated);
          final eventCategory =
              generated.metadata['eventCategory']?.toString() ??
                  'community_event';
          eventCategoryCounts[eventCategory] =
              (eventCategoryCounts[eventCategory] ?? 0) + 1;
          inferredNodes.add(
            ReplayPlaceGraphNode(
              nodeId: 'place-graph:${generated.identity.normalizedEntityId}',
              identity: generated.identity,
              nodeType: 'event',
              localityAnchor: locality,
              statusInReplayYear: 'occurred_in_2023',
              sourceRefs: sourceRefs,
              associatedEntityIds: <String>[
                identity.normalizedEntityId,
                if (organizationId != null) organizationId,
              ],
              venueCategory: category,
              neighborhood: locality,
              capacityBand: capacityBand,
              recurrenceAffinity: generated.recurrenceClass,
              demandPressureBand: demandBand,
              metadata: <String, dynamic>{
                'nodeKind': 'inferred_event',
              },
            ),
          );
        }
      }
    }

    var finalVenueProfiles = _dedupeVenueProfiles(venueProfiles);
    var finalClubProfiles = _dedupeClubProfiles(clubProfiles);
    final finalOrganizationProfiles =
        _dedupeOrganizations(organizationProfiles);
    var finalCommunityProfiles = _dedupeCommunityProfiles(communityProfiles);
    final finalEventProfiles = _dedupeEventProfiles(eventProfiles);

    final inferredCommunityProfiles = _buildInferredCommunityProfiles(
      organizations: finalOrganizationProfiles,
      existingCommunities: finalCommunityProfiles,
    );
    finalCommunityProfiles = _dedupeCommunityProfiles(
      <ReplayCommunityProfile>[
        ...finalCommunityProfiles,
        ...inferredCommunityProfiles,
      ],
    );

    final eventInferredVenueProfiles = _buildInferredVenueProfilesFromEvents(
      events: finalEventProfiles,
      existingVenues: finalVenueProfiles,
    );
    final inferredVenueProfiles = _buildInferredVenueProfiles(
      communities: finalCommunityProfiles,
      organizations: finalOrganizationProfiles,
      existingVenues: finalVenueProfiles,
    );
    finalVenueProfiles = _dedupeVenueProfiles(
      <ReplayVenueProfile>[
        ...finalVenueProfiles,
        ...eventInferredVenueProfiles,
        ...inferredVenueProfiles,
      ],
    );

    final inferredCommunityProfilesFromVenues =
        _buildInferredCommunityProfilesFromVenues(
      venues: finalVenueProfiles,
      existingCommunities: finalCommunityProfiles,
    );
    finalCommunityProfiles = _dedupeCommunityProfiles(
      <ReplayCommunityProfile>[
        ...finalCommunityProfiles,
        ...inferredCommunityProfilesFromVenues,
      ],
    );

    final inferredClubProfiles = _buildInferredClubProfiles(
      communities: finalCommunityProfiles,
      organizations: finalOrganizationProfiles,
      venues: finalVenueProfiles,
      existingClubs: finalClubProfiles,
    );
    final inferredClubProfilesFromVenues = _buildInferredClubProfilesFromVenues(
      venues: finalVenueProfiles,
      existingClubs: finalClubProfiles,
    );
    finalClubProfiles = _dedupeClubProfiles(
      <ReplayClubProfile>[
        ...finalClubProfiles,
        ...inferredClubProfiles,
        ...inferredClubProfilesFromVenues,
      ],
    );

    final finalVenueCategoryCounts = <String, int>{};
    for (final profile in finalVenueProfiles) {
      finalVenueCategoryCounts[profile.venueCategory] =
          (finalVenueCategoryCounts[profile.venueCategory] ?? 0) + 1;
    }
    final finalOrganizationTypeCounts = <String, int>{};
    for (final profile in finalOrganizationProfiles) {
      finalOrganizationTypeCounts[profile.organizationType] =
          (finalOrganizationTypeCounts[profile.organizationType] ?? 0) + 1;
    }
    final finalCommunityCategoryCounts = <String, int>{};
    for (final profile in finalCommunityProfiles) {
      finalCommunityCategoryCounts[profile.communityCategory] =
          (finalCommunityCategoryCounts[profile.communityCategory] ?? 0) + 1;
    }
    final finalEventCategoryCounts = <String, int>{};
    for (final profile in finalEventProfiles) {
      final category =
          profile.metadata['eventCategory']?.toString() ?? 'community_event';
      finalEventCategoryCounts[category] =
          (finalEventCategoryCounts[category] ?? 0) + 1;
    }
    final finalClubCategoryCounts = <String, int>{};
    for (final profile in finalClubProfiles) {
      finalClubCategoryCounts[profile.clubCategory] =
          (finalClubCategoryCounts[profile.clubCategory] ?? 0) + 1;
    }

    final nodes = <ReplayPlaceGraphNode>[
      ...directNodes,
      ...inferredNodes,
    ];
    return ReplayPlaceGraph(
      replayYear: environment.replayYear,
      nodeCount: nodes.length,
      localityCounts: Map<String, int>.from(environment.localityCounts),
      venueCategoryCounts: _sortedCounts(finalVenueCategoryCounts),
      organizationTypeCounts: _sortedCounts(finalOrganizationTypeCounts),
      communityCategoryCounts: _sortedCounts(finalCommunityCategoryCounts),
      eventCategoryCounts: _sortedCounts(finalEventCategoryCounts),
      nodes: nodes,
      venueProfiles: finalVenueProfiles,
      clubProfiles: finalClubProfiles,
      organizationProfiles: finalOrganizationProfiles,
      communityProfiles: finalCommunityProfiles,
      eventProfiles: finalEventProfiles,
      metadata: <String, dynamic>{
        'environmentId': environment.environmentId,
        'graphKind': citySlug?.isNotEmpty == true
            ? 'canonical_${_slugify(citySlug!)}_truth_year_place_graph'
            : 'canonical_replay_truth_year_place_graph',
        'cityCode': cityCode,
        'citySlug': citySlug,
        'cityDisplayName': cityDisplayName,
        'cityPackManifestRef':
            environment.metadata['cityPackManifestRef']?.toString(),
        'cityPackId': environment.metadata['cityPackId']?.toString(),
        'cityPackStructuralRef':
            environment.metadata['cityPackStructuralRef']?.toString(),
        'campaignDefaultsRef':
            environment.metadata['campaignDefaultsRef']?.toString(),
        'localityExpectationProfileRef':
            environment.metadata['localityExpectationProfileRef']?.toString(),
        'worldHealthProfileRef':
            environment.metadata['worldHealthProfileRef']?.toString(),
        'directNodeCount': directNodes.length,
        'inferredNodeCount': inferredNodes.length,
        'clubCategoryCounts': _sortedCounts(finalClubCategoryCounts),
      },
    );
  }

  List<ReplayVenueProfile> _dedupeVenueProfiles(
    List<ReplayVenueProfile> profiles,
  ) {
    final byId = <String, ReplayVenueProfile>{};
    for (final profile in profiles) {
      byId.putIfAbsent(profile.identity.normalizedEntityId, () => profile);
    }
    return byId.values.toList(growable: false);
  }

  List<ReplayClubProfile> _dedupeClubProfiles(
    List<ReplayClubProfile> profiles,
  ) {
    final byId = <String, ReplayClubProfile>{};
    for (final profile in profiles) {
      byId.putIfAbsent(profile.identity.normalizedEntityId, () => profile);
    }
    return byId.values.toList(growable: false);
  }

  List<ReplayOrganizationProfile> _dedupeOrganizations(
    List<ReplayOrganizationProfile> profiles,
  ) {
    final byId = <String, ReplayOrganizationProfile>{};
    for (final profile in profiles) {
      byId.putIfAbsent(profile.organizationId, () => profile);
    }
    return byId.values.toList(growable: false);
  }

  List<ReplayCommunityProfile> _dedupeCommunityProfiles(
    List<ReplayCommunityProfile> profiles,
  ) {
    final byId = <String, ReplayCommunityProfile>{};
    for (final profile in profiles) {
      byId.putIfAbsent(profile.identity.normalizedEntityId, () => profile);
    }
    return byId.values.toList(growable: false);
  }

  List<ReplayEventProfile> _dedupeEventProfiles(
    List<ReplayEventProfile> profiles,
  ) {
    final byId = <String, ReplayEventProfile>{};
    for (final profile in profiles) {
      byId.putIfAbsent(profile.identity.normalizedEntityId, () => profile);
    }
    return byId.values.toList(growable: false);
  }

  List<ReplayCommunityProfile> _buildInferredCommunityProfiles({
    required List<ReplayOrganizationProfile> organizations,
    required List<ReplayCommunityProfile> existingCommunities,
  }) {
    final existingOrganizationIds = existingCommunities
        .expand((profile) => profile.organizationIds)
        .toSet();
    final inferred = <ReplayCommunityProfile>[];
    for (final organization in organizations) {
      if (existingOrganizationIds.contains(organization.organizationId)) {
        continue;
      }
      final category = _communityCategoryForOrganization(
        organization.organizationType,
      );
      if (category == null) {
        continue;
      }
      inferred.add(
        ReplayCommunityProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId:
                'community:${_slugify('${organization.localityAnchor}-${organization.canonicalName}')}',
            entityType: 'community',
            canonicalName: organization.canonicalName,
            localityAnchor: organization.localityAnchor,
          ),
          localityAnchor: organization.localityAnchor,
          communityCategory: category,
          organizationIds: <String>[organization.organizationId],
          eventIds: organization.associatedEntityIds
              .where((id) => id.startsWith('event:'))
              .toList(growable: false),
          metadata: <String, dynamic>{
            'inferred': true,
            'derivedFromOrganizationId': organization.organizationId,
          },
        ),
      );
    }
    return inferred;
  }

  List<ReplayVenueProfile> _buildInferredVenueProfiles({
    required List<ReplayCommunityProfile> communities,
    required List<ReplayOrganizationProfile> organizations,
    required List<ReplayVenueProfile> existingVenues,
  }) {
    final existingIds = existingVenues
        .map((profile) => profile.identity.normalizedEntityId)
        .toSet();
    final inferred = <ReplayVenueProfile>[];

    for (final community in communities) {
      final venueCategory = _venueCategoryForCommunity(community);
      if (venueCategory == null) {
        continue;
      }
      final venueId =
          'venue:${_slugify('${community.localityAnchor}-${community.identity.canonicalName}')}';
      if (!existingIds.add(venueId)) {
        continue;
      }
      inferred.add(
        ReplayVenueProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: venueId,
            entityType: 'venue',
            canonicalName: community.identity.canonicalName,
            localityAnchor: community.localityAnchor,
          ),
          localityAnchor: community.localityAnchor,
          venueCategory: venueCategory,
          capacityBand: _capacityBand(venueCategory, <String, dynamic>{}),
          recurrenceAffinity:
              community.eventIds.length >= 3 ? 'high' : 'medium',
          demandPressureBand:
              community.eventIds.isNotEmpty ? 'moderate' : 'low',
          sourceRefs: community.organizationIds,
          metadata: <String, dynamic>{
            'inferred': true,
            'derivedFromCommunityId': community.identity.normalizedEntityId,
          },
        ),
      );
    }

    for (final organization in organizations) {
      final venueCategory = _venueCategoryForOrganization(organization);
      if (venueCategory == null) {
        continue;
      }
      final venueId =
          'venue:${_slugify('${organization.localityAnchor}-${organization.canonicalName}')}';
      if (!existingIds.add(venueId)) {
        continue;
      }
      final eventIds = organization.associatedEntityIds
          .where((id) => id.startsWith('event:'))
          .toList(growable: false);
      inferred.add(
        ReplayVenueProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: venueId,
            entityType: 'venue',
            canonicalName: organization.canonicalName,
            localityAnchor: organization.localityAnchor,
          ),
          localityAnchor: organization.localityAnchor,
          venueCategory: venueCategory,
          capacityBand: _capacityBand(venueCategory, <String, dynamic>{}),
          recurrenceAffinity: eventIds.length >= 3 ? 'high' : 'medium',
          demandPressureBand: eventIds.isNotEmpty ? 'moderate' : 'low',
          sourceRefs: organization.sourceRefs,
          metadata: <String, dynamic>{
            'inferred': true,
            'derivedFromOrganizationId': organization.organizationId,
          },
        ),
      );
    }
    return inferred;
  }

  List<ReplayVenueProfile> _buildInferredVenueProfilesFromEvents({
    required List<ReplayEventProfile> events,
    required List<ReplayVenueProfile> existingVenues,
    Set<String>? seedIds,
  }) {
    final existingIds = seedIds ??
        existingVenues
            .map((profile) => profile.identity.normalizedEntityId)
            .toSet();
    final inferred = <ReplayVenueProfile>[];
    for (final event in events) {
      final venueId = event.venueId;
      if (venueId == null || venueId.isEmpty) {
        continue;
      }
      if (!existingIds.add(venueId)) {
        continue;
      }
      final venueCategory = _venueCategoryForEvent(event);
      inferred.add(
        ReplayVenueProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: venueId,
            entityType: 'venue',
            canonicalName: _canonicalNameFromEntityId(venueId),
            localityAnchor: event.localityAnchor,
          ),
          localityAnchor: event.localityAnchor,
          venueCategory: venueCategory,
          capacityBand: _capacityBand(venueCategory, const <String, dynamic>{}),
          recurrenceAffinity: event.recurrenceClass == 'annual'
              ? 'high'
              : event.recurrenceClass == 'one_off'
                  ? 'medium'
                  : 'high',
          demandPressureBand: event.attendanceBand == 'large'
              ? 'high'
              : event.attendanceBand == 'small'
                  ? 'low'
                  : 'moderate',
          sourceRefs: event.sourceRefs,
          metadata: <String, dynamic>{
            'inferred': true,
            'derivedFromEventId': event.identity.normalizedEntityId,
          },
        ),
      );
    }
    return inferred;
  }

  List<ReplayCommunityProfile> _buildInferredCommunityProfilesFromVenues({
    required List<ReplayVenueProfile> venues,
    required List<ReplayCommunityProfile> existingCommunities,
  }) {
    final existingIds = existingCommunities
        .map((profile) => profile.identity.normalizedEntityId)
        .toSet();
    final inferred = <ReplayCommunityProfile>[];
    for (final venue in venues) {
      final communityCategory = _communityCategoryForVenue(venue);
      if (communityCategory == null) {
        continue;
      }
      final communityId =
          'community:${_slugify('${venue.localityAnchor}-${venue.identity.canonicalName}')}';
      if (!existingIds.add(communityId)) {
        continue;
      }
      inferred.add(
        ReplayCommunityProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: communityId,
            entityType: 'community',
            canonicalName: venue.identity.canonicalName,
            localityAnchor: venue.localityAnchor,
          ),
          localityAnchor: venue.localityAnchor,
          communityCategory: communityCategory,
          organizationIds: const <String>[],
          eventIds: const <String>[],
          metadata: <String, dynamic>{
            'inferred': true,
            'derivedFromVenueId': venue.identity.normalizedEntityId,
          },
        ),
      );
    }
    return inferred;
  }

  List<ReplayClubProfile> _buildInferredClubProfiles({
    required List<ReplayCommunityProfile> communities,
    required List<ReplayOrganizationProfile> organizations,
    required List<ReplayVenueProfile> venues,
    required List<ReplayClubProfile> existingClubs,
  }) {
    final existingIds = existingClubs
        .map((profile) => profile.identity.normalizedEntityId)
        .toSet();
    final inferred = <ReplayClubProfile>[];

    for (final community in communities) {
      final clubCategory = _clubCategoryForCommunity(community);
      if (clubCategory == null) {
        continue;
      }
      final clubId =
          'club:${_slugify('${community.localityAnchor}-${community.identity.canonicalName}')}';
      if (!existingIds.add(clubId)) {
        continue;
      }
      inferred.add(
        ReplayClubProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: clubId,
            entityType: 'club',
            canonicalName:
                '${community.identity.canonicalName} ${_clubDisplaySuffix(clubCategory)}',
            localityAnchor: community.localityAnchor,
          ),
          localityAnchor: community.localityAnchor,
          clubCategory: clubCategory,
          hostOrganizationId: community.organizationIds.isEmpty
              ? null
              : community.organizationIds.first,
          venueIds: venues
              .where(
                  (venue) => venue.localityAnchor == community.localityAnchor)
              .take(3)
              .map((venue) => venue.identity.normalizedEntityId)
              .toList(growable: false),
          eventIds: community.eventIds.take(8).toList(growable: false),
          sourceRefs: community.organizationIds,
          metadata: <String, dynamic>{
            'inferred': true,
            'derivedFromCommunityId': community.identity.normalizedEntityId,
          },
        ),
      );
    }

    for (final organization in organizations) {
      final clubCategory = _clubCategoryForOrganization(organization);
      if (clubCategory == null) {
        continue;
      }
      final clubId =
          'club:${_slugify('${organization.localityAnchor}-${organization.canonicalName}')}';
      if (!existingIds.add(clubId)) {
        continue;
      }
      final eventIds = organization.associatedEntityIds
          .where((id) => id.startsWith('event:'))
          .take(8)
          .toList(growable: false);
      inferred.add(
        ReplayClubProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: clubId,
            entityType: 'club',
            canonicalName:
                '${organization.canonicalName} ${_clubDisplaySuffix(clubCategory)}',
            localityAnchor: organization.localityAnchor,
          ),
          localityAnchor: organization.localityAnchor,
          clubCategory: clubCategory,
          hostOrganizationId: organization.organizationId,
          venueIds: venues
              .where((venue) =>
                  venue.localityAnchor == organization.localityAnchor)
              .take(3)
              .map((venue) => venue.identity.normalizedEntityId)
              .toList(growable: false),
          eventIds: eventIds,
          sourceRefs: organization.sourceRefs,
          metadata: <String, dynamic>{
            'inferred': true,
            'derivedFromOrganizationId': organization.organizationId,
          },
        ),
      );
    }

    return inferred;
  }

  List<ReplayClubProfile> _buildInferredClubProfilesFromVenues({
    required List<ReplayVenueProfile> venues,
    required List<ReplayClubProfile> existingClubs,
  }) {
    final existingIds = existingClubs
        .map((profile) => profile.identity.normalizedEntityId)
        .toSet();
    final inferred = <ReplayClubProfile>[];
    for (final venue in venues) {
      final clubCategory = _clubCategoryForVenue(venue);
      if (clubCategory == null) {
        continue;
      }
      final clubId =
          'club:${_slugify('${venue.localityAnchor}-${venue.identity.canonicalName}')}';
      if (!existingIds.add(clubId)) {
        continue;
      }
      inferred.add(
        ReplayClubProfile(
          identity: ReplayEntityIdentity(
            normalizedEntityId: clubId,
            entityType: 'club',
            canonicalName:
                '${venue.identity.canonicalName} ${_clubDisplaySuffix(clubCategory)}',
            localityAnchor: venue.localityAnchor,
          ),
          localityAnchor: venue.localityAnchor,
          clubCategory: clubCategory,
          hostOrganizationId: null,
          venueIds: <String>[venue.identity.normalizedEntityId],
          eventIds: const <String>[],
          sourceRefs: venue.sourceRefs,
          metadata: <String, dynamic>{
            'inferred': true,
            'derivedFromVenueId': venue.identity.normalizedEntityId,
          },
        ),
      );
    }
    return inferred;
  }

  String? _venueIdFor(Map<String, dynamic> fields) {
    final venueName = fields['venue_name']?.toString();
    if (venueName == null || venueName.isEmpty) {
      return null;
    }
    return 'venue:${_slugify(venueName)}';
  }

  String? _organizationIdFor(Map<String, dynamic> fields, String locality) {
    final raw = fields['community_name']?.toString() ??
        fields['organization_name']?.toString() ??
        fields['source_host']?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return 'organization:${_slugify('$locality-$raw')}';
  }

  String _organizationNameFor(Map<String, dynamic> fields, String fallback) {
    return fields['community_name']?.toString() ??
        fields['organization_name']?.toString() ??
        fields['source_host']?.toString() ??
        fallback;
  }

  String _categoryFor(String entityType, Map<String, dynamic> fields) {
    return fields['poi_type']?.toString() ??
        fields['amenity']?.toString() ??
        fields['tourism']?.toString() ??
        fields['category']?.toString() ??
        fields['feature_type']?.toString() ??
        entityType;
  }

  String _eventCategoryFor(Map<String, dynamic> fields) {
    final title = (fields['source_page_title'] ?? fields['name'] ?? '')
        .toString()
        .toLowerCase();
    if (title.contains('festival') || title.contains('classic')) {
      return 'festival';
    }
    if (title.contains('tour') ||
        title.contains('concert') ||
        title.contains('celebration')) {
      return 'performance';
    }
    if (title.contains('museum') || title.contains('art')) {
      return 'arts';
    }
    return 'community_event';
  }

  String _recurrenceClassFor(Map<String, dynamic> fields) {
    final title = (fields['source_page_title'] ?? fields['name'] ?? '')
        .toString()
        .toLowerCase();
    if (title.contains('annual') || title.contains('classic')) {
      return 'annual';
    }
    if (title.contains('weekly') || title.contains('monthly')) {
      return 'recurring';
    }
    return 'one_off';
  }

  String _attendanceBandFor(Map<String, dynamic> fields, String locality) {
    final title = (fields['source_page_title'] ?? fields['name'] ?? '')
        .toString()
        .toLowerCase();
    if (title.contains('legacy') ||
        title.contains('protective') ||
        title.contains('classic')) {
      return 'large';
    }
    if (locality.contains('downtown') || locality.contains('uptown')) {
      return 'medium';
    }
    return 'small';
  }

  String _capacityBand(String category, Map<String, dynamic> fields) {
    final lowered = '$category ${fields['name'] ?? ''}'.toLowerCase();
    if (lowered.contains('stadium') ||
        lowered.contains('arena') ||
        lowered.contains('amphitheatre') ||
        lowered.contains('amphitheater')) {
      return 'large';
    }
    if (lowered.contains('theatre') ||
        lowered.contains('museum') ||
        lowered.contains('library') ||
        lowered.contains('garden') ||
        lowered.contains('park')) {
      return 'medium';
    }
    if (lowered.contains('restaurant') ||
        lowered.contains('bar') ||
        lowered.contains('club') ||
        lowered.contains('cafe') ||
        lowered.contains('pub')) {
      return 'small';
    }
    return 'medium';
  }

  String _recurrenceAffinity(
    String entityType,
    String category,
    int associatedEventCount,
  ) {
    if (entityType == 'community') {
      return 'high';
    }
    if (associatedEventCount >= 3) {
      return 'high';
    }
    if (category.contains('library') || category.contains('park')) {
      return 'medium';
    }
    return 'low';
  }

  String _demandPressureBand(
    String entityType,
    String category,
    int associatedEventCount,
    int associatedCommunityCount,
  ) {
    if (entityType == 'event') {
      return associatedEventCount >= 3 ? 'high' : 'moderate';
    }
    if (associatedEventCount >= 4 || associatedCommunityCount >= 4) {
      return 'high';
    }
    if (category.contains('restaurant') ||
        category.contains('theatre') ||
        category.contains('museum') ||
        category.contains('nightclub')) {
      return 'moderate';
    }
    return 'low';
  }

  String _statusFor(String entityType) {
    return switch (entityType) {
      'event' => 'occurred_in_2023',
      'community' => 'active_structural',
      'locality' => 'active_structural',
      'venue' => 'active_or_structural',
      'club' => 'active_or_structural',
      _ => 'active',
    };
  }

  List<ReplayNormalizedObservation> _observations(
    Map<String, dynamic> consolidatedArtifact,
  ) {
    final ingestion = Map<String, dynamic>.from(
      consolidatedArtifact['ingestion'] as Map? ?? const {},
    );
    final results = (ingestion['results'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        const <Map<String, dynamic>>[];
    final observations = <ReplayNormalizedObservation>[];
    for (final result in results) {
      final rows = (result['observations'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayNormalizedObservation.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayNormalizedObservation>[];
      observations.addAll(rows.where((observation) {
        return switch (observation.subjectIdentity.entityType) {
          'venue' || 'club' || 'community' || 'event' || 'locality' => true,
          _ => false,
        };
      }));
    }
    return observations;
  }

  Map<String, int> _sortedCounts(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((left, right) {
        final countOrder = right.value.compareTo(left.value);
        if (countOrder != 0) {
          return countOrder;
        }
        return left.key.compareTo(right.key);
      });
    return Map<String, int>.fromEntries(entries);
  }

  String _slugify(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  bool _isVenueLike(String entityType, String category) {
    if (entityType == 'venue' || entityType == 'club') {
      return true;
    }
    return category.contains('theatre') ||
        category.contains('museum') ||
        category.contains('library') ||
        category.contains('park') ||
        category.contains('restaurant') ||
        category.contains('cafe') ||
        category.contains('bar') ||
        category.contains('nightclub') ||
        category.contains('stadium') ||
        category.contains('arena') ||
        category.contains('arts_centre') ||
        category.contains('music_club') ||
        category.contains('community_centre') ||
        category.contains('public_library_branch') ||
        category.contains('playground') ||
        category.contains('viewpoint') ||
        category.contains('official_cultural_venue_anchor') ||
        category.contains('destination_community_anchor');
  }

  bool _shouldMaterializeOrganization(String entityType, String category) {
    return entityType == 'community' ||
        entityType == 'event' ||
        category.contains('association') ||
        category.contains('community') ||
        category.contains('library') ||
        category.contains('arts') ||
        category.contains('music') ||
        category.contains('sports') ||
        category.contains('place_of_worship');
  }

  String _organizationTypeFor(
    String entityType,
    Map<String, dynamic> fields,
  ) {
    return fields['organization_type']?.toString() ??
        fields['category']?.toString() ??
        fields['source_family']?.toString() ??
        entityType;
  }

  String? _clubCategoryFor(String entityType, String category) {
    if (entityType == 'club') {
      return category;
    }
    if (category.contains('music_club') ||
        category.contains('nightclub') ||
        category.contains('bar') ||
        category.contains('pub')) {
      return 'nightlife';
    }
    if (category.contains('sports')) {
      return 'sports';
    }
    if (category.contains('library') ||
        category.contains('community') ||
        category.contains('association') ||
        category.contains('recurring_social_group_anchor')) {
      return 'community';
    }
    if (category.contains('arts') || category.contains('theatre')) {
      return 'arts';
    }
    return null;
  }

  String _clubDisplaySuffix(String category) {
    return switch (category) {
      'nightlife' => 'Nightlife Club',
      'sports' => 'Sports Club',
      'arts' => 'Arts Club',
      _ => 'Community Club',
    };
  }

  String? _communityCategoryForOrganization(String organizationType) {
    final lowered = organizationType.toLowerCase();
    if (lowered.contains('arts')) {
      return 'arts';
    }
    if (lowered.contains('sports')) {
      return 'sports';
    }
    if (lowered.contains('library')) {
      return 'library';
    }
    if (lowered.contains('community') ||
        lowered.contains('association') ||
        lowered.contains('neighborhood') ||
        lowered.contains('church') ||
        lowered.contains('place_of_worship') ||
        lowered.contains('school')) {
      return 'community';
    }
    return null;
  }

  String? _communityCategoryForVenue(ReplayVenueProfile venue) {
    final category = venue.venueCategory.toLowerCase();
    if (category.contains('library')) {
      return 'library';
    }
    if (category.contains('arts') ||
        category.contains('theatre') ||
        category.contains('museum') ||
        category.contains('music')) {
      return 'arts';
    }
    if (category.contains('sports') ||
        category.contains('stadium') ||
        category.contains('arena')) {
      return 'sports';
    }
    if (category.contains('community') ||
        category.contains('park') ||
        category.contains('civic') ||
        category.contains('school')) {
      return 'community';
    }
    if (category.contains('nightclub') ||
        category.contains('bar') ||
        category.contains('pub')) {
      return 'nightlife';
    }
    return null;
  }

  String? _venueCategoryForCommunity(ReplayCommunityProfile community) {
    final loweredName = community.identity.canonicalName.toLowerCase();
    final loweredCategory = community.communityCategory.toLowerCase();
    if (_looksLikePlaceAnchor(loweredName) ||
        loweredCategory.contains('library') ||
        loweredCategory.contains('arts') ||
        loweredCategory.contains('sports') ||
        loweredCategory.contains('community')) {
      return loweredCategory == 'arts'
          ? 'arts_centre'
          : loweredCategory == 'library'
              ? 'library'
              : loweredCategory == 'sports'
                  ? 'sports_centre'
                  : 'community_centre';
    }
    return null;
  }

  String? _venueCategoryForOrganization(
      ReplayOrganizationProfile organization) {
    final loweredName = organization.canonicalName.toLowerCase();
    final loweredType = organization.organizationType.toLowerCase();
    if (_looksLikePlaceAnchor(loweredName) ||
        loweredType.contains('library') ||
        loweredType.contains('arts') ||
        loweredType.contains('sports') ||
        loweredType.contains('community') ||
        loweredType.contains('association')) {
      return loweredType.contains('library')
          ? 'library'
          : loweredType.contains('arts')
              ? 'arts_centre'
              : loweredType.contains('sports')
                  ? 'sports_centre'
                  : 'community_centre';
    }
    return null;
  }

  String? _clubCategoryForCommunity(ReplayCommunityProfile community) {
    final loweredName = community.identity.canonicalName.toLowerCase();
    final loweredCategory = community.communityCategory.toLowerCase();
    if (loweredCategory.contains('sports')) {
      return 'sports';
    }
    if (loweredCategory.contains('arts') ||
        loweredName.contains('theatre') ||
        loweredName.contains('music')) {
      return 'arts';
    }
    if (loweredCategory.contains('community') ||
        loweredCategory.contains('library') ||
        loweredName.contains('association') ||
        loweredName.contains('church') ||
        loweredName.contains('center') ||
        community.eventIds.isNotEmpty) {
      return 'community';
    }
    return null;
  }

  String? _clubCategoryForOrganization(ReplayOrganizationProfile organization) {
    final loweredType = organization.organizationType.toLowerCase();
    final loweredName = organization.canonicalName.toLowerCase();
    if (loweredType.contains('sports')) {
      return 'sports';
    }
    if (loweredType.contains('arts') ||
        loweredName.contains('music') ||
        loweredName.contains('theatre')) {
      return 'arts';
    }
    if (loweredType.contains('community') ||
        loweredType.contains('association') ||
        loweredType.contains('library') ||
        loweredName.contains('church') ||
        organization.associatedEntityIds.any((id) => id.startsWith('event:'))) {
      return 'community';
    }
    return null;
  }

  String? _clubCategoryForVenue(ReplayVenueProfile venue) {
    final category = venue.venueCategory.toLowerCase();
    if (category.contains('nightclub') ||
        category.contains('bar') ||
        category.contains('pub') ||
        category.contains('music')) {
      return 'nightlife';
    }
    if (category.contains('sports') ||
        category.contains('stadium') ||
        category.contains('arena')) {
      return 'sports';
    }
    if (category.contains('arts') ||
        category.contains('theatre') ||
        category.contains('museum')) {
      return 'arts';
    }
    if (category.contains('community') ||
        category.contains('library') ||
        category.contains('park')) {
      return 'community';
    }
    return null;
  }

  String _venueCategoryForEvent(ReplayEventProfile event) {
    final eventCategory =
        event.metadata['eventCategory']?.toString().toLowerCase() ?? '';
    if (eventCategory.contains('festival')) {
      return 'festival_ground';
    }
    if (eventCategory.contains('performance')) {
      return 'music_venue';
    }
    if (eventCategory.contains('arts')) {
      return 'arts_centre';
    }
    if (eventCategory.contains('sports')) {
      return 'sports_centre';
    }
    if (eventCategory.contains('library')) {
      return 'library';
    }
    return event.attendanceBand == 'large'
        ? 'civic_event_space'
        : 'community_centre';
  }

  String _canonicalNameFromEntityId(String entityId) {
    final raw = entityId.contains(':') ? entityId.split(':').last : entityId;
    return raw
        .split('-')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part[0].toUpperCase() + part.substring(1),
        )
        .join(' ');
  }

  bool _looksLikePlaceAnchor(String loweredName) {
    return loweredName.contains('church') ||
        loweredName.contains('chapel') ||
        loweredName.contains('center') ||
        loweredName.contains('centre') ||
        loweredName.contains('hall') ||
        loweredName.contains('library') ||
        loweredName.contains('museum') ||
        loweredName.contains('theatre') ||
        loweredName.contains('theater') ||
        loweredName.contains('park') ||
        loweredName.contains('school') ||
        loweredName.contains('campus') ||
        loweredName.contains('arena') ||
        loweredName.contains('stadium') ||
        loweredName.contains('amphitheatre') ||
        loweredName.contains('amphitheater');
  }

  bool _shouldGenerateRecurringEvents(
    String entityType,
    String category,
    String recurrenceAffinity,
  ) {
    if (entityType == 'event') {
      return false;
    }
    return recurrenceAffinity != 'low' ||
        category.contains('library') ||
        category.contains('music') ||
        category.contains('theatre') ||
        category.contains('community') ||
        category.contains('association') ||
        category.contains('park');
  }

  List<ReplayEventProfile> _buildGeneratedEventsForNode({
    required ReplayEntityIdentity identity,
    required String locality,
    required String category,
    required List<String> sourceRefs,
    required String recurrenceAffinity,
    required String attendanceBand,
    required String? venueId,
    required String? organizationId,
  }) {
    final count = switch (recurrenceAffinity) {
      'high' => 4,
      'medium' => 2,
      _ => 1,
    };
    final months = switch (count) {
      4 => const <int>[1, 4, 7, 10],
      2 => const <int>[3, 9],
      _ => const <int>[6],
    };
    return months.map((month) {
      final eventId =
          'event:${_slugify('${identity.normalizedEntityId}-$month-generated')}';
      final eventCategory = category.contains('library')
          ? 'library_program'
          : category.contains('park')
              ? 'outdoor_community'
              : category.contains('theatre') || category.contains('music')
                  ? 'performance'
                  : category.contains('sports')
                      ? 'sports'
                      : 'community_event';
      return ReplayEventProfile(
        identity: ReplayEntityIdentity(
          normalizedEntityId: eventId,
          entityType: 'event',
          canonicalName: '${identity.canonicalName} ${_monthLabel(month)} 2023',
          localityAnchor: locality,
        ),
        localityAnchor: locality,
        startsAtIso: DateTime.utc(2023, month, 15).toIso8601String(),
        recurrenceClass: recurrenceAffinity == 'high'
            ? 'quarterly'
            : recurrenceAffinity == 'medium'
                ? 'seasonal'
                : 'annual',
        attendanceBand: attendanceBand,
        sourceRefs: sourceRefs,
        venueId: venueId,
        organizationId: organizationId,
        metadata: <String, dynamic>{
          'eventCategory': eventCategory,
          'inferred': true,
          'derivedFromEntityId': identity.normalizedEntityId,
        },
      );
    }).toList(growable: false);
  }

  String _monthLabel(int month) {
    const labels = <int, String>{
      1: 'Winter',
      3: 'Spring',
      4: 'Spring',
      6: 'Summer',
      7: 'Summer',
      9: 'Fall',
      10: 'Fall',
    };
    return labels[month] ?? 'Seasonal';
  }
}
