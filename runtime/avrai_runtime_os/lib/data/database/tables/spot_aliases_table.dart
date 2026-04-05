import 'package:drift/drift.dart';

import 'spots_table.dart';

/// Provider-specific aliases for a canonical spot.
///
/// This table keeps external provider identifiers and lightweight alias
/// metadata tied back to the local canonical `Spots` row.
@DataClassName('SpotAliasData')
@TableIndex(
  name: 'idx_spot_aliases_canonical_spot',
  columns: {#canonicalSpotId},
)
class SpotAliases extends Table {
  TextColumn get canonicalSpotId => text().references(Spots, #id)();

  TextColumn get provider => text()();

  TextColumn get externalId => text()();

  TextColumn get name => text().nullable()();

  TextColumn get address => text().nullable()();

  RealColumn get latitude => real().nullable()();

  RealColumn get longitude => real().nullable()();

  TextColumn get phoneNumber => text().nullable()();

  TextColumn get website => text().nullable()();

  TextColumn get category => text().nullable()();

  RealColumn get confidenceScore => real().withDefault(const Constant(1.0))();

  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  BoolColumn get isPrimaryAlias =>
      boolean().withDefault(const Constant(false))();

  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {provider, externalId};
}
