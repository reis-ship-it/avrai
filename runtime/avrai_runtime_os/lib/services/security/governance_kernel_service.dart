import 'dart:developer' as developer;

/// Represents an abstract vector payload passed through the Epidemic Routing mesh.
/// In the v0.1 pivot, phones do not exchange chat logs; they exchange "Knowledge Vectors"
/// or "Topological Pheromones" which are purely numerical/categorical.
class KnowledgeVector {
  final String senderAgentId;
  
  // The numerical representation of an insight (e.g. a category affinity jump)
  final List<double> insightWeights;
  
  // Metadata about the context (e.g. category ID of a coffee shop)
  final String contextCategory;
  
  final DateTime timestamp;

  KnowledgeVector({
    required this.senderAgentId,
    required this.insightWeights,
    required this.contextCategory,
    required this.timestamp,
  });
}

/// Result of a Governance Kernel security check
class SecurityClearance {
  final bool isApproved;
  final KnowledgeVector? sanitizedVector;
  final String? rejectionReason;

  SecurityClearance._({
    required this.isApproved,
    this.sanitizedVector,
    this.rejectionReason,
  });

  factory SecurityClearance.approved(KnowledgeVector vector) {
    return SecurityClearance._(isApproved: true, sanitizedVector: vector);
  }

  factory SecurityClearance.rejected(String reason) {
    return SecurityClearance._(isApproved: false, rejectionReason: reason);
  }
}

/// The Governance Kernel (Spike 4 - Corrected for Pheromone Mesh)
///
/// A deterministic, un-bypassable rule engine that sits *between* the local OS
/// and the physical mesh network. It guarantees that AIs can exchange 
/// "Topological Pheromones" (Knowledge Vectors) without leaking PII or succumbing 
/// to adversarial mathematical injections.
class GovernanceKernelService {
  static const String _logName = 'GovernanceKernel';

  // Allowed categories to prevent arbitrary data passing
  static const Set<String> _allowedCategories = {
    'spot_affinity',
    'event_resonance',
    'community_vibe',
    'club_overlap'
  };

  /// Intercepts an OUTGOING Knowledge Vector before it hits the mesh.
  /// Ensures the vector contains no string payloads and bounds the math.
  SecurityClearance interceptOutgoing(KnowledgeVector vector) {
    developer.log('Intercepting outgoing Knowledge Vector from ${vector.senderAgentId}', name: _logName);
    
    // 1. Category Whitelist Check
    // Prevents phones from using the vector payload to tunnel arbitrary text data
    if (!_allowedCategories.contains(vector.contextCategory)) {
      developer.log('Vector rejected: Unauthorized category tunnel attempt.', name: _logName);
      return SecurityClearance.rejected('Unauthorized category.');
    }

    // 2. Vector Bounds Check (Preventing Gradient Poisoning)
    // Ensure the weights aren't astronomically high, which could poison the receiver's model
    List<double> sanitizedWeights = [];
    for (final weight in vector.insightWeights) {
      if (weight.isNaN || weight.isInfinite) {
        return SecurityClearance.rejected('Invalid vector math (NaN/Infinite).');
      }
      // Hard clamp between -1.0 and 1.0
      sanitizedWeights.add(weight.clamp(-1.0, 1.0));
    }

    // 3. Payload Size Limit
    if (sanitizedWeights.length > 512) {
      return SecurityClearance.rejected('Vector exceeds maximum dimensionality (512).');
    }

    final sanitizedVector = KnowledgeVector(
      senderAgentId: vector.senderAgentId,
      insightWeights: sanitizedWeights,
      contextCategory: vector.contextCategory,
      timestamp: vector.timestamp,
    );

    return SecurityClearance.approved(sanitizedVector);
  }

  /// Intercepts an INCOMING Knowledge Vector from the mesh.
  /// Validates the math bounds before allowing the local batch process to ingest it.
  SecurityClearance interceptIncoming(KnowledgeVector vector) {
    developer.log('Intercepting incoming Knowledge Vector from Swarm...', name: _logName);
    
    // 1. Structural Validation
    if (vector.insightWeights.isEmpty) {
      return SecurityClearance.rejected('Empty vector payload.');
    }

    // 2. Data Poisoning Defense
    // If a malicious node tries to send a massive weight to force a recommendation
    for (final weight in vector.insightWeights) {
      if (weight > 1.0 || weight < -1.0) {
        developer.log('CRITICAL: Gradient Poisoning detected! Blocking vector.', name: _logName);
        return SecurityClearance.rejected('Vector weight out of bounds. Possible poisoning attempt.');
      }
    }

    // 3. Temporal Validity
    // Prevent replay attacks of old data
    final age = DateTime.now().difference(vector.timestamp);
    if (age.inDays > 7) {
      return SecurityClearance.rejected('Vector payload expired (Replay attack prevention).');
    }

    return SecurityClearance.approved(vector);
  }
}
