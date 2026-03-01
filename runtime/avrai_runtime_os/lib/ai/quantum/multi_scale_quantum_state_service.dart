// Multi-Scale Quantum State Service
//
// Service for generating quantum states at different temporal and contextual scales
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/multi_scale_quantum_state.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Service for generating multi-scale quantum states
///
/// **Responsibilities:**
/// - Generate short-term quantum states (last 7 days)
/// - Generate long-term quantum states (all historical data)
/// - Generate contextual quantum states (work, social, etc.)
/// - Combine scales using weighted superposition
///
/// **Performance Optimizations (Phase 4):**
/// - Parallel generation: Generates all scales in parallel using Future.wait()
/// - Caching: Caches generated states to avoid redundant computations
class MultiScaleQuantumStateService {
  static const String _logName = 'MultiScaleQuantumStateService';

  final AtomicClockService _atomicClock;

  // Performance optimization: Cache generated states
  // Cache key: profile.agentId + context key
  final Map<String, MultiScaleQuantumState> _stateCache = {};
  static const int _maxCacheSize = 500;

  MultiScaleQuantumStateService({
    required AtomicClockService atomicClock,
  }) : _atomicClock = atomicClock;

  /// Generate multi-scale quantum states from personality profile
  ///
  /// **Flow:**
  /// 1. Get personality profile data
  /// 2. Filter data by time scale (short-term vs long-term)
  /// 3. Filter data by context (if available)
  /// 4. Generate quantum states for each scale **in parallel**
  /// 5. Return multi-scale state
  ///
  /// **Parameters:**
  /// - `profile`: Personality profile
  /// - `historicalData`: Optional historical personality data (for long-term state)
  /// - `contextualData`: Optional context-specific data (work, social, etc.)
  /// - `useCache`: Whether to use cached results (default: true)
  Future<MultiScaleQuantumState> generateMultiScaleStates({
    required PersonalityProfile profile,
    List<PersonalityProfile>? historicalData,
    Map<ContextualScale, PersonalityProfile>? contextualData,
    bool useCache = true,
  }) async {
    // Performance optimization: Check cache first
    if (useCache) {
      final cacheKey =
          _generateCacheKey(profile.agentId, historicalData, contextualData);
      final cached = _stateCache[cacheKey];
      if (cached != null) {
        developer.log(
          '✅ Using cached multi-scale states for ${profile.agentId}',
          name: _logName,
        );
        return cached;
      }
    }

    developer.log(
      'Generating multi-scale quantum states for ${profile.agentId}',
      name: _logName,
    );

    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();
      final now = DateTime.now();

      // Performance optimization: Generate all states in parallel using Future.wait()
      // This significantly improves performance when generating multiple scales

      // Prepare futures for parallel execution
      final futures = <Future<QuantumEntityState>>[];
      final futureTypes = <String>[]; // Track which future is which

      // Short-term state future
      Future<QuantumEntityState> shortTermFuture;
      if (historicalData != null) {
        final recentData = historicalData.where((p) {
          // Filter to last 7 days (simplified - would use actual timestamps)
          return true; // For now, use all data
        }).toList();

        if (recentData.isNotEmpty) {
          final combinedProfile = _combineProfiles(recentData);
          shortTermFuture = _generateQuantumState(
            profile: combinedProfile,
            tAtomic: tAtomic,
          );
        } else {
          shortTermFuture = _generateQuantumState(
            profile: profile,
            tAtomic: tAtomic,
          );
        }
      } else {
        shortTermFuture = _generateQuantumState(
          profile: profile,
          tAtomic: tAtomic,
        );
      }
      futures.add(shortTermFuture);
      futureTypes.add('shortTerm');

      // Long-term state future
      Future<QuantumEntityState> longTermFuture;
      if (historicalData != null && historicalData.isNotEmpty) {
        final combinedProfile = _combineProfiles([profile, ...historicalData]);
        longTermFuture = _generateQuantumState(
          profile: combinedProfile,
          tAtomic: tAtomic,
        );
      } else {
        longTermFuture = _generateQuantumState(
          profile: profile,
          tAtomic: tAtomic,
        );
      }
      futures.add(longTermFuture);
      futureTypes.add('longTerm');

      // Contextual states futures
      final contextualFutures =
          <Future<MapEntry<ContextualScale, QuantumEntityState>>>[];

      if (contextualData != null) {
        for (final entry in contextualData.entries) {
          final future = _generateQuantumState(
            profile: entry.value,
            tAtomic: tAtomic,
          ).then((state) => MapEntry(entry.key, state));
          contextualFutures.add(future);
        }
      }

      // Always include general context
      final generalFuture = _generateQuantumState(
        profile: profile,
        tAtomic: tAtomic,
      ).then((state) => MapEntry(ContextualScale.general, state));
      contextualFutures.add(generalFuture);

      // Wait for all futures in parallel
      final results = await Future.wait([
        Future.wait(futures),
        Future.wait(contextualFutures),
      ]);

      final scaleStates = results[0] as List<QuantumEntityState>;
      final contextualResults =
          results[1] as List<MapEntry<ContextualScale, QuantumEntityState>>;

      final shortTermState = scaleStates[0];
      final longTermState = scaleStates[1];

      final contextualStates = <ContextualScale, QuantumEntityState>{};
      for (final entry in contextualResults) {
        contextualStates[entry.key] = entry.value;
      }

      final multiScaleState = MultiScaleQuantumState(
        entityId: profile.agentId,
        shortTerm: shortTermState,
        longTerm: longTermState,
        contextual: contextualStates,
        createdAt: now,
      );

      developer.log(
        '✅ Generated multi-scale states in parallel: shortTerm=true, '
        'longTerm=true, contextual=${contextualStates.length}',
        name: _logName,
      );

      // Performance optimization: Cache result
      if (useCache) {
        final cacheKey =
            _generateCacheKey(profile.agentId, historicalData, contextualData);
        _addToCache(cacheKey, multiScaleState);
      }

      return multiScaleState;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to generate multi-scale states: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Combine scales using weighted superposition
  ///
  /// **Formula:**
  /// |ψ_combined⟩ = √w_short·|ψ_short⟩ + √w_long·|ψ_long⟩ + √w_context·|ψ_context⟩
  ///
  /// **Parameters:**
  /// - `multiScaleState`: Multi-scale quantum state
  /// - `weights`: Weights for each scale
  /// - `context`: Optional specific context to use
  Future<QuantumEntityState> combineScales({
    required MultiScaleQuantumState multiScaleState,
    required ScaleWeights weights,
    ContextualScale? context,
  }) async {
    developer.log(
      'Combining scales for ${multiScaleState.entityId}',
      name: _logName,
    );

    try {
      // Get contextual state
      final contextualState = context != null
          ? multiScaleState.getStateForContext(context)
          : multiScaleState.getStateForContext(ContextualScale.general);

      if (contextualState == null) {
        throw StateError('No contextual state available');
      }

      // Start with contextual state
      var combined = contextualState;
      final contextualWeight = weights.getContextualWeight(
        context ?? ContextualScale.general,
      );

      // Superpose with short-term state
      final shortTerm = multiScaleState.shortTerm;
      if (shortTerm != null && weights.shortTermWeight > 0.0) {
        final totalWeight = contextualWeight + weights.shortTermWeight;
        combined = _superposeStates(
          combined,
          shortTerm,
          contextualWeight / totalWeight,
        );
      }

      // Superpose with long-term state
      final longTerm = multiScaleState.longTerm;
      if (longTerm != null && weights.longTermWeight > 0.0) {
        final currentWeight = contextualWeight + weights.shortTermWeight;
        final totalWeight = currentWeight + weights.longTermWeight;
        combined = _superposeStates(
          combined,
          longTerm,
          currentWeight / totalWeight,
        );
      }

      // Normalize result
      return combined.normalized();
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to combine scales: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Get state for specific context
  ///
  /// Returns the most appropriate quantum state for the given context
  Future<QuantumEntityState> getStateForContext({
    required MultiScaleQuantumState multiScaleState,
    required ContextualScale context,
    ScaleWeights? weights,
  }) async {
    // If weights provided, combine scales
    if (weights != null) {
      return combineScales(
        multiScaleState: multiScaleState,
        weights: weights,
        context: context,
      );
    }

    // Otherwise, return contextual state directly
    final contextualState = multiScaleState.getStateForContext(context);
    if (contextualState != null) {
      return contextualState;
    }

    // Fallback to general context
    final generalState =
        multiScaleState.getStateForContext(ContextualScale.general);
    if (generalState != null) {
      return generalState;
    }

    // Last resort: use long-term state
    if (multiScaleState.longTerm != null) {
      return multiScaleState.longTerm!;
    }

    throw StateError('No quantum state available for context');
  }

  /// Generate quantum entity state from personality profile
  Future<QuantumEntityState> _generateQuantumState({
    required PersonalityProfile profile,
    required AtomicTimestamp tAtomic,
  }) async {
    // For now, use profile dimensions as quantum vibe analysis
    // In a full implementation, would use QuantumVibeEngine with proper insights
    final quantumDimensions = Map<String, double>.from(profile.dimensions);

    return QuantumEntityState(
      entityId: profile.agentId,
      entityType: QuantumEntityType.user,
      personalityState: profile.dimensions,
      quantumVibeAnalysis: quantumDimensions,
      entityCharacteristics: {},
      location: null,
      timing: null,
      tAtomic: tAtomic,
    ).normalized();
  }

  /// Combine multiple personality profiles into one
  PersonalityProfile _combineProfiles(List<PersonalityProfile> profiles) {
    if (profiles.isEmpty) {
      throw ArgumentError('Cannot combine empty profile list');
    }

    if (profiles.length == 1) {
      return profiles.first;
    }

    // Average dimensions across profiles
    final combinedDimensions = <String, double>{};
    final allDimensions = <String>{};

    for (final profile in profiles) {
      allDimensions.addAll(profile.dimensions.keys);
    }

    for (final dimension in allDimensions) {
      double sum = 0.0;
      int count = 0;

      for (final profile in profiles) {
        if (profile.dimensions.containsKey(dimension)) {
          sum += profile.dimensions[dimension]!;
          count++;
        }
      }

      if (count > 0) {
        combinedDimensions[dimension] = sum / count;
      }
    }

    // Use first profile as template
    final firstProfile = profiles.first;
    return PersonalityProfile(
      agentId: firstProfile.agentId,
      userId: firstProfile.userId,
      dimensions: combinedDimensions,
      dimensionConfidence: firstProfile.dimensionConfidence,
      archetype: firstProfile.archetype,
      authenticity: firstProfile.authenticity,
      createdAt: firstProfile.createdAt,
      lastUpdated: DateTime.now(),
      evolutionGeneration: firstProfile.evolutionGeneration,
      learningHistory: firstProfile.learningHistory,
    );
  }

  /// Superpose two quantum states
  QuantumEntityState _superposeStates(
    QuantumEntityState state1,
    QuantumEntityState state2,
    double weight1,
  ) {
    // Combine personality states
    final combinedPersonality = <String, double>{};
    final allKeys = <String>{};
    allKeys.addAll(state1.personalityState.keys);
    allKeys.addAll(state2.personalityState.keys);

    for (final key in allKeys) {
      final v1 = state1.personalityState[key] ?? 0.0;
      final v2 = state2.personalityState[key] ?? 0.0;
      combinedPersonality[key] =
          (weight1 * v1 + (1.0 - weight1) * v2).clamp(0.0, 1.0);
    }

    // Combine quantum vibe analysis
    final combinedVibe = <String, double>{};
    final allVibeKeys = <String>{};
    allVibeKeys.addAll(state1.quantumVibeAnalysis.keys);
    allVibeKeys.addAll(state2.quantumVibeAnalysis.keys);

    for (final key in allVibeKeys) {
      final v1 = state1.quantumVibeAnalysis[key] ?? 0.0;
      final v2 = state2.quantumVibeAnalysis[key] ?? 0.0;
      combinedVibe[key] = (weight1 * v1 + (1.0 - weight1) * v2).clamp(0.0, 1.0);
    }

    return QuantumEntityState(
      entityId: state1.entityId,
      entityType: state1.entityType,
      personalityState: combinedPersonality,
      quantumVibeAnalysis: combinedVibe,
      entityCharacteristics: state1.entityCharacteristics,
      location: state1.location,
      timing: state1.timing,
      tAtomic: state1.tAtomic,
    );
  }

  // ===== Performance Optimization Methods =====

  /// Generate cache key for multi-scale state
  String _generateCacheKey(
    String agentId,
    List<PersonalityProfile>? historicalData,
    Map<ContextualScale, PersonalityProfile>? contextualData,
  ) {
    final historyKey = historicalData != null
        ? '${historicalData.length}_${historicalData.map((p) => p.agentId).join(",")}'
        : 'none';
    final contextKey = contextualData != null
        ? contextualData.keys.map((k) => k.toString()).join(",")
        : 'none';
    return '${agentId}_${historyKey}_$contextKey';
  }

  /// Add state to cache
  /// Evicts oldest entries if cache exceeds max size
  void _addToCache(String key, MultiScaleQuantumState state) {
    // Evict oldest entries if cache is full
    if (_stateCache.length >= _maxCacheSize) {
      // Remove first entry (FIFO eviction)
      final firstKey = _stateCache.keys.first;
      _stateCache.remove(firstKey);
      developer.log(
        'State cache full, evicted entry: $firstKey',
        name: _logName,
      );
    }

    _stateCache[key] = state;
  }

  /// Clear state cache
  /// Useful for memory management or when profiles are updated
  void clearCache() {
    final size = _stateCache.length;
    _stateCache.clear();
    developer.log(
      'Cleared multi-scale state cache ($size entries)',
      name: _logName,
    );
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _stateCache.length,
      'maxSize': _maxCacheSize,
      'usage':
          '${(_stateCache.length / _maxCacheSize * 100).toStringAsFixed(1)}%',
    };
  }
}
