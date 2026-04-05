import 'package:avrai_core/models/misc/list.dart';
import 'package:avrai_runtime_os/data/datasources/remote/lists_remote_datasource.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_core/avra_core.dart' as spots_core;
import 'package:get_it/get_it.dart';

class ListsRemoteDataSourceImpl implements ListsRemoteDataSource {
  DataBackend? get _data {
    try {
      return GetIt.instance<DataBackend>();
    } catch (_) {
      // DataBackend not registered (e.g., Supabase not initialized)
      return null;
    }
  }

  // ignore: unused_field
  static const String _collection = 'spot_lists';

  @override
  Future<List<SpotList>> getLists() async {
    final data = _data;
    if (data == null) return [];
    try {
      final res = await data.getSpotLists(limit: 100);
      if (res.hasData && res.data != null) {
        return res.data!
            .map((coreList) => SpotList.fromJson(coreList.toJson()))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<SpotList>> getPublicLists({int? limit}) async {
    final data = _data;
    if (data == null) return [];
    try {
      final res = await data.getSpotLists(
        limit: limit ?? 50,
        filters: {'is_public': true},
      );
      if (res.hasData && res.data != null) {
        return res.data!
            .map((coreList) => SpotList.fromJson(coreList.toJson()))
            .where((list) => list.isPublic) // Double-check filter
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<SpotList> createList(SpotList list) async {
    final data = _data;
    if (data == null) return list;
    try {
      final json = list.toJson();
      // `spots_core.SpotList` expects a non-null enum-backed category.
      json['category'] = (json['category'] as String?) ?? 'general';
      // `spots_core.SpotList` expects a non-null enum-backed type.
      json['type'] =
          (json['type'] as String?) ?? (list.isPublic ? 'public' : 'private');
      // `spots_core.SpotList` expects a non-null curatorId.
      json['curatorId'] =
          (json['curatorId'] as String?) ?? (list.curatorId ?? 'unknown');
      final res = await data.createSpotList(
        spots_core.SpotList.fromJson(json),
      );
      if (res.hasData && res.data != null) {
        return SpotList.fromJson(res.data!.toJson());
      }
      return list;
    } catch (_) {
      return list;
    }
  }

  @override
  Future<SpotList> updateList(SpotList list) async {
    final data = _data;
    if (data == null) return list;
    try {
      final json = list.toJson();
      // `spots_core.SpotList` expects a non-null enum-backed category.
      json['category'] = (json['category'] as String?) ?? 'general';
      // `spots_core.SpotList` expects a non-null enum-backed type.
      json['type'] =
          (json['type'] as String?) ?? (list.isPublic ? 'public' : 'private');
      // `spots_core.SpotList` expects a non-null curatorId.
      json['curatorId'] =
          (json['curatorId'] as String?) ?? (list.curatorId ?? 'unknown');
      final res = await data.updateSpotList(
        spots_core.SpotList.fromJson(json),
      );
      if (res.hasData && res.data != null) {
        return SpotList.fromJson(res.data!.toJson());
      }
      return list;
    } catch (_) {
      return list;
    }
  }

  @override
  Future<void> deleteList(String id) async {
    final data = _data;
    if (data == null) return;
    try {
      await data.deleteSpotList(id);
    } catch (_) {
      // Ignore errors if backend not available
    }
  }
}
