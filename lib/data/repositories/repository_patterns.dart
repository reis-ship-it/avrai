import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';

/// Centralized repository patterns to eliminate code repetition
/// Date: July 30, 2025
/// Updated: January 2025 - Added optional connectivity support for local-only repositories

/// Base class for simplified repositories that separate local and remote concerns
/// 
/// **Connectivity Support:**
/// - If `connectivity` is provided: Full online/offline support
/// - If `connectivity` is null: Local-only operations (no network checks)
abstract class SimplifiedRepositoryBase {
  final Connectivity? connectivity;

  /// Constructor accepts optional connectivity for local-only repositories
  SimplifiedRepositoryBase({this.connectivity});

  /// Check if device is online
  /// Returns false if connectivity is null (local-only mode)
  Future<bool> get isOnline async {
    if (connectivity == null) {
      return false; // Local-only mode, always considered offline
    }
    try {
      final result = await connectivity!.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e, st) {
      // In some environments (notably widget/integration tests), the underlying
      // platform implementation may not be available. Treat failures as offline.
      developer.log(
        'Connectivity check failed; assuming offline',
        name: 'SimplifiedRepositoryBase',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Execute operation with offline-first strategy
  /// Returns local result immediately, then syncs with remote if online
  Future<T> executeOfflineFirst<T>({
    required Future<T> Function() localOperation,
    Future<T> Function()? remoteOperation,
    Future<void> Function(T)? syncToLocal,
  }) async {
    try {
      // Always execute local operation first
      final localResult = await localOperation();

      // If online and remote operation is provided, try to sync
      if (await isOnline && remoteOperation != null) {
        try {
          final remoteResult = await remoteOperation();
          if (syncToLocal != null) {
            await syncToLocal(remoteResult);
          }
          return remoteResult;
        } catch (e) {
          // If remote fails, return local result
          return localResult;
        }
      }

      return localResult;
    } catch (e) {
      throw Exception('Operation failed: $e');
    }
  }

  /// Execute operation with online-first strategy
  /// Tries remote first, falls back to local if offline or remote fails
  Future<T> executeOnlineFirst<T>({
    required Future<T> Function() remoteOperation,
    required Future<T> Function() localOperation,
    Future<void> Function(T)? syncToLocal,
  }) async {
    try {
      if (await isOnline) {
        try {
          final remoteResult = await remoteOperation();
          if (syncToLocal != null) {
            await syncToLocal(remoteResult);
          }
          return remoteResult;
        } catch (e) {
          // If remote fails, try local
          return await localOperation();
        }
      } else {
        // If offline, use local
        return await localOperation();
      }
    } catch (e) {
      throw Exception('Operation failed: $e');
    }
  }

  /// Execute operation with local-only strategy
  /// Useful for operations that should only work locally
  Future<T> executeLocalOnly<T>({
    required Future<T> Function() localOperation,
  }) async {
    try {
      return await localOperation();
    } catch (e) {
      throw Exception('Local operation failed: $e');
    }
  }

  /// Execute operation with remote-only strategy
  /// Useful for operations that require network connectivity
  Future<T> executeRemoteOnly<T>({
    required Future<T> Function() remoteOperation,
  }) async {
    try {
      if (!await isOnline) {
        throw Exception('Operation requires internet connection');
      }
      return await remoteOperation();
    } catch (e) {
      throw Exception('Remote operation failed: $e');
    }
  }
}

/// Generic repository interface for CRUD operations
abstract class GenericRepository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> delete(String id);
}

/// Simplified repository that implements the new unified models
abstract class UnifiedRepository<T> extends SimplifiedRepositoryBase
    implements GenericRepository<T> {
  /// Constructor accepts optional connectivity for local-only repositories
  UnifiedRepository({super.connectivity});

  /// Local data source operations
  Future<List<T>> getAllLocal();
  Future<T?> getByIdLocal(String id);
  Future<T> createLocal(T item);
  Future<T> updateLocal(T item);
  Future<void> deleteLocal(String id);

  /// Remote data source operations (optional)
  Future<List<T>> getAllRemote();
  Future<T?> getByIdRemote(String id);
  Future<T> createRemote(T item);
  Future<T> updateRemote(T item);
  Future<void> deleteRemote(String id);

  /// Sync operations
  Future<void> syncToLocal(T item);
  Future<void> syncToRemote(T item);

  @override
  Future<List<T>> getAll() async {
    return executeOfflineFirst(
      localOperation: getAllLocal,
      remoteOperation: getAllRemote,
    );
  }

  @override
  Future<T?> getById(String id) async {
    return executeOfflineFirst(
      localOperation: () => getByIdLocal(id),
      remoteOperation: () => getByIdRemote(id),
    );
  }

  @override
  Future<T> create(T item) async {
    return executeOfflineFirst(
      localOperation: () => createLocal(item),
      remoteOperation: () => createRemote(item),
      syncToLocal: syncToLocal,
    );
  }

  @override
  Future<T> update(T item) async {
    return executeOfflineFirst(
      localOperation: () => updateLocal(item),
      remoteOperation: () => updateRemote(item),
      syncToLocal: syncToLocal,
    );
  }

  @override
  Future<void> delete(String id) async {
    return executeOfflineFirst(
      localOperation: () => deleteLocal(id),
      remoteOperation: () => deleteRemote(id),
    );
  }
}

/// Repository for operations that require specific business logic
abstract class BusinessLogicRepository<T> extends SimplifiedRepositoryBase {
  /// Constructor accepts optional connectivity for local-only repositories
  BusinessLogicRepository({super.connectivity});

  /// Business logic operations
  Future<List<T>> getByBusinessCriteria(Map<String, dynamic> criteria);
  Future<T> processBusinessLogic(T item);
  Future<void> validateBusinessRules(T item);
}
