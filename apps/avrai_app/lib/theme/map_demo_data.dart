import 'package:latlong2/latlong.dart';
import 'package:avrai_core/models/spots/spot.dart';

class MapDemoData {
  static List<Spot> getDemoSpots() {
    return [
      Spot(
        id: 'demo-1',
        name: 'Blue Bottle Coffee',
        description: 'Artisanal coffee shop with pour-over brewing',
        category: 'Coffee',
        latitude: 37.7749,
        longitude: -122.4194,
        address: '1 Ferry Building, San Francisco, CA',
        rating: 4.5,
        createdBy: 'demo_user_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['coffee', 'artisanal', 'pour-over'],
      ),
      Spot(
        id: 'demo-2',
        name: 'Golden Gate Park',
        description: 'Iconic urban park with gardens and museums',
        category: 'Park',
        latitude: 37.7694,
        longitude: -122.4862,
        address: 'Golden Gate Park, San Francisco, CA',
        rating: 4.8,
        createdBy: 'demo_user_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['park', 'nature', 'outdoor'],
      ),
      Spot(
        id: 'demo-3',
        name: 'Tartine Bakery',
        description: 'Famous bakery known for sourdough bread',
        category: 'Bakery',
        latitude: 37.7614,
        longitude: -122.4247,
        address: '600 Guerrero St, San Francisco, CA',
        rating: 4.6,
        createdBy: 'demo_user_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['bakery', 'sourdough', 'pastries'],
      ),
      Spot(
        id: 'demo-4',
        name: 'Alcatraz Island',
        description: 'Historic prison island with guided tours',
        category: 'Attraction',
        latitude: 37.8270,
        longitude: -122.4230,
        address: 'Alcatraz Island, San Francisco, CA',
        rating: 4.7,
        createdBy: 'demo_user_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['attraction', 'historic', 'tours'],
      ),
      Spot(
        id: 'demo-5',
        name: 'Fisherman\'s Wharf',
        description: 'Popular waterfront area with seafood restaurants',
        category: 'Restaurant',
        latitude: 37.8080,
        longitude: -122.4150,
        address: 'Fisherman\'s Wharf, San Francisco, CA',
        rating: 4.3,
        createdBy: 'demo_user_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['restaurant', 'seafood', 'waterfront'],
      ),
    ];
  }

  static List<LatLng> getDemoLocations() {
    return [
      const LatLng(37.7749, -122.4194), // Blue Bottle Coffee
      const LatLng(37.7694, -122.4862), // Golden Gate Park
      const LatLng(37.7614, -122.4247), // Tartine Bakery
      const LatLng(37.8270, -122.4230), // Alcatraz Island
      const LatLng(37.8080, -122.4150), // Fisherman's Wharf
    ];
  }

  static List<String> getDemoCategories() {
    return ['Coffee', 'Park', 'Bakery', 'Attraction', 'Restaurant'];
  }
}
