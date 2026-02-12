import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/data/datasources/remote/spots_remote_datasource.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_core/avra_core.dart' as spots_core;
import 'package:avrai/injection_container.dart' as di;

class SpotsRemoteDataSourceImpl implements SpotsRemoteDataSource {
  DataBackend? get _data {
    try {
      return di.sl<DataBackend>();
    } catch (_) {
      // DataBackend not registered (e.g., Supabase not initialized)
      return null;
    }
  }

  // ignore: unused_field
  static const String _collection = 'spots';

  @override
  Future<List<Spot>> getSpots() async {
    final data = _data;
    if (data == null) return [];
    try {
      final res = await data.getSpots(limit: 100);
    if (res.hasData && res.data != null) {
      return res.data!
          .map((coreSpot) => Spot.fromJson(coreSpot.toJson()))
          .toList();
    }
    return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Spot> createSpot(Spot spot) async {
    final data = _data;
    if (data == null) return spot;
    try {
      final res = await data.createSpot(
        spots_core.Spot.fromJson(spot.toJson()),
      );
      if (res.hasData && res.data != null) {
        return Spot.fromJson(res.data!.toJson());
      }
      return spot;
    } catch (_) {
      return spot;
    }
  }

  @override
  Future<Spot> updateSpot(Spot spot) async {
    final data = _data;
    if (data == null) return spot;
    try {
      final res = await data.updateSpot(
        spots_core.Spot.fromJson(spot.toJson()),
      );
      if (res.hasData && res.data != null) {
        return Spot.fromJson(res.data!.toJson());
      }
      return spot;
    } catch (_) {
      return spot;
    }
  }

  @override
  Future<void> deleteSpot(String id) async {
    final data = _data;
    if (data == null) return;
    try {
      await data.deleteSpot(id);
    } catch (_) {
      // Ignore errors if backend not available
    }
  }
}
