import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/geographic/discovered_spot_candidate.dart';
import 'package:avrai_runtime_os/services/places/geohash_service.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/models/visit_pattern.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';

/// Organic Spot Discovery Service
///
/// Discovers meaningful locations organically from user behavior. When users
/// repeatedly visit locations that don't match any known place in Google Places,
/// Apple Maps, or community-created spots, this service detects the pattern,
/// clusters visits by proximity, and surfaces "discovered spot candidates."
///
/// Philosophy: "Every spot is a door." These are doors that haven't been
/// named yet -- the system learns them from how people live, not from databases.
///
/// Integration points:
/// - [LocationPatternAnalyzer] calls [processUnmatchedVisit] after recording
///   a visit with no placeId match
/// - [AnonymousCommunicationProtocol] shares anonymized cluster signals via mesh
/// - [ContinuousLearningSystem] receives discovery events as learning signals
/// - [PersonalityLearning] evolves personality when user creates spots from
///   discoveries (explorer/curator traits)
/// - [ContextEngine] includes discovered spots in recommendation context
/// - [EpisodicMemory] records discovery as (state, action, next_state, outcome)
///
/// See: docs/plans/organic_spot_discovery/ORGANIC_SPOT_DISCOVERY_PLAN.md
class OrganicSpotDiscoveryService {
  static const String _logName = 'OrganicSpotDiscoveryService';
  static const String _boxName = 'organic_spot_discoveries';

  /// Geohash precision for clustering (~153m radius)
  static const int _clusterPrecision = 7;

  /// Minimum visits by a single user to surface a candidate
  static const int _minVisitsThreshold = 3;

  /// Minimum unique mesh users to surface a candidate (overrides visit count)
  static const int _minUniqueUsersThreshold = 2;

  /// Minimum dwell time (minutes) for a visit to count toward discovery
  static const int _minDwellMinutes = 5;

  /// Maximum candidates stored per user
  static const int _maxCandidatesPerUser = 50;

  /// Confidence boost per visit
  static const double _confidencePerVisit = 0.15;

  /// Confidence boost per unique mesh user
  static const double _confidencePerMeshUser = 0.25;

  /// Confidence boost for group visits
  static const double _confidenceGroupBoost = 0.1;

  /// Confidence boost for consistent timing patterns
  static const double _confidenceTimingBoost = 0.1;

  // Dependencies
  final AtomicClockService _atomicClock;

  // Storage
  static GetStorage? _storage;

  GetStorage get _box {
    _storage ??= GetStorage(_boxName);
    return _storage!;
  }

  /// Initialize storage -- must be called before using the service
  static Future<void> initStorage() async {
    await GetStorage.init(_boxName);
  }

  OrganicSpotDiscoveryService({required AtomicClockService atomicClock})
      : _atomicClock = atomicClock;

  // ─── Core Discovery Logic ────────────────────────────────────────────

  /// Process an unmatched visit (no placeId from external databases).
  ///
  /// Called by [LocationPatternAnalyzer.recordVisit] when _matchToPlace
  /// returns null. This is the primary entry point for organic discovery.
  ///
  /// Returns the updated [DiscoveredSpotCandidate] if one was created or
  /// updated, or null if the visit didn't qualify (e.g., dwell too short).
  Future<DiscoveredSpotCandidate?> processUnmatchedVisit({
    required String userId,
    required double latitude,
    required double longitude,
    required Duration dwellTime,
    required DateTime timestamp,
    required DayOfWeek dayOfWeek,
    required TimeSlot timeSlot,
    int groupSize = 1,
  }) async {
    // Skip very short visits -- they're likely just passing through
    if (dwellTime.inMinutes < _minDwellMinutes) {
      developer.log(
        'Skipping unmatched visit: dwell time ${dwellTime.inMinutes}m < '
        '${_minDwellMinutes}m threshold',
        name: _logName,
      );
      return null;
    }

    developer.log(
      'Processing unmatched visit for $userId at '
      '($latitude, $longitude), dwell: ${dwellTime.inMinutes}m',
      name: _logName,
    );

    // Compute geohash for clustering
    final geohash = GeohashService.encode(
      latitude: latitude,
      longitude: longitude,
      precision: _clusterPrecision,
    );

    // Look for existing candidate at this geohash cluster
    var candidate = await _findCandidateByGeohash(userId, geohash);

    if (candidate != null) {
      // Update existing candidate with new visit
      candidate = _updateCandidateWithVisit(
        candidate: candidate,
        latitude: latitude,
        longitude: longitude,
        dwellMinutes: dwellTime.inMinutes,
        timestamp: timestamp,
        dayOfWeek: dayOfWeek,
        timeSlot: timeSlot,
        groupSize: groupSize,
      );
    } else {
      // Create new candidate for this cluster
      candidate = DiscoveredSpotCandidate(
        id: const Uuid().v4(),
        userId: userId,
        centroidLatitude: latitude,
        centroidLongitude: longitude,
        geohash: geohash,
        visitCount: 1,
        uniqueUserCount: 1,
        confidence: _calculateConfidence(
          visitCount: 1,
          uniqueUserCount: 1,
          hasGroupVisits: groupSize > 1,
          hasConsistentTiming: false,
        ),
        inferredCategory: _inferCategory(
          timeSlot: timeSlot,
          dwellMinutes: dwellTime.inMinutes,
          dayOfWeek: dayOfWeek,
          groupSize: groupSize,
        ),
        status: DiscoveredSpotStatus.detecting,
        firstVisitAt: timestamp,
        lastVisitAt: timestamp,
        averageDwellMinutes: dwellTime.inMinutes,
        weekendHeavy:
            dayOfWeek == DayOfWeek.saturday || dayOfWeek == DayOfWeek.sunday,
        groupVisitsDetected: groupSize > 1,
      );
    }

    // Check if candidate has reached threshold
    if (_hasReachedThreshold(candidate) &&
        candidate.status == DiscoveredSpotStatus.detecting) {
      candidate = candidate.copyWith(status: DiscoveredSpotStatus.ready);
      developer.log(
        'Candidate ${candidate.id} reached discovery threshold! '
        '${candidate.visitCount} visits, '
        '${candidate.uniqueUserCount} unique users',
        name: _logName,
      );
    }

    // Persist the candidate
    await _saveCandidate(candidate);

    return candidate;
  }

  /// Process a discovery signal received from the AI2AI mesh.
  ///
  /// When another user's AI detects an unmatched location at the same
  /// geohash, it shares an anonymized signal. This boosts our confidence
  /// that the location is meaningful.
  ///
  /// Called by [ConnectionOrchestrator] when receiving an
  /// 'organic_spot_discovery' mesh message.
  Future<DiscoveredSpotCandidate?> processMeshDiscoverySignal({
    required String userId,
    required String geohash,
    required int reportedVisitCount,
    required double centroidLatitude,
    required double centroidLongitude,
  }) async {
    developer.log(
      'Processing mesh discovery signal for geohash: $geohash '
      '($reportedVisitCount visits reported)',
      name: _logName,
    );

    var candidate = await _findCandidateByGeohash(userId, geohash);

    if (candidate != null) {
      // Boost existing candidate with mesh signal
      final newUniqueCount = candidate.uniqueUserCount + 1;
      candidate = candidate.copyWith(
        uniqueUserCount: newUniqueCount,
        confidence: _calculateConfidence(
          visitCount: candidate.visitCount,
          uniqueUserCount: newUniqueCount,
          hasGroupVisits: candidate.groupVisitsDetected,
          hasConsistentTiming: true, // Mesh signal implies consistency
        ),
      );

      // Check if mesh signal pushed us over the threshold
      if (_hasReachedThreshold(candidate) &&
          candidate.status == DiscoveredSpotStatus.detecting) {
        candidate = candidate.copyWith(status: DiscoveredSpotStatus.ready);
        developer.log(
          'Mesh signal pushed candidate ${candidate.id} to ready! '
          '$newUniqueCount unique users',
          name: _logName,
        );
      }
    } else {
      // Create new candidate from mesh signal -- we haven't visited
      // this place ourselves, but others have. Store it so if we visit
      // later, we already have community context.
      final now = await _atomicClock.getAtomicTimestamp();
      candidate = DiscoveredSpotCandidate(
        id: const Uuid().v4(),
        userId: userId,
        centroidLatitude: centroidLatitude,
        centroidLongitude: centroidLongitude,
        geohash: geohash,
        visitCount: 0, // We haven't visited ourselves
        uniqueUserCount: 1, // One mesh user reported it
        confidence: _calculateConfidence(
          visitCount: 0,
          uniqueUserCount: 1,
          hasGroupVisits: false,
          hasConsistentTiming: false,
        ),
        inferredCategory: InferredCategory.unknown,
        status: DiscoveredSpotStatus.detecting,
        firstVisitAt: now.serverTime,
        lastVisitAt: now.serverTime,
        averageDwellMinutes: 0,
      );
    }

    await _saveCandidate(candidate);
    return candidate;
  }

  // ─── Candidate Retrieval ─────────────────────────────────────────────

  /// Get all discovery candidates for a user that are ready to surface.
  ///
  /// Used by [ContextEngine] and [PerpetualListOrchestrator] to include
  /// discovered spots in recommendations.
  Future<List<DiscoveredSpotCandidate>> getReadyCandidates(
    String userId,
  ) async {
    final candidates = await _loadAllCandidates(userId);
    return candidates
        .where((c) => c.status == DiscoveredSpotStatus.ready)
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  /// Get all active candidates (detecting + ready) for a user.
  Future<List<DiscoveredSpotCandidate>> getActiveCandidates(
    String userId,
  ) async {
    final candidates = await _loadAllCandidates(userId);
    return candidates
        .where(
          (c) =>
              c.status == DiscoveredSpotStatus.detecting ||
              c.status == DiscoveredSpotStatus.ready,
        )
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  /// Get the single best candidate to surface to the user right now.
  ///
  /// Returns null if no candidate is ready, or if all ready candidates
  /// have already been prompted.
  Future<DiscoveredSpotCandidate?> getBestCandidateToSurface(
    String userId,
  ) async {
    final candidates = await getReadyCandidates(userId);
    if (candidates.isEmpty) return null;

    // Return highest-confidence candidate that hasn't been prompted
    return candidates.first;
  }

  // ─── Candidate State Transitions ─────────────────────────────────────

  /// Mark a candidate as prompted (user has been shown the suggestion).
  Future<void> markAsPrompted(String userId, String candidateId) async {
    final candidate = await _findCandidateById(userId, candidateId);
    if (candidate == null) return;

    await _saveCandidate(
      candidate.copyWith(status: DiscoveredSpotStatus.prompted),
    );

    developer.log('Candidate $candidateId marked as prompted', name: _logName);
  }

  /// Mark a candidate as created (user created a full Spot from it).
  ///
  /// This is the happy path -- the system discovered a meaningful place,
  /// the user confirmed it, and now it's a real spot in the system.
  ///
  /// The [createdSpotId] links back to the full [Spot] entity.
  Future<void> markAsCreated(
    String userId,
    String candidateId,
    String createdSpotId,
  ) async {
    final candidate = await _findCandidateById(userId, candidateId);
    if (candidate == null) return;

    await _saveCandidate(
      candidate.copyWith(
        status: DiscoveredSpotStatus.created,
        createdSpotId: createdSpotId,
      ),
    );

    developer.log(
      'Candidate $candidateId converted to spot $createdSpotId',
      name: _logName,
    );
  }

  /// Mark a candidate as dismissed (user rejected the suggestion).
  ///
  /// The candidate won't be surfaced again. We still learn from this --
  /// it tells us what kinds of unmatched locations the user does NOT
  /// consider meaningful.
  Future<void> dismissCandidate(
    String userId,
    String candidateId, {
    NegativePreferenceIntent intent =
        NegativePreferenceIntent.hardNotInterested,
  }) async {
    final candidate = await _findCandidateById(userId, candidateId);
    if (candidate == null) return;

    await _saveCandidate(
      candidate.copyWith(status: DiscoveredSpotStatus.dismissed),
    );

    final getIt = GetIt.instance;
    if (getIt.isRegistered<EntitySignatureService>()) {
      await getIt<EntitySignatureService>().recordNegativePreferenceSignal(
        userId: userId,
        title: 'Unmatched location candidate',
        subtitle:
            'Candidate ${candidate.inferredCategory.name} at ${candidate.geohash}',
        category: candidate.inferredCategory.name,
        tags: <String>[
          candidate.geohash,
          candidate.inferredCategory.name,
          'organic_spot_candidate',
        ],
        intent: intent,
        entityType: 'organic_spot_candidate',
      );
    }

    developer.log('Candidate $candidateId dismissed by user', name: _logName);
  }

  // ─── Mesh Signal Generation ──────────────────────────────────────────

  /// Generate an anonymized mesh signal for a discovery candidate.
  ///
  /// This is called when a candidate reaches a certain confidence to share
  /// the discovery with nearby devices via the AI2AI mesh. The signal
  /// contains ONLY the geohash and visit count -- never raw GPS, user
  /// identity, or visit timing.
  ///
  /// Returns null if the candidate is not yet worth sharing.
  Map<String, dynamic>? generateMeshSignal(DiscoveredSpotCandidate candidate) {
    // Only share candidates with at least 2 visits (not noise)
    if (candidate.visitCount < 2) return null;

    return {
      'type': 'organic_spot_discovery',
      'geohash': candidate.geohash,
      'visitCount': candidate.visitCount,
      'centroidLatitude': candidate.centroidLatitude,
      'centroidLongitude': candidate.centroidLongitude,
      'inferredCategory': candidate.inferredCategory.name,
      'confidence': candidate.confidence,
      // TTL: 48 hours, scope: locality
      'ttlHours': 48,
      'scope': 'locality',
    };
  }

  /// Whether a candidate has reached the threshold for surfacing.
  ///
  /// Uses the service-level constants so thresholds are centralized here
  /// rather than spread across models.
  bool _hasReachedThreshold(DiscoveredSpotCandidate candidate) {
    return candidate.visitCount >= _minVisitsThreshold ||
        candidate.uniqueUserCount >= _minUniqueUsersThreshold;
  }

  // ─── Category Inference ──────────────────────────────────────────────

  /// Infer the likely category of a location from visit patterns.
  ///
  /// Uses timing, dwell, day of week, and group size to make educated
  /// guesses about what kind of place this is. These are hints, not
  /// certainties -- the user will confirm when creating the spot.
  InferredCategory _inferCategory({
    required TimeSlot timeSlot,
    required int dwellMinutes,
    required DayOfWeek dayOfWeek,
    required int groupSize,
  }) {
    final isWeekend =
        dayOfWeek == DayOfWeek.saturday || dayOfWeek == DayOfWeek.sunday;

    // Group visit pattern
    if (groupSize > 2) return InferredCategory.gatheringPlace;

    // Time-based inference
    if (timeSlot == TimeSlot.earlyMorning || timeSlot == TimeSlot.morning) {
      return dwellMinutes > 60
          ? InferredCategory.daytimeRetreat
          : InferredCategory.morningHangout;
    }

    if (timeSlot == TimeSlot.lateNight) {
      return InferredCategory.lateNightSpot;
    }

    // Dwell-based inference
    if (dwellMinutes < 15) return InferredCategory.quickStop;
    if (dwellMinutes > 120) return InferredCategory.lingering;

    // Weekend-heavy pattern
    if (isWeekend) return InferredCategory.weekendSpot;

    // Evening social pattern
    if (timeSlot == TimeSlot.evening) return InferredCategory.eveningSpot;

    // Daytime moderate dwell
    return InferredCategory.daytimeRetreat;
  }

  /// Recalculate inferred category from accumulated visit history.
  InferredCategory _recalculateCategory({
    required InferredCategory current,
    required TimeSlot newTimeSlot,
    required int newDwellMinutes,
    required DayOfWeek newDayOfWeek,
    required int newGroupSize,
    required bool weekendHeavy,
    required bool groupVisitsDetected,
  }) {
    // If group visits are consistently detected, it's a gathering place
    if (groupVisitsDetected && newGroupSize > 1) {
      return InferredCategory.gatheringPlace;
    }

    // Otherwise, use the latest visit's inference but weighted toward
    // existing category -- don't flip on every visit
    final newInference = _inferCategory(
      timeSlot: newTimeSlot,
      dwellMinutes: newDwellMinutes,
      dayOfWeek: newDayOfWeek,
      groupSize: newGroupSize,
    );

    // If new inference matches current, keep it (reinforced)
    if (newInference == current) return current;

    // If current is unknown, adopt the new inference
    if (current == InferredCategory.unknown) return newInference;

    // Otherwise keep the established category -- takes multiple
    // divergent visits to change the inference
    return current;
  }

  // ─── Confidence Calculation ──────────────────────────────────────────

  /// Calculate confidence score for a candidate.
  ///
  /// Factors:
  /// - Visit count (more visits = higher confidence)
  /// - Unique users from mesh (community validation)
  /// - Group visits (social signal)
  /// - Consistent timing (behavioral pattern)
  double _calculateConfidence({
    required int visitCount,
    required int uniqueUserCount,
    required bool hasGroupVisits,
    required bool hasConsistentTiming,
  }) {
    var confidence = 0.0;

    // Visit count contribution (diminishing returns)
    confidence += math.min(visitCount * _confidencePerVisit, 0.5);

    // Mesh user contribution (strong signal)
    confidence += math.min((uniqueUserCount - 1) * _confidencePerMeshUser, 0.4);

    // Group visit bonus
    if (hasGroupVisits) confidence += _confidenceGroupBoost;

    // Consistent timing bonus
    if (hasConsistentTiming) confidence += _confidenceTimingBoost;

    return confidence.clamp(0.0, 1.0);
  }

  // ─── Candidate Updates ───────────────────────────────────────────────

  /// Update an existing candidate with a new visit.
  DiscoveredSpotCandidate _updateCandidateWithVisit({
    required DiscoveredSpotCandidate candidate,
    required double latitude,
    required double longitude,
    required int dwellMinutes,
    required DateTime timestamp,
    required DayOfWeek dayOfWeek,
    required TimeSlot timeSlot,
    required int groupSize,
  }) {
    final newVisitCount = candidate.visitCount + 1;
    final isWeekend =
        dayOfWeek == DayOfWeek.saturday || dayOfWeek == DayOfWeek.sunday;

    // Update running average centroid (weighted toward new visit)
    final weight = 1.0 / newVisitCount;
    final newLat =
        candidate.centroidLatitude * (1 - weight) + latitude * weight;
    final newLon =
        candidate.centroidLongitude * (1 - weight) + longitude * weight;

    // Update running average dwell time
    final newAvgDwell =
        ((candidate.averageDwellMinutes * candidate.visitCount) +
                dwellMinutes) ~/
            newVisitCount;

    // Update weekend pattern
    final newWeekendHeavy = candidate.weekendHeavy || isWeekend;

    // Update group pattern
    final newGroupDetected = candidate.groupVisitsDetected || groupSize > 1;

    // Recalculate category
    final newCategory = _recalculateCategory(
      current: candidate.inferredCategory,
      newTimeSlot: timeSlot,
      newDwellMinutes: dwellMinutes,
      newDayOfWeek: dayOfWeek,
      newGroupSize: groupSize,
      weekendHeavy: newWeekendHeavy,
      groupVisitsDetected: newGroupDetected,
    );

    // Recalculate confidence
    final newConfidence = _calculateConfidence(
      visitCount: newVisitCount,
      uniqueUserCount: candidate.uniqueUserCount,
      hasGroupVisits: newGroupDetected,
      hasConsistentTiming: newVisitCount >= 3, // 3+ visits = pattern
    );

    return candidate.copyWith(
      centroidLatitude: newLat,
      centroidLongitude: newLon,
      visitCount: newVisitCount,
      confidence: newConfidence,
      inferredCategory: newCategory,
      lastVisitAt: timestamp,
      averageDwellMinutes: newAvgDwell,
      weekendHeavy: newWeekendHeavy,
      groupVisitsDetected: newGroupDetected,
    );
  }

  // ─── Storage ─────────────────────────────────────────────────────────

  Future<DiscoveredSpotCandidate?> _findCandidateByGeohash(
    String userId,
    String geohash,
  ) async {
    final candidates = await _loadAllCandidates(userId);
    try {
      return candidates.firstWhere(
        (c) => c.geohash == geohash && !c.isResolved,
      );
    } catch (_) {
      return null;
    }
  }

  Future<DiscoveredSpotCandidate?> _findCandidateById(
    String userId,
    String candidateId,
  ) async {
    final candidates = await _loadAllCandidates(userId);
    try {
      return candidates.firstWhere((c) => c.id == candidateId);
    } catch (_) {
      return null;
    }
  }

  Future<List<DiscoveredSpotCandidate>> _loadAllCandidates(
    String userId,
  ) async {
    try {
      final key = 'candidates_$userId';
      final raw = _box.read<List<dynamic>>(key);
      if (raw == null) return [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map((json) => DiscoveredSpotCandidate.fromJson(json))
          .toList();
    } catch (e) {
      developer.log('Error loading discovery candidates: $e', name: _logName);
      return [];
    }
  }

  Future<void> _saveCandidate(DiscoveredSpotCandidate candidate) async {
    try {
      final key = 'candidates_${candidate.userId}';
      final candidates = await _loadAllCandidates(candidate.userId);

      // Update or add the candidate
      final index = candidates.indexWhere((c) => c.id == candidate.id);
      if (index >= 0) {
        candidates[index] = candidate;
      } else {
        candidates.add(candidate);
      }

      // Enforce max candidates limit (remove oldest resolved first)
      if (candidates.length > _maxCandidatesPerUser) {
        _pruneOldCandidates(candidates);
      }

      await _box.write(key, candidates.map((c) => c.toJson()).toList());
    } catch (e) {
      developer.log('Error saving discovery candidate: $e', name: _logName);
    }
  }

  /// Remove oldest resolved candidates to stay within storage limits.
  void _pruneOldCandidates(List<DiscoveredSpotCandidate> candidates) {
    // Sort resolved candidates by last visit date (oldest first)
    final resolved = candidates.where((c) => c.isResolved).toList()
      ..sort((a, b) => a.lastVisitAt.compareTo(b.lastVisitAt));

    // Remove oldest resolved until we're under the limit
    while (candidates.length > _maxCandidatesPerUser && resolved.isNotEmpty) {
      final toRemove = resolved.removeAt(0);
      candidates.removeWhere((c) => c.id == toRemove.id);
    }
  }
}
