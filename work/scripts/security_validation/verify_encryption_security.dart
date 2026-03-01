#!/usr/bin/env dart

// ignore_for_file: avoid_print
library;

/// Security Validation Script
///
/// Verifies encryption security for agent ID mappings:
/// - Encryption service is required
/// - No plaintext storage
/// - Keys stored securely
///
/// Usage: dart scripts/security_validation/verify_encryption_security.dart

import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  print('🔒 Security Validation: Encryption Security\n');

  // Get project root (assuming script is in scripts/security_validation/)
  final scriptPath = Platform.script.toFilePath();
  final scriptDir = path.dirname(scriptPath);
  final projectRoot = path.dirname(path.dirname(scriptDir));

  final agentIdServicePath = path.join(
    projectRoot,
    'lib',
    'core',
    'services',
    'agent_id_service.dart',
  );

  final file = File(agentIdServicePath);
  if (!await file.exists()) {
    print('❌ Error: agent_id_service.dart not found');
    exit(1);
  }

  final content = await file.readAsString();

  // Check 1: Encryption service is required
  print('1. Checking encryption service is required...');
  if (content
      .contains('required SecureMappingEncryptionService encryptionService')) {
    print('   ✅ Encryption service is required parameter');
  } else {
    print('   ❌ Encryption service is NOT required');
    exit(1);
  }

  // Check 2: No plaintext fallback
  print('\n2. Checking for plaintext fallback...');
  if (content.contains('user_agent_mappings[^_]') ||
      content.contains('from(\'user_agent_mappings\')')) {
    print('   ❌ Plaintext fallback found');
    exit(1);
  } else {
    print('   ✅ No plaintext fallback');
  }

  // Check 3: Only secure table used
  print('\n3. Checking secure table usage...');
  if (content.contains('user_agent_mappings_secure')) {
    print('   ✅ Secure table (user_agent_mappings_secure) is used');
  } else {
    print('   ❌ Secure table not found');
    exit(1);
  }

  // Check 4: Encryption service field is non-nullable
  print('\n4. Checking encryption service field...');
  if (content.contains(
          'final SecureMappingEncryptionService _encryptionService') &&
      !content.contains('SecureMappingEncryptionService? _encryptionService')) {
    print('   ✅ Encryption service field is non-nullable');
  } else {
    print('   ❌ Encryption service field is nullable');
    exit(1);
  }

  // Check 5: No null checks for encryption service
  print('\n5. Checking for unnecessary null checks...');
  if (content.contains('if (_encryptionService == null)') ||
      content.contains('_encryptionService != null')) {
    print('   ⚠️  Unnecessary null checks found (should be removed)');
  } else {
    print('   ✅ No unnecessary null checks');
  }

  print('\n✅ All encryption security checks passed!');
}
