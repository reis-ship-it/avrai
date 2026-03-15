import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_source_puller.dart';
import 'package:http/http.dart' as http;

class BirminghamPublicLibraryArchivesReplaySourcePuller
    extends BhamReplayAutomatedSourcePuller {
  BirminghamPublicLibraryArchivesReplaySourcePuller({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  String get pullerId => 'birmingham_public_library_archives_replay_source_puller';

  @override
  bool supports(ReplaySourcePullPlan plan) {
    return plan.sourceName == 'Birmingham Public Library Archives';
  }

  @override
  Future<ReplaySourceDataset> pull({
    required ReplaySourcePullPlan plan,
  }) async {
    final endpoints = _candidateEndpointsFor(plan);
    if (endpoints.isEmpty) {
      throw ArgumentError(
        'Birmingham Public Library Archives pull plan requires an endpoint.',
      );
    }
    final attemptErrors = <String>[];
    Uri? resolvedUri;
    List<(String, String)> candidates = const <(String, String)>[];

    for (final endpoint in endpoints) {
      final uri = Uri.parse(endpoint);
      try {
        final response = await _client
            .get(
              uri,
              headers: const <String, String>{
                'accept': 'text/html,application/xhtml+xml,application/xml',
                'user-agent': 'AVRAI-BHAM-Replay/1.0',
              },
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) {
          attemptErrors.add('${uri.host}${uri.path} status ${response.statusCode}');
          continue;
        }

        final html = response.body;
        final extracted = _extractArchiveCandidates(html);
        if (extracted.isEmpty) {
          attemptErrors.add('${uri.host}${uri.path} returned no archive candidates');
          continue;
        }

        resolvedUri = uri;
        candidates = extracted;
        break;
      } catch (error) {
        attemptErrors.add('${uri.host}${uri.path} ${error.runtimeType}');
      }
    }

    if (resolvedUri == null || candidates.isEmpty) {
      final summary = attemptErrors.isEmpty
          ? 'no successful archive endpoint'
          : attemptErrors.join('; ');
      throw StateError(
        'Birmingham Public Library Archives pull failed across official endpoints: $summary.',
      );
    }

    final records = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
      final title = candidate.$1;
      final href = candidate.$2;
      final key = '${title.toLowerCase()}|$href';
      if (!seen.add(key)) {
        continue;
      }
      final entityType = _entityTypeFor(title: title, href: href);
      records.add(<String, dynamic>{
        'record_id': 'bpl-archive-$index',
        'entity_id': 'bpl_archive:${_slugFor(title)}',
        'entity_type': entityType,
        'archive_type': entityType,
        'name': title,
        'title': title,
        'archive_url': href,
        'locality': _localityFor(title, href),
        'observed_at': DateTime.utc(plan.replayYear, 12, 31, 12).toIso8601String(),
        'published_at': DateTime.now().toUtc().toIso8601String(),
        'valid_from': DateTime.utc(plan.replayYear, 1, 1).toIso8601String(),
        'valid_to': DateTime.utc(plan.replayYear, 12, 31, 23, 59, 59).toIso8601String(),
        'historical_admissibility': 'deep_context_archive',
        'retrospective_evidence': true,
        'confidence': 0.72,
        'uncertainty_minutes': 1440,
      });
    }

    return ReplaySourceDataset(
      sourceName: plan.sourceName,
      records: records,
      metadata: <String, dynamic>{
        'pullerId': pullerId,
        'uri': resolvedUri.toString(),
        'attemptedEndpoints': endpoints,
        'recordCount': records.length,
        'coverageStatus': 'archive_index_discovery',
        'historicalReplayReady': records.isNotEmpty,
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
    add('https://www.cobpl.org/resources/archives/collections.aspx');
    add('https://www.cobpl.org/resources/archives/');
    add('https://www.cobpl.org/virtual/');
    add('https://www.bplonline.org/resources/archives/');

    return ordered;
  }

  List<(String, String)> _extractArchiveCandidates(String html) {
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
      final normalizedHref = href.toLowerCase();
      final normalizedText = text.toLowerCase();
      final looksRelevant =
          normalizedHref.contains('archive') ||
          normalizedHref.contains('history') ||
          normalizedHref.contains('collection') ||
          normalizedHref.contains('digital') ||
          normalizedText.contains('archive') ||
          normalizedText.contains('history') ||
          normalizedText.contains('collection') ||
          normalizedText.contains('birmingham');
      if (!looksRelevant) {
        continue;
      }
      results.add((text, href));
    }
    return results;
  }

  String _stripHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _entityTypeFor({
    required String title,
    required String href,
  }) {
    final combined = '${title.toLowerCase()} $href'.toLowerCase();
    if (combined.contains('event') ||
        combined.contains('festival') ||
        combined.contains('parade') ||
        combined.contains('opening')) {
      return 'event';
    }
    if (combined.contains('neighborhood') ||
        combined.contains('district') ||
        combined.contains('community')) {
      return 'community';
    }
    if (combined.contains('city') ||
        combined.contains('birmingham') ||
        combined.contains('southside') ||
        combined.contains('avondale')) {
      return 'locality';
    }
    return 'venue';
  }

  String _localityFor(String title, String href) {
    final combined = '${title.toLowerCase()} $href';
    if (combined.contains('southside')) {
      return 'bham_southside';
    }
    if (combined.contains('avondale')) {
      return 'bham_avondale';
    }
    if (combined.contains('downtown')) {
      return 'bham_downtown';
    }
    return 'bham_metro_regional';
  }

  String _slugFor(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
