import 'dart:io';
// ignore_for_file: avoid_print - Script file
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Helper script to generate password hash for business credentials
/// 
/// Usage:
///   dart run scripts/add_business_credential.dart &lt;business_id&gt; &lt;username&gt; &lt;password&gt;
/// 
/// This will output the SQL INSERT statement to add the credential to Supabase.
/// 
/// Example:
///   dart run scripts/add_business_credential.dart business_abc123 mybusiness mySecurePassword123
void main(List<String> args) {
  if (args.length < 3) {
    print('Usage: dart run scripts/add_business_credential.dart <business_id> <username> <password>');
    print('');
    print('Example:');
    print('  dart run scripts/add_business_credential.dart business_abc123 mybusiness mySecurePassword123');
    exit(1);
  }

  final businessId = args[0];
  final username = args[1];
  final password = args[2];

  // Hash password using SHA-256 (same as used in BusinessAuthService)
  final bytes = utf8.encode(password);
  final hash = sha256.convert(bytes);
  final passwordHash = hash.toString();

  print('');
  print('=' * 60);
  print('Business Credential SQL');
  print('=' * 60);
  print('');
  print('Run this SQL in your Supabase SQL Editor:');
  print('');
  print('INSERT INTO business_credentials (business_id, username, password_hash, is_active)');
  print("VALUES ('$businessId', '$username', '$passwordHash', true);");
  print('');
  print('=' * 60);
  print('');
  print('⚠️  SECURITY WARNING:');
  print('   - Keep this password secure');
  print('   - Never commit credentials to version control');
  print('   - Use strong passwords (12+ characters, mixed case, numbers, symbols)');
  print('   - Consider enabling 2FA for additional security');
  print('');
}

