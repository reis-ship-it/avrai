import 'dart:developer' as developer;
import 'simulated_human.dart';
import 'spatial/swarm_map_environment.dart';

/// Simulates the federated learning and knowledge exchange between agents.
/// When one agent discovers a high-quality gap, it shares the abstract embedding
/// (not the raw user data) with the swarm, allowing other agents to learn.
class FederatedKnowledgeExchange {
  static const String _logName = 'FederatedKnowledgeExchange';

  // In a real system, this would be a vector database of successful trajectory embeddings.
  // For the simulation, we track highly successful POI IDs and their average success rate.
  final Map<String, _GlobalGapKnowledge> _globalKnowledgeBase = {};

  /// Records a successful "Routine Enhancement" discovery.
  void recordSuccess(SimulatedHuman human, PointOfInterest poi, double successScore) {
    if (!_globalKnowledgeBase.containsKey(poi.id)) {
      _globalKnowledgeBase[poi.id] = _GlobalGapKnowledge(poi: poi);
    }
    
    final knowledge = _globalKnowledgeBase[poi.id]!;
    knowledge.addSuccess(successScore);

    // If it becomes highly verified, log it as a swarm discovery
    if (knowledge.isHighlyVerified && !knowledge.hasBeenLogged) {
      developer.log(
        '🌐 SWARM DISCOVERY: The network has verified ${poi.name} (${poi.category.name}) as a highly reliable gap filler!',
        name: _logName,
      );
      knowledge.hasBeenLogged = true;
    }
  }

  /// Allows an agent to query the global knowledge base to boost the quality
  /// score of a candidate POI if it has been verified by the swarm.
  double getSwarmConfidenceBoost(String poiId) {
    final knowledge = _globalKnowledgeBase[poiId];
    if (knowledge == null) return 0.0;
    if (!knowledge.isHighlyVerified) return 0.0;

    // Provide a small boost to perceived quality based on swarm success
    return knowledge.averageScore * 0.2; // Max 20% boost
  }
}

class _GlobalGapKnowledge {
  final PointOfInterest poi;
  int successCount = 0;
  double totalScore = 0.0;
  bool hasBeenLogged = false;

  _GlobalGapKnowledge({required this.poi});

  void addSuccess(double score) {
    successCount++;
    totalScore += score;
  }

  double get averageScore => successCount == 0 ? 0 : totalScore / successCount;

  // Deemed highly verified if at least 3 agents had a great time
  bool get isHighlyVerified => successCount >= 3 && averageScore > 0.6;
}
