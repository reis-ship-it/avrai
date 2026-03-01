import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'dart:developer' as developer;

/// The interface defining how the Reality Engine stores abstract knowledge.
abstract class SemanticKnowledgeStore {
  /// Persists a list of abstract meaning tuples to the database.
  Future<void> saveTuples(List<SemanticTuple> tuples);

  /// Retrieves tuples matching a specific subject.
  Future<List<SemanticTuple>> getTuplesForSubject(String subject);
}

/// A mock in-memory implementation for the v0.1 Sandbox.
class InMemorySemanticStore implements SemanticKnowledgeStore {
  final List<SemanticTuple> _storage = [];

  @override
  Future<void> saveTuples(List<SemanticTuple> tuples) async {
    _storage.addAll(tuples);
    developer.log(
        'InMemorySemanticStore: Saved ${tuples.length} tuples. Total facts: ${_storage.length}',
        name: 'RealityEngine');
  }

  @override
  Future<List<SemanticTuple>> getTuplesForSubject(String subject) async {
    return _storage.where((t) => t.subject == subject).toList();
  }
}
