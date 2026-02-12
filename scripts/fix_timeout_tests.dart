#!/usr/bin/env dart
// ignore_for_file: avoid_print
// scripts/fix_timeout_tests.dart
// Analyzes and fixes testWidgets that should be converted to test

import 'dart:io';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final autoFix = args.contains('--fix');
  
  print('🔍 Scanning for timeout-prone tests...\n');
  
  final testDir = Directory('test/integration');
  if (!await testDir.exists()) {
    print('❌ test/integration directory not found');
    exit(1);
  }
  
  final issues = <TestIssue>[];
  
  for (final file in testDir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('_test.dart')) {
      final issuesInFile = analyzeFile(file);
      issues.addAll(issuesInFile);
    }
  }
  
  print('📊 Analysis Results:\n');
  print('Found ${issues.length} potential timeout issues:\n');
  
  for (final issue in issues) {
    print('${issue.severity} ${issue.file.path}:${issue.lineNumber}');
    print('  Test: ${issue.testName}');
    print('  Issue: ${issue.description}');
    print('');
  }
  
  if (autoFix && !dryRun) {
    print('🔧 Applying fixes...\n');
    for (final issue in issues) {
      fixIssue(issue);
    }
    print('✅ Fixes applied. Run tests to verify.');
  } else if (dryRun) {
    print('ℹ️  Dry run mode - no changes made');
    print('Run with --fix to apply changes');
  } else {
    print('ℹ️  Run with --fix to apply fixes automatically');
  }
}

List<TestIssue> analyzeFile(File file) {
  final issues = <TestIssue>[];
  final content = file.readAsStringSync();
  final lines = content.split('\n');
  
  int lineNumber = 0;
  for (final line in lines) {
    lineNumber++;
    
    // Find testWidgets declarations
    if (line.contains('testWidgets(') && line.contains('tester')) {
      // Extract test name (simple extraction between quotes)
      String? testName;
      final singleQuoteMatch = RegExp(r"'([^']+)'").firstMatch(line);
      final doubleQuoteMatch = RegExp(r'"([^"]+)"').firstMatch(line);
      testName = singleQuoteMatch?.group(1) ?? doubleQuoteMatch?.group(1);
      
      // Find the test body (next 100 lines or until closing brace)
      final testBody = <String>[];
      int braceCount = 0;
      bool inTest = false;
      
      for (int i = lineNumber - 1; i < lines.length && i < lineNumber + 100; i++) {
        final currentLine = lines[i];
        if (currentLine.contains('testWidgets(')) {
          inTest = true;
          braceCount = currentLine.split('{').length - currentLine.split('}').length;
        } else if (inTest) {
          testBody.add(currentLine);
          braceCount += currentLine.split('{').length - currentLine.split('}').length;
          if (braceCount <= 0) break;
        }
      }
      
      final bodyText = testBody.join('\n');
      
      // Check if tester is actually used for widget operations
      final usesTester = bodyText.contains(RegExp(r'\btester\.(pump|tap|drag|enterText|find|getCenter|getSize|takeException|allWidgets|allElements|widget|element|binding)'));
      final usesFind = bodyText.contains(RegExp(r'\bfind\.'));
      final usesPumpWidget = bodyText.contains('pumpWidget') || bodyText.contains('pumpAndSettle');
      
      if (!usesTester && !usesFind && !usesPumpWidget) {
        // Check if it only calls helper functions (business logic)
        final hasHelperCalls = bodyText.contains(RegExp(r'await\s+_[a-zA-Z]+\('));
        final hasDirectWidgetOps = bodyText.contains(RegExp(r'(pumpWidget|pumpAndSettle|tester\.tap|tester\.drag|tester\.enterText)'));
        
        if (hasHelperCalls && !hasDirectWidgetOps) {
          issues.add(TestIssue(
            file: file,
            lineNumber: lineNumber,
            testName: testName ?? 'Unknown',
            description: 'testWidgets declared but tester parameter never used - only calls helper functions',
            severity: '⚠️',
            fix: () => convertTestWidgetsToTest(file, lineNumber, testName ?? 'Unknown'),
          ));
        }
      }
    }
  }
  
  return issues;
}

void convertTestWidgetsToTest(File file, int lineNumber, String testName) {
  final content = file.readAsStringSync();
  final lines = content.split('\n');
  
  // Find the testWidgets line
  final line = lines[lineNumber - 1];
  
  // Replace testWidgets with test and remove tester parameter
  final fixedLine = line
      .replaceAll('testWidgets', 'test')
      .replaceAll(RegExp(r'\([^)]*tester[^)]*\)'), '()');
  
  lines[lineNumber - 1] = fixedLine;
  
  file.writeAsStringSync(lines.join('\n'));
  print('  ✅ Fixed: ${file.path}:$lineNumber');
}

void fixIssue(TestIssue issue) {
  issue.fix();
}

class TestIssue {
  final File file;
  final int lineNumber;
  final String testName;
  final String description;
  final String severity;
  final void Function() fix;
  
  TestIssue({
    required this.file,
    required this.lineNumber,
    required this.testName,
    required this.description,
    required this.severity,
    required this.fix,
  });
}

