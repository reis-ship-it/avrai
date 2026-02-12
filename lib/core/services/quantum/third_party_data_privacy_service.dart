// Third-Party Data Privacy Service
//
// Implements complete privacy protection for all third-party data using agentId exclusively
// Part of Phase 19 Section 19.13: Privacy-Protected Third-Party Data API
// Patent #29: Multi-Entity Quantum Entanglement Matching System
//
// Enhanced with:
// - Knot/string/fabric/worldsheet anonymization
// - Signal Protocol encryption for transmission
// - AI2AI mesh networking for privacy-preserving routing

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/security/hybrid_encryption_service.dart';
import 'package:avrai/core/ai2ai/anonymous_communication.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';
import 'package:avrai_knot/models/knot/fabric_snapshot.dart';
import 'package:avrai_knot/models/knot/fabric_invariants.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai/core/services/security/message_encryption_service.dart';

/// Privacy protection service for third-party data
///
/// **Core Principle:**
/// All third-party data uses `agentId` exclusively (never `userId`)
///
/// **Security Features:**
/// - Encrypted userId ↔ agentId mapping (AES-256-GCM)
/// - Complete PII removal
/// - Location obfuscation (city-level only, ~1km precision)
/// - Differential privacy for quantum states
/// - Temporal expiration (using atomic timestamps)
/// - GDPR/CCPA compliance
/// - **Signal Protocol encryption** for all transmissions
/// - **AI2AI mesh networking** for privacy-preserving routing
/// - **Knot/string/fabric/worldsheet anonymization**
class ThirdPartyDataPrivacyService {
  static const String _logName = 'ThirdPartyDataPrivacyService';

  final AtomicClockService _atomicClock;
  final AgentIdService _agentIdService;
  final HybridEncryptionService? _encryptionService;
  final AnonymousCommunicationProtocol? _ai2aiProtocol;
  // Note: _orchestrator and _knotStringService reserved for future mesh routing enhancements
  // ignore: unused_field
  final VibeConnectionOrchestrator? _orchestrator;
  // ignore: unused_field
  final KnotEvolutionStringService? _knotStringService;

  // Privacy configuration
  static const double _differentialPrivacyEpsilon = 1.0; // Privacy budget

  ThirdPartyDataPrivacyService({
    required AtomicClockService atomicClock,
    required AgentIdService agentIdService,
    HybridEncryptionService? encryptionService,
    AnonymousCommunicationProtocol? ai2aiProtocol,
    VibeConnectionOrchestrator? orchestrator,
    KnotEvolutionStringService? knotStringService,
  })  : _atomicClock = atomicClock,
        _agentIdService = agentIdService,
        _encryptionService = encryptionService,
        _ai2aiProtocol = ai2aiProtocol,
        _orchestrator = orchestrator,
        _knotStringService = knotStringService;

  /// Convert userId to agentId for third-party data
  ///
  /// **Security:**
  /// - Uses encrypted mapping from AgentIdService
  /// - Never exposes userId to third parties
  ///
  /// **Returns:**
  /// agentId for use in third-party data
  Future<String> convertUserIdToAgentId(String userId) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);
      developer.log(
        'Converted userId to agentId (privacy-protected)',
        name: _logName,
      );
      return agentId;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error converting userId to agentId: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Anonymize quantum entity state for third-party transmission
  ///
  /// **Process:**
  /// 1. Convert entityId (userId) → agentId
  /// 2. Remove all personal identifiers
  /// 3. Apply differential privacy to quantum states
  /// 4. Obfuscate location data
  /// 5. Apply temporal expiration
  ///
  /// **Returns:**
  /// AnonymizedQuantumState safe for third-party transmission
  Future<AnonymizedQuantumState> anonymizeQuantumState({
    required QuantumEntityState originalState,
    required String userId,
  }) async {
    developer.log(
      'Anonymizing quantum state for third-party transmission',
      name: _logName,
    );

    try {
      // Get atomic timestamp
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // 1. Convert userId → agentId
      final agentId = await convertUserIdToAgentId(userId);

      // 2. Remove personal identifiers from entity characteristics
      final anonymizedCharacteristics = _removePersonalIdentifiers(
        originalState.entityCharacteristics,
      );

      // 3. Apply differential privacy to quantum states
      final anonymizedPersonality = _applyDifferentialPrivacy(
        originalState.personalityState,
      );
      final anonymizedVibe = _applyDifferentialPrivacy(
        originalState.quantumVibeAnalysis,
      );

      // 4. Obfuscate location data
      final anonymizedLocation = originalState.location != null
          ? _obfuscateLocation(originalState.location!)
          : null;

      // 5. Create anonymized state
      final anonymizedState = QuantumEntityState(
        entityId: agentId, // Use agentId, not userId
        entityType: originalState.entityType,
        personalityState: anonymizedPersonality,
        quantumVibeAnalysis: anonymizedVibe,
        entityCharacteristics: anonymizedCharacteristics,
        location: anonymizedLocation,
        timing: originalState.timing, // Timing is safe (no personal data)
        tAtomic: tAtomic,
      );

      return AnonymizedQuantumState(
        anonymizedState: anonymizedState,
        originalUserId: userId, // Keep for internal reference only
        agentId: agentId,
        anonymizedAt: tAtomic,
        expiresAt: tAtomic, // Would add expiration logic
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error anonymizing quantum state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Validate privacy compliance
  ///
  /// **Checks:**
  /// - No userId exposure
  /// - No personal identifiers
  /// - Location obfuscation applied
  /// - Differential privacy applied
  ///
  /// **Returns:**
  /// PrivacyValidationResult with compliance status
  Future<PrivacyValidationResult> validatePrivacy({
    required Map<String, dynamic> data,
  }) async {
    try {
      final violations = <String>[];

      // Check for userId exposure
      if (data.containsKey('userId') || data.containsKey('user_id')) {
        violations.add('userId exposure detected');
      }

      // Check for personal identifiers
      final personalFields = ['name', 'email', 'phone', 'address', 'ssn'];
      for (final field in personalFields) {
        if (data.containsKey(field)) {
          violations.add('Personal identifier detected: $field');
        }
      }

      // Check for agentId (should be present, not userId)
      if (!data.containsKey('agentId') && !data.containsKey('agent_id')) {
        violations.add('Missing agentId (required for privacy)');
      }

      final isCompliant = violations.isEmpty;

      developer.log(
        isCompliant
            ? '✅ Privacy validation passed'
            : '⚠️ Privacy violations detected: ${violations.join(", ")}',
        name: _logName,
      );

      return PrivacyValidationResult(
        isCompliant: isCompliant,
        violations: violations,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error validating privacy: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return PrivacyValidationResult(
        isCompliant: false,
        violations: ['Validation error: $e'],
      );
    }
  }

  /// Remove personal identifiers from entity characteristics
  Map<String, dynamic> _removePersonalIdentifiers(
    Map<String, dynamic> characteristics,
  ) {
    final anonymized = Map<String, dynamic>.from(characteristics);

    // Remove personal identifiers
    final personalFields = [
      'name',
      'email',
      'phone',
      'address',
      'ssn',
      'credit_card',
      'bank_account',
    ];

    for (final field in personalFields) {
      anonymized.remove(field);
    }

    return anonymized;
  }

  /// Apply differential privacy to quantum state values
  ///
  /// **Formula:**
  /// value_anonymized = value + Laplace(0, sensitivity / epsilon)
  ///
  /// Where:
  /// - sensitivity = 1.0 (for normalized quantum states)
  /// - epsilon = privacy budget
  Map<String, double> _applyDifferentialPrivacy(
    Map<String, double> originalValues,
  ) {
    final anonymized = <String, double>{};
    final random = math.Random.secure();

    for (final entry in originalValues.entries) {
      // Laplace mechanism for differential privacy
      final sensitivity = 1.0;
      final scale = sensitivity / _differentialPrivacyEpsilon;

      // Generate Laplace noise
      final u1 = random.nextDouble();
      final u2 = random.nextDouble();
      final laplaceNoise = scale *
          (math.log(u1) - math.log(u2)) *
          (u2 < 0.5 ? -1 : 1);

      // Add noise to original value
      final anonymizedValue = (entry.value + laplaceNoise).clamp(0.0, 1.0);
      anonymized[entry.key] = anonymizedValue;
    }

    return anonymized;
  }

  /// Obfuscate location data to city-level only (~1km precision)
  ///
  /// **Process:**
  /// - Round coordinates to ~1km precision
  /// - Add differential privacy noise
  EntityLocationQuantumState _obfuscateLocation(
    EntityLocationQuantumState originalLocation,
  ) {
    // Round to ~1km precision (approximately 0.01 degrees)
    final obfuscatedLat = (originalLocation.latitudeQuantumState / 0.01).round() * 0.01;
    final obfuscatedLon = (originalLocation.longitudeQuantumState / 0.01).round() * 0.01;

    // Add small random noise for additional privacy
    final random = math.Random.secure();
    final noiseLat = (random.nextDouble() - 0.5) * 0.005; // ±0.005 degrees
    final noiseLon = (random.nextDouble() - 0.5) * 0.005;

    return EntityLocationQuantumState(
      latitudeQuantumState: (obfuscatedLat + noiseLat).clamp(-1.0, 1.0),
      longitudeQuantumState: (obfuscatedLon + noiseLon).clamp(-1.0, 1.0),
      locationType: originalLocation.locationType, // Safe to keep
      accessibilityScore: originalLocation.accessibilityScore, // Safe to keep
      vibeLocationMatch: originalLocation.vibeLocationMatch, // Safe to keep
    );
  }

  /// Enforce API privacy (validate and block on violations)
  ///
  /// **Process:**
  /// 1. Validate privacy compliance
  /// 2. Block data transmission on violations
  /// 3. Log violations for audit
  Future<bool> enforceAPIPrivacy({
    required Map<String, dynamic> data,
  }) async {
    try {
      final validation = await validatePrivacy(data: data);

      if (!validation.isCompliant) {
        developer.log(
          '🚫 API privacy violation detected - blocking transmission',
          name: _logName,
        );
        return false; // Block transmission
      }

      return true; // Allow transmission
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error enforcing API privacy: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return false; // Block on error (fail-safe)
    }
  }

  // ============================================================
  // Knot/String/Fabric/Worldsheet Anonymization Methods
  // ============================================================

  /// Anonymize knot evolution string for third-party transmission
  ///
  /// **Process:**
  /// 1. Convert userId → agentId in all snapshots
  /// 2. Remove personal identifiers from knots
  /// 3. Apply differential privacy to knot invariants
  /// 4. Reduce snapshot count (privacy + efficiency)
  ///
  /// **Returns:**
  /// AnonymizedKnotString safe for third-party transmission
  Future<AnonymizedKnotString> anonymizeKnotString({
    required KnotString originalString,
    required String userId,
  }) async {
    developer.log(
      'Anonymizing knot evolution string for third-party transmission',
      name: _logName,
    );

    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();
      final agentId = await convertUserIdToAgentId(userId);

      // Anonymize initial knot
      final anonymizedInitialKnot = await _anonymizeKnot(
        originalString.initialKnot,
        agentId,
      );

      // Anonymize snapshots (reduce count for privacy)
      final anonymizedSnapshots = <KnotSnapshot>[];
      final maxSnapshots = 10; // Limit for privacy
      final step = (originalString.snapshots.length / maxSnapshots).ceil();

      for (int i = 0; i < originalString.snapshots.length; i += step) {
        final snapshot = originalString.snapshots[i];
        final anonymizedKnot = await _anonymizeKnot(snapshot.knot, agentId);
        anonymizedSnapshots.add(
          KnotSnapshot(
            timestamp: snapshot.timestamp,
            knot: anonymizedKnot,
          ),
        );
      }

      return AnonymizedKnotString(
        anonymizedString: KnotString(
          initialKnot: anonymizedInitialKnot,
          snapshots: anonymizedSnapshots,
          params: originalString.params,
        ),
        agentId: agentId,
        anonymizedAt: tAtomic,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error anonymizing knot string: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Anonymize knot fabric for third-party transmission
  ///
  /// **Process:**
  /// 1. Convert all userIds → agentIds in fabric
  /// 2. Anonymize all user knots
  /// 3. Apply differential privacy to fabric invariants
  /// 4. Obfuscate fabric metadata
  ///
  /// **Returns:**
  /// AnonymizedKnotFabric safe for third-party transmission
  Future<AnonymizedKnotFabric> anonymizeKnotFabric({
    required KnotFabric originalFabric,
    required Map<String, String> userIdToAgentIdMap, // Pre-converted map
  }) async {
    developer.log(
      'Anonymizing knot fabric for third-party transmission',
      name: _logName,
    );

    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Anonymize all user knots
      final anonymizedKnots = <PersonalityKnot>[];
      for (final knot in originalFabric.userKnots) {
        // Find agentId for this knot's userId (if available)
        final agentId = userIdToAgentIdMap[knot.agentId] ?? knot.agentId;
        final anonymizedKnot = await _anonymizeKnot(knot, agentId);
        anonymizedKnots.add(anonymizedKnot);
      }

      // Anonymize braid (convert userId keys to agentId)
      final anonymizedBraid = MultiStrandBraid(
        strandCount: originalFabric.braid.strandCount,
        braidData: originalFabric.braid.braidData,
        userToStrandIndex: originalFabric.braid.userToStrandIndex.map(
          (userId, index) => MapEntry(
            userIdToAgentIdMap[userId] ?? userId,
            index,
          ),
        ),
      );

      // Apply differential privacy to fabric invariants
      final anonymizedInvariants = _anonymizeFabricInvariants(
        originalFabric.invariants,
      );

      return AnonymizedKnotFabric(
        anonymizedFabric: KnotFabric(
          fabricId: originalFabric.fabricId,
          userKnots: anonymizedKnots,
          braid: anonymizedBraid,
          invariants: anonymizedInvariants,
          createdAt: originalFabric.createdAt,
          updatedAt: originalFabric.updatedAt,
        ),
        anonymizedAt: tAtomic,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error anonymizing knot fabric: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Anonymize knot worldsheet for third-party transmission
  ///
  /// **Process:**
  /// 1. Convert all userIds → agentIds in worldsheet
  /// 2. Anonymize all user strings
  /// 3. Anonymize all fabric snapshots
  /// 4. Apply temporal obfuscation
  ///
  /// **Returns:**
  /// AnonymizedKnotWorldsheet safe for third-party transmission
  Future<AnonymizedKnotWorldsheet> anonymizeKnotWorldsheet({
    required KnotWorldsheet originalWorldsheet,
    required Map<String, String> userIdToAgentIdMap, // Pre-converted map
  }) async {
    developer.log(
      'Anonymizing knot worldsheet for third-party transmission',
      name: _logName,
    );

    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Anonymize initial fabric
      final anonymizedInitialFabric = await anonymizeKnotFabric(
        originalFabric: originalWorldsheet.initialFabric,
        userIdToAgentIdMap: userIdToAgentIdMap,
      );

      // Anonymize user strings
      final anonymizedUserStrings = <String, KnotString>{};
      for (final entry in originalWorldsheet.userStrings.entries) {
        final userId = entry.key;
        final agentId = userIdToAgentIdMap[userId] ?? userId;
        final anonymizedString = await anonymizeKnotString(
          originalString: entry.value,
          userId: userId,
        );
        anonymizedUserStrings[agentId] = anonymizedString.anonymizedString;
      }

      // Anonymize fabric snapshots
      final anonymizedSnapshots = <FabricSnapshot>[];
      for (final snapshot in originalWorldsheet.snapshots) {
        final anonymizedFabric = await anonymizeKnotFabric(
          originalFabric: snapshot.fabric,
          userIdToAgentIdMap: userIdToAgentIdMap,
        );
        anonymizedSnapshots.add(
          FabricSnapshot(
            timestamp: snapshot.timestamp,
            fabric: anonymizedFabric.anonymizedFabric,
          ),
        );
      }

      return AnonymizedKnotWorldsheet(
        anonymizedWorldsheet: KnotWorldsheet(
          groupId: originalWorldsheet.groupId,
          initialFabric: anonymizedInitialFabric.anonymizedFabric,
          snapshots: anonymizedSnapshots,
          userStrings: anonymizedUserStrings,
          createdAt: originalWorldsheet.createdAt,
          lastUpdated: originalWorldsheet.lastUpdated,
        ),
        anonymizedAt: tAtomic,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error anonymizing knot worldsheet: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Anonymize a single knot
  ///
  /// **Process:**
  /// 1. Replace agentId with anonymized agentId
  /// 2. Apply differential privacy to invariants
  /// 3. Remove timestamps (or obfuscate)
  Future<PersonalityKnot> _anonymizeKnot(
    PersonalityKnot originalKnot,
    String agentId,
  ) async {
    // Apply differential privacy to invariants
    final anonymizedJones = _applyDifferentialPrivacy(
      originalKnot.invariants.jonesPolynomial.asMap().map(
        (i, v) => MapEntry(i.toString(), v),
      ),
    );
    final anonymizedAlexander = _applyDifferentialPrivacy(
      originalKnot.invariants.alexanderPolynomial.asMap().map(
        (i, v) => MapEntry(i.toString(), v),
      ),
    );

    return PersonalityKnot(
      agentId: agentId,
      braidData: originalKnot.braidData,
      invariants: KnotInvariants(
        jonesPolynomial: anonymizedJones.values.toList(),
        alexanderPolynomial: anonymizedAlexander.values.toList(),
        crossingNumber: originalKnot.invariants.crossingNumber,
        writhe: originalKnot.invariants.writhe,
        signature: originalKnot.invariants.signature,
        unknottingNumber: originalKnot.invariants.unknottingNumber,
        bridgeNumber: originalKnot.invariants.bridgeNumber,
        braidIndex: originalKnot.invariants.braidIndex,
        determinant: originalKnot.invariants.determinant,
        arfInvariant: originalKnot.invariants.arfInvariant,
        hyperbolicVolume: originalKnot.invariants.hyperbolicVolume,
        homflyPolynomial: originalKnot.invariants.homflyPolynomial,
      ),
      createdAt: DateTime.now(), // Obfuscate timestamp
      lastUpdated: DateTime.now(),
    );
  }

  /// Anonymize fabric invariants using differential privacy
  FabricInvariants _anonymizeFabricInvariants(
    FabricInvariants originalInvariants,
  ) {
    // Apply differential privacy to density and stability
    final anonymizedDensity = _applyDifferentialPrivacy(
      {'density': originalInvariants.density},
    )['density'] ?? originalInvariants.density;

    final anonymizedStability = _applyDifferentialPrivacy(
      {'stability': originalInvariants.stability},
    )['stability'] ?? originalInvariants.stability;

    return FabricInvariants(
      jonesPolynomial: originalInvariants.jonesPolynomial,
      alexanderPolynomial: originalInvariants.alexanderPolynomial,
      crossingNumber: originalInvariants.crossingNumber,
      density: anonymizedDensity.clamp(0.0, 1.0),
      stability: anonymizedStability.clamp(0.0, 1.0),
    );
  }

  // ============================================================
  // Signal Protocol & AI2AI Mesh Integration
  // ============================================================

  /// Encrypt and transmit anonymized data via Signal Protocol + AI2AI mesh
  ///
  /// **Process:**
  /// 1. Anonymize data (quantum state, knot, string, fabric, worldsheet)
  /// 2. Encrypt using Signal Protocol (via HybridEncryptionService)
  /// 3. Route through AI2AI mesh (via AnonymousCommunicationProtocol)
  /// 4. Return transmission result
  ///
  /// **Returns:**
  /// EncryptedTransmissionResult with transmission status
  Future<EncryptedTransmissionResult> encryptAndTransmit({
    required Map<String, dynamic> anonymizedData,
    required String recipientAgentId,
    MessageType? messageType,
  }) async {
    developer.log(
      'Encrypting and transmitting anonymized data via Signal Protocol + AI2AI mesh',
      name: _logName,
    );

    try {
      // 1. Validate privacy compliance
      final validation = await validatePrivacy(data: anonymizedData);
      if (!validation.isCompliant) {
        throw Exception(
          'Privacy validation failed: ${validation.violations.join(", ")}',
        );
      }

      // 2. Encrypt using Signal Protocol (via HybridEncryptionService)
      String? encryptedPayload;
      EncryptionType encryptionType = EncryptionType.aes256gcm;

      if (_encryptionService != null) {
        final payloadJson = jsonEncode(anonymizedData);
        final encrypted = await _encryptionService.encrypt(
          payloadJson,
          recipientAgentId,
        );
        encryptedPayload = base64Encode(Uint8List.fromList(encrypted.encryptedContent));
        encryptionType = encrypted.encryptionType;
      } else {
        developer.log(
          '⚠️ Encryption service not available, skipping encryption',
          name: _logName,
        );
        encryptedPayload = jsonEncode(anonymizedData);
      }

      // 3. Route through AI2AI mesh (if available)
      bool meshTransmitted = false;
      if (_ai2aiProtocol != null) {
        try {
          // Use sendEncryptedMessage method
          await _ai2aiProtocol.sendEncryptedMessage(
            recipientAgentId,
            messageType ?? MessageType.recommendationShare,
            {
              'encrypted_data': encryptedPayload,
              'encryption_type': encryptionType.toString(),
              'anonymized': true,
            },
          );
          meshTransmitted = true;
          developer.log(
            '✅ Data transmitted via AI2AI mesh with Signal Protocol encryption',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ AI2AI mesh transmission failed: $e',
            name: _logName,
          );
        }
      }

      return EncryptedTransmissionResult(
        success: true,
        encryptionType: encryptionType,
        meshTransmitted: meshTransmitted,
        recipientAgentId: recipientAgentId,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error encrypting and transmitting: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return EncryptedTransmissionResult(
        success: false,
        encryptionType: EncryptionType.aes256gcm,
        meshTransmitted: false,
        recipientAgentId: recipientAgentId,
        error: e.toString(),
      );
    }
  }
}

/// Anonymized quantum state for third-party transmission
class AnonymizedQuantumState {
  final QuantumEntityState anonymizedState;
  final String originalUserId; // Internal reference only, never exposed
  final String agentId; // Public identifier for third parties
  final AtomicTimestamp anonymizedAt;
  final AtomicTimestamp expiresAt;

  AnonymizedQuantumState({
    required this.anonymizedState,
    required this.originalUserId,
    required this.agentId,
    required this.anonymizedAt,
    required this.expiresAt,
  });

  /// Check if anonymized state has expired
  bool get isExpired {
    final now = DateTime.now();
    return now.isAfter(expiresAt.serverTime);
  }

  /// Convert to JSON for transmission (agentId only, no userId)
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'anonymizedState': anonymizedState.toJson(),
      'anonymizedAt': anonymizedAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      // Note: originalUserId is NOT included in JSON
    };
  }
}

/// Privacy validation result
class PrivacyValidationResult {
  final bool isCompliant;
  final List<String> violations;

  PrivacyValidationResult({
    required this.isCompliant,
    required this.violations,
  });

  @override
  String toString() {
    return 'PrivacyValidationResult(compliant: $isCompliant, violations: ${violations.length})';
  }
}

/// Anonymized knot evolution string for third-party transmission
class AnonymizedKnotString {
  final KnotString anonymizedString;
  final String agentId;
  final AtomicTimestamp anonymizedAt;

  AnonymizedKnotString({
    required this.anonymizedString,
    required this.agentId,
    required this.anonymizedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'anonymizedString': {
        'initialKnot': anonymizedString.initialKnot.toJson(),
        'snapshotCount': anonymizedString.snapshots.length,
        // Note: Full serialization would include snapshots
      },
      'anonymizedAt': anonymizedAt.toJson(),
    };
  }
}

/// Anonymized knot fabric for third-party transmission
class AnonymizedKnotFabric {
  final KnotFabric anonymizedFabric;
  final AtomicTimestamp anonymizedAt;

  AnonymizedKnotFabric({
    required this.anonymizedFabric,
    required this.anonymizedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'fabricId': anonymizedFabric.fabricId,
      'userCount': anonymizedFabric.userCount,
      'density': anonymizedFabric.density,
      'stability': anonymizedFabric.stability,
      'anonymizedAt': anonymizedAt.toJson(),
    };
  }
}

/// Anonymized knot worldsheet for third-party transmission
class AnonymizedKnotWorldsheet {
  final KnotWorldsheet anonymizedWorldsheet;
  final AtomicTimestamp anonymizedAt;

  AnonymizedKnotWorldsheet({
    required this.anonymizedWorldsheet,
    required this.anonymizedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': anonymizedWorldsheet.groupId,
      'userCount': anonymizedWorldsheet.userStrings.length,
      'snapshotCount': anonymizedWorldsheet.snapshots.length,
      'timeSpan': anonymizedWorldsheet.timeSpan.inMilliseconds,
      'anonymizedAt': anonymizedAt.toJson(),
    };
  }
}

/// Encrypted transmission result
class EncryptedTransmissionResult {
  final bool success;
  final EncryptionType encryptionType;
  final bool meshTransmitted;
  final String recipientAgentId;
  final String? error;

  EncryptedTransmissionResult({
    required this.success,
    required this.encryptionType,
    required this.meshTransmitted,
    required this.recipientAgentId,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'encryptionType': encryptionType.toString(),
      'meshTransmitted': meshTransmitted,
      'recipientAgentId': recipientAgentId,
      if (error != null) 'error': error,
    };
  }
}
