# Phase 26: Drift Database

## Setup

After adding the Drift dependencies, run code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `app_database.g.dart` - Generated database code with type-safe queries

## Tables

- **Messages** - Chat messages with indexes on chatId, timestamp, isRead
- **Spots** - Location/venue data with geospatial indexes
- **Lists** - User-created lists of spots
- **ListSpots** - Junction table for list-spot relationships
- **Users** - Local user profile data
- **LinkedDevices** - Multi-device tracking
- **DeviceLinkRequests** - Device pairing requests
- **TransferProgress** - History transfer progress for resume support
- **SyncState** - Cross-device sync tracking
- **SyncQueue** - Pending sync operations queue

## Usage

```dart
final db = GetIt.I<AppDatabase>();

// Insert message
await db.upsertMessage(MessagesCompanion.insert(...));

// Query messages
final messages = await db.getMessagesForChat(chatId);

// Watch for changes (reactive)
db.watchMessagesForChat(chatId).listen((messages) {
  // Update UI
});
```

## Migration from Sembast (Completed)

The migration from Sembast to Drift was completed in Phase 26.
- All Sembast datasources have been replaced with GetStorage or Drift equivalents
- The `StorageMigrationService` was removed after migration completion
- New installations use Drift/GetStorage directly without migration

For historical context, see:
- `docs/reports/feature_implementation/sembast_complete_removal_report.md`
- `docs/reports/feature_implementation/sembast_to_getstorage_migration_report.md`
