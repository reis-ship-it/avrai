import '../models/community.dart';

/// Minimal read interface for community retrieval.
///
/// Knot/network packages can depend on this interface without importing the app.
abstract class CommunityReader {
  Future<List<Community>> getAllCommunities({int maxResults});
}

