// Quantum State Knot Service
//
// Bridges `QuantumEntityState` → `EntityKnot` so the knot layer can contribute
// truthful signals to multi-entity quantum matching (Patent #29 + Patent #31).

import 'dart:developer' as developer;

import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:avrai_knot/services/knot/bridge/knot_rust_loader.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';

/// Generates a knot representation directly from a `QuantumEntityState`.
///
/// This is used when we only have the quantum state vector (not the original
/// domain model like `ExpertiseEvent`, `Spot`, etc.) but still want a truthful
/// topological/weave signal.
class QuantumStateKnotService {
  static const String _logName = 'QuantumStateKnotService';

  /// Caps the number of properties used to build correlations so complexity
  /// stays bounded as entityCharacteristics grow.
  static const int _maxProperties = 32;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      try {
        await initKnotRustLib();
      } catch (e) {
        if (e.toString().contains(
          'Should not initialize flutter_rust_bridge twice',
        )) {
          _initialized = true;
          return;
        }
        rethrow;
      }
      _initialized = true;
    } catch (e, st) {
      developer.log(
        'Failed to initialize knot runtime: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<EntityKnot> generateEntityKnot({
    required QuantumEntityState state,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final props = _buildProperties(state);
      final correlations = _analyzeEntanglement(props);
      final braidData = _createBraidDataFromEntanglement(correlations);

      final rustResult = generateKnotFromBraid(braidData: braidData);

      final now = DateTime.now();
      final knot = PersonalityKnot(
        agentId: state.entityId,
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
        createdAt: now,
        lastUpdated: now,
      );

      return EntityKnot(
        entityId: state.entityId,
        entityType: _mapEntityType(state.entityType),
        knot: knot,
        metadata: <String, dynamic>{
          'quantum_entity_type': state.entityType.name,
          'dimensions': _mergeDimensions(state),
        },
        createdAt: now,
        lastUpdated: now,
      );
    } catch (e, st) {
      developer.log(
        'Failed to generate knot from quantum state: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  EntityType _mapEntityType(QuantumEntityType type) {
    switch (type) {
      case QuantumEntityType.expert:
      case QuantumEntityType.user:
        return EntityType.person;
      case QuantumEntityType.business:
        return EntityType.company;
      case QuantumEntityType.brand:
        return EntityType.brand;
      case QuantumEntityType.event:
        return EntityType.event;
      case QuantumEntityType.sponsor:
        return EntityType.sponsorship;
    }
  }

  Map<String, double> _mergeDimensions(QuantumEntityState state) {
    // Prefer the actual quantum-vibe vectors if present.
    final merged = <String, double>{};
    for (final e in state.personalityState.entries) {
      merged[e.key] = (e.value).clamp(0.0, 1.0);
    }
    for (final e in state.quantumVibeAnalysis.entries) {
      merged[e.key] = (e.value).clamp(0.0, 1.0);
    }
    return merged;
  }

  Map<String, double> _buildProperties(QuantumEntityState state) {
    final props = <String, double>{};

    // Personality + quantum vibe (most meaningful numeric features).
    for (final e in state.personalityState.entries) {
      props['ps:${e.key}'] = (e.value).clamp(0.0, 1.0);
    }
    for (final e in state.quantumVibeAnalysis.entries) {
      props['qv:${e.key}'] = (e.value).clamp(0.0, 1.0);
    }

    // Location/timing features (if present).
    final loc = state.location;
    if (loc != null) {
      props['loc:lat'] = loc.latitudeQuantumState.clamp(0.0, 1.0);
      props['loc:lon'] = loc.longitudeQuantumState.clamp(0.0, 1.0);
      props['loc:access'] = loc.accessibilityScore.clamp(0.0, 1.0);
      props['loc:vibe'] = loc.vibeLocationMatch.clamp(0.0, 1.0);
    }

    final t = state.timing;
    if (t != null) {
      props['time:day'] = t.timeOfDayPreference.clamp(0.0, 1.0);
      props['time:week'] = t.dayOfWeekPreference.clamp(0.0, 1.0);
      props['time:freq'] = t.frequencyPreference.clamp(0.0, 1.0);
      props['time:dur'] = t.durationPreference.clamp(0.0, 1.0);
      props['time:vibe'] = t.timingVibeMatch.clamp(0.0, 1.0);
    }

    // Entity characteristics (best-effort numeric extraction).
    for (final entry in state.entityCharacteristics.entries) {
      final key = entry.key;
      final v = entry.value;

      if (v is num) {
        props['ec:$key'] = v.toDouble().clamp(0.0, 1.0);
      } else if (v is bool) {
        props['ec:$key'] = v ? 1.0 : 0.0;
      } else if (v is String) {
        props['ec:$key'] = (v.hashCode.toDouble().abs() % 1000) / 1000.0;
      }
    }

    // Cap for predictable runtime.
    if (props.length <= _maxProperties) return props;
    final keys = props.keys.toList()..sort();
    final out = <String, double>{};
    for (final k in keys.take(_maxProperties)) {
      out[k] = props[k] ?? 0.5;
    }
    return out;
  }

  Map<String, double> _analyzeEntanglement(Map<String, double> properties) {
    final correlations = <String, double>{};
    final names = properties.keys.toList();

    for (var i = 0; i < names.length; i++) {
      for (var j = i + 1; j < names.length; j++) {
        final a = names[i];
        final b = names[j];
        final va = properties[a] ?? 0.5;
        final vb = properties[b] ?? 0.5;
        final corr = 1.0 - (va - vb).abs();
        if (corr > 0.3) {
          correlations['$a:$b'] = corr;
        }
      }
    }

    return correlations;
  }

  /// **Format:** `[strands, crossing1_strand, crossing1_over, ...]`
  List<double> _createBraidDataFromEntanglement(
    Map<String, double> correlations,
  ) {
    const baseStrands = 8;
    final numStrands = (baseStrands + correlations.length).clamp(2, 20);
    final braidData = <double>[numStrands.toDouble()];

    final entries = correlations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var strandIndex = 0;
    for (final entry in entries) {
      final strand = strandIndex % (numStrands - 1);
      final isOver = entry.value > 0.0;
      braidData.add(strand.toDouble());
      braidData.add(isOver ? 1.0 : 0.0);
      strandIndex++;
    }

    return braidData;
  }
}
