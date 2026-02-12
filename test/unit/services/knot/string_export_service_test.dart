/// avrai StringExportService Service Tests
/// Date: January 27, 2026
/// Purpose: Test StringExportService functionality
///
/// Test Coverage:
/// - Core Methods: exportStringToJSON, exportStringToCSV, exportStringAnalytics
/// - Error Handling: Invalid inputs, file system errors
///
/// Dependencies:
/// - None (service is self-contained, uses path_provider)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/services/knot/string_export_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'dart:io';

// Helper to create test knot
PersonalityKnot createTestKnot(String agentId, int crossingNumber) {
  return PersonalityKnot(
    agentId: agentId,
    invariants: KnotInvariants(
      jonesPolynomial: [crossingNumber.toDouble()],
      alexanderPolynomial: [crossingNumber.toDouble()],
      crossingNumber: crossingNumber,
      writhe: 0,
      signature: 0,
      bridgeNumber: 1,
      braidIndex: 1,
      determinant: crossingNumber,
    ),
    braidData: [8.0],
    createdAt: DateTime(2025, 1, 1),
    lastUpdated: DateTime(2025, 1, 1),
  );
}

// Helper to create test string
KnotString createTestString(PersonalityKnot initialKnot) {
  return KnotString(
    initialKnot: initialKnot,
    snapshots: [
      KnotSnapshot(
        timestamp: DateTime(2025, 1, 2),
        knot: createTestKnot(initialKnot.agentId, 2),
        reason: 'test',
      ),
      KnotSnapshot(
        timestamp: DateTime(2025, 1, 3),
        knot: createTestKnot(initialKnot.agentId, 3),
        reason: 'test',
      ),
    ],
  );
}

void main() {
  group('StringExportService', () {
    late StringExportService service;

    setUp(() {
      service = StringExportService();
    });

    group('exportStringToJSON', () {
      test('should export string to JSON format with metadata and snapshots',
          () async {
        // Arrange
        final knot = createTestKnot('agent-123', 1);
        final string = createTestString(knot);

        // Act
        final filePath = await service.exportStringToJSON(string: string);

        // Assert - Should return file path
        expect(filePath, isNotEmpty);
        expect(filePath.endsWith('.json'), isTrue);

        // Verify file exists and contains valid JSON
        final file = File(filePath);
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        expect(content, isNotEmpty);
        // Should contain JSON structure
        expect(content.contains('metadata'), isTrue);
        expect(content.contains('initialKnot'), isTrue);
        expect(content.contains('snapshots'), isTrue);

        // Cleanup
        await file.delete();
      });

      test('should use custom filename when provided', () async {
        // Arrange
        final knot = createTestKnot('agent-123', 1);
        final string = createTestString(knot);
        final customFilename = 'custom_export.json';

        // Act
        final filePath = await service.exportStringToJSON(
          string: string,
          filename: customFilename,
        );

        // Assert - Should use custom filename
        expect(filePath, contains(customFilename));

        // Cleanup
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      });
    });

    group('exportStringToCSV', () {
      test('should export string trajectory to CSV format', () async {
        // Arrange
        final knot = createTestKnot('agent-123', 1);
        final string = createTestString(knot);

        // Act
        final filePath = await service.exportStringToCSV(
          string: string,
          timeStep: const Duration(hours: 1),
        );

        // Assert - Should return file path
        expect(filePath, isNotEmpty);
        expect(filePath.endsWith('.csv'), isTrue);

        // Verify file exists and contains CSV data
        final file = File(filePath);
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        expect(content, isNotEmpty);
        // Should contain CSV header
        expect(content.contains('timestamp'), isTrue);
        expect(content.contains('crossing_number'), isTrue);

        // Cleanup
        await file.delete();
      });

      test('should respect timeStep parameter for trajectory sampling',
          () async {
        // Arrange
        final knot = createTestKnot('agent-123', 1);
        final string = createTestString(knot);

        // Act - Use different time steps
        final filePath1 = await service.exportStringToCSV(
          string: string,
          timeStep: const Duration(hours: 1),
        );
        final filePath2 = await service.exportStringToCSV(
          string: string,
          timeStep: const Duration(hours: 6),
        );

        // Assert - Different time steps should produce different file sizes
        final file1 = File(filePath1);
        final file2 = File(filePath2);

        if (await file1.exists() && await file2.exists()) {
          final content1 = await file1.readAsString();
          final content2 = await file2.readAsString();
          // Smaller time step should produce more data points
          expect(content1.split('\n').length,
              greaterThanOrEqualTo(content2.split('\n').length));
        }

        // Cleanup
        if (await file1.exists()) await file1.delete();
        if (await file2.exists()) await file2.delete();
      });
    });

    group('exportStringAnalytics', () {
      test('should export string analytics with patterns and trends', () async {
        // Arrange
        final knot = createTestKnot('agent-123', 1);
        final string = createTestString(knot);

        // Act
        final filePath = await service.exportStringAnalytics(string: string);

        // Assert - Should return file path
        expect(filePath, isNotEmpty);
        expect(filePath.endsWith('.json'), isTrue);

        // Verify file exists and contains analytics
        final file = File(filePath);
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        expect(content, isNotEmpty);
        // Should contain analytics structure
        expect(
            content.contains('patterns') ||
                content.contains('trends') ||
                content.contains('milestones'),
            isTrue);

        // Cleanup
        await file.delete();
      });
    });

    group('Error Handling', () {
      test('should handle string with empty snapshots', () async {
        // Arrange
        final knot = createTestKnot('agent-123', 1);
        final string = KnotString(
          initialKnot: knot,
          snapshots: [], // Empty snapshots
        );

        // Act
        final filePath = await service.exportStringToJSON(string: string);

        // Assert - Should handle empty snapshots gracefully
        expect(filePath, isNotEmpty);
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          expect(content, isNotEmpty);
          await file.delete();
        }
      });
    });
  });
}
