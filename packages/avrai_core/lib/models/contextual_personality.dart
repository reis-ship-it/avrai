import 'package:equatable/equatable.dart';

/// OUR_GUTS.md: "Your doors stay yours"
/// Phase 3: Contextual Personality System
/// Philosophy: Preserve core identity while allowing contextual adaptation

// ============================================================================
// CONTEXTUAL PERSONALITY
// Flexible personality adaptation for different contexts (work, social, etc.)
// ============================================================================

/// Contextual Personality Layer
/// Represents temporary personality adaptations in specific contexts
/// Philosophy: You can be different at work vs. with friends, but your core stays the same
class ContextualPersonality extends Equatable {
  final String contextId;
  final PersonalityContextType contextType;
  final Map<String, double> adaptedDimensions;
  final double adaptationWeight; // How much to blend with core (0.0-1.0)
  final DateTime lastUpdated;
  final int updateCount;
  final Map<String, dynamic> metadata; // Context-specific data
  
  const ContextualPersonality({
    required this.contextId,
    required this.contextType,
    required this.adaptedDimensions,
    this.adaptationWeight = 0.3, // 30% blend by default
    required this.lastUpdated,
    this.updateCount = 0,
    this.metadata = const {},
  });
  
  /// Create initial context with no adaptations
  factory ContextualPersonality.initial({
    required String contextId,
    required PersonalityContextType contextType,
  }) {
    return ContextualPersonality(
      contextId: contextId,
      contextType: contextType,
      adaptedDimensions: const {},
      adaptationWeight: 0.0, // No adaptation yet
      lastUpdated: DateTime.now(),
      updateCount: 0,
      metadata: const {},
    );
  }
  
  /// Update context with new adaptations
  ContextualPersonality adapt({
    Map<String, double>? newAdaptations,
    double? newWeight,
    Map<String, dynamic>? newMetadata,
  }) {
    final updatedAdaptations = Map<String, double>.from(adaptedDimensions);
    
    if (newAdaptations != null) {
      newAdaptations.forEach((dimension, value) {
        updatedAdaptations[dimension] = value.clamp(0.0, 1.0);
      });
    }
    
    final updatedMetadata = Map<String, dynamic>.from(metadata);
    if (newMetadata != null) {
      updatedMetadata.addAll(newMetadata);
    }
    
    return ContextualPersonality(
      contextId: contextId,
      contextType: contextType,
      adaptedDimensions: updatedAdaptations,
      adaptationWeight: (newWeight ?? adaptationWeight).clamp(0.0, 1.0),
      lastUpdated: DateTime.now(),
      updateCount: updateCount + 1,
      metadata: updatedMetadata,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'contextId': contextId,
    'contextType': contextType.name,
    'adaptedDimensions': adaptedDimensions,
    'adaptationWeight': adaptationWeight,
    'lastUpdated': lastUpdated.toIso8601String(),
    'updateCount': updateCount,
    'metadata': metadata,
  };
  
  factory ContextualPersonality.fromJson(Map<String, dynamic> json) {
    return ContextualPersonality(
      contextId: json['contextId'] as String,
      contextType: PersonalityContextType.values.firstWhere(
        (e) => e.name == json['contextType'],
        orElse: () => PersonalityContextType.general,
      ),
      adaptedDimensions: Map<String, double>.from(json['adaptedDimensions'] as Map),
      adaptationWeight: (json['adaptationWeight'] as num?)?.toDouble() ?? 0.3,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      updateCount: json['updateCount'] as int? ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
  
  @override
  List<Object?> get props => [
    contextId,
    contextType,
    adaptedDimensions,
    adaptationWeight,
    lastUpdated,
    updateCount,
    metadata,
  ];
}

/// Types of personality contexts
enum PersonalityContextType {
  work,        // Professional settings
  social,      // Friends and social gatherings
  exploration, // Discovery and exploration mode
  location,    // Geographic context (home vs. travel)
  activity,    // Activity-specific (sports, art, food)
  general,     // Default/general context
}

// ============================================================================
// LIFE PHASE
// Preserved personality snapshot from a specific life period
// ============================================================================

/// Life Phase
/// Represents who you were during a specific period of your life
/// Philosophy: You can grow and change, but we preserve who you were
class LifePhase extends Equatable {
  final String phaseId;
  final String name; // "College Years", "Early Career", etc.
  final Map<String, double> corePersonality; // Who you were then
  final double authenticity;
  final DateTime startDate;
  final DateTime? endDate; // null if current phase
  final Map<String, dynamic> milestones; // Key events in this phase
  final int interactionCount; // How many interactions in this phase
  final List<String> dominantTraits; // Top traits during this phase
  final String? transitionReason; // Why this phase ended
  
  const LifePhase({
    required this.phaseId,
    required this.name,
    required this.corePersonality,
    required this.authenticity,
    required this.startDate,
    this.endDate,
    this.milestones = const {},
    this.interactionCount = 0,
    this.dominantTraits = const [],
    this.transitionReason,
  });
  
  /// Create initial life phase
  /// Phase 8.3: Uses agentId for privacy protection
  factory LifePhase.initial({
    required String userId, // Can be agentId or userId (for backward compatibility)
    required Map<String, double> initialPersonality,
  }) {
    return LifePhase(
      phaseId: '${userId}_phase_1', // Uses provided identifier (agentId or userId)
      name: 'Initial Phase',
      corePersonality: initialPersonality,
      authenticity: 0.5,
      startDate: DateTime.now(),
      endDate: null, // Current phase
      milestones: {'created': DateTime.now().toIso8601String()},
      interactionCount: 0,
      dominantTraits: const [],
      transitionReason: null,
    );
  }
  
  /// End this phase and create new one
  LifePhase end({
    required String reason,
    DateTime? endTime,
  }) {
    return LifePhase(
      phaseId: phaseId,
      name: name,
      corePersonality: corePersonality,
      authenticity: authenticity,
      startDate: startDate,
      endDate: endTime ?? DateTime.now(),
      milestones: milestones,
      interactionCount: interactionCount,
      dominantTraits: dominantTraits,
      transitionReason: reason,
    );
  }
  
  /// Check if this is the current phase
  bool get isCurrent => endDate == null;
  
  /// Get phase duration
  Duration get duration {
    final end = endDate ?? DateTime.now();
    return end.difference(startDate);
  }
  
  Map<String, dynamic> toJson() => {
    'phaseId': phaseId,
    'name': name,
    'corePersonality': corePersonality,
    'authenticity': authenticity,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'milestones': milestones,
    'interactionCount': interactionCount,
    'dominantTraits': dominantTraits,
    'transitionReason': transitionReason,
  };
  
  factory LifePhase.fromJson(Map<String, dynamic> json) {
    return LifePhase(
      phaseId: json['phaseId'] as String,
      name: json['name'] as String,
      corePersonality: Map<String, double>.from(json['corePersonality'] as Map),
      authenticity: (json['authenticity'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      milestones: Map<String, dynamic>.from(json['milestones'] as Map? ?? {}),
      interactionCount: json['interactionCount'] as int? ?? 0,
      dominantTraits: List<String>.from(json['dominantTraits'] as List? ?? []),
      transitionReason: json['transitionReason'] as String?,
    );
  }
  
  @override
  List<Object?> get props => [
    phaseId,
    name,
    corePersonality,
    authenticity,
    startDate,
    endDate,
    milestones,
    interactionCount,
    dominantTraits,
    transitionReason,
  ];
}

// ============================================================================
// TRANSITION METRICS
// Tracks and validates personality transitions
// ============================================================================

/// Transition Metrics
/// Detects and validates authentic personality transformations vs. surface drift
/// Philosophy: Real growth is gradual and consistent, not sudden
class TransitionMetrics extends Equatable {
  final String transitionId;
  final DateTime startDate;
  final String fromPhaseId;
  final String? toPhaseId; // null if transition in progress
  final Map<String, double> dimensionChanges; // Change magnitude per dimension
  final double changeVelocity; // How fast personality is changing
  final double consistency; // How consistent the change direction
  final double authenticityScore; // Is this change authentic or drift?
  final List<String> triggers; // What triggered this transition
  final bool isComplete;
  
  const TransitionMetrics({
    required this.transitionId,
    required this.startDate,
    required this.fromPhaseId,
    this.toPhaseId,
    required this.dimensionChanges,
    required this.changeVelocity,
    required this.consistency,
    required this.authenticityScore,
    this.triggers = const [],
    this.isComplete = false,
  });
  
  /// Detect if transition is authentic (true growth) vs. surface drift
  bool get isAuthentic => authenticityScore >= 0.7 && consistency >= 0.6;
  
  /// Detect if transition is too fast (suspicious)
  bool get isTooFast => changeVelocity > 0.5;
  
  /// Get dimensions with significant change
  List<String> get significantChanges {
    return dimensionChanges.entries
        .where((e) => e.value.abs() > 0.15)
        .map((e) => e.key)
        .toList();
  }
  
  /// Complete the transition
  TransitionMetrics complete({
    required String toPhaseId,
    required double finalAuthenticityScore,
  }) {
    return TransitionMetrics(
      transitionId: transitionId,
      startDate: startDate,
      fromPhaseId: fromPhaseId,
      toPhaseId: toPhaseId,
      dimensionChanges: dimensionChanges,
      changeVelocity: changeVelocity,
      consistency: consistency,
      authenticityScore: finalAuthenticityScore,
      triggers: triggers,
      isComplete: true,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'transitionId': transitionId,
    'startDate': startDate.toIso8601String(),
    'fromPhaseId': fromPhaseId,
    'toPhaseId': toPhaseId,
    'dimensionChanges': dimensionChanges,
    'changeVelocity': changeVelocity,
    'consistency': consistency,
    'authenticityScore': authenticityScore,
    'triggers': triggers,
    'isComplete': isComplete,
  };
  
  factory TransitionMetrics.fromJson(Map<String, dynamic> json) {
    return TransitionMetrics(
      transitionId: json['transitionId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      fromPhaseId: json['fromPhaseId'] as String,
      toPhaseId: json['toPhaseId'] as String?,
      dimensionChanges: Map<String, double>.from(json['dimensionChanges'] as Map),
      changeVelocity: (json['changeVelocity'] as num).toDouble(),
      consistency: (json['consistency'] as num).toDouble(),
      authenticityScore: (json['authenticityScore'] as num).toDouble(),
      triggers: List<String>.from(json['triggers'] as List? ?? []),
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }
  
  @override
  List<Object?> get props => [
    transitionId,
    startDate,
    fromPhaseId,
    toPhaseId,
    dimensionChanges,
    changeVelocity,
    consistency,
    authenticityScore,
    triggers,
    isComplete,
  ];
}