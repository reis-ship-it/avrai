import 'package:avrai_core/avra_core.dart';
import '../models/api_response.dart';

/// Data backend interface for CRUD operations
/// Handles all data persistence and retrieval operations
abstract class DataBackend {
  // User operations
  Future<ApiResponse<User>> createUser(User user);
  Future<ApiResponse<User?>> getUser(String userId);
  Future<ApiResponse<User>> updateUser(User user);
  Future<ApiResponse<void>> deleteUser(String userId);
  Future<ApiResponse<List<User>>> getUsers({
    int? limit,
    String? cursor,
    Map<String, dynamic>? filters,
  });
  
  // Spot operations
  Future<ApiResponse<Spot>> createSpot(Spot spot);
  Future<ApiResponse<Spot?>> getSpot(String spotId);
  Future<ApiResponse<Spot>> updateSpot(Spot spot);
  Future<ApiResponse<void>> deleteSpot(String spotId);
  Future<ApiResponse<List<Spot>>> getSpots({
    int? limit,
    String? cursor,
    Map<String, dynamic>? filters,
  });
  Future<ApiResponse<List<Spot>>> getNearbySpots(
    double latitude,
    double longitude,
    double radiusKm, {
    int? limit,
  });
  Future<ApiResponse<List<Spot>>> searchSpots(String query, {
    int? limit,
    Map<String, dynamic>? filters,
  });
  
  // SpotList operations
  Future<ApiResponse<SpotList>> createSpotList(SpotList spotList);
  Future<ApiResponse<SpotList?>> getSpotList(String listId);
  Future<ApiResponse<SpotList>> updateSpotList(SpotList spotList);
  Future<ApiResponse<void>> deleteSpotList(String listId);
  Future<ApiResponse<List<SpotList>>> getSpotLists({
    int? limit,
    String? cursor,
    Map<String, dynamic>? filters,
  });
  Future<ApiResponse<List<SpotList>>> searchSpotLists(String query, {
    int? limit,
    Map<String, dynamic>? filters,
  });
  
  // Spot-List relationships
  Future<ApiResponse<void>> addSpotToList(String spotId, String listId);
  Future<ApiResponse<void>> removeSpotFromList(String spotId, String listId);
  Future<ApiResponse<List<Spot>>> getSpotsInList(String listId);
  
  // User interactions
  Future<ApiResponse<void>> respectSpot(String spotId, String userId);
  Future<ApiResponse<void>> unrespectSpot(String spotId, String userId);
  Future<ApiResponse<void>> respectList(String listId, String userId);
  Future<ApiResponse<void>> unrespectList(String listId, String userId);
  Future<ApiResponse<void>> followList(String listId, String userId);
  Future<ApiResponse<void>> unfollowList(String listId, String userId);
  
  // Analytics and metrics
  Future<ApiResponse<void>> incrementViewCount(String entityId, String entityType);
  Future<ApiResponse<void>> incrementShareCount(String entityId, String entityType);
  Future<ApiResponse<Map<String, int>>> getEntityMetrics(String entityId);
  
  // Batch operations
  Future<ApiResponse<List<T>>> batchGet<T>(
    List<String> ids,
    T Function(Map<String, dynamic>) fromJson,
  );
  Future<ApiResponse<void>> batchWrite(List<BatchOperation> operations);
  
  // File operations (if supported)
  Future<ApiResponse<String>> uploadFile(
    String filePath,
    List<int> fileBytes, {
    Map<String, String>? metadata,
  });
  Future<ApiResponse<void>> deleteFile(String filePath);
  Future<ApiResponse<String>> getFileUrl(String filePath);
  
  // Custom queries (backend dependent)
  Future<ApiResponse<T>> executeQuery<T>(
    String query,
    Map<String, dynamic> parameters,
    T Function(Map<String, dynamic>) fromJson,
  );
  
  // Transaction support (if available)
  Future<ApiResponse<T>> executeTransaction<T>(
    Future<T> Function(TransactionContext) operation,
  );
}

/// Batch operation for bulk data operations
class BatchOperation {
  final String operation; // 'create', 'update', 'delete'
  final String collection;
  final String? id;
  final Map<String, dynamic>? data;
  
  const BatchOperation({
    required this.operation,
    required this.collection,
    this.id,
    this.data,
  });
  
  BatchOperation.create(this.collection, this.data)
      : operation = 'create',
        id = null;
  
  BatchOperation.update(this.collection, this.id, this.data)
      : operation = 'update';
  
  BatchOperation.delete(this.collection, this.id)
      : operation = 'delete',
        data = null;
}

/// Transaction context for backend-specific transaction handling
abstract class TransactionContext {
  Future<T> get<T>(String collection, String id, T Function(Map<String, dynamic>) fromJson);
  Future<void> set(String collection, String id, Map<String, dynamic> data);
  Future<void> update(String collection, String id, Map<String, dynamic> data);
  Future<void> delete(String collection, String id);
}
