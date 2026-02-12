import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:avrai_core/avra_core.dart';
import '../../interfaces/data_backend.dart';
import '../../models/api_response.dart';

/// Supabase data backend implementation
class SupabaseDataBackend implements DataBackend {
  final SupabaseClient _client;
  bool _isInitialized = false;
  
  SupabaseDataBackend(this._client);
  
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize(Map<String, dynamic> config) async {
    _isInitialized = true;
  }
  
  Future<void> dispose() async {
    _isInitialized = false;
  }
  
  // User operations
  @override
  Future<ApiResponse<User>> createUser(User user) async {
    try {
      final response = await _client
        .from('users')
        .insert(user.toJson())
        .select()
        .single();
      
      return ApiResponse.success(User.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Create user failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<User?>> getUser(String userId) async {
    try {
      final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
      
      if (response == null) {
        return ApiResponse.success(null);
      }
      return ApiResponse.success(User.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Get user failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<User>> updateUser(User user) async {
    try {
      final response = await _client
        .from('users')
        .update(user.toJson())
        .eq('id', user.id)
        .select()
        .single();
      
      return ApiResponse.success(User.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Update user failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> deleteUser(String userId) async {
    try {
      await _client
        .from('users')
        .delete()
        .eq('id', userId);
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Delete user failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<User>>> getUsers({
    int? limit,
    String? cursor,
    Map<String, dynamic>? filters,
  }) async {
    try {
      dynamic query = _client.from('users').select();
      
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      
      if (cursor != null) {
        query = query.gt('id', cursor);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query;
      
      final users = (response as List)
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(users);
    } catch (e) {
      return ApiResponse.error('Get users failed: $e');
    }
  }
  
  // Spot operations
  @override
  Future<ApiResponse<Spot>> createSpot(Spot spot) async {
    try {
      final response = await _client
        .from('spots')
        .insert(spot.toJson())
        .select()
        .single();
      
      return ApiResponse.success(Spot.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Create spot failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<Spot?>> getSpot(String spotId) async {
    try {
      final response = await _client
        .from('spots')
        .select()
        .eq('id', spotId)
        .maybeSingle();
      
      if (response == null) {
        return ApiResponse.success(null);
      }
      return ApiResponse.success(Spot.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Get spot failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<Spot>> updateSpot(Spot spot) async {
    try {
      final response = await _client
        .from('spots')
        .update(spot.toJson())
        .eq('id', spot.id)
        .select()
        .single();
      
      return ApiResponse.success(Spot.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Update spot failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> deleteSpot(String spotId) async {
    try {
      await _client
        .from('spots')
        .delete()
        .eq('id', spotId);
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Delete spot failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<Spot>>> getSpots({
    int? limit,
    String? cursor,
    Map<String, dynamic>? filters,
  }) async {
    try {
      dynamic query = _client.from('spots').select();
      
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      
      if (cursor != null) {
        query = query.gt('id', cursor);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query;
      
      final spots = (response as List)
          .map((json) => Spot.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(spots);
    } catch (e) {
      return ApiResponse.error('Get spots failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<Spot>>> getNearbySpots(
    double latitude,
    double longitude,
    double radiusKm, {
    int? limit,
  }) async {
    try {
      // Use PostGIS function for distance calculation if available
      // Otherwise, fetch all and filter client-side
      dynamic query = _client.from('spots').select();
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query;
      final allSpots = (response as List)
          .map((json) => Spot.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Filter by distance
      final nearbySpots = allSpots.where((spot) {
        final distance = spot.distanceFrom(latitude, longitude);
        return distance <= radiusKm;
      }).toList();
      
      // Sort by distance
      nearbySpots.sort((a, b) {
        final distA = a.distanceFrom(latitude, longitude);
        final distB = b.distanceFrom(latitude, longitude);
        return distA.compareTo(distB);
      });
      
      if (limit != null && nearbySpots.length > limit) {
        return ApiResponse.success(nearbySpots.sublist(0, limit));
      }
      
      return ApiResponse.success(nearbySpots);
    } catch (e) {
      return ApiResponse.error('Get nearby spots failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<Spot>>> searchSpots(String query, {
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      dynamic searchQuery = _client.from('spots').select();
      
      // Use text search if available, otherwise filter by name/description
      searchQuery = searchQuery.or('name.ilike.%$query%,description.ilike.%$query%');
      
      if (filters != null) {
        for (final entry in filters.entries) {
          searchQuery = searchQuery.eq(entry.key, entry.value);
        }
      }
      
      if (limit != null) {
        searchQuery = searchQuery.limit(limit);
      }
      
      final response = await searchQuery;
      
      final spots = (response as List)
          .map((json) => Spot.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(spots);
    } catch (e) {
      return ApiResponse.error('Search spots failed: $e');
    }
  }
  
  // SpotList operations
  @override
  Future<ApiResponse<SpotList>> createSpotList(SpotList spotList) async {
    try {
      final response = await _client
        .from('spot_lists')
        .insert(spotList.toJson())
        .select()
        .single();
      
      return ApiResponse.success(SpotList.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Create spot list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<SpotList?>> getSpotList(String listId) async {
    try {
      final response = await _client
        .from('spot_lists')
        .select()
        .eq('id', listId)
        .maybeSingle();
      
      if (response == null) {
        return ApiResponse.success(null);
      }
      return ApiResponse.success(SpotList.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Get spot list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<SpotList>> updateSpotList(SpotList spotList) async {
    try {
      final response = await _client
        .from('spot_lists')
        .update(spotList.toJson())
        .eq('id', spotList.id)
        .select()
        .single();
      
      return ApiResponse.success(SpotList.fromJson(response));
    } catch (e) {
      return ApiResponse.error('Update spot list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> deleteSpotList(String listId) async {
    try {
      await _client
        .from('spot_lists')
        .delete()
        .eq('id', listId);
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Delete spot list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<SpotList>>> getSpotLists({
    int? limit,
    String? cursor,
    Map<String, dynamic>? filters,
  }) async {
    try {
      dynamic query = _client.from('spot_lists').select();
      
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      
      if (cursor != null) {
        query = query.gt('id', cursor);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query;
      
      final lists = (response as List)
          .map((json) => SpotList.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(lists);
    } catch (e) {
      return ApiResponse.error('Get spot lists failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<SpotList>>> searchSpotLists(String query, {
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      dynamic searchQuery = _client.from('spot_lists').select();
      
      searchQuery = searchQuery.or('title.ilike.%$query%,description.ilike.%$query%');
      
      if (filters != null) {
        for (final entry in filters.entries) {
          searchQuery = searchQuery.eq(entry.key, entry.value);
        }
      }
      
      if (limit != null) {
        searchQuery = searchQuery.limit(limit);
      }
      
      final response = await searchQuery;
      
      final lists = (response as List)
          .map((json) => SpotList.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse.success(lists);
    } catch (e) {
      return ApiResponse.error('Search spot lists failed: $e');
    }
  }
  
  // Spot-List relationships
  @override
  Future<ApiResponse<void>> addSpotToList(String spotId, String listId) async {
    try {
      // Get the list
      final listResponse = await getSpotList(listId);
      if (!listResponse.success || listResponse.data == null) {
        return ApiResponse.error('List not found');
      }
      
      final list = listResponse.data!;
      final updatedSpotIds = List<String>.from(list.spotIds);
      if (!updatedSpotIds.contains(spotId)) {
        updatedSpotIds.add(spotId);
      }
      
      final updatedList = list.copyWith(spotIds: updatedSpotIds);
      final updateResponse = await updateSpotList(updatedList);
      if (!updateResponse.success) {
        return updateResponse.map((_) {});
      }
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Add spot to list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> removeSpotFromList(String spotId, String listId) async {
    try {
      final listResponse = await getSpotList(listId);
      if (!listResponse.success || listResponse.data == null) {
        return ApiResponse.error('List not found');
      }
      
      final list = listResponse.data!;
      final updatedSpotIds = List<String>.from(list.spotIds)..remove(spotId);
      
      final updatedList = list.copyWith(spotIds: updatedSpotIds);
      final updateResponse = await updateSpotList(updatedList);
      if (!updateResponse.success) {
        return updateResponse.map((_) {});
      }
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Remove spot from list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<List<Spot>>> getSpotsInList(String listId) async {
    try {
      final listResponse = await getSpotList(listId);
      if (!listResponse.success || listResponse.data == null) {
        return ApiResponse.error('List not found');
      }
      
      final list = listResponse.data!;
      final spotIds = list.spotIds;
      
      if (spotIds.isEmpty) {
        return ApiResponse.success(const []);
      }
      
      final batchResponse = await batchGet<Spot>(
        spotIds,
        (json) => Spot.fromJson(json),
      );
      
      return batchResponse;
    } catch (e) {
      return ApiResponse.error('Get spots in list failed: $e');
    }
  }
  
  // User interactions
  @override
  Future<ApiResponse<void>> respectSpot(String spotId, String userId) async {
    try {
      final spotResponse = await getSpot(spotId);
      if (!spotResponse.success || spotResponse.data == null) {
        return ApiResponse.error('Spot not found');
      }
      
      final spot = spotResponse.data!;
      final updatedRespectedBy = List<String>.from(spot.respectedBy);
      if (!updatedRespectedBy.contains(userId)) {
        updatedRespectedBy.add(userId);
      }
      
      final updatedSpot = spot.copyWith(
        respectedBy: updatedRespectedBy,
        respectCount: spot.respectCount + 1,
      );
      
      await updateSpot(updatedSpot);
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Respect spot failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> unrespectSpot(String spotId, String userId) async {
    try {
      final spotResponse = await getSpot(spotId);
      if (!spotResponse.success || spotResponse.data == null) {
        return ApiResponse.error('Spot not found');
      }
      
      final spot = spotResponse.data!;
      final updatedRespectedBy = List<String>.from(spot.respectedBy)..remove(userId);
      
      final updatedSpot = spot.copyWith(
        respectedBy: updatedRespectedBy,
        respectCount: spot.respectCount > 0 ? spot.respectCount - 1 : 0,
      );
      
      await updateSpot(updatedSpot);
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Unrespect spot failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> respectList(String listId, String userId) async {
    try {
      final listResponse = await getSpotList(listId);
      if (!listResponse.success || listResponse.data == null) {
        return ApiResponse.error('List not found');
      }
      
      final list = listResponse.data!;
      final updatedRespectedBy = List<String>.from(list.respectedBy);
      if (!updatedRespectedBy.contains(userId)) {
        updatedRespectedBy.add(userId);
      }
      
      final updatedList = list.copyWith(
        respectedBy: updatedRespectedBy,
        respectCount: list.respectCount + 1,
      );
      
      await updateSpotList(updatedList);
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Respect list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> unrespectList(String listId, String userId) async {
    try {
      final listResponse = await getSpotList(listId);
      if (!listResponse.success || listResponse.data == null) {
        return ApiResponse.error('List not found');
      }
      
      final list = listResponse.data!;
      final updatedRespectedBy = List<String>.from(list.respectedBy)..remove(userId);
      
      final updatedList = list.copyWith(
        respectedBy: updatedRespectedBy,
        respectCount: list.respectCount > 0 ? list.respectCount - 1 : 0,
      );
      
      await updateSpotList(updatedList);
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Unrespect list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> followList(String listId, String userId) async {
    try {
      final listResponse = await getSpotList(listId);
      if (!listResponse.success || listResponse.data == null) {
        return ApiResponse.error('List not found');
      }
      
      final list = listResponse.data!;
      final updatedFollowers = List<String>.from(list.followers);
      if (!updatedFollowers.contains(userId)) {
        updatedFollowers.add(userId);
      }
      
      final updatedList = list.copyWith(followers: updatedFollowers);
      await updateSpotList(updatedList);
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Follow list failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> unfollowList(String listId, String userId) async {
    try {
      final listResponse = await getSpotList(listId);
      if (!listResponse.success || listResponse.data == null) {
        return ApiResponse.error('List not found');
      }
      
      final list = listResponse.data!;
      final updatedFollowers = List<String>.from(list.followers)..remove(userId);
      
      final updatedList = list.copyWith(followers: updatedFollowers);
      final updateResponse = await updateSpotList(updatedList);
      if (!updateResponse.success) {
        return updateResponse.map((_) {});
      }
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Unfollow list failed: $e');
    }
  }
  
  // Analytics and metrics
  @override
  Future<ApiResponse<void>> incrementViewCount(String entityId, String entityType) async {
    try {
      if (entityType == 'spot') {
        final spotResponse = await getSpot(entityId);
        if (spotResponse.success && spotResponse.data != null) {
          final spot = spotResponse.data!;
          final updatedSpot = spot.copyWith(viewCount: spot.viewCount + 1);
          await updateSpot(updatedSpot);
        }
      } else if (entityType == 'list') {
        final listResponse = await getSpotList(entityId);
        if (listResponse.success && listResponse.data != null) {
          final list = listResponse.data!;
          final updatedList = list.copyWith(viewCount: list.viewCount + 1);
          await updateSpotList(updatedList);
        }
      }
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Increment view count failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> incrementShareCount(String entityId, String entityType) async {
    try {
      if (entityType == 'spot') {
        final spotResponse = await getSpot(entityId);
        if (spotResponse.success && spotResponse.data != null) {
          final spot = spotResponse.data!;
          final updatedSpot = spot.copyWith(shareCount: spot.shareCount + 1);
          await updateSpot(updatedSpot);
        }
      } else if (entityType == 'list') {
        final listResponse = await getSpotList(entityId);
        if (listResponse.success && listResponse.data != null) {
          final list = listResponse.data!;
          final updatedList = list.copyWith(shareCount: list.shareCount + 1);
          await updateSpotList(updatedList);
        }
      }
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Increment share count failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<Map<String, int>>> getEntityMetrics(String entityId) async {
    try {
      // Try spot first
      final spotResponse = await getSpot(entityId);
      if (spotResponse.success && spotResponse.data != null) {
        final spot = spotResponse.data!;
        return ApiResponse.success({
          'viewCount': spot.viewCount,
          'respectCount': spot.respectCount,
          'shareCount': spot.shareCount,
        });
      }
      
      // Try list
      final listResponse = await getSpotList(entityId);
      if (listResponse.success && listResponse.data != null) {
        final list = listResponse.data!;
        return ApiResponse.success({
          'viewCount': list.viewCount,
          'respectCount': list.respectCount,
          'shareCount': list.shareCount,
          'followerCount': list.followers.length,
        });
      }
      
      return ApiResponse.error('Entity not found');
    } catch (e) {
      return ApiResponse.error('Get entity metrics failed: $e');
    }
  }
  
  // Batch operations
  @override
  Future<ApiResponse<List<T>>> batchGet<T>(
    List<String> ids,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      // Determine collection from first ID or use a generic approach
      // For now, we'll need to know the collection type
      // This is a limitation - in practice, you'd need to pass collection name
      throw UnimplementedError('batchGet requires collection name - use specific methods instead');
    } catch (e) {
      return ApiResponse.error('Batch get failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> batchWrite(List<BatchOperation> operations) async {
    try {
      for (final operation in operations) {
        switch (operation.operation) {
          case 'create':
            await _client
              .from(operation.collection)
              .insert(operation.data ?? {});
            break;
            
          case 'update':
            if (operation.id != null && operation.data != null) {
              await _client
                .from(operation.collection)
                .update(operation.data!)
                .eq('id', operation.id!);
            }
            break;
            
          case 'delete':
            if (operation.id != null) {
              await _client
                .from(operation.collection)
                .delete()
                .eq('id', operation.id!);
            }
            break;
        }
      }
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Batch write failed: $e');
    }
  }
  
  // File operations
  @override
  Future<ApiResponse<String>> uploadFile(
    String filePath,
    List<int> fileBytes, {
    Map<String, String>? metadata,
  }) async {
    try {
      final response = await _client.storage
        .from('files')
        .uploadBinary(
          filePath,
          Uint8List.fromList(fileBytes),
          fileOptions: FileOptions(
            contentType: metadata?['contentType'],
            upsert: false,
          ),
        );
      
      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Upload file failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<void>> deleteFile(String filePath) async {
    try {
      await _client.storage
        .from('files')
        .remove([filePath]);
      
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error('Delete file failed: $e');
    }
  }
  
  @override
  Future<ApiResponse<String>> getFileUrl(String filePath) async {
    try {
      final response = _client.storage
        .from('files')
        .getPublicUrl(filePath);
      
      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Get file URL failed: $e');
    }
  }
  
  // Custom queries
  @override
  Future<ApiResponse<T>> executeQuery<T>(
    String query,
    Map<String, dynamic> parameters,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      // Supabase doesn't support raw SQL queries directly
      // This would need to be implemented via RPC functions
      throw UnimplementedError('Custom queries require RPC functions');
    } catch (e) {
      return ApiResponse.error('Execute query failed: $e');
    }
  }
  
  // Transactions
  @override
  Future<ApiResponse<T>> executeTransaction<T>(
    Future<T> Function(TransactionContext) operation,
  ) async {
    try {
      // Supabase doesn't have native transactions in the client
      // This would need to be implemented via database functions
      throw UnimplementedError('Transactions require database functions');
    } catch (e) {
      return ApiResponse.error('Execute transaction failed: $e');
    }
  }
}
