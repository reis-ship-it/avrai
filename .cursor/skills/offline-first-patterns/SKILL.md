---
name: offline-first-patterns
description: Enforces offline-first architecture patterns: GetStorage/Drift database, local-first data sources, sync strategies, offline indicator. Use when implementing features, designing data flow, or ensuring offline functionality.
---

# Offline-First Patterns

## Core Principle

**All features must work offline.** Online features are enhancements, not requirements.

## Architecture Pattern

### Local-First Data Flow
```
User Action → Local Database → UI Update
              ↓ (background)
           Sync to Remote (when online)
```

**NOT:**
```
User Action → Remote API → UI Update (❌ Requires internet)
```

## Data Sources Pattern

### Local Data Source (Primary)
```dart
/// Local data source (GetStorage for key-value, Drift for relational)
class SpotsLocalDataSource {
  final GetStorage _box = GetStorage('spots');
  
  Future<List<Spot>> getSpots() async {
    // Read from local storage
    final keys = _box.getKeys<String>();
    final spots = <Spot>[];
    for (final key in keys) {
      final data = _box.read<Map<String, dynamic>>(key);
      if (data != null) spots.add(Spot.fromJson(data));
    }
    return spots;
  }
  
  Future<void> saveSpot(Spot spot) async {
    // Save to local storage
    await _box.write(spot.id, spot.toJson());
  }
}
```

### Remote Data Source (Optional Enhancement)
```dart
/// Remote data source (optional sync)
class SpotsRemoteDataSource {
  Future<List<Spot>> getSpots() async {
    // Fetch from remote API (only when online)
    // Returns empty list if offline
  }
  
  Future<void> syncSpots(List<Spot> spots) async {
    // Sync to remote (background, when online)
  }
}
```

### Repository Pattern (Combines Both)
```dart
/// Repository: Local-first, remote sync
class SpotsRepositoryImpl implements SpotsRepository {
  final SpotsLocalDataSource _localDataSource;
  final SpotsRemoteDataSource? _remoteDataSource;
  
  @override
  Future<List<Spot>> getSpots() async {
    // Always read from local first (works offline)
    final localSpots = await _localDataSource.getSpots();
    
    // Sync from remote in background (if online)
    if (_remoteDataSource != null) {
      _syncInBackground();
    }
    
    return localSpots;
  }
  
  void _syncInBackground() async {
    try {
      final remoteSpots = await _remoteDataSource!.getSpots();
      // Update local database with remote data
      for (final spot in remoteSpots) {
        await _localDataSource.saveSpot(spot);
      }
    } catch (e) {
      // Silently fail - offline mode
    }
  }
}
```

## GetStorage Database

### Initialization
```dart
/// Initialize GetStorage (offline-first storage)
/// Call in main.dart before DI initialization
Future<void> initializeGetStorageBoxes() async {
  await GetStorage.init('spots');
  await GetStorage.init('users');
  await GetStorage.init('chat_messages');
  // ... other boxes
}
```

### Storage Service Pattern
```dart
/// Storage service using GetStorage (offline-first)
class SpotsStorageService {
  final GetStorage _box = GetStorage('spots');
  
  Future<void> saveSpot(Spot spot) async {
    // Save to local storage (always works)
    await _box.write(spot.id, spot.toJson());
    
    // Queue for remote sync (if online)
    await _queueForSync(spot);
  }
  
  Future<Spot?> getSpot(String id) async {
    // Read from local storage (always works)
    final data = _box.read<Map<String, dynamic>>(id);
    
    if (data == null) return null;
    return Spot.fromJson(data);
  }
}
```

## Drift Database (Relational)

For complex relational data (users, lists, spots with queries):

```dart
/// Drift database for relational data
final db = GetIt.I<AppDatabase>();

// Insert
await db.upsertSpot(SpotsCompanion.insert(...));

// Query
final spots = await db.getAllSpots();

// Watch for changes (reactive)
db.watchSpots().listen((spots) => updateUI(spots));
```

## Offline Indicator

Show user when offline:

```dart
/// Offline indicator widget
class OfflineIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final isOnline = snapshot.data != ConnectivityResult.none;
        
        if (!isOnline) {
          return Container(
            color: AppColors.warning,
            child: Text(
              'Offline mode - changes will sync when online',
              style: TextStyle(color: AppColors.white),
            ),
          );
        }
        
        return SizedBox.shrink();
      },
    );
  }
}
```

## Sync Strategy

### Background Sync
```dart
/// Background sync service
class SyncService {
  final Database _database;
  final RemoteDataSource _remoteDataSource;
  
  Future<void> syncInBackground() async {
    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      return; // No sync if offline
    }
    
    // Sync pending changes
    await _syncPendingChanges();
    
    // Pull latest from remote
    await _pullLatestData();
  }
  
  Future<void> _syncPendingChanges() async {
    final pendingChanges = await _getPendingChanges();
    for (final change in pendingChanges) {
      try {
        await _remoteDataSource.syncChange(change);
        await _markSynced(change.id);
      } catch (e) {
        // Keep in queue for retry
      }
    }
  }
}
```

## Offline-First Checklist

- [ ] Feature works without internet connection
- [ ] Data stored locally (GetStorage for key-value, Drift for relational)
- [ ] UI updates immediately (no waiting for network)
- [ ] Remote sync happens in background (when online)
- [ ] Offline indicator shown when disconnected
- [ ] Pending changes queued for sync
- [ ] Error handling for offline scenarios
- [ ] No blocking network calls in UI thread
- [ ] GetStorage boxes initialized in main.dart before DI

## Reference

- `lib/core/services/storage_service.dart` - Storage service pattern (GetStorage)
- `lib/data/database/app_database.dart` - Drift database for relational data
- `lib/data/datasources/local/` - Local data sources (Drift/GetStorage)
- `test/helpers/test_storage_helper.dart` - Test storage initialization
