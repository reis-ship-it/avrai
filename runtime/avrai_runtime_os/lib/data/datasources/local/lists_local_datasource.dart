import 'package:avrai_core/models/misc/list.dart';

abstract class ListsLocalDataSource {
  Future<List<SpotList>> getLists();
  Future<SpotList?> saveList(SpotList list);
  Future<void> deleteList(String id);
}
