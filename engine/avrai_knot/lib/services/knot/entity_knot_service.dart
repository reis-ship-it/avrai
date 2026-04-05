// Entity Knot Service
//
// Service for generating knots for all entity types (people, events, places, companies)
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1.5: Universal Cross-Pollination Extension

import 'dart:developer' as developer;
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/utils/vibe_constants.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_knot/services/knot/bridge/knot_rust_loader.dart';

/// Service for generating knots for any entity type
///
/// **Supported Entity Types:**
/// - Person (PersonalityProfile)
/// - Event (ExpertiseEvent)
/// - Place (Spot)
/// - Company (BusinessAccount)
///
/// **Flow:**
/// 1. Extract entity properties
/// 2. Analyze property entanglement/correlations
/// 3. Create braid sequence from correlations
/// 4. Call Rust FFI to generate knot
/// 5. Return EntityKnot
class EntityKnotService {
  static const String _logName = 'EntityKnotService';

  final PersonalityKnotService _personalityKnotService;
  bool _initialized = false;

  EntityKnotService({PersonalityKnotService? personalityKnotService})
    : _personalityKnotService =
          personalityKnotService ?? PersonalityKnotService();

  /// Initialize the Rust library
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if RustLib is already initialized
      try {
        await initKnotRustLib();
      } catch (e) {
        // If already initialized, that's fine
        if (e.toString().contains(
          'Should not initialize flutter_rust_bridge twice',
        )) {
          developer.log('Rust library already initialized', name: _logName);
          _initialized = true;
          return;
        }
        rethrow;
      }
      _initialized = true;
      developer.log('✅ Rust library initialized', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to initialize Rust library: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Generate knot for any entity type
  ///
  /// **Supported Types:**
  /// - EntityType.person → PersonalityProfile
  /// - EntityType.event → ExpertiseEvent
  /// - EntityType.place → Spot
  /// - EntityType.company → BusinessAccount
  /// - EntityType.brand → BrandAccount
  /// When [dimensions12D] is provided for company/event/place, the knot is
  /// built from these dimensions (attraction 12D) via the same pipeline as
  /// personality knots, so knot and fidelity are aligned.
  Future<EntityKnot> generateKnotForEntity({
    required EntityType entityType,
    required dynamic entity,
    Map<String, double>? dimensions12D,
  }) async {
    developer.log(
      'Generating knot for ${entityType.toString().split('.').last}: ${_getEntityId(entity)}',
      name: _logName,
    );

    // Ensure Rust library is initialized
    if (!_initialized) {
      await initialize();
    }

    try {
      if (dimensions12D != null &&
          dimensions12D.isNotEmpty &&
          (entityType == EntityType.company ||
              entityType == EntityType.event ||
              entityType == EntityType.place)) {
        return await _generateKnotFrom12D(
          entityType: entityType,
          entity: entity,
          dimensions12D: dimensions12D,
        );
      }
      switch (entityType) {
        case EntityType.person:
          return await _generatePersonKnot(entity as PersonalityProfile);
        case EntityType.event:
          return await _generateEventKnot(entity);
        case EntityType.place:
          return await _generatePlaceKnot(entity);
        case EntityType.company:
          return await _generateCompanyKnot(entity);
        case EntityType.brand:
          // Brand knots are not yet implemented; keep the enum value but fail fast
          // with a clear error until the BrandAccount model and extraction logic
          // are wired end-to-end.
          throw ArgumentError('Unsupported entity type: $entityType');
        default:
          throw ArgumentError('Unsupported entity type: $entityType');
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to generate knot for ${entityType.toString().split('.').last}: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Generate knot from 12D dimensions (attraction 12D for company/event/place).
  Future<EntityKnot> _generateKnotFrom12D({
    required EntityType entityType,
    required dynamic entity,
    required Map<String, double> dimensions12D,
  }) async {
    final entityId = _getEntityId(entity);
    final dims = _ensureAllDimensions12D(dimensions12D);
    final profile = PersonalityProfile.fromDimensions(entityId, dims);
    final personalityKnot = await _personalityKnotService.generateKnot(profile);
    final now = DateTime.now();
    return EntityKnot(
      entityId: entityId,
      entityType: entityType,
      knot: personalityKnot,
      metadata: _metadataForEntity(entityType, entity),
      createdAt: now,
      lastUpdated: now,
    );
  }

  Map<String, double> _ensureAllDimensions12D(Map<String, double> input) {
    final dims = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      dims[d] = (input[d] ?? VibeConstants.defaultDimensionValue).clamp(
        0.0,
        1.0,
      );
    }
    return dims;
  }

  Map<String, dynamic> _metadataForEntity(
    EntityType entityType,
    dynamic entity,
  ) {
    switch (entityType) {
      case EntityType.company:
        return {
          'businessType': entity.businessType,
          'verificationStatus': entity.verification != null
              ? entity.verification!.status.toString()
              : 'unverified',
          'businessName': entity.name,
        };
      case EntityType.event:
        return {
          'category': entity.category,
          'eventType': entity.eventType.toString(),
          'hostId': entity.host.id,
        };
      case EntityType.place:
        return {
          'category': entity.category,
          'rating': entity.rating,
          'name': entity.name,
        };
      default:
        return const {};
    }
  }

  /// Generate knot from personality profile (delegates to PersonalityKnotService)
  Future<EntityKnot> _generatePersonKnot(PersonalityProfile profile) async {
    final personalityKnot = await _personalityKnotService.generateKnot(profile);

    return EntityKnot(
      entityId: profile.agentId,
      entityType: EntityType.person,
      knot: personalityKnot,
      metadata: {
        'archetype': profile.archetype,
        'authenticity': profile.authenticity,
        'evolutionGeneration': profile.evolutionGeneration,
      },
      createdAt: personalityKnot.createdAt,
      lastUpdated: personalityKnot.lastUpdated,
    );
  }

  /// Generate knot from event characteristics
  ///
  /// **Extracted Properties:**
  /// - Category, event type
  /// - Host personality (if available)
  /// - Attendee diversity
  /// - Location characteristics
  /// - Time/seasonality
  Future<EntityKnot> _generateEventKnot(dynamic event) async {
    // Extract event properties
    final eventProperties = _extractEventProperties(event);

    // Analyze property entanglement
    final entanglement = _analyzeEventPropertyEntanglement(eventProperties);

    // Create braid sequence from correlations
    final braidData = _createBraidDataFromEntanglement(entanglement);

    // Call Rust FFI to generate knot
    final rustResult = generateKnotFromBraid(braidData: braidData);

    // Convert to PersonalityKnot structure
    final knot = PersonalityKnot(
      agentId: event.id,
      invariants: KnotInvariants(
        jonesPolynomial: rustResult.jonesPolynomial.toList(),
        alexanderPolynomial: rustResult.alexanderPolynomial.toList(),
        crossingNumber: rustResult.crossingNumber.toInt(),
        writhe: rustResult.writhe,
        signature: rustResult.signature,
        unknottingNumber: rustResult.unknottingNumber?.toInt(),
        bridgeNumber: rustResult.bridgeNumber.toInt(),
        braidIndex: rustResult.braidIndex.toInt(),
        determinant: rustResult.determinant,
        arfInvariant: rustResult.arfInvariant,
        hyperbolicVolume: rustResult.hyperbolicVolume,
        homflyPolynomial: rustResult.homflyPolynomial?.toList(),
      ),
      braidData: braidData,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    return EntityKnot(
      entityId: event.id,
      entityType: EntityType.event,
      knot: knot,
      metadata: {
        'category': event.category,
        'eventType': event.eventType.toString(),
        'hostId': event.host.id,
        'attendeeCount': event.attendeeCount,
        'maxAttendees': event.maxAttendees,
        'isPaid': event.isPaid,
        'latitude': event.latitude,
        'longitude': event.longitude,
      },
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Generate knot from place characteristics
  ///
  /// **Extracted Properties:**
  /// - Category, rating
  /// - Location (latitude/longitude)
  /// - Atmosphere/vibe characteristics
  /// - Tags, metadata
  Future<EntityKnot> _generatePlaceKnot(dynamic spot) async {
    // Extract place properties
    final placeProperties = _extractPlaceProperties(spot);

    // Analyze property entanglement
    final entanglement = _analyzePlacePropertyEntanglement(placeProperties);

    // Create braid sequence from correlations
    final braidData = _createBraidDataFromEntanglement(entanglement);

    // Call Rust FFI to generate knot
    final rustResult = generateKnotFromBraid(braidData: braidData);

    // Convert to PersonalityKnot structure
    final knot = PersonalityKnot(
      agentId: spot.id,
      invariants: KnotInvariants(
        jonesPolynomial: rustResult.jonesPolynomial.toList(),
        alexanderPolynomial: rustResult.alexanderPolynomial.toList(),
        crossingNumber: rustResult.crossingNumber.toInt(),
        writhe: rustResult.writhe,
        signature: rustResult.signature,
        unknottingNumber: rustResult.unknottingNumber?.toInt(),
        bridgeNumber: rustResult.bridgeNumber.toInt(),
        braidIndex: rustResult.braidIndex.toInt(),
        determinant: rustResult.determinant,
        arfInvariant: rustResult.arfInvariant,
        hyperbolicVolume: rustResult.hyperbolicVolume,
        homflyPolynomial: rustResult.homflyPolynomial?.toList(),
      ),
      braidData: braidData,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    return EntityKnot(
      entityId: spot.id,
      entityType: EntityType.place,
      knot: knot,
      metadata: {
        'category': spot.category,
        'rating': spot.rating,
        'latitude': spot.latitude,
        'longitude': spot.longitude,
        'name': spot.name,
      },
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Generate knot from company characteristics
  ///
  /// **Extracted Properties:**
  /// - Brand identity, values
  /// - Business type, category
  /// - Culture characteristics
  /// - Partnership preferences
  Future<EntityKnot> _generateCompanyKnot(dynamic business) async {
    // Extract business properties
    final businessProperties = _extractBusinessProperties(business);

    // Analyze property entanglement
    final entanglement = _analyzeBusinessPropertyEntanglement(
      businessProperties,
    );

    // Create braid sequence from correlations
    final braidData = _createBraidDataFromEntanglement(entanglement);

    // Call Rust FFI to generate knot
    final rustResult = generateKnotFromBraid(braidData: braidData);

    // Convert to PersonalityKnot structure
    final knot = PersonalityKnot(
      agentId: business.id,
      invariants: KnotInvariants(
        jonesPolynomial: rustResult.jonesPolynomial.toList(),
        alexanderPolynomial: rustResult.alexanderPolynomial.toList(),
        crossingNumber: rustResult.crossingNumber.toInt(),
        writhe: rustResult.writhe,
        signature: rustResult.signature,
        unknottingNumber: rustResult.unknottingNumber?.toInt(),
        bridgeNumber: rustResult.bridgeNumber.toInt(),
        braidIndex: rustResult.braidIndex.toInt(),
        determinant: rustResult.determinant,
        arfInvariant: rustResult.arfInvariant,
        hyperbolicVolume: rustResult.hyperbolicVolume,
        homflyPolynomial: rustResult.homflyPolynomial?.toList(),
      ),
      braidData: braidData,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    return EntityKnot(
      entityId: business.id,
      entityType: EntityType.company,
      knot: knot,
      metadata: {
        'businessType': business.businessType,
        'verificationStatus': business.verification != null
            ? business.verification!.status.toString()
            : 'unverified',
        'businessName': business.name,
      },
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  // --- Property Extraction Methods ---

  /// Extract properties from event for knot generation
  Map<String, double> _extractEventProperties(dynamic event) {
    final properties = <String, double>{};

    // Category encoding (hash to number)
    properties['category'] = event.category.hashCode.toDouble() % 1000 / 1000.0;

    // Event type encoding
    properties['eventType'] = event.eventType.index.toDouble() / 10.0;

    // Attendee diversity (ratio of attendees to max)
    properties['attendeeDiversity'] = event.maxAttendees > 0
        ? (event.attendeeCount / event.maxAttendees).clamp(0.0, 1.0)
        : 0.0;

    // Time-based properties
    final now = DateTime.now();
    final daysUntilEvent = event.startTime.difference(now).inDays;
    properties['timeProximity'] = (1.0 / (daysUntilEvent.abs() + 1.0)).clamp(
      0.0,
      1.0,
    );

    // Location encoding (if available)
    if (event.latitude != null && event.longitude != null) {
      properties['latitude'] =
          (event.latitude! + 90.0) / 180.0; // Normalize to [0, 1]
      properties['longitude'] =
          (event.longitude! + 180.0) / 360.0; // Normalize to [0, 1]
    }

    // Price encoding
    properties['price'] = event.isPaid && event.price != null
        ? (event.price! / 1000.0).clamp(0.0, 1.0) // Normalize to [0, 1]
        : 0.0;

    return properties;
  }

  /// Extract properties from place for knot generation
  Map<String, double> _extractPlaceProperties(dynamic spot) {
    final properties = <String, double>{};

    // Category encoding
    properties['category'] = spot.category.hashCode.toDouble() % 1000 / 1000.0;

    // Rating encoding
    properties['rating'] = (spot.rating.clamp(0.0, 5.0) / 5.0);

    // Location encoding
    properties['latitude'] =
        (spot.latitude + 90.0) / 180.0; // Normalize to [0, 1]
    properties['longitude'] =
        (spot.longitude + 180.0) / 360.0; // Normalize to [0, 1]

    // Name encoding (hash to number)
    properties['name'] = spot.name.hashCode.toDouble() % 1000 / 1000.0;

    return properties;
  }

  /// Extract properties from business for knot generation
  Map<String, double> _extractBusinessProperties(dynamic business) {
    final properties = <String, double>{};

    // Business type encoding
    properties['businessType'] =
        business.businessType.hashCode.toDouble() % 1000 / 1000.0;

    // Verification status encoding
    properties['verificationStatus'] = business.verification != null
        ? business.verification!.status.index.toDouble() / 10.0
        : 0.0;

    // Business name encoding
    properties['businessName'] =
        business.name.hashCode.toDouble() % 1000 / 1000.0;

    return properties;
  }

  // --- Entanglement Analysis Methods ---

  /// Analyze property entanglement for events
  Map<String, double> _analyzeEventPropertyEntanglement(
    Map<String, double> properties,
  ) {
    final correlations = <String, double>{};
    final propertyNames = properties.keys.toList();

    // Calculate correlations between property pairs
    for (int i = 0; i < propertyNames.length; i++) {
      for (int j = i + 1; j < propertyNames.length; j++) {
        final prop1 = propertyNames[i];
        final prop2 = propertyNames[j];
        final val1 = properties[prop1] ?? 0.5;
        final val2 = properties[prop2] ?? 0.5;

        // Simple correlation: similarity between values
        final correlation = 1.0 - (val1 - val2).abs();

        // Only include correlations above threshold
        if (correlation > 0.3) {
          correlations['$prop1:$prop2'] = correlation;
        }
      }
    }

    return correlations;
  }

  /// Analyze property entanglement for places
  Map<String, double> _analyzePlacePropertyEntanglement(
    Map<String, double> properties,
  ) {
    // Same approach as events
    return _analyzeEventPropertyEntanglement(properties);
  }

  /// Analyze property entanglement for businesses
  Map<String, double> _analyzeBusinessPropertyEntanglement(
    Map<String, double> properties,
  ) {
    // Same approach as events
    return _analyzeEventPropertyEntanglement(properties);
  }

  // --- Braid Creation Methods ---

  /// Create braid data from entanglement correlations
  ///
  /// **Format:** [strands, crossing1_strand, crossing1_over, ...]
  List<double> _createBraidDataFromEntanglement(
    Map<String, double> correlations,
  ) {
    // Determine number of strands from correlation count
    // Use a base number of strands (e.g., 8) plus correlation count
    const baseStrands = 8;
    final numStrands = (baseStrands + correlations.length).clamp(2, 20);
    final braidData = <double>[numStrands.toDouble()];

    // Create crossings from correlations
    int strandIndex = 0;
    for (final entry in correlations.entries) {
      final parts = entry.key.split(':');
      if (parts.length != 2) continue;

      final strand = strandIndex % (numStrands - 1);
      final correlation = entry.value;

      // Crossing type: positive correlation = over, negative = under
      final isOver = correlation > 0.0;

      braidData.add(strand.toDouble());
      braidData.add(isOver ? 1.0 : 0.0);

      strandIndex++;
    }

    return braidData;
  }

  // --- Helper Methods ---

  /// Get entity ID from entity object
  String _getEntityId(dynamic entity) {
    if (entity is PersonalityProfile) return entity.agentId;
    try {
      final id = entity.id;
      if (id is String) return id;
    } catch (_) {}
    return 'unknown';
  }
}
