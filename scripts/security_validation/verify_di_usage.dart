#!/usr/bin/env dart
// ignore_for_file: avoid_print
library;

/// Security Validation Script
/// 
/// Verifies all services use DI for AgentIdService:
/// - No direct instantiations
/// - All use di.sl&lt;AgentIdService&gt;() or sl&lt;AgentIdService&gt;()
/// 
/// Usage: dart scripts/security_validation/verify_di_usage.dart

import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  print('🔒 Security Validation: DI Usage Verification\n');
  
  // Get project root (assuming script is in scripts/security_validation/)
  final scriptPath = Platform.script.toFilePath();
  final scriptDir = path.dirname(scriptPath);
  final projectRoot = path.dirname(path.dirname(scriptDir));
  
  final libDir = Directory(path.join(projectRoot, 'lib'));
  
  if (!await libDir.exists()) {
    print('❌ Error: lib directory not found');
    exit(1);
  }
  
  final dartFiles = await _findDartFiles(libDir);
  final issues = <String>[];
  int totalFiles = 0;
  int filesWithDi = 0;
  
  for (final file in dartFiles) {
    final content = await file.readAsString();
    
    // Check for AgentIdService usage
    if (content.contains('AgentIdService')) {
      totalFiles++;
      
      // Check for direct instantiation
      if (content.contains('AgentIdService()') && 
          !content.contains('di.sl<AgentIdService>()') &&
          !content.contains('sl<AgentIdService>()') &&
          !content.contains('GetIt.instance<AgentIdService>()')) {
        // Check if it's in a comment
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains('AgentIdService()') &&
              !lines[i].trim().startsWith('//') &&
              !lines[i].contains('di.sl') &&
              !lines[i].contains('sl<') &&
              !lines[i].contains('GetIt.instance')) {
            issues.add('${file.path}:${i + 1}');
          }
        }
      }
      
      // Check for DI usage
      if (content.contains('di.sl<AgentIdService>()') ||
          content.contains('sl<AgentIdService>()') ||
          content.contains('GetIt.instance<AgentIdService>()')) {
        filesWithDi++;
      }
    }
  }
  
  print('📊 Statistics:');
  print('   Total files using AgentIdService: $totalFiles');
  print('   Files using DI: $filesWithDi');
  print('   Direct instantiations found: ${issues.length}');
  
  if (issues.isNotEmpty) {
    print('\n❌ Direct instantiations found:');
    for (final issue in issues) {
      print('   - $issue');
    }
    exit(1);
  } else {
    print('\n✅ All services use DI for AgentIdService!');
  }
}

Future<List<File>> _findDartFiles(Directory dir) async {
  final files = <File>[];
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity);
    }
  }
  
  return files;
}
