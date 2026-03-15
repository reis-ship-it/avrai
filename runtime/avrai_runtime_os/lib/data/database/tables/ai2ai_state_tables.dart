import 'package:drift/drift.dart';

/// Stores compressed passive location dwells
class DwellEvents extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  // JSON encoded list of Agent IDs encountered during this dwell
  TextColumn get encounteredAgentIds => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stores Topological Pheromones (KnowledgeVectors)
class Pheromones extends Table {
  TextColumn get id => text()();
  TextColumn get senderAgentId => text()();

  // JSON encoded list of doubles
  TextColumn get insightWeights => text()();

  TextColumn get contextCategory => text()();
  DateTimeColumn get timestamp => dateTime()();

  // Queue state
  TextColumn get queueType =>
      text().withDefault(const Constant('inbox'))(); // 'inbox' or 'outbox'

  @override
  Set<Column> get primaryKey => {id};
}

/// Stores Learned Archetypes (The "Soul")
class Archetypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  // JSON encoded state
  TextColumn get stateJson => text()();

  DateTimeColumn get lastUpdatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stores the user's PersonalityKnot (The "DNA")
class PersonalityKnots extends Table {
  TextColumn get userId => text()();

  // Binary DNA string
  BlobColumn get dnaPayload => blob()();

  DateTimeColumn get lastUpdatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
