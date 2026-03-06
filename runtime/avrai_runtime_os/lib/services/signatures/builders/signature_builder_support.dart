import 'package:avrai_core/models/signatures/signature_dimensions.dart';
import 'package:avrai_runtime_os/services/geographic/metro_experience_service.dart';

Map<String, double> heuristicDimensionsFromText({
  String? title,
  String? subtitle,
  String? category,
  Iterable<String> tags = const <String>[],
}) {
  final haystack = [
    title,
    subtitle,
    category,
    tags.join(' '),
  ].whereType<String>().join(' ').toLowerCase();

  final nudges = <String, double>{};

  if (_containsAny(
      haystack, const ['coffee', 'book', 'museum', 'gallery', 'art'])) {
    nudges['authenticity_preference'] = 0.18;
    nudges['exploration_eagerness'] = 0.08;
  }
  if (_containsAny(
      haystack, const ['bar', 'music', 'dance', 'night', 'party'])) {
    nudges['energy_preference'] = 0.22;
    nudges['social_discovery_style'] = 0.18;
  }
  if (_containsAny(
      haystack, const ['volunteer', 'community', 'club', 'group', 'meet'])) {
    nudges['community_orientation'] = 0.22;
    nudges['trust_network_reliance'] = 0.14;
  }
  if (_containsAny(
      haystack, const ['park', 'trail', 'walk', 'outdoor', 'nature'])) {
    nudges['location_adventurousness'] = 0.18;
    nudges['temporal_flexibility'] = 0.10;
  }
  if (_containsAny(
      haystack, const ['workshop', 'talk', 'lecture', 'learning'])) {
    nudges['exploration_eagerness'] = 0.14;
    nudges['authenticity_preference'] = 0.10;
  }
  if (_containsAny(haystack, const ['chill', 'quiet', 'calm', 'slow'])) {
    nudges['energy_preference'] = -0.18;
  }

  return SignatureDimensions.nudge(
    const <String, double>{},
    nudges,
  );
}

Map<String, double> metroPheromoneShape({
  String? cityCode,
  String? localityCode,
  String? label,
  String? title,
  String? category,
  required List<String> priors,
}) {
  final metroKey = MetroExperienceService.resolveMetroKey(
    cityCode: cityCode,
    displayName: localityCode,
    fallbackLabel: label,
  );
  if (metroKey == 'default') {
    return SignatureDimensions.normalize(const <String, double>{});
  }

  final profile = MetroExperienceService.profileForMetroKey(
    metroKey: metroKey,
    cityCode: cityCode,
    localityCode: localityCode,
  );
  final haystack =
      '${title ?? ''} ${category ?? ''} ${label ?? ''}'.toLowerCase();
  final matchedPriiors =
      priors.where((prior) => _matchesPrior(haystack, prior)).length;
  final matchedKeywords = profile.categoryKeywords
      .where((keyword) => haystack.contains(keyword))
      .length;

  final nudges = <String, double>{};
  if (matchedPriiors > 0) {
    nudges['community_orientation'] = 0.04 * matchedPriiors;
    nudges['authenticity_preference'] = 0.03 * matchedPriiors;
  }
  if (matchedKeywords > 0) {
    nudges['exploration_eagerness'] = 0.02 * matchedKeywords;
  }

  if (metroKey == 'birmingham') {
    nudges['trust_network_reliance'] =
        (nudges['trust_network_reliance'] ?? 0.0) + 0.05;
  }

  return SignatureDimensions.nudge(const <String, double>{}, nudges);
}

bool _containsAny(String haystack, List<String> needles) {
  for (final needle in needles) {
    if (haystack.contains(needle)) {
      return true;
    }
  }
  return false;
}

bool _matchesPrior(String haystack, String prior) {
  final normalized = prior.toLowerCase();
  final parts =
      normalized.split(RegExp(r'[^a-z0-9]+')).where((part) => part.isNotEmpty);
  return parts.any(haystack.contains);
}
