import 'package:avrai_core/models/misc/list.dart';

abstract class ListsRepository {
  Future<List<SpotList>> getLists();
  Future<List<SpotList>> getPublicLists();
  Future<SpotList> createList(SpotList list);
  Future<SpotList> updateList(SpotList list);
  Future<void> deleteList(String id);
  // Legacy permission helpers used in tests
  Future<bool> canUserCreateList(String userId) async => true;
  Future<bool> canUserDeleteList(String userId, String listId) async => true;
  Future<bool> canUserManageCollaborators(String userId, String listId) async =>
      true;
  Future<bool> canUserAddSpotToList(String userId, String listId) async => true;
  Future<void> createStarterListsForUser({
    required String userId,
  });
  Future<void> createPersonalizedListsForUser({
    required String userId,
    required Map<String, dynamic> userPreferences,
  });
}
