import '../models/spot_list.dart';
import '../models/user.dart';
import '../enums/list_enums.dart';

abstract class ListsRepository {
  /// Get all lists
  Future<List<SpotList>> getLists();
  
  /// Get lists with filtering options
  Future<List<SpotList>> getListsFiltered({
    ListCategory? category,
    ListType? type,
    bool? isPublic,
    String? searchQuery,
    int? limit,
  });
  
  /// Create a new list
  Future<SpotList> createList(SpotList list);
  
  /// Update an existing list
  Future<SpotList> updateList(SpotList list);
  
  /// Delete a list
  Future<void> deleteList(String id);
  
  /// Get list by ID
  Future<SpotList?> getListById(String id);
  
  /// Get lists created by a specific user
  Future<List<SpotList>> getListsByUser(String userId);
  
  /// Get public lists
  Future<List<SpotList>> getPublicLists();
  
  /// Get lists followed by user
  Future<List<SpotList>> getFollowedLists(String userId);
  
  /// Get lists where user is collaborator
  Future<List<SpotList>> getListsWhereUserIsCollaborator(String userId);
  
  /// Get curated lists
  Future<List<SpotList>> getCuratedLists();
  
  /// Get popular lists
  Future<List<SpotList>> getPopularLists({int limit = 20});
  
  /// Get recently created lists
  Future<List<SpotList>> getRecentLists({int limit = 20});
  
  /// Get trending lists
  Future<List<SpotList>> getTrendingLists({int limit = 20});
  
  /// Search lists by query
  Future<List<SpotList>> searchLists(String query);
  
  /// Add spot to list
  Future<void> addSpotToList(String spotId, String listId);
  
  /// Remove spot from list
  Future<void> removeSpotFromList(String spotId, String listId);
  
  /// Check if spot is in list
  Future<bool> isSpotInList(String spotId, String listId);
  
  /// Get spots in list
  Future<List<String>> getSpotsInList(String listId);
  
  /// Follow a list
  Future<void> followList(String listId, String userId);
  
  /// Unfollow a list
  Future<void> unfollowList(String listId, String userId);
  
  /// Check if user is following a list
  Future<bool> isFollowingList(String listId, String userId);
  
  /// Respect a list
  Future<void> respectList(String listId, String userId);
  
  /// Unrespect a list
  Future<void> unrespectList(String listId, String userId);
  
  /// Check if user has respected a list
  Future<bool> hasRespectedList(String listId, String userId);
  
  /// Get lists respected by user
  Future<List<SpotList>> getRespectedLists(String userId);
  
  /// Increment view count for a list
  Future<void> incrementViewCount(String listId);
  
  /// Increment share count for a list
  Future<void> incrementShareCount(String listId);
  
  /// Check if user can create a list
  Future<bool> canUserCreateList(User user);
  
  /// Check if user can edit a list
  Future<bool> canUserEditList(User user, String listId);
  
  /// Check if user can delete a list
  Future<bool> canUserDeleteList(User user, String listId);
  
  /// Check if user can add spot to list
  Future<bool> canUserAddSpotToList(User user, String listId);
  
  /// Check if user can remove spot from list
  Future<bool> canUserRemoveSpotFromList(User user, String listId);
  
  /// Request collaboration on a list
  Future<void> requestCollaboration(String userId, String listId);
  
  /// Approve collaboration request
  Future<void> approveCollaborationRequest(String userId, String listId, String approvedBy);
  
  /// Deny collaboration request
  Future<void> denyCollaborationRequest(String userId, String listId, String deniedBy);
  
  /// Check if user can manage collaborators
  Future<bool> canUserManageCollaborators(User user, String listId);
  
  /// Add collaborator to list
  Future<void> addCollaborator(String userId, String listId, ListRole role);
  
  /// Remove collaborator from list
  Future<void> removeCollaborator(String userId, String listId);
  
  /// Get collaborators for a list
  Future<List<String>> getCollaborators(String listId);
  
  /// Get user's role in a list
  Future<ListRole?> getUserRoleInList(String userId, String listId);
  
  /// Update user's role in a list
  Future<void> updateUserRoleInList(String userId, String listId, ListRole role);
  
  /// Report a list for moderation
  Future<void> reportList(String listId, String reason, String reportedBy);
  
  /// Get lists pending moderation
  Future<List<SpotList>> getListsPendingModeration();
  
  /// Approve a list
  Future<void> approveList(String listId, String approvedBy);
  
  /// Reject a list
  Future<void> rejectList(String listId, String rejectedBy, String reason);
  
  /// Stream of list changes
  Stream<List<SpotList>> watchLists();
  
  /// Stream of specific list changes
  Stream<SpotList?> watchList(String listId);
  
  /// Stream of lists where user is involved
  Stream<List<SpotList>> watchUserLists(String userId);
}
