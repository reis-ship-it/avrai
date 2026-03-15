import 'package:avrai_core/avra_core.dart';

class ReplayYearCompletenessService {
  const ReplayYearCompletenessService();

  ReplayYearCompletenessScore scoreYear({
    required int year,
    required List<ReplaySourceDescriptor> sources,
  }) {
    final relevant = sources
        .where((source) => source.coversYear(year))
        .where((source) => _statusWeight(source.status) > 0.0)
        .where((source) => _legalWeight(source.legalStatus) > 0.0)
        .toList();

    if (relevant.isEmpty) {
      return ReplayYearCompletenessScore(
        year: year,
        eventCoverage: 0.0,
        venueCoverage: 0.0,
        communityCoverage: 0.0,
        recurrenceFidelity: 0.0,
        temporalCertainty: 0.0,
        trustQuality: 0.0,
        overallScore: 0.0,
        notes: const <String>['no eligible sources cover this year'],
      );
    }

    final eventCoverage = _coverageScore(
      relevant,
      const <String>{'event', 'events', 'calendar', 'festival', 'venue'},
    );
    final venueCoverage = _coverageScore(
      relevant,
      const <String>{'venue', 'venues', 'restaurant', 'spot', 'place'},
    );
    final communityCoverage = _coverageScore(
      relevant,
      const <String>{'community', 'communities', 'club', 'clubs', 'neighborhood'},
    );
    final recurrenceFidelity = _average(
      relevant.map(_recurrenceFidelityFor),
    );
    final temporalCertainty = _average(
      relevant.map((source) => _temporalCertaintyFor(source, year)),
    );
    final trustQuality = _average(
      relevant.map(_sourceQualityWeight),
    );

    final overallScore = _average(
      <double>[
        eventCoverage * 0.24,
        venueCoverage * 0.22,
        communityCoverage * 0.16,
        recurrenceFidelity * 0.15,
        temporalCertainty * 0.11,
        trustQuality * 0.12,
      ],
    ) *
        6.0;

    final notes = <String>[
      if (eventCoverage < 0.5) 'event coverage is weak',
      if (venueCoverage < 0.5) 'venue coverage is weak',
      if (communityCoverage < 0.45) 'community/club coverage is weak',
      if (relevant.any((source) => source.status == ReplaySourceStatus.candidate))
        'candidate sources still influence score',
    ];

    return ReplayYearCompletenessScore(
      year: year,
      eventCoverage: eventCoverage,
      venueCoverage: venueCoverage,
      communityCoverage: communityCoverage,
      recurrenceFidelity: recurrenceFidelity,
      temporalCertainty: temporalCertainty,
      trustQuality: trustQuality,
      overallScore: overallScore.clamp(0.0, 1.0),
      notes: notes,
      sourceRefs: relevant.map((source) => source.sourceName).toList(),
    );
  }

  List<ReplayYearCompletenessScore> scoreYears({
    required List<int> candidateYears,
    required List<ReplaySourceDescriptor> sources,
  }) {
    return candidateYears
        .map((year) => scoreYear(year: year, sources: sources))
        .toList();
  }

  ReplayYearCompletenessScore selectBestYear({
    required List<int> candidateYears,
    required List<ReplaySourceDescriptor> sources,
  }) {
    final scores = scoreYears(candidateYears: candidateYears, sources: sources);
    scores.sort((left, right) {
      final scoreCompare = right.overallScore.compareTo(left.overallScore);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final leftTie = left.year == 2025;
      final rightTie = right.year == 2025;
      if (leftTie && !rightTie) {
        return -1;
      }
      if (rightTie && !leftTie) {
        return 1;
      }
      return right.year.compareTo(left.year);
    });
    return scores.first;
  }

  double _coverageScore(
    List<ReplaySourceDescriptor> sources,
    Set<String> coverageTerms,
  ) {
    final matching = sources.where((source) {
      final normalized = source.entityCoverage
          .map((entry) => entry.toLowerCase())
          .toSet();
      return normalized.any(
        (entry) => coverageTerms.any(
          (term) => entry.contains(term),
        ),
      );
    }).toList();
    if (matching.isEmpty) {
      return 0.0;
    }
    return _average(matching.map(_sourceQualityWeight));
  }

  double _recurrenceFidelityFor(ReplaySourceDescriptor source) {
    final cadence = (source.updateCadence ?? '').toLowerCase();
    final cadenceWeight = switch (cadence) {
      'realtime' => 1.0,
      'daily' => 0.92,
      'weekly' => 0.82,
      'monthly' => 0.68,
      'quarterly' => 0.55,
      'yearly' => 0.42,
      _ => 0.5,
    };
    final exportBonus = source.structuredExportAvailable ? 0.08 : 0.0;
    return (cadenceWeight + exportBonus).clamp(0.0, 1.0);
  }

  double _temporalCertaintyFor(ReplaySourceDescriptor source, int year) {
    final yearDistance = source.richestYear == null
        ? 1.0
        : (source.richestYear! - year).abs().clamp(0, 5) / 5.0;
    final richestYearWeight = 1.0 - (yearDistance * 0.35);
    final exportBonus = source.structuredExportAvailable ? 0.1 : 0.0;
    return (_sourceQualityWeight(source) * 0.7 + richestYearWeight * 0.3 + exportBonus)
        .clamp(0.0, 1.0);
  }

  double _sourceQualityWeight(ReplaySourceDescriptor source) {
    final trust = switch (source.trustTier) {
      ReplaySourceTrustTier.tier1 => 1.0,
      ReplaySourceTrustTier.tier2 => 0.85,
      ReplaySourceTrustTier.tier3 => 0.7,
      ReplaySourceTrustTier.tier4 => 0.55,
      ReplaySourceTrustTier.tier5 => 0.4,
    };
    return (trust * _statusWeight(source.status) * _legalWeight(source.legalStatus))
        .clamp(0.0, 1.0);
  }

  double _statusWeight(ReplaySourceStatus status) {
    return switch (status) {
      ReplaySourceStatus.ingested => 1.0,
      ReplaySourceStatus.approved => 0.9,
      ReplaySourceStatus.candidate => 0.6,
      ReplaySourceStatus.deferred => 0.35,
      ReplaySourceStatus.legacy => 0.25,
      ReplaySourceStatus.blocked => 0.0,
    };
  }

  double _legalWeight(String legalStatus) {
    final normalized = legalStatus.toLowerCase();
    if (normalized.contains('blocked') || normalized.contains('forbidden')) {
      return 0.0;
    }
    if (normalized.contains('review')) {
      return 0.6;
    }
    return 1.0;
  }

  double _average(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) {
      return 0.0;
    }
    final sum = list.fold<double>(0.0, (total, value) => total + value);
    return sum / list.length;
  }
}
