import 'package:avrai/core/models/spots/spot.dart';

abstract class SpotsRepository {
  Future<List<Spot>> getSpots();
  Future<List<Spot>> getSpotsFromRespectedLists();
  Future<Spot> createSpot(Spot spot);
  Future<Spot> updateSpot(Spot spot);
  Future<void> deleteSpot(String spotId);
}
