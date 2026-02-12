import '../models/spot.dart';
import '../models/user.dart';

abstract class SpotsRepository {
  /// Get all spots
  Future<List<Spot>> getSpots();
  
  /// Get spots with filtering options
  Future<List<Spot>> getSpotsFiltered({
    String? category,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? limit,
    String? searchQuery,
  });
  
  /// Create a new spot
  Future<Spot> createSpot(Spot spot);
  
  /// Update an existing spot
  Future<Spot> updateSpot(Spot spot);
  
  /// Delete a spot
  Future<void> deleteSpot(String id);
  
  /// Get spot by ID
  Future<Spot?> getSpotById(String id);
  
  /// Get spots created by a specific user
  Future<List<Spot>> getSpotsByUser(String userId);
  
  /// Get spots from respected lists
  Future<List<Spot>> getSpotsFromRespectedLists();
  
  /// Get nearby spots
  Future<List<Spot>> getNearbySpots(
    double latitude, 
    double longitude, 
    double radiusKm,
  );
  
  /// Search spots by query
  Future<List<Spot>> searchSpots(String query);
  
  /// Get popular spots
  Future<List<Spot>> getPopularSpots({int limit = 20});
  
  /// Get recently added spots
  Future<List<Spot>> getRecentSpots({int limit = 20});
  
  /// Get trending spots
  Future<List<Spot>> getTrendingSpots({int limit = 20});
  
  /// Respect a spot
  Future<void> respectSpot(String spotId, String userId);
  
  /// Unrespect a spot
  Future<void> unrespectSpot(String spotId, String userId);
  
  /// Check if user has respected a spot
  Future<bool> hasRespectedSpot(String spotId, String userId);
  
  /// Get spots respected by user
  Future<List<Spot>> getRespectedSpots(String userId);
  
  /// Increment view count for a spot
  Future<void> incrementViewCount(String spotId);
  
  /// Increment share count for a spot
  Future<void> incrementShareCount(String spotId);
  
  /// Check if user can edit a spot
  Future<bool> canUserEditSpot(User user, String spotId);
  
  /// Check if user can delete a spot
  Future<bool> canUserDeleteSpot(User user, String spotId);
  
  /// Report a spot for moderation
  Future<void> reportSpot(String spotId, String reason, String reportedBy);
  
  /// Get spots pending moderation
  Future<List<Spot>> getSpotsPendingModeration();
  
  /// Approve a spot
  Future<void> approveSpot(String spotId, String approvedBy);
  
  /// Reject a spot
  Future<void> rejectSpot(String spotId, String rejectedBy, String reason);
  
  /// Stream of spot changes
  Stream<List<Spot>> watchSpots();
  
  /// Stream of specific spot changes
  Stream<Spot?> watchSpot(String spotId);
}
