#!/usr/bin/env dart
// ignore_for_file: avoid_print
library;

/// SPOTS Test Quality Checker
/// 
/// Analyzes test files for quality issues and anti-patterns
/// 
/// Usage:
///   dart run scripts/check_test_quality.dart [file_or_directory]
/// 
/// Examples:
///   dart run scripts/check_test_quality.dart test/unit/models/spot_test.dart
///   dart run scripts/check_test_quality.dart test/unit/models/
///   dart run scripts/check_test_quality.dart  # checks all test files
/// 
/// See: docs/plans/test_refactoring/PHASE_6_CONTINUOUS_IMPROVEMENT_PLAN.md

import 'dart:io';

class TestQualityChecker {
  final String filePath;
  final List<String> lines;
  final List<QualityIssue> issues = [];

  TestQualityChecker(this.filePath) : lines = File(filePath).readAsLinesSync();

  void analyze() {
    _checkPropertyAssignments();
    _checkConstructorOnlyTests();
    _checkFieldByFieldJsonTests();
    _checkTrivialNullChecks();
    _checkMissingDocumentation();
    _checkTestConsolidation();
  }

  void _checkPropertyAssignments() {
    int propertyChecks = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains(RegExp(r'expect\(.*\.(equals|isNotNull|isNull)'))) {
        propertyChecks++;
      }
    }

    if (propertyChecks > 5) {
      issues.add(QualityIssue(
        severity: IssueSeverity.warning,
        type: IssueType.propertyAssignment,
        message: 'Found $propertyChecks property-assignment checks',
        suggestion: 'Consider testing behavior instead of property values',
        lineCount: propertyChecks,
      ));
    }
  }

  void _checkConstructorOnlyTests() {
    int constructorTests = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains(RegExp(
          r'test.*should (create|instantiate|be created|can be created)'))) {
        constructorTests++;
      }
    }

    if (constructorTests > 0) {
      issues.add(QualityIssue(
        severity: IssueSeverity.warning,
        type: IssueType.constructorOnly,
        message: 'Found $constructorTests constructor-only test(s)',
        suggestion: 'Consider testing behavior instead of instantiation',
        lineCount: constructorTests,
      ));
    }
  }

  void _checkFieldByFieldJsonTests() {
    int jsonFieldChecks = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Check for individual JSON field checks (expect(json['field'] or expect(json["field"]))
      if (line.contains(RegExp(r'expect\(.*json\[[' r'"' r"'" r']'))) {
        jsonFieldChecks++;
      }
    }

    if (jsonFieldChecks > 3) {
      issues.add(QualityIssue(
        severity: IssueSeverity.warning,
        type: IssueType.fieldByFieldJson,
        message: 'Found $jsonFieldChecks individual JSON field checks',
        suggestion: 'Consider using round-trip JSON test instead',
        lineCount: jsonFieldChecks,
      ));
    }
  }

  void _checkTrivialNullChecks() {
    int trivialChecks = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains(RegExp(r'expect\(.*(isNotNull|isNull)'))) {
        // Check if it's part of a behavior test or standalone
        bool isStandalone = true;
        for (int j = i - 5; j < i && j >= 0; j++) {
          if (lines[j].contains(RegExp(r'(when|then|verify|should)'))) {
            isStandalone = false;
            break;
          }
        }
        if (isStandalone) {
          trivialChecks++;
        }
      }
    }

    if (trivialChecks > 3) {
      issues.add(QualityIssue(
        severity: IssueSeverity.warning,
        type: IssueType.trivialNullCheck,
        message: 'Found $trivialChecks trivial null checks',
        suggestion: 'Consider testing actual behavior instead',
        lineCount: trivialChecks,
      ));
    }
  }

  void _checkMissingDocumentation() {
    bool hasHeader = false;
    bool hasPurpose = false;

    for (int i = 0; i < lines.length && i < 20; i++) {
      final line = lines[i];
      if (line.contains(RegExp(r'///.*SPOTS|///.*Test'))) {
        hasHeader = true;
      }
      if (line.contains(RegExp(r'///.*Purpose|///.*Test Coverage'))) {
        hasPurpose = true;
      }
    }

    if (!hasHeader || !hasPurpose) {
      issues.add(QualityIssue(
        severity: IssueSeverity.info,
        type: IssueType.missingDocumentation,
        message: 'Missing or incomplete test file documentation header',
        suggestion: 'Add file header with purpose and test coverage',
        lineCount: 0,
      ));
    }
  }

  void _checkTestConsolidation() {
    // Look for multiple similar tests that could be consolidated
    final testNames = <String>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Match test('name') or testWidgets('name') patterns
      final match = RegExp(r'test(Widgets)?\([' r'"' r"'" r'](.*?)[' r'"' r"'" r']\)').firstMatch(line);
      if (match != null && match.groupCount >= 2) {
        testNames.add(match.group(2) ?? '');
      }
    }

    // Check for similar test names (potential consolidation)
    final similarTests = <List<String>>[];
    for (int i = 0; i < testNames.length; i++) {
      for (int j = i + 1; j < testNames.length; j++) {
        if (_areSimilar(testNames[i], testNames[j])) {
          similarTests.add([testNames[i], testNames[j]]);
        }
      }
    }

    if (similarTests.length > 2) {
      issues.add(QualityIssue(
        severity: IssueSeverity.info,
        type: IssueType.consolidationOpportunity,
        message: 'Found ${similarTests.length} pairs of similar tests',
        suggestion: 'Consider consolidating similar tests into comprehensive test blocks',
        lineCount: similarTests.length,
      ));
    }
  }

  bool _areSimilar(String a, String b) {
    // Simple similarity check - tests with many common words
    final wordsA = a.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
    final wordsB = b.toLowerCase().split(RegExp(r'[^a-z0-9]+'));

    int commonWords = 0;
    for (final word in wordsA) {
      if (word.length > 3 && wordsB.contains(word)) {
        commonWords++;
      }
    }

    return commonWords >= 2;
  }

  QualityReport generateReport() {
    return QualityReport(
      filePath: filePath,
      issues: issues,
      totalLines: lines.length,
      testCount: lines.where((l) => l.contains(RegExp(r'^\s*test(Widgets)?\('))).length,
    );
  }
}

class QualityIssue {
  final IssueSeverity severity;
  final IssueType type;
  final String message;
  final String suggestion;
  final int lineCount;

  QualityIssue({
    required this.severity,
    required this.type,
    required this.message,
    required this.suggestion,
    required this.lineCount,
  });
}

enum IssueSeverity { error, warning, info }

enum IssueType {
  propertyAssignment,
  constructorOnly,
  fieldByFieldJson,
  trivialNullCheck,
  missingDocumentation,
  consolidationOpportunity,
}

class QualityReport {
  final String filePath;
  final List<QualityIssue> issues;
  final int totalLines;
  final int testCount;

  QualityReport({
    required this.filePath,
    required this.issues,
    required this.totalLines,
    required this.testCount,
  });

  double get qualityScore {
    if (issues.isEmpty) return 10.0;

    double score = 10.0;
    for (final issue in issues) {
      switch (issue.severity) {
        case IssueSeverity.error:
          score -= 2.0;
          break;
        case IssueSeverity.warning:
          score -= 1.0;
          break;
        case IssueSeverity.info:
          score -= 0.5;
          break;
      }
    }

    return score.clamp(0.0, 10.0);
  }

  void printReport() {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Test Quality Report: ${filePath.split('/').last}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📁 File: $filePath');
    print('📏 Lines: $totalLines | Tests: $testCount');
    print('⭐ Quality Score: ${qualityScore.toStringAsFixed(1)}/10.0');
    print('');

    if (issues.isEmpty) {
      print('✅ No issues found!');
      print('');
      return;
    }

    print('🔍 Issues Found: ${issues.length}');
    print('');

    for (final issue in issues) {
      final icon = issue.severity == IssueSeverity.error
          ? '❌'
          : issue.severity == IssueSeverity.warning
              ? '⚠️'
              : 'ℹ️';
      print('$icon ${issue.type.name.toUpperCase().replaceAll('_', ' ')}');
      print('   Message: ${issue.message}');
      print('   Suggestion: ${issue.suggestion}');
      if (issue.lineCount > 0) {
        print('   Count: ${issue.lineCount}');
      }
      print('');
    }

    print('📚 Resources:');
    print('   • Test Writing Guide: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md');
    print('   • Quick Reference: docs/plans/test_refactoring/TEST_QUALITY_QUICK_REFERENCE.md');
    print('   • Refactoring Plan: docs/plans/test_refactoring/TEST_REFACTORING_PLAN.md');
    print('');
  }
}

void main(List<String> args) {
  final target = args.isNotEmpty ? args[0] : 'test';

  final List<FileSystemEntity> files = [];
  if (FileSystemEntity.isFileSync(target)) {
    files.add(File(target));
  } else if (FileSystemEntity.isDirectorySync(target)) {
    files.addAll(_findTestFiles(Directory(target)));
  } else {
    // Default: check all test files
    files.addAll(_findTestFiles(Directory('test')));
  }

  if (files.isEmpty) {
    print('❌ No test files found');
    exit(1);
  }

  print('🔍 Analyzing ${files.length} test file(s)...\n');

  final reports = <QualityReport>[];
  for (final file in files) {
    try {
      final checker = TestQualityChecker(file.path);
      checker.analyze();
      final report = checker.generateReport();
      reports.add(report);
      report.printReport();
    } catch (e) {
      print('❌ Error analyzing ${file.path}: $e');
    }
  }

  // Summary
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 Summary');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Files analyzed: ${reports.length}');
  print('Average quality score: ${(reports.map((r) => r.qualityScore).reduce((a, b) => a + b) / reports.length).toStringAsFixed(1)}/10.0');
  print('Files with issues: ${reports.where((r) => r.issues.isNotEmpty).length}');
  print('Total issues: ${reports.map((r) => r.issues.length).reduce((a, b) => a + b)}');
  print('');
}

List<File> _findTestFiles(Directory dir) {
  final files = <File>[];
  try {
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        files.add(entity);
      }
    }
  } catch (e) {
    // Ignore permission errors
  }
  return files;
}
