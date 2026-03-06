import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_kernel.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/onboarding_locality_lists.dart';

class MetroExperienceContext {
  final String metroKey;
  final String displayName;
  final String? cityCode;
  final String? localityCode;
  final String summary;
  final List<String> categoryKeywords;
  final List<String> spotPriors;
  final List<String> eventPriors;
  final List<String> communityPriors;
  final List<String> promptSuggestions;

  const MetroExperienceContext({
    required this.metroKey,
    required this.displayName,
    required this.cityCode,
    required this.localityCode,
    required this.summary,
    required this.categoryKeywords,
    required this.spotPriors,
    required this.eventPriors,
    required this.communityPriors,
    required this.promptSuggestions,
  });

  bool get hasMetroProfile => metroKey != 'default';

  Map<String, dynamic> toPreferenceMap() {
    return {
      'metro_key': metroKey,
      'display_name': displayName,
      'city_code': cityCode,
      'locality_code': localityCode,
      'summary': summary,
      'spot_priors': spotPriors,
      'event_priors': eventPriors,
      'community_priors': communityPriors,
      'prompt_suggestions': promptSuggestions,
    };
  }
}

class MetroExperienceService {
  final GeoHierarchyService _geoHierarchyService;
  final SharedPreferencesCompat _prefs;
  final LocalityKernelContract? _localityKernel;

  const MetroExperienceService({
    required GeoHierarchyService geoHierarchyService,
    required SharedPreferencesCompat prefs,
    LocalityKernelContract? localityKernel,
  })  : _geoHierarchyService = geoHierarchyService,
        _prefs = prefs,
        _localityKernel = localityKernel;

  Future<MetroExperienceContext> resolveBestEffort({
    double? latitude,
    double? longitude,
    String? locationLabel,
  }) async {
    final lat = latitude ?? _prefs.getDouble('cached_lat');
    final lon = longitude ?? _prefs.getDouble('cached_lng');

    String? cityCode;
    String? localityCode;
    String? displayName = locationLabel;

    if (lat != null && lon != null) {
      final localityKernel = _resolveKernel();
      if (localityKernel != null) {
        final resolution = await localityKernel.resolvePoint(
          LocalityPointQuery(
            latitude: lat,
            longitude: lon,
            occurredAtUtc: DateTime.now().toUtc(),
            audience: LocalityProjectionAudience.user,
          ),
        );
        cityCode = resolution.cityCode;
        localityCode = resolution.localityCode;
        displayName = displayName ?? resolution.displayName;
      } else {
        final locality = await _geoHierarchyService.lookupLocalityByPoint(
          lat: lat,
          lon: lon,
        );
        cityCode = locality?.cityCode;
        localityCode = locality?.localityCode;
        displayName = displayName ?? locality?.displayName;
      }
    }

    final metroKey = resolveMetroKey(
      cityCode: cityCode,
      displayName: displayName,
      fallbackLabel: locationLabel,
    );

    return MetroExperienceService.profileForMetroKey(
      metroKey: metroKey,
      cityCode: cityCode,
      localityCode: localityCode,
    );
  }

  LocalityKernelContract? _resolveKernel() {
    if (_localityKernel != null) return _localityKernel;
    final sl = GetIt.instance;
    if (!sl.isRegistered<LocalityKernelContract>()) return null;
    return sl<LocalityKernelContract>();
  }

  double scoreCategoryAffinity({
    required MetroExperienceContext context,
    String? category,
    String? title,
    String? subtitle,
  }) {
    if (!context.hasMetroProfile) {
      return 0.0;
    }

    final haystack = '${category ?? ''} ${title ?? ''} ${subtitle ?? ''}'
        .toLowerCase()
        .trim();
    if (haystack.isEmpty) {
      return 0.0;
    }

    final keywordHits = context.categoryKeywords
        .where((keyword) => haystack.contains(keyword))
        .length;
    final priorHits = [
      ...context.spotPriors,
      ...context.eventPriors,
      ...context.communityPriors,
    ].where((prior) => _matchesPrior(haystack, prior)).length;

    return ((keywordHits * 0.025) + (priorHits * 0.02)).clamp(0.0, 0.12);
  }

  double scoreLocationAffinity({
    required MetroExperienceContext context,
    String? cityCode,
    String? localityCode,
    String? locationLabel,
  }) {
    if (!context.hasMetroProfile) {
      return 0.0;
    }

    if (localityCode != null &&
        context.localityCode != null &&
        localityCode == context.localityCode) {
      return 0.12;
    }

    if (cityCode != null &&
        context.cityCode != null &&
        cityCode == context.cityCode) {
      return 0.08;
    }

    final haystack =
        '${cityCode ?? ''} ${localityCode ?? ''} ${locationLabel ?? ''}'
            .toLowerCase()
            .trim();
    if (haystack.isEmpty) {
      return 0.0;
    }

    final aliases = _metroAliasesFor(context.metroKey);
    if (aliases.any(haystack.contains)) {
      return 0.05;
    }

    return 0.0;
  }

  static String resolveMetroKey({
    String? cityCode,
    String? displayName,
    String? fallbackLabel,
  }) {
    final haystack =
        '${cityCode ?? ''} ${displayName ?? ''} ${fallbackLabel ?? ''}'
            .toLowerCase()
            .trim();

    if (haystack.isEmpty) {
      return 'default';
    }

    if (_containsAny(haystack, const [
      'us-nyc',
      'nyc',
      'new york',
      'brooklyn',
      'manhattan',
      'queens',
      'bronx',
      'staten island',
    ])) {
      return 'nyc';
    }

    if (_containsAny(haystack, const [
      'denver',
      'boulder',
      'aurora',
      'lakewood',
      'us-den',
    ])) {
      return 'denver';
    }

    if (_containsAny(haystack, const [
      'atlanta',
      'decatur',
      'buckhead',
      'marietta',
      'us-atl',
    ])) {
      return 'atlanta';
    }

    if (_containsAny(haystack, const [
      'birmingham',
      'homewood',
      'avondale',
      'five points',
      'mountain brook',
      'us-bhm',
    ])) {
      return 'birmingham';
    }

    return 'default';
  }

  static MetroExperienceContext profileForMetroKey({
    required String metroKey,
    String? cityCode,
    String? localityCode,
  }) {
    switch (metroKey) {
      case 'nyc':
        return MetroExperienceContext(
          metroKey: 'nyc',
          displayName: 'NYC',
          cityCode: cityCode,
          localityCode: localityCode,
          summary:
              'Dense, fast, and highly neighborhood-driven. Prefer short-hop plans, culture-rich events, and communities that fit the user pace without adding too much friction.',
          categoryKeywords: const [
            'food',
            'drink',
            'coffee',
            'music',
            'art',
            'culture',
            'night',
            'park',
          ],
          spotPriors: _priorTitlesFor('nyc', type: _MetroPriorType.spot),
          eventPriors: _priorTitlesFor('nyc', type: _MetroPriorType.event),
          communityPriors: const [
            'Creative circles',
            'Neighborhood supper clubs',
            'Volunteer and arts communities',
          ],
          promptSuggestions: const [
            'What fits my neighborhood energy tonight?',
            'Where should I go if I only have an hour?',
            'Which community fits my pace in NYC?',
            'What should my agent learn about my city rhythm?',
          ],
        );
      case 'denver':
        return MetroExperienceContext(
          metroKey: 'denver',
          displayName: 'Denver',
          cityCode: cityCode,
          localityCode: localityCode,
          summary:
              'Lower-friction, outdoors-forward, and routine-sensitive. Favor practical movement, nature-adjacent plans, and communities that turn free time into real-world activity.',
          categoryKeywords: const [
            'outdoor',
            'nature',
            'hiking',
            'fitness',
            'coffee',
            'music',
            'park',
            'activity',
          ],
          spotPriors: _priorTitlesFor('denver', type: _MetroPriorType.spot),
          eventPriors: _priorTitlesFor('denver', type: _MetroPriorType.event),
          communityPriors: const [
            'Outdoor crews',
            'Cowork and coffee circles',
            'Live music and neighborhood groups',
          ],
          promptSuggestions: const [
            'What fits my Denver routine this week?',
            'What outdoor or low-friction plan should I try next?',
            'Which community would suit my energy in Denver?',
            'What should my agent know about how I move through Denver?',
          ],
        );
      case 'atlanta':
        return MetroExperienceContext(
          metroKey: 'atlanta',
          displayName: 'Atlanta',
          cityCode: cityCode,
          localityCode: localityCode,
          summary:
              'Social, neighborhood-clustered, and event-driven with more travel friction. Value worthwhile outings, strong food-and-music signals, and communities that justify the trip.',
          categoryKeywords: const [
            'food',
            'music',
            'culture',
            'community',
            'volunteer',
            'night',
            'neighborhood',
            'event',
          ],
          spotPriors: _priorTitlesFor('atlanta', type: _MetroPriorType.spot),
          eventPriors: _priorTitlesFor('atlanta', type: _MetroPriorType.event),
          communityPriors: const [
            'Neighborhood collectives',
            'Music and food communities',
            'Volunteer and civic groups',
          ],
          promptSuggestions: const [
            'What feels worth driving for in Atlanta?',
            'What fits my part of the city right now?',
            'Which community door should I open in Atlanta?',
            'What should my agent learn about my Atlanta habits?',
          ],
        );
      case 'birmingham':
        return MetroExperienceContext(
          metroKey: 'birmingham',
          displayName: 'Birmingham',
          cityCode: cityCode,
          localityCode: localityCode,
          summary:
              'Neighborhood-driven, relationship-heavy, and best when plans feel grounded in the local scene. Favor clear locality context, trusted repeat spots, and communities that can turn online signals into real-world attendance.',
          categoryKeywords: const [
            'coffee',
            'food',
            'music',
            'volunteer',
            'community',
            'festival',
            'arts',
            'local',
          ],
          spotPriors: _priorTitlesFor('birmingham', type: _MetroPriorType.spot),
          eventPriors:
              _priorTitlesFor('birmingham', type: _MetroPriorType.event),
          communityPriors: const [
            'Neighborhood volunteer groups',
            'Arts and music communities',
            'Faith-adjacent and civic circles',
          ],
          promptSuggestions: const [
            'What feels most grounded in Birmingham right now?',
            'Which nearby plan is actually worth showing up for?',
            'What community door fits my part of Birmingham?',
            'What should my agent learn about how I move through Birmingham?',
          ],
        );
      default:
        return const MetroExperienceContext(
          metroKey: 'default',
          displayName: 'Your area',
          cityCode: null,
          localityCode: null,
          summary:
              'Lean on nearby behavior, locality context, and direct feedback until the city pattern is clearer.',
          categoryKeywords: [
            'food',
            'music',
            'community',
            'outdoor',
          ],
          spotPriors: [
            'Nearby neighborhood spots',
            'Good coffee and work places',
            'Reliable casual favorites',
          ],
          eventPriors: [
            'Local events this week',
            'Low-friction social plans',
            'Live happenings nearby',
          ],
          communityPriors: [
            'Local volunteer groups',
            'Interest-based communities',
            'Neighborhood meetups',
          ],
          promptSuggestions: [
            'What fits me nearby right now?',
            'Why is this a match for me?',
            'What community would suit me?',
            'Remember this about me',
          ],
        );
    }
  }

  static List<String> _priorTitlesFor(
    String city, {
    required _MetroPriorType type,
  }) {
    final raw = OnboardingLocalityLists.getListsForCity(city);
    if (raw.isEmpty) {
      return const [];
    }

    final filtered = raw.where((list) {
      final category = (list['category'] ?? '').toString().toLowerCase();
      switch (type) {
        case _MetroPriorType.spot:
          return category.contains('food') ||
              category.contains('activity') ||
              category.contains('outdoor');
        case _MetroPriorType.event:
          return category.contains('entertainment');
      }
    }).take(3);

    return filtered
        .map((list) => (list['name'] ?? '').toString())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  static bool _matchesPrior(String haystack, String prior) {
    final tokens = prior
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 4);
    for (final token in tokens) {
      if (haystack.contains(token)) {
        return true;
      }
    }
    return false;
  }

  static List<String> _metroAliasesFor(String metroKey) {
    switch (metroKey) {
      case 'nyc':
        return const ['nyc', 'new york', 'brooklyn', 'manhattan', 'queens'];
      case 'denver':
        return const ['denver', 'boulder', 'aurora', 'lakewood'];
      case 'atlanta':
        return const ['atlanta', 'decatur', 'buckhead', 'marietta'];
      case 'birmingham':
        return const [
          'birmingham',
          'homewood',
          'avondale',
          'five points',
          'mountain brook',
        ];
      default:
        return const [];
    }
  }
}

enum _MetroPriorType {
  spot,
  event,
}
