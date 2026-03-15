import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_automated_source_puller.dart';
import 'package:http/http.dart' as http;

class RpcgbSpatialReplaySourcePuller extends BhamReplayAutomatedSourcePuller {
  RpcgbSpatialReplaySourcePuller({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  String get pullerId => 'rpcgb_spatial_replay_source_puller';

  @override
  bool supports(ReplaySourcePullPlan plan) {
    return plan.sourceName == 'Jefferson / Shelby / Regional GIS and Assessors';
  }

  @override
  Future<ReplaySourceDataset> pull({
    required ReplaySourcePullPlan plan,
  }) async {
    final endpoint = plan.endpointRef ?? plan.sourceUrl;
    if (endpoint == null || endpoint.isEmpty) {
      throw ArgumentError('RPCGB pull plan requires an endpoint.');
    }

    final uri = Uri.parse(endpoint);
    final response = await _client.get(
      uri,
      headers: const <String, String>{
        'accept': 'text/html,application/xhtml+xml,application/xml',
        'user-agent': 'AVRAI-BHAM-Replay/1.0',
      },
    );
    if (response.statusCode != 200) {
      throw StateError('RPCGB pull failed with status ${response.statusCode}.');
    }

    final records = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final candidate in _extractCandidates(response.body)) {
      final title = candidate.$1;
      final href = candidate.$2;
      final key = '${title.toLowerCase()}|$href';
      if (!seen.add(key)) {
        continue;
      }

      final entityType = _entityTypeFor(title);
      final observedAt = DateTime.utc(plan.replayYear, 12, 31, 12);
      records.add(<String, dynamic>{
        'record_id': 'rpcgb-${records.length + 1}',
        'entity_id': 'rpcgb:${_slugFor(title)}',
        'entity_type': entityType,
        'name': title,
        'title': title,
        'source_url': href,
        'locality': _localityFor(title),
        'observed_at': observedAt.toIso8601String(),
        'published_at': DateTime.now().toUtc().toIso8601String(),
        'valid_from': DateTime.utc(plan.replayYear, 1, 1).toIso8601String(),
        'valid_to': DateTime.utc(plan.replayYear, 12, 31, 23, 59, 59)
            .toIso8601String(),
        'catalog_type': entityType,
        'historical_admissibility': 'structural_spatial_catalog_only',
        'confidence': 0.68,
        'uncertainty_minutes': 10080,
      });
    }

    return ReplaySourceDataset(
      sourceName: plan.sourceName,
      records: records,
      metadata: <String, dynamic>{
        'pullerId': pullerId,
        'uri': uri.toString(),
        'recordCount': records.length,
        'coverageStatus': 'current_spatial_catalog',
        'historicalReplayReady': false,
      },
    );
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
      final looksRelevant =
          normalized.contains('jefferson') ||
          normalized.contains('shelby') ||
          normalized.contains('birmingham') ||
          normalized.contains('region') ||
          normalized.contains('parcel') ||
          normalized.contains('building') ||
          normalized.contains('housing') ||
          normalized.contains('population') ||
          normalized.contains('income') ||
          normalized.contains('employment') ||
          normalized.contains('open data') ||
          normalized.contains('data portal') ||
          normalized.contains('boundar') ||
          normalized.contains('assessor') ||
          normalized.contains('zoning');
      if (!looksRelevant) {
        continue;
      }
      results.add((text, href));
    }
    return results;
  }

  String _entityTypeFor(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('housing') || normalized.contains('rent')) {
      return 'housing_signal';
    }
    if (normalized.contains('income') ||
        normalized.contains('employment') ||
        normalized.contains('labor')) {
      return 'economic_signal';
    }
    if (normalized.contains('population') || normalized.contains('census')) {
      return 'population_cohort';
    }
    return 'locality';
  }

  String _localityFor(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('jefferson')) {
      return 'jefferson_county';
    }
    if (normalized.contains('shelby')) {
      return 'shelby_county';
    }
    if (normalized.contains('birmingham')) {
      return 'bham_metro_regional';
    }
    return 'greater_birmingham_region';
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
