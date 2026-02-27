class SocialConnectionSyncLane {
  const SocialConnectionSyncLane();

  String connectionKey({required String agentId, required String platform}) {
    return 'social_media_connections_${agentId}_$platform';
  }

  String tokenKey({required String agentId, required String platform}) {
    return 'social_media_tokens_${agentId}_$platform';
  }

  String profileCacheKey({required String agentId, required String platform}) {
    return 'social_media_profile_cache_${agentId}_$platform';
  }
}
