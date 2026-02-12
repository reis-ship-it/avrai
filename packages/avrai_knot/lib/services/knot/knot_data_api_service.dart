// Knot Data API Service
//
// Provides knot data for research and data sale
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 8: Data Sale & Research Integration

import 'dart:async';
import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_distribution_data.dart';
import 'package:avrai_knot/models/knot/knot_pattern_analysis.dart';
import 'package:avrai_knot/models/knot/knot_personality_correlations.dart';
import 'package:avrai_knot/models/knot/anonymized_knot_data.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_privacy_service.dart';

/// Service for providing knot data for research and data sale
///
/// **Privacy:** All data is fully anonymized - no personal identifiers
/// **Aggregate Only:** Only aggregate statistics, no individual knot data
/// **Topology Only:** Only topological structure, no dimension mapping
class KnotDataAPI {
  static const String _logName = 'KnotDataAPI';

  // These will be used when implementing actual data aggregation
  // ignore: unused_field
  final KnotStorageService _knotStorageService;
  // ignore: unused_field
  final KnotPrivacyService _privacyService;

  KnotDataAPI({
    required KnotStorageService knotStorageService,
    required KnotPrivacyService privacyService,
  })  : _knotStorageService = knotStorageService,
        _privacyService = privacyService;

  /// Get aggregate knot distributions
  ///
  /// **Returns:** Anonymized distribution data by location/category/time
  /// **Privacy:** Fully anonymized, aggregate only
  Future<KnotDistributionData> getKnotDistributions({
    String? location,
    String? category,
    DateTime? timeRange,
  }) async {
    developer.log(
      'Getting knot distributions: location=$location, category=$category, timeRange=$timeRange',
      name: _logName,
    );

    try {
      // Load all knots from storage
      final allKnots = await _knotStorageService.getAllKnots();

      // Filter by time range if provided
      final filteredKnots = timeRange != null
          ? allKnots.where((knot) => knot.createdAt.isAfter(timeRange)).toList()
          : allKnots;

      // Aggregate distributions
      final knotTypeDistribution = <String, int>{};
      final crossingNumberDistribution = <int, int>{};
      final writheDistribution = <int, int>{};

      for (final knot in filteredKnots) {
        // Determine knot type based on crossing number
        final knotType = _classifyKnotType(knot.invariants.crossingNumber);
        knotTypeDistribution[knotType] =
            (knotTypeDistribution[knotType] ?? 0) + 1;

        // Aggregate crossing numbers
        final crossingNum = knot.invariants.crossingNumber;
        crossingNumberDistribution[crossingNum] =
            (crossingNumberDistribution[crossingNum] ?? 0) + 1;

        // Aggregate writhe values
        final writhe = knot.invariants.writhe;
        writheDistribution[writhe] = (writheDistribution[writhe] ?? 0) + 1;
      }

      developer.log(
        '✅ Aggregated ${filteredKnots.length} knots into distributions',
        name: _logName,
      );

      return KnotDistributionData(
        location: location,
        category: category,
        timeRangeStart: timeRange,
        timeRangeEnd: timeRange?.add(const Duration(days: 30)),
        knotTypeDistribution: knotTypeDistribution,
        crossingNumberDistribution: crossingNumberDistribution,
        writheDistribution: writheDistribution,
        totalKnots: filteredKnots.length,
        calculatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get knot distributions: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Classify knot type based on crossing number
  ///
  /// **Knot Types:**
  /// - Unknot: 0 crossings
  /// - Trefoil: 3 crossings
  /// - Figure-Eight: 4 crossings
  /// - Cinquefoil: 5 crossings
  /// - Stevedore: 6 crossings
  /// - Complex: 7+ crossings
  String _classifyKnotType(int crossingNumber) {
    switch (crossingNumber) {
      case 0:
        return 'Unknot';
      case 3:
        return 'Trefoil';
      case 4:
        return 'Figure-Eight';
      case 5:
        return 'Cinquefoil';
      case 6:
        return 'Stevedore';
      default:
        if (crossingNumber < 0) {
          return 'Invalid';
        } else if (crossingNumber <= 10) {
          return 'Moderate ($crossingNumber)';
        } else {
          return 'Complex ($crossingNumber)';
        }
    }
  }

  /// Get knot topology patterns
  ///
  /// **Returns:** Analysis of knot patterns across user base
  /// **Privacy:** Fully anonymized, aggregate only
  Future<KnotPatternAnalysis> getKnotPatterns({
    required AnalysisType type,
  }) async {
    developer.log(
      'Getting knot patterns: type=$type',
      name: _logName,
    );

    try {
      final patterns = <PatternInsight>[];

      switch (type) {
        case AnalysisType.weavingPatterns:
          patterns.addAll(await _analyzeWeavingPatterns());
          break;
        case AnalysisType.compatibilityPatterns:
          patterns.addAll(await _analyzeCompatibilityPatterns());
          break;
        case AnalysisType.evolutionPatterns:
          patterns.addAll(await _analyzeEvolutionPatterns());
          break;
        case AnalysisType.communityFormation:
          patterns.addAll(await _analyzeCommunityFormationPatterns());
          break;
      }

      // Calculate statistics
      final averageStrength = patterns.isEmpty
          ? 0.0
          : patterns.map((p) => p.strength).reduce((a, b) => a + b) /
              patterns.length;

      final diversity = _calculateDiversity(patterns);
      final mostCommonPattern = patterns.isEmpty
          ? null
          : patterns
              .map((p) => p.description)
              .fold<Map<String, int>>(
                {},
                (map, desc) => map..[desc] = (map[desc] ?? 0) + 1,
              )
              .entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

      final statistics = PatternStatistics(
        totalPatterns: patterns.length,
        averageStrength: averageStrength,
        diversity: diversity,
        mostCommonPattern: mostCommonPattern,
      );

      developer.log(
        '✅ Analyzed ${patterns.length} patterns (avg strength: ${averageStrength.toStringAsFixed(3)})',
        name: _logName,
      );

      return KnotPatternAnalysis(
        type: type,
        patterns: patterns,
        statistics: statistics,
        analyzedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get knot patterns: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Analyze weaving patterns from braided knots
  Future<List<PatternInsight>> _analyzeWeavingPatterns() async {
    final braidedKnots = await _knotStorageService.getAllBraidedKnots();

    if (braidedKnots.isEmpty) {
      return [];
    }

    final patterns = <PatternInsight>[];

    // Analyze relationship type distribution
    final relationshipCounts = <String, int>{};
    for (final braidedKnot in braidedKnots) {
      final type = braidedKnot.relationshipType.toString();
      relationshipCounts[type] = (relationshipCounts[type] ?? 0) + 1;
    }

    for (final entry in relationshipCounts.entries) {
      final strength = entry.value / braidedKnots.length;
      patterns.add(PatternInsight(
        description: '${entry.key} relationships: ${entry.value} occurrences',
        strength: strength,
        metrics: {'count': entry.value, 'percentage': strength * 100},
      ));
    }

    // Analyze complexity patterns
    final avgComplexity =
        braidedKnots.map((k) => k.complexity).reduce((a, b) => a + b) /
            braidedKnots.length;
    patterns.add(PatternInsight(
      description:
          'Average braided knot complexity: ${avgComplexity.toStringAsFixed(2)}',
      strength: 0.8,
      metrics: {'averageComplexity': avgComplexity},
    ));

    return patterns;
  }

  /// Analyze compatibility patterns
  Future<List<PatternInsight>> _analyzeCompatibilityPatterns() async {
    final allKnots = await _knotStorageService.getAllKnots();

    if (allKnots.length < 2) {
      return [];
    }

    final patterns = <PatternInsight>[];

    // Sample compatibility pairs
    final sampleSize = allKnots.length > 100 ? 100 : allKnots.length;
    final compatibilityScores = <double>[];

    for (int i = 0; i < sampleSize && i < allKnots.length; i++) {
      for (int j = i + 1; j < sampleSize && j < allKnots.length; j++) {
        final knotA = allKnots[i];
        final knotB = allKnots[j];

        // Calculate topological compatibility (simplified)
        final crossingDiff =
            (knotA.invariants.crossingNumber - knotB.invariants.crossingNumber)
                .abs();
        final writheDiff =
            (knotA.invariants.writhe - knotB.invariants.writhe).abs();

        // Normalize to 0-1 range
        final compatibility = 1.0 / (1.0 + (crossingDiff + writheDiff) / 20.0);
        compatibilityScores.add(compatibility);
      }
    }

    if (compatibilityScores.isNotEmpty) {
      final avgCompatibility = compatibilityScores.reduce((a, b) => a + b) /
          compatibilityScores.length;
      patterns.add(PatternInsight(
        description:
            'Average topological compatibility: ${avgCompatibility.toStringAsFixed(3)}',
        strength: avgCompatibility,
        metrics: {
          'averageCompatibility': avgCompatibility,
          'sampleSize': compatibilityScores.length
        },
      ));
    }

    return patterns;
  }

  /// Analyze evolution patterns
  Future<List<PatternInsight>> _analyzeEvolutionPatterns() async {
    final allKnots = await _knotStorageService.getAllKnots();

    if (allKnots.isEmpty) {
      return [];
    }

    final patterns = <PatternInsight>[];

    // Analyze crossing number distribution
    final crossingNumbers =
        allKnots.map((k) => k.invariants.crossingNumber).toList();
    final avgCrossings =
        crossingNumbers.reduce((a, b) => a + b) / crossingNumbers.length;

    patterns.add(PatternInsight(
      description:
          'Average crossing number: ${avgCrossings.toStringAsFixed(2)}',
      strength: 0.7,
      metrics: {'averageCrossings': avgCrossings},
    ));

    // Analyze writhe distribution
    final writhes = allKnots.map((k) => k.invariants.writhe).toList();
    final avgWrithe = writhes.reduce((a, b) => a + b) / writhes.length;

    patterns.add(PatternInsight(
      description: 'Average writhe: ${avgWrithe.toStringAsFixed(2)}',
      strength: 0.7,
      metrics: {'averageWrithe': avgWrithe},
    ));

    return patterns;
  }

  /// Analyze community formation patterns
  Future<List<PatternInsight>> _analyzeCommunityFormationPatterns() async {
    final braidedKnots = await _knotStorageService.getAllBraidedKnots();

    if (braidedKnots.isEmpty) {
      return [];
    }

    final patterns = <PatternInsight>[];

    // Analyze harmony scores (indicator of community cohesion)
    final harmonyScores = braidedKnots.map((k) => k.harmonyScore).toList();
    final avgHarmony =
        harmonyScores.reduce((a, b) => a + b) / harmonyScores.length;

    patterns.add(PatternInsight(
      description:
          'Average community harmony: ${avgHarmony.toStringAsFixed(3)}',
      strength: avgHarmony,
      metrics: {
        'averageHarmony': avgHarmony,
        'totalConnections': braidedKnots.length
      },
    ));

    return patterns;
  }

  /// Calculate pattern diversity (entropy measure)
  double _calculateDiversity(List<PatternInsight> patterns) {
    if (patterns.isEmpty) return 0.0;

    // Group by description
    final groups = <String, int>{};
    for (final pattern in patterns) {
      groups[pattern.description] = (groups[pattern.description] ?? 0) + 1;
    }

    // Calculate entropy
    final total = patterns.length;
    double entropy = 0.0;
    for (final count in groups.values) {
      final probability = count / total;
      if (probability > 0) {
        entropy -=
            probability * (probability > 0 ? (probability * probability) : 0);
      }
    }

    return entropy.clamp(0.0, 1.0);
  }

  /// Get knot-personality correlations
  ///
  /// **Returns:** Correlations between knot properties and knot characteristics
  /// **Privacy:** Fully anonymized, aggregate only
  /// **Note:** For privacy, correlations are calculated between knot properties only
  Future<KnotPersonalityCorrelations> getCorrelations() async {
    developer.log(
      'Getting knot correlations',
      name: _logName,
    );

    try {
      // Load all knots (already anonymized)
      final allKnots = await _knotStorageService.getAllKnots();

      if (allKnots.length < 2) {
        // Need at least 2 data points for correlation
        return KnotPersonalityCorrelations(
          correlationMatrix: const {},
          strongestCorrelations: const [],
          significance: const {},
          sampleSize: allKnots.length,
          calculatedAt: DateTime.now(),
        );
      }

      // Extract knot properties
      final crossingNumbers =
          allKnots.map((k) => k.invariants.crossingNumber.toDouble()).toList();
      final writhes =
          allKnots.map((k) => k.invariants.writhe.toDouble()).toList();
      final jonesPolyLengths = allKnots
          .map((k) => k.invariants.jonesPolynomial.length.toDouble())
          .toList();
      final alexanderPolyLengths = allKnots
          .map((k) => k.invariants.alexanderPolynomial.length.toDouble())
          .toList();

      // Calculate correlations between knot properties
      final correlationMatrix = <String, Map<String, double>>{};

      // Crossing number correlations
      correlationMatrix['crossing_number'] = {
        'writhe': _calculatePearsonCorrelation(crossingNumbers, writhes),
        'jones_poly_length':
            _calculatePearsonCorrelation(crossingNumbers, jonesPolyLengths),
        'alexander_poly_length':
            _calculatePearsonCorrelation(crossingNumbers, alexanderPolyLengths),
      };

      // Writhe correlations
      correlationMatrix['writhe'] = {
        'jones_poly_length':
            _calculatePearsonCorrelation(writhes, jonesPolyLengths),
        'alexander_poly_length':
            _calculatePearsonCorrelation(writhes, alexanderPolyLengths),
      };

      // Jones polynomial length correlations
      correlationMatrix['jones_poly_length'] = {
        'alexander_poly_length': _calculatePearsonCorrelation(
            jonesPolyLengths, alexanderPolyLengths),
      };

      // Find strongest correlations
      final strongestCorrelations = <StrongCorrelation>[];
      for (final entry in correlationMatrix.entries) {
        final knotProperty = entry.key;
        for (final subEntry in entry.value.entries) {
          final property = subEntry.key;
          final correlation = subEntry.value;

          // Only include significant correlations (|r| > 0.3)
          if (correlation.abs() > 0.3) {
            // Calculate p-value (simplified - assumes normal distribution)
            final pValue = _calculatePValue(correlation, allKnots.length);

            strongestCorrelations.add(StrongCorrelation(
              knotProperty: knotProperty,
              personalityDimension:
                  property, // Using property name as dimension identifier
              correlation: correlation,
              significance: pValue,
            ));
          }
        }
      }

      // Sort by absolute correlation strength
      strongestCorrelations
          .sort((a, b) => b.correlation.abs().compareTo(a.correlation.abs()));

      // Calculate significance map
      final significance = <String, double>{};
      for (final correlation in strongestCorrelations) {
        final key =
            '${correlation.knotProperty}_${correlation.personalityDimension}';
        significance[key] = correlation.significance;
      }

      developer.log(
        '✅ Calculated correlations: ${strongestCorrelations.length} significant correlations found',
        name: _logName,
      );

      return KnotPersonalityCorrelations(
        correlationMatrix: correlationMatrix,
        strongestCorrelations:
            strongestCorrelations.take(10).toList(), // Top 10
        significance: significance,
        sampleSize: allKnots.length,
        calculatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get correlations: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate Pearson correlation coefficient
  ///
  /// **Formula:** r = Σ((x - x̄)(y - ȳ)) / √(Σ(x - x̄)² · Σ(y - ȳ)²)
  double _calculatePearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) {
      return 0.0;
    }

    // Calculate means
    final meanX = x.reduce((a, b) => a + b) / x.length;
    final meanY = y.reduce((a, b) => a + b) / y.length;

    // Calculate numerator: Σ((x - x̄)(y - ȳ))
    double numerator = 0.0;
    for (int i = 0; i < x.length; i++) {
      numerator += (x[i] - meanX) * (y[i] - meanY);
    }

    // Calculate denominators
    double sumSqX = 0.0;
    double sumSqY = 0.0;
    for (int i = 0; i < x.length; i++) {
      final diffX = x[i] - meanX;
      final diffY = y[i] - meanY;
      sumSqX += diffX * diffX;
      sumSqY += diffY * diffY;
    }

    // Calculate correlation
    final denominator = (sumSqX * sumSqY);
    if (denominator == 0.0) {
      return 0.0;
    }

    return numerator / (denominator > 0 ? denominator : 1.0);
  }

  /// Calculate p-value for correlation (simplified t-test)
  ///
  /// **Formula:** t = r * √((n-2) / (1-r²))
  /// **Note:** This is a simplified calculation. For production, use a proper statistical library.
  double _calculatePValue(double correlation, int sampleSize) {
    if (sampleSize < 3 || correlation.abs() >= 1.0) {
      return 1.0; // Cannot calculate
    }

    // Calculate t-statistic
    final n = sampleSize.toDouble();
    final t =
        correlation.abs() * ((n - 2) / (1 - correlation * correlation)).abs();

    // Simplified p-value approximation (for large samples, t > 2 is significant)
    // This is a rough approximation - for production, use proper t-distribution
    if (t > 3.0) {
      return 0.001; // Highly significant
    } else if (t > 2.0) {
      return 0.01; // Significant
    } else if (t > 1.5) {
      return 0.05; // Marginally significant
    } else {
      return 0.1; // Not significant
    }
  }

  /// Stream anonymized knot data
  ///
  /// **Returns:** Real-time stream of anonymized knot data
  /// **Privacy:** Fully anonymized, topology only
  Stream<AnonymizedKnotData> streamKnotData({
    required StreamType type,
  }) async* {
    developer.log(
      'Starting knot data stream: type=$type',
      name: _logName,
    );

    // TODO: Implement actual streaming
    // In production, this would:
    // 1. Set up stream from knot storage
    // 2. Anonymize each knot before emitting
    // 3. Emit at configured interval
    // 4. Handle stream errors gracefully

    // Placeholder: Empty stream
    // In production, this would yield anonymized knot data
    yield* const Stream<AnonymizedKnotData>.empty();
  }

  /// Anonymize knot for research data
  ///
  /// **Privacy:** Removes all personal identifiers, keeps only topology
  /// **Note:** This method will be used when implementing actual data streaming
  // ignore: unused_element
  AnonymizedKnotData _anonymizeKnot(PersonalityKnot knot) {
    // Anonymize timestamp (round to hour)
    final anonymizedTimestamp = DateTime(
      knot.createdAt.year,
      knot.createdAt.month,
      knot.createdAt.day,
      knot.createdAt.hour,
    );

    return AnonymizedKnotData(
      type: StreamType.realTime,
      topology: knot.invariants,
      anonymizedTimestamp: anonymizedTimestamp,
      metadata: null, // No metadata to preserve privacy
    );
  }
}
