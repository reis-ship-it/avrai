import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_source_puller.dart';
import 'package:http/http.dart' as http;

class InBirminghamReplaySourcePuller extends BhamReplayAutomatedSourcePuller {
  InBirminghamReplaySourcePuller({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  String get pullerId => 'in_birmingham_replay_source_puller';

  @override
  bool supports(ReplaySourcePullPlan plan) {
    return plan.sourceName == 'IN Birmingham (CVB Calendar)';
  }

  @override
  Future<ReplaySourceDataset> pull({
    required ReplaySourcePullPlan plan,
  }) async {
    final endpoints = _candidateEndpointsFor(plan);
    final records = <Map<String, dynamic>>[];
    final seen = <String>{};
    String? resolvedUri;

    for (final endpoint in endpoints) {
      final uri = Uri.parse(endpoint);
      final response = await _client.get(
        uri,
        headers: const <String, String>{
          'accept': 'text/html,application/xhtml+xml,application/xml',
          'user-agent': 'AVRAI-BHAM-Replay/1.0',
        },
      );
      if (response.statusCode != 200) {
        continue;
      }
      resolvedUri ??= uri.toString();
      for (final candidate in _extractCandidates(response.body)) {
        final title = candidate.$1;
        final href = candidate.$2;
        final key = '${title.toLowerCase()}|$href';
        if (!seen.add(key)) {
          continue;
        }
        final entityType = _entityTypeFor(title, href);
        records.add(<String, dynamic>{
          'record_id': 'inbham-${records.length + 1}',
          'entity_id': 'inbirmingham:${_slugFor(title)}',
          'entity_type': entityType,
          'name': title,
          'title': title,
          'source_url': href,
          'locality': _localityFor(title, href),
          'observed_at': DateTime.utc(plan.replayYear, 12, 31, 12)
              .toIso8601String(),
          'published_at': DateTime.now().toUtc().toIso8601String(),
          'valid_from': DateTime.utc(plan.replayYear, 1, 1).toIso8601String(),
          'valid_to': DateTime.utc(plan.replayYear, 12, 31, 23, 59, 59)
              .toIso8601String(),
          'catalog_type': entityType,
          'historical_admissibility': 'tourism_catalog_seed_only',
          'confidence': 0.64,
          'uncertainty_minutes': 4320,
        });
      }
    }

    if (resolvedUri == null) {
      throw StateError('IN Birmingham pull failed across candidate endpoints.');
    }

    return ReplaySourceDataset(
      sourceName: plan.sourceName,
      records: records,
      metadata: <String, dynamic>{
        'pullerId': pullerId,
        'uri': resolvedUri,
        'recordCount': records.length,
        'coverageStatus': 'current_tourism_catalog',
        'historicalReplayReady': false,
      },
    );
  }

  List<String> _candidateEndpointsFor(ReplaySourcePullPlan plan) {
    final seen = <String>{};
    final ordered = <String>[];

    void add(String? raw) {
      final normalized = raw?.trim();
      if (normalized == null || normalized.isEmpty) {
        return;
      }
      if (seen.add(normalized)) {
        ordered.add(normalized);
      }
    }

    add(plan.endpointRef);
    add(plan.sourceUrl);
    add('https://inbirmingham.com/community-guides/');
    add('https://inbirmingham.com/');
    return ordered;
  }

  List<(String, String)> _extractCandidates(String html) {
    final matches = RegExp(
      r'<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);
    final results = <(String, String)>[];
    for (final match in matches) {
      final href = match.group(1)?.trim();
      final rawText = match.group(2);
      if (href == null || href.isEmpty || rawText == null) {
        continue;
      }
      final text = _stripHtml(rawText);
      if (text.length < 4) {
        continue;
      }
      final normalized = '${text.toLowerCase()} ${href.toLowerCase()}';
      if (_isGenericNavigation(text, href)) {
        continue;
      }
      final looksRelevant =
          href.contains('/event/') ||
          href.contains('/community-guides/') ||
          href.contains('/neighborhood') ||
          normalized.contains('festival') ||
          normalized.contains('community') ||
          normalized.contains('guide');
      if (!looksRelevant) {
        continue;
      }
      results.add((text, href));
    }
    return results;
  }

  bool _isGenericNavigation(String text, String href) {
    final normalizedText = text.toLowerCase();
    final normalizedHref = href.toLowerCase();
    const blockedTitles = <String>{
      'sports',
      'travel pros',
      'news & stories',
      'news and stories',
      'meetings & conventions',
      'meetings and conventions',
      'home',
      'search',
      'menu',
    };
    if (blockedTitles.contains(normalizedText)) {
      return true;
    }
    return normalizedHref.endsWith('/news-and-stories/') ||
        normalizedHref.endsWith('/travel-pros/') ||
        normalizedHref.endsWith('/sports/') ||
        normalizedHref.endsWith('/meetings-and-conventions/');
  }

  String _entityTypeFor(String title, String href) {
    final normalized = '${title.toLowerCase()} ${href.toLowerCase()}';
    if (normalized.contains('event') || normalized.contains('festival')) {
      return 'event';
    }
    if (normalized.contains('community') || normalized.contains('neighborhood')) {
      return 'community';
    }
    if (normalized.contains('guide')) {
      return 'locality';
    }
    return 'venue';
  }

  String _localityFor(String title, String href) {
    final normalized = '${title.toLowerCase()} ${href.toLowerCase()}';
    if (normalized.contains('downtown')) {
      return 'bham_downtown';
    }
    if (normalized.contains('southside')) {
      return 'bham_southside';
    }
    if (normalized.contains('avondale')) {
      return 'bham_avondale';
    }
    return 'bham_metro_regional';
  }

  String _stripHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _slugFor(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
