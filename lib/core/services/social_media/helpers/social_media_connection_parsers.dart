const List<String> socialConnectionKnownPlatforms = <String>[
  'google',
  'instagram',
  'facebook',
  'twitter',
  'tiktok',
  'linkedin',
];

List<String> parseInstagramInterests(List<Map<String, dynamic>> media) {
  final interests = <String>{};
  const interestKeywords = <String, List<String>>{
    'food': <String>[
      'food',
      'restaurant',
      'cafe',
      'coffee',
      'brunch',
      'dinner',
      'lunch',
      'foodie',
      'culinary',
    ],
    'travel': <String>[
      'travel',
      'trip',
      'vacation',
      'explore',
      'adventure',
      'wanderlust',
      'journey',
    ],
    'art': <String>[
      'art',
      'gallery',
      'museum',
      'exhibition',
      'artist',
      'creative',
      'design',
    ],
    'music': <String>['music', 'concert', 'live', 'gig', 'festival', 'dj', 'band'],
    'fitness': <String>[
      'fitness',
      'gym',
      'workout',
      'yoga',
      'running',
      'exercise',
      'health',
    ],
    'nature': <String>[
      'nature',
      'outdoor',
      'hiking',
      'camping',
      'park',
      'beach',
      'mountain',
    ],
    'fashion': <String>[
      'fashion',
      'style',
      'outfit',
      'clothing',
      'shopping',
      'boutique',
    ],
    'photography': <String>[
      'photography',
      'photo',
      'camera',
      'shot',
      'picture',
      'photographer',
    ],
  };

  for (final item in media) {
    final caption = (item['caption'] as String? ?? '').toLowerCase();
    for (final entry in interestKeywords.entries) {
      if (entry.value.any((keyword) => caption.contains(keyword))) {
        interests.add(entry.key);
      }
    }
  }

  return interests.toList();
}

List<String> parseInstagramCommunities(List<Map<String, dynamic>> media) {
  final communities = <String>{};
  for (final item in media) {
    final caption = item['caption'] as String? ?? '';
    final hashtags = RegExp(r'#(\w+)').allMatches(caption);
    for (final match in hashtags) {
      communities.add(match.group(1)!.toLowerCase());
    }
  }
  return communities.toList();
}

Duration parseRetryAfterHeader(String? retryAfter) {
  if (retryAfter == null) return const Duration(seconds: 60);
  final seconds = int.tryParse(retryAfter);
  if (seconds != null) return Duration(seconds: seconds);
  return const Duration(seconds: 60);
}
