// String Export Service
//
// Service for exporting string evolution data
// Part of Low Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:io';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/models/knot/string_export_format.dart';

/// Service for exporting string evolution data
///
/// **Responsibilities:**
/// - Export string data to JSON format
/// - Export string trajectory to CSV format
/// - Export string analytics (patterns, trends, milestones)
///
/// **Performance Optimizations (Phase 4):**
/// - Streaming: Streams large exports to avoid memory issues
/// - Sampling: Supports sampling for large time ranges
class StringExportService {
  static const String _logName = 'StringExportService';

  // Performance optimization: Streaming threshold
  // If snapshots exceed this count, use streaming export
  static const int _streamingThreshold = 10000;

  static String _safePrefix(String value, int length) =>
      value.length <= length ? value : value.substring(0, length);

  /// Export string to JSON format
  ///
  /// **Returns:**
  /// - File path of exported JSON file
  ///
  /// **Parameters:**
  /// - `string`: KnotString to export
  /// - `filename`: Optional filename (default: auto-generated)
  Future<String> exportStringToJSON({
    required KnotString string,
    String? filename,
  }) async {
    developer.log(
      'Exporting string to JSON: agentId=${_safePrefix(string.initialKnot.agentId, 10)}...',
      name: _logName,
    );

    try {
      // Prepare export data
      final exportData = <String, dynamic>{
        'metadata': _createMetadata(string),
        'initialKnot': string.initialKnot.toJson(),
        'snapshots': string.snapshots
            .map(
              (s) => {
                'timestamp': s.timestamp.toIso8601String(),
                'knot': s.knot.toJson(),
                'reason': s.reason,
              },
            )
            .toList(),
        'params': {
          'interpolationMethod': 'polynomial',
          'extrapolationMethod': 'physics_based',
        },
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to file
      final file = await _getExportFile(
        filename:
            filename ??
            'string_export_${_safePrefix(string.initialKnot.agentId, 8)}.json',
      );

      await file.writeAsString(jsonString);

      developer.log('✅ Exported string to JSON: ${file.path}', name: _logName);

      return file.path;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to export string to JSON: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Export string trajectory to CSV format
  ///
  /// **Returns:**
  /// - File path of exported CSV file
  ///
  /// **Parameters:**
  /// - `string`: KnotString to export
  /// - `timeStep`: Time step for trajectory sampling (default: 1 hour)
  /// - `filename`: Optional filename
  /// - `useStreaming`: Whether to use streaming for large exports (default: auto-detect)
  Future<String> exportStringToCSV({
    required KnotString string,
    Duration timeStep = const Duration(hours: 1),
    String? filename,
    bool? useStreaming,
  }) async {
    developer.log(
      'Exporting string to CSV: agentId=${_safePrefix(string.initialKnot.agentId, 10)}...',
      name: _logName,
    );

    try {
      // Determine time range
      DateTime startTime;
      DateTime endTime;

      if (string.snapshots.isEmpty) {
        startTime = DateTime.now();
        endTime = DateTime.now();
      } else {
        final sorted = List.from(string.snapshots)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        startTime = sorted.first.timestamp;
        endTime = sorted.last.timestamp;
      }

      // Estimate number of data points
      final timeSpan = endTime.difference(startTime);
      final estimatedPoints = (timeSpan.inHours / timeStep.inHours).ceil();

      // Auto-detect streaming if not specified
      final shouldStream =
          useStreaming ?? (estimatedPoints > _streamingThreshold);

      final file = await _getExportFile(
        filename:
            filename ??
            'string_trajectory_${_safePrefix(string.initialKnot.agentId, 8)}.csv',
      );

      // Open file for writing
      final sink = file.openWrite();

      try {
        // Write CSV header
        sink.writeln(
          'timestamp,crossing_number,writhe,signature,bridge_number,braid_index,determinant',
        );

        int pointCount = 0;

        // Performance optimization: Stream data points for large exports
        if (shouldStream) {
          developer.log(
            'Using streaming export for large time range (estimated $estimatedPoints points)',
            name: _logName,
          );

          // Stream trajectory points
          var currentTime = startTime;
          while (currentTime.isBefore(endTime) || currentTime == endTime) {
            final knot = string.getKnotAtTime(currentTime);
            if (knot != null) {
              sink.writeln(
                '${currentTime.toIso8601String()},'
                '${knot.invariants.crossingNumber},'
                '${knot.invariants.writhe},'
                '${knot.invariants.signature},'
                '${knot.invariants.bridgeNumber},'
                '${knot.invariants.braidIndex},'
                '${knot.invariants.determinant}',
              );
              pointCount++;
            }

            currentTime = currentTime.add(timeStep);

            // Flush periodically to avoid memory buildup
            if (pointCount % 1000 == 0) {
              await sink.flush();
            }
          }
        } else {
          // Non-streaming: collect all points first (for smaller exports)
          final csvLines = <String>[];

          var currentTime = startTime;
          while (currentTime.isBefore(endTime) || currentTime == endTime) {
            final knot = string.getKnotAtTime(currentTime);
            if (knot != null) {
              csvLines.add(
                '${currentTime.toIso8601String()},'
                '${knot.invariants.crossingNumber},'
                '${knot.invariants.writhe},'
                '${knot.invariants.signature},'
                '${knot.invariants.bridgeNumber},'
                '${knot.invariants.braidIndex},'
                '${knot.invariants.determinant}',
              );
              pointCount++;
            }

            currentTime = currentTime.add(timeStep);
          }

          // Write all at once
          for (final line in csvLines) {
            sink.writeln(line);
          }
        }

        await sink.flush();
        await sink.close();

        developer.log(
          '✅ Exported string to CSV: ${file.path} ($pointCount data points)',
          name: _logName,
        );

        return file.path;
      } catch (e) {
        await sink.close();
        rethrow;
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to export string to CSV: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Export string analytics
  ///
  /// **Returns:**
  /// - File path of exported analytics file
  ///
  /// **Parameters:**
  /// - `string`: KnotString to analyze
  /// - `filename`: Optional filename
  Future<String> exportStringAnalytics({
    required KnotString string,
    String? filename,
  }) async {
    developer.log(
      'Exporting string analytics: agentId=${_safePrefix(string.initialKnot.agentId, 10)}...',
      name: _logName,
    );

    try {
      // Analyze string
      final analytics = _analyzeString(string);

      // Prepare export data
      final exportData = <String, dynamic>{
        'metadata': _createMetadata(string),
        'analytics': analytics.toJson(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to file
      final file = await _getExportFile(
        filename:
            filename ??
            'string_analytics_${_safePrefix(string.initialKnot.agentId, 8)}.json',
      );

      await file.writeAsString(jsonString);

      developer.log(
        '✅ Exported string analytics: ${file.path}',
        name: _logName,
      );

      return file.path;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to export string analytics: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Create metadata for export
  StringExportMetadata _createMetadata(KnotString string) {
    DateTime startTime;
    DateTime endTime;

    if (string.snapshots.isEmpty) {
      startTime = DateTime.now();
      endTime = DateTime.now();
    } else {
      final sorted = List.from(string.snapshots)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      startTime = sorted.first.timestamp;
      endTime = sorted.last.timestamp;
    }

    return StringExportMetadata(
      agentId: string.initialKnot.agentId,
      startTime: startTime,
      endTime: endTime,
      snapshotCount: string.snapshots.length,
      patternTypes: _detectPatternTypes(string),
      exportedAt: DateTime.now(),
    );
  }

  /// Analyze string for patterns, trends, and milestones
  StringAnalytics _analyzeString(KnotString string) {
    final patterns = <String>[];
    final trends = <String, String>{};
    final milestones = <Map<String, dynamic>>[];

    if (string.snapshots.length < 2) {
      return StringAnalytics(
        patterns: patterns,
        trends: trends,
        milestones: milestones,
        evolutionRate: 0.0,
      );
    }

    final sorted = List.from(string.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Detect trends
    final initialCrossing = string.initialKnot.invariants.crossingNumber;
    final finalCrossing = sorted.last.knot.invariants.crossingNumber;

    if (finalCrossing > initialCrossing) {
      trends['crossing_number'] = 'increasing';
      patterns.add('complexity_increase');
    } else if (finalCrossing < initialCrossing) {
      trends['crossing_number'] = 'decreasing';
      patterns.add('complexity_decrease');
    } else {
      trends['crossing_number'] = 'stable';
    }

    // Detect milestones (significant changes)
    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1].knot;
      final curr = sorted[i].knot;

      final crossingChange =
          (curr.invariants.crossingNumber - prev.invariants.crossingNumber)
              .abs();
      if (crossingChange >= 2) {
        milestones.add({
          'timestamp': sorted[i].timestamp.toIso8601String(),
          'type': 'crossing_change',
          'magnitude': crossingChange,
          'reason': sorted[i].reason,
        });
      }
    }

    // Calculate evolution rate
    final timeSpan = sorted.last.timestamp.difference(sorted.first.timestamp);
    final evolutionRate = timeSpan.inMilliseconds > 0
        ? sorted.length / (timeSpan.inDays + 1)
        : 0.0;

    return StringAnalytics(
      patterns: patterns,
      trends: trends,
      milestones: milestones,
      evolutionRate: evolutionRate,
    );
  }

  /// Detect pattern types in string
  List<String> _detectPatternTypes(KnotString string) {
    final patterns = <String>[];

    if (string.snapshots.isEmpty) {
      return patterns;
    }

    // Check for cycles (repeating patterns)
    if (string.snapshots.length >= 4) {
      patterns.add('potential_cycles');
    }

    // Check for trends
    final sorted = List.from(string.snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sorted.length >= 2) {
      final initial = sorted.first.knot.invariants.crossingNumber;
      final final_ = sorted.last.knot.invariants.crossingNumber;

      if (final_ > initial) {
        patterns.add('increasing_complexity');
      } else if (final_ < initial) {
        patterns.add('decreasing_complexity');
      }
    }

    return patterns;
  }

  /// Get export file
  Future<File> _getExportFile({required String filename}) async {
    final exportDir = Directory(
      '${Directory.systemTemp.path}/avrai_string_exports',
    );

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return File('${exportDir.path}/$filename');
  }
}
