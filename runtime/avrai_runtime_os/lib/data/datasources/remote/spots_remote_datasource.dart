import 'package:avrai_core/models/spots/spot.dart';

abstract class SpotsRemoteDataSource {
  Future<List<Spot>> getSpots();
  Future<Spot> createSpot(Spot spot);
  Future<Spot> updateSpot(Spot spot);
  Future<void> deleteSpot(String spotId);
}
