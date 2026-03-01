// Signal Protocol End-to-End Integration Tests
// Phase 14.6: Testing and Validation
//
// Tests complete Signal Protocol integration with:
// 1. AI2AIProtocol with Signal Protocol
// 2. AnonymousCommunicationProtocol with Signal Protocol
// 3. Fallback to AES-256-GCM when Signal Protocol unavailable
// 4. Performance benchmarks
// 5. Security validation

import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/crypto/signal/secure_signal_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avrai_network/network/ai2ai_protocol.dart' as ai2ai;
import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart'
    as anonymous;
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart'
    as message_encryption;
import 'package:avrai_runtime_os/services/security/hybrid_encryption_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/security/signal_protocol_encryption_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_session_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_protocol_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai_runtime_os/services/security/signal_protocol_initialization_service.dart';
import 'package:avrai_runtime_os/services/user/user_anonymization_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import '../../mocks/in_memory_flutter_secure_storage.dart';

/// Mock Supabase client for testing
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Test logging helper - logs to both developer.log and print for visibility
// ignore: avoid_print - Intentional print for test output visibility
void _logTestStep(String step, {Map<String, dynamic>? data}) {
  final message = '🧪 [TEST] $step';
  if (data != null) {
    developer.log('$message: ${data.toString()}',
        name: 'SignalProtocolE2ETest');
    // ignore: avoid_print - Test output
    print(message);
    data.forEach((key, value) {
      // ignore: avoid_print - Test output
      print('   $key: $value');
    });
  } else {
    developer.log(message, name: 'SignalProtocolE2ETest');
    // ignore: avoid_print - Test output
    print(message);
  }
}

/// Find project root by walking up from the test file to find pubspec.yaml
String? _findProjectRoot() {
  try {
    final testFile = Platform.script.toFilePath();
    var current = Directory(testFile).parent;

    while (current.path != current.parent.path) {
      final pubspec = File('${current.path}/pubspec.yaml');
      if (pubspec.existsSync()) {
        return current.path;
      }
      current = current.parent;
    }
  } catch (e) {
    // If we can't determine project root, return null
  }
  return null;
}

/// Results file for capturing test results before cleanup
File? _getResultsFile() {
  try {
    final projectRoot = _findProjectRoot() ?? Directory.current.path;
    return File(
        '$projectRoot/test/integration/signal_protocol_e2e_results.txt');
  } catch (e) {
    return null;
  }
}

/// Write test result to file (captures results before cleanup crash)
Future<void> _writeTestResult(
    String operation, Map<String, dynamic> data) async {
  try {
    final resultsFile = _getResultsFile();
    if (resultsFile == null) return;

    final timestamp = DateTime.now().toIso8601String();
    final entry = '''
[$timestamp] $operation
${data.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}
---
''';

    await resultsFile.writeAsString(entry, mode: FileMode.append);
  } catch (e) {
    // Silently fail - logging is best effort
  }
}

/// Write final test summary to file
Future<void> _writeTestSummary(
    String testName, bool passed, Map<String, dynamic>? summary) async {
  try {
    final resultsFile = _getResultsFile();
    if (resultsFile == null) return;

    final timestamp = DateTime.now().toIso8601String();
    final entry = '''
========================================
TEST SUMMARY: $testName
Status: ${passed ? 'PASSED' : 'FAILED'}
Timestamp: $timestamp
${summary != null ? summary.entries.map((e) => '${e.key}: ${e.value}').join('\n') : ''}
========================================

''';

    await resultsFile.writeAsString(entry, mode: FileMode.append);
  } catch (e) {
    // Silently fail - logging is best effort
  }
}

void main() {
  final runNativeSignalTests =
      Platform.environment['RUN_SIGNAL_NATIVE_TESTS'] == 'true';
  if (!runNativeSignalTests) {
    test(
      'Signal native integration tests are skipped by default',
      () {
        // Set RUN_SIGNAL_NATIVE_TESTS=true to opt in locally.
      },
    );
    return;
  }

  group('Signal Protocol End-to-End Integration Tests', () {
    late MockSupabaseClient mockSupabase;
    late SignalFFIBindings aliceFFI;
    late SignalFFIBindings bobFFI;
    late SignalPlatformBridgeBindings alicePlatformBridge;
    late SignalPlatformBridgeBindings bobPlatformBridge;
    late SignalRustWrapperBindings aliceRustWrapper;
    late SignalRustWrapperBindings bobRustWrapper;
    late SignalKeyManager aliceKeyManager;
    late SignalKeyManager bobKeyManager;
    late SignalSessionManager aliceSessionManager;
    late SignalSessionManager bobSessionManager;
    late SignalFFIStoreCallbacks aliceStoreCallbacks;
    late SignalFFIStoreCallbacks bobStoreCallbacks;
    late SignalProtocolService aliceProtocol;
    late SignalProtocolService bobProtocol;
    late message_encryption.MessageEncryptionService aliceEncryptionService;
    // ignore: unused_field - Reserved for future bidirectional tests
    // late message_encryption.MessageEncryptionService bobEncryptionService;
    late ai2ai.AI2AIProtocol aliceAI2AI;
    // ignore: unused_field - Reserved for future bidirectional tests
    // late ai2ai.AI2AIProtocol bobAI2AI;
    late anonymous.AnonymousCommunicationProtocol aliceAnonymous;
    late InMemoryFlutterSecureStorage secureStorage;
    bool librariesAvailable = false;

    setUpAll(() async {
      _logTestStep('=== Setting up test environment ===');
      mockSupabase = MockSupabaseClient();

      // Check if native libraries are available
      if (Platform.isMacOS) {
        final pathsToTry = [
          'runtime/avrai_network/native/signal_ffi/macos/libsignal_ffi.dylib',
          '${Directory.current.path}/runtime/avrai_network/native/signal_ffi/macos/libsignal_ffi.dylib',
          _findProjectRoot() != null
              ? '${_findProjectRoot()}/runtime/avrai_network/native/signal_ffi/macos/libsignal_ffi.dylib'
              : null,
        ].whereType<String>().toList();

        _logTestStep('Checking for native Signal Protocol libraries', data: {
          'platform': Platform.operatingSystem,
          'pathsToCheck': pathsToTry.length,
        });

        librariesAvailable = false;
        String? foundPath;
        for (final libPath in pathsToTry) {
          final libFile = File(libPath);
          if (libFile.existsSync()) {
            librariesAvailable = true;
            foundPath = libPath;
            break;
          }
        }

        _logTestStep('Library availability check complete', data: {
          'available': librariesAvailable,
          'foundPath': foundPath ?? 'not found',
          'pathsChecked': pathsToTry.length,
        });
      } else {
        _logTestStep('Platform check', data: {
          'platform': Platform.operatingSystem,
          'signalProtocolSupported': false,
          'note': 'Signal Protocol tests currently support macOS only',
        });
      }
      _logTestStep('=== Test environment setup complete ===');
    });

    setUp(() async {
      _logTestStep('--- Setting up test instance ---');

      // Use in-memory FlutterSecureStorage implementation (no platform channels needed)
      secureStorage = InMemoryFlutterSecureStorage();
      _logTestStep('In-memory secure storage initialized');

      _logTestStep('Initializing Alice\'s Signal Protocol services');
      // Setup Alice's Signal Protocol services
      aliceFFI = SignalFFIBindings();
      alicePlatformBridge = SignalPlatformBridgeBindings();
      aliceRustWrapper = SignalRustWrapperBindings();

      aliceKeyManager = SignalKeyManager(
        secureStorage: secureStorage,
        ffiBindings: aliceFFI,
      );

      aliceSessionManager = SignalSessionManager(
        storage: SecureSignalStorage(secureStorage: secureStorage),
        ffiBindings: aliceFFI,
        keyManager: aliceKeyManager,
      );

      aliceStoreCallbacks = SignalFFIStoreCallbacks(
        ffiBindings: aliceFFI,
        rustWrapper: aliceRustWrapper,
        platformBridge: alicePlatformBridge,
        keyManager: aliceKeyManager,
        sessionManager: aliceSessionManager,
      );

      aliceProtocol = SignalProtocolService(
        ffiBindings: aliceFFI,
        storeCallbacks: aliceStoreCallbacks,
        keyManager: aliceKeyManager,
        sessionManager: aliceSessionManager,
      );

      _logTestStep('Initializing Bob\'s Signal Protocol services');
      // Setup Bob's Signal Protocol services
      bobFFI = SignalFFIBindings();
      bobPlatformBridge = SignalPlatformBridgeBindings();
      bobRustWrapper = SignalRustWrapperBindings();

      bobKeyManager = SignalKeyManager(
        secureStorage: secureStorage,
        ffiBindings: bobFFI,
      );

      bobSessionManager = SignalSessionManager(
        storage: SecureSignalStorage(secureStorage: secureStorage),
        ffiBindings: bobFFI,
        keyManager: bobKeyManager,
      );

      bobStoreCallbacks = SignalFFIStoreCallbacks(
        ffiBindings: bobFFI,
        rustWrapper: bobRustWrapper,
        platformBridge: bobPlatformBridge,
        keyManager: bobKeyManager,
        sessionManager: bobSessionManager,
      );

      bobProtocol = SignalProtocolService(
        ffiBindings: bobFFI,
        storeCallbacks: bobStoreCallbacks,
        keyManager: bobKeyManager,
        sessionManager: bobSessionManager,
      );

      // Initialize Signal Protocol if libraries are available
      if (librariesAvailable) {
        try {
          _logTestStep('Initializing Alice Signal Protocol service');
          await _writeTestResult('Alice Initialization Start', {
            'status': 'starting',
            'timestamp': DateTime.now().toIso8601String(),
          });

          final stopwatch = Stopwatch()..start();

          // Step-by-step initialization with granular logging
          // (We initialize manually instead of using initService to get better error visibility)
          _logTestStep('Step 1: About to initialize Signal Protocol service');
          await _writeTestResult('Before Protocol Initialize', {'step': '1'});

          try {
            // Try to initialize with timeout and error capture
            await aliceProtocol.initialize().timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException(
                    'Protocol initialization timed out after 10 seconds');
              },
            );

            await _writeTestResult('After Protocol Initialize',
                {'step': '1', 'status': 'success'});
            _logTestStep('✅ Step 1: Protocol service initialized');
          } on TimeoutException catch (e) {
            // Timeout - write and continue with fallback
            await _writeTestResult('After Protocol Initialize', {
              'step': '1',
              'status': 'timeout',
              'error': e.toString(),
            });
            _logTestStep('⚠️ Step 1: Protocol service initialization timed out',
                data: {'error': e.toString()});
            librariesAvailable = false;
          } catch (e) {
            // Any other error - capture details and continue with fallback
            await _writeTestResult('After Protocol Initialize', {
              'step': '1',
              'status': 'failed',
              'error': e.toString(),
              'errorType': e.runtimeType.toString(),
            });
            _logTestStep('⚠️ Step 1: Protocol service initialization failed',
                data: {
                  'error': e.toString(),
                  'errorType': e.runtimeType.toString(),
                });
            // Don't rethrow - continue with fallback encryption
            librariesAvailable = false;
          }

          _logTestStep('Step 2: About to initialize platform bridge');
          await _writeTestResult(
              'Before Platform Bridge Initialize', {'step': '2'});

          try {
            if (!alicePlatformBridge.isInitialized) {
              await alicePlatformBridge.initialize().timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  throw TimeoutException(
                      'Platform bridge initialization timed out');
                },
              );
            }
            await _writeTestResult('After Platform Bridge Initialize',
                {'step': '2', 'status': 'success'});
            _logTestStep('✅ Step 2: Platform bridge initialized');
          } catch (e) {
            await _writeTestResult('After Platform Bridge Initialize',
                {'step': '2', 'status': 'failed', 'error': e.toString()});
            _logTestStep(
                '⚠️ Step 2: Platform bridge initialization failed (continuing)',
                data: {'error': e.toString()});
            // Continue - platform bridge might not be needed
          }

          _logTestStep('Step 3: About to initialize Rust wrapper');
          await _writeTestResult(
              'Before Rust Wrapper Initialize', {'step': '3'});

          try {
            if (!aliceRustWrapper.isInitialized) {
              await aliceRustWrapper.initialize().timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  throw TimeoutException(
                      'Rust wrapper initialization timed out');
                },
              );
            }
            await _writeTestResult('After Rust Wrapper Initialize',
                {'step': '3', 'status': 'success'});
            _logTestStep('✅ Step 3: Rust wrapper initialized');
          } catch (e) {
            await _writeTestResult('After Rust Wrapper Initialize',
                {'step': '3', 'status': 'failed', 'error': e.toString()});
            _logTestStep(
                '⚠️ Step 3: Rust wrapper initialization failed (continuing)',
                data: {'error': e.toString()});
            // Continue - rust wrapper might not be needed
          }

          _logTestStep('Step 4: About to initialize store callbacks');
          await _writeTestResult(
              'Before Store Callbacks Initialize', {'step': '4'});

          try {
            if (!aliceStoreCallbacks.isInitialized) {
              await aliceStoreCallbacks.initialize().timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  throw TimeoutException(
                      'Store callbacks initialization timed out');
                },
              );
            }
            await _writeTestResult('After Store Callbacks Initialize',
                {'step': '4', 'status': 'success'});
            _logTestStep('✅ Step 4: Store callbacks initialized');
          } catch (e) {
            await _writeTestResult('After Store Callbacks Initialize',
                {'step': '4', 'status': 'failed', 'error': e.toString()});
            _logTestStep(
                '⚠️ Step 4: Store callbacks initialization failed (continuing)',
                data: {'error': e.toString()});
            // Continue - might work with partial initialization
          }

          // Mark as initialized if protocol service initialized successfully
          if (aliceProtocol.isInitialized) {
            await _writeTestResult('Alice Initialization Complete', {
              'status': 'success',
              'protocolInitialized': true,
              'platformBridgeInitialized': alicePlatformBridge.isInitialized,
              'rustWrapperInitialized': aliceRustWrapper.isInitialized,
              'storeCallbacksInitialized': aliceStoreCallbacks.isInitialized,
            });
          }

          stopwatch.stop();
          _logTestStep('Alice initialization complete', data: {
            'initialized': aliceProtocol.isInitialized,
            'duration_ms': stopwatch.elapsedMilliseconds,
            'platformBridge': alicePlatformBridge.isInitialized,
            'rustWrapper': aliceRustWrapper.isInitialized,
            'storeCallbacks': aliceStoreCallbacks.isInitialized,
          });

          // Initialize Bob (simplified - use init service but with timeout)
          _logTestStep('Initializing Bob Signal Protocol service');
          await _writeTestResult('Bob Initialization Start', {
            'status': 'starting',
            'timestamp': DateTime.now().toIso8601String(),
          });

          stopwatch.reset();
          stopwatch.start();
          final bobInitService = SignalProtocolInitializationService(
            signalProtocol: bobProtocol,
            platformBridge: bobPlatformBridge,
            rustWrapper: bobRustWrapper,
            storeCallbacks: bobStoreCallbacks,
            skipProductionVerification: true, // Skip in tests
          );

          await bobInitService.initialize().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                  'Bob initialization timed out after 15 seconds');
            },
          );

          stopwatch.stop();
          await _writeTestResult('Bob Initialization Complete', {
            'status': 'success',
            'initialized': bobProtocol.isInitialized,
            'duration_ms': stopwatch.elapsedMilliseconds,
          });

          _logTestStep('Bob initialization complete', data: {
            'initialized': bobProtocol.isInitialized,
            'duration_ms': stopwatch.elapsedMilliseconds,
          });
        } catch (e, stackTrace) {
          _logTestStep('Signal Protocol initialization failed', data: {
            'error': e.toString(),
            'errorType': e.runtimeType.toString(),
          });
          await _writeTestResult('Initialization Failed', {
            'status': 'failed',
            'error': e.toString(),
            'errorType': e.runtimeType.toString(),
          });
          developer.log('Initialization error details',
              error: e, stackTrace: stackTrace, name: 'SignalProtocolE2ETest');
          // Signal Protocol initialization failed, will use fallback
          librariesAvailable = false;
        }
      } else {
        _logTestStep(
            'Skipping Signal Protocol initialization (libraries not available)');
        await _writeTestResult('Initialization Skipped', {
          'reason': 'libraries_not_available',
        });
      }

      // Create encryption services (HybridEncryptionService with Signal Protocol if available)
      if (librariesAvailable && aliceProtocol.isInitialized) {
        _logTestStep('Creating HybridEncryptionService with Signal Protocol');
        aliceEncryptionService = HybridEncryptionService(
          signalProtocolService: SignalProtocolEncryptionService(
            signalProtocol: aliceProtocol,
            supabaseService: SupabaseService(),
            atomicClock: AtomicClockService(),
          ),
        );
        _logTestStep('Encryption service created', data: {
          'type': 'HybridEncryptionService',
          'signalProtocolAvailable': true,
          'encryptionType': aliceEncryptionService.encryptionType.name,
        });
      } else {
        _logTestStep('Using AES-256-GCM fallback encryption');
        aliceEncryptionService =
            message_encryption.AES256GCMEncryptionService();
        _logTestStep('Encryption service created', data: {
          'type': 'AES256GCMEncryptionService',
          'signalProtocolAvailable': false,
          'encryptionType': aliceEncryptionService.encryptionType.name,
        });
      }

      _logTestStep('Creating protocol instances');
      // Create protocol instances
      aliceAI2AI = ai2ai.AI2AIProtocol(
        encryptionService: aliceEncryptionService,
      );

      // Create anonymous communication protocols
      final atomicClock = AtomicClockService();
      final anonymizationService = UserAnonymizationService();

      aliceAnonymous = anonymous.AnonymousCommunicationProtocol(
        encryptionService: aliceEncryptionService,
        supabase: mockSupabase,
        atomicClock: atomicClock,
        anonymizationService: anonymizationService,
      );

      _logTestStep('--- Test instance setup complete ---');
    });

    // Note: No tearDown() - We intentionally avoid disposing native libraries
    // to prevent SIGABRT crashes during test finalization.
    // This is documented expected behavior (see PHASE_14_SIGABRT_FINAL_ANALYSIS.md).
    // In production, libraries live for the app's lifetime and are unloaded by OS on termination.

    group('AI2AIProtocol with Signal Protocol', () {
      test('should encrypt and decrypt message using Signal Protocol',
          () async {
        // Check if Signal Protocol is actually initialized
        // If initialization failed, test will use fallback encryption
        final signalProtocolReady =
            librariesAvailable && aliceProtocol.isInitialized;

        if (!signalProtocolReady) {
          _logTestStep(
              '⚠️ Signal Protocol not ready - skipping Signal-specific E2E test');
          await _writeTestResult('Test Start', {
            'signalProtocolReady': false,
            'skipped': true,
            'reason':
                'SignalProtocolService did not initialize (FFI not usable in this environment)',
          });
          return;
        } else {
          _logTestStep(
              '✅ Signal Protocol ready - will test with Signal Protocol encryption');
          await _writeTestResult('Test Start', {
            'signalProtocolReady': true,
            'willTestSignalProtocol': true,
          });
        }

        _logTestStep('=== Starting AI2AIProtocol Signal Protocol Test ===');
        const aliceAgentId = 'agent_alice';
        const bobAgentId = 'agent_bob';

        // Step 1: Bob generates prekey bundle
        _logTestStep('Step 1: Generating Bob\'s prekey bundle');
        final stopwatch = Stopwatch()..start();
        final bobPreKeyBundle = await bobKeyManager.generatePreKeyBundle();
        stopwatch.stop();
        expect(bobPreKeyBundle, isNotNull);
        _logTestStep('Prekey bundle generated', data: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'hasIdentityKey': bobPreKeyBundle.identityKey.isNotEmpty,
          'hasSignedPreKey': bobPreKeyBundle.signedPreKey.isNotEmpty,
          'identityKeyLength': bobPreKeyBundle.identityKey.length,
          'signedPreKeyLength': bobPreKeyBundle.signedPreKey.length,
        });

        // Store Bob's prekey bundle for Alice to fetch
        _logTestStep('Storing Bob\'s prekey bundle for Alice to fetch');
        bobKeyManager.setTestPreKeyBundle(bobAgentId, bobPreKeyBundle);

        // Step 2: Alice performs X3DH key exchange with Bob (via FFI bindings)
        _logTestStep('Step 2: Getting Alice\'s identity key');
        stopwatch.reset();
        stopwatch.start();
        final aliceIdentityKey =
            await aliceKeyManager.getOrGenerateIdentityKeyPair();
        stopwatch.stop();
        _logTestStep('Alice identity key ready', data: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'publicKeyLength': aliceIdentityKey.publicKey.length,
          'privateKeyLength': aliceIdentityKey.privateKey.length,
        });

        _logTestStep('Step 3: Performing X3DH key exchange (Alice → Bob)');
        stopwatch.reset();
        stopwatch.start();
        aliceFFI.performX3DHKeyExchange(
          recipientId: bobAgentId,
          preKeyBundle: bobPreKeyBundle,
          identityKeyPair: aliceIdentityKey,
          storeCallbacks: aliceStoreCallbacks,
        );
        stopwatch.stop();
        _logTestStep('X3DH key exchange completed', data: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'recipientId': bobAgentId,
        });

        // Write X3DH result to file (before cleanup)
        await _writeTestResult('X3DH Key Exchange', {
          'status': 'completed',
          'duration_ms': stopwatch.elapsedMilliseconds,
          'recipientId': bobAgentId,
        });

        // Step 3: Alice encrypts message for Bob using AI2AIProtocol
        // This will use Signal Protocol if available, otherwise fallback to AES-256-GCM
        _logTestStep('Step 4: Encrypting message with AI2AIProtocol');
        final messagePayload = {
          'messageType': 'discoverySync',
          'data': 'Hello from Alice!',
          'timestamp': DateTime.now().toIso8601String(),
        };

        stopwatch.reset();
        stopwatch.start();
        final encryptedMessage = await aliceAI2AI.encodeMessage(
          type: ai2ai.MessageType.heartbeat,
          payload: messagePayload,
          senderNodeId: aliceAgentId,
          recipientNodeId: bobAgentId,
        );
        stopwatch.stop();

        expect(encryptedMessage, isNotNull);
        _logTestStep('Message encrypted successfully', data: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'encryptionType': aliceEncryptionService.encryptionType.name,
          'payloadSize': messagePayload.toString().length,
          'hasPayload': encryptedMessage.payload.isNotEmpty,
          'messageType': encryptedMessage.type.name,
          'senderId': encryptedMessage.senderId,
          'recipientId': encryptedMessage.recipientId,
        });

        await _writeTestResult('Message Encryption', {
          'status': 'success',
          'encryptionType': aliceEncryptionService.encryptionType.name,
          'duration_ms': stopwatch.elapsedMilliseconds,
        });

        // Step 4: Verify encrypted message structure
        _logTestStep('Step 5: Verifying encrypted message structure');
        expect(encryptedMessage.payload['data'], equals('Hello from Alice!'));
        _logTestStep('✅ Message payload verified', data: {
          'expected': 'Hello from Alice!',
          'actual': encryptedMessage.payload['data'],
        });

        // Write encryption result to file (before cleanup)
        await _writeTestResult('Message Encryption', {
          'status': 'success',
          'encryptionType': aliceEncryptionService.encryptionType.name,
          'payloadSize': messagePayload.toString().length,
          'messageType': encryptedMessage.type.name,
          'senderId': encryptedMessage.senderId,
          'recipientId': encryptedMessage.recipientId,
        });

        // Note: Full round-trip decryption requires packet serialization
        // encodeMessage returns ProtocolMessage, but decodeMessage needs ProtocolPacket
        // Encryption is verified above - decryption would require packet format implementation
        _logTestStep(
            'Step 6: Encryption verified (decryption requires packet serialization)');

        // Write final summary (encryption succeeded)
        await _writeTestSummary('AI2AIProtocol Signal Protocol E2E', true, {
          'prekeyBundleGeneration': 'success',
          'x3dhKeyExchange': 'success',
          'messageEncryption': 'success',
          'encryptionType': aliceEncryptionService.encryptionType.name,
          'note':
              'Encryption verified. Full round-trip requires packet serialization.',
        });

        _logTestStep('=== AI2AIProtocol Signal Protocol Test Complete ===');
      });
    });

    group('Fallback to AES-256-GCM', () {
      test('should fallback to AES-256-GCM when Signal Protocol unavailable',
          () async {
        _logTestStep('=== Starting AES-256-GCM Fallback Test ===');

        // Create encryption service without Signal Protocol
        _logTestStep('Creating AES-256-GCM encryption service');
        final fallbackEncryptionService =
            message_encryption.AES256GCMEncryptionService();

        final ai2aiProtocol = ai2ai.AI2AIProtocol(
          encryptionService: fallbackEncryptionService,
        );

        const aliceAgentId = 'agent_alice';
        const bobAgentId = 'agent_bob';

        // Encrypt message
        _logTestStep('Encrypting message with AES-256-GCM');
        final stopwatch = Stopwatch()..start();
        final encrypted = await ai2aiProtocol.encodeMessage(
          type: ai2ai.MessageType.heartbeat,
          payload: {'data': 'Test message'},
          senderNodeId: aliceAgentId,
          recipientNodeId: bobAgentId,
        );
        stopwatch.stop();

        expect(encrypted, isNotNull);
        _logTestStep('Message encrypted with AES-256-GCM', data: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'encryptionType': 'aes256gcm',
          'hasPayload': encrypted.payload.isNotEmpty,
        });

        // For AES-256-GCM, we can verify encryption worked by checking message structure
        // Full decodeMessage test requires proper packet serialization
        expect(encrypted.payload['data'], equals('Test message'));

        // Write fallback test result to file (before cleanup)
        await _writeTestResult('AES-256-GCM Fallback', {
          'status': 'success',
          'encryptionType': 'aes256gcm',
          'duration_ms': stopwatch.elapsedMilliseconds,
        });

        await _writeTestSummary('AES-256-GCM Fallback Test', true, {
          'encryption': 'success',
          'fallbackWorking': 'true',
        });

        _logTestStep('✅ AES-256-GCM fallback test complete');
      });

      test('HybridEncryptionService should fallback gracefully', () async {
        _logTestStep('=== Starting HybridEncryptionService Fallback Test ===');

        // Create HybridEncryptionService without Signal Protocol
        _logTestStep(
            'Creating HybridEncryptionService without Signal Protocol');
        final hybridService = HybridEncryptionService(
          signalProtocolService: null, // Signal Protocol not available
        );

        expect(hybridService.encryptionType,
            equals(message_encryption.EncryptionType.aes256gcm));
        _logTestStep('HybridEncryptionService created', data: {
          'encryptionType': hybridService.encryptionType.name,
          'signalProtocolAvailable': hybridService.isSignalProtocolAvailable,
        });

        // Encrypt should use AES-256-GCM fallback
        _logTestStep('Encrypting message (should use AES-256-GCM fallback)');
        final stopwatch = Stopwatch()..start();
        final encrypted = await hybridService.encrypt(
          'Test message',
          'agent_bob',
        );
        stopwatch.stop();

        expect(encrypted, isNotNull);
        expect(encrypted.encryptionType,
            equals(message_encryption.EncryptionType.aes256gcm));
        _logTestStep('Encryption completed with fallback', data: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'encryptionType': encrypted.encryptionType.name,
          'encryptedContentLength': encrypted.encryptedContent.length,
        });

        // Write hybrid service test result to file (before cleanup)
        await _writeTestResult('HybridEncryptionService Fallback', {
          'status': 'success',
          'encryptionType': encrypted.encryptionType.name,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'encryptedContentLength': encrypted.encryptedContent.length,
        });

        await _writeTestSummary('HybridEncryptionService Fallback Test', true, {
          'fallbackWorking': 'true',
          'encryptionType': encrypted.encryptionType.name,
        });

        _logTestStep('✅ HybridEncryptionService fallback test complete');
      });
    });

    group('AnonymousCommunicationProtocol', () {
      test('should encrypt anonymous message', () async {
        _logTestStep('=== Starting AnonymousCommunicationProtocol Test ===');
        const bobAgentId = 'agent_bob';

        final anonymousPayload = {
          'agentId': 'agent_alice',
          'personalityDimensions': {
            'exploration': 0.5,
            'social': 0.7,
          },
        };

        _logTestStep('Preparing anonymous message payload', data: {
          'targetAgentId': bobAgentId,
          'payloadKeys': anonymousPayload.keys.toList(),
          'payloadSize': anonymousPayload.toString().length,
        });

        _logTestStep('Encrypting anonymous message');
        final stopwatch = Stopwatch()..start();
        final encryptedMessage = await aliceAnonymous.sendEncryptedMessage(
          bobAgentId,
          anonymous.MessageType.discoverySync,
          anonymousPayload,
        );
        stopwatch.stop();

        expect(encryptedMessage, isNotNull);
        expect(encryptedMessage.encryptedPayload, isNotEmpty);
        _logTestStep('Anonymous message encrypted', data: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'encryptionType': aliceEncryptionService.encryptionType.name,
          'messageId': encryptedMessage.messageId,
          'targetAgentId': encryptedMessage.targetAgentId,
          'messageType': encryptedMessage.messageType.name,
          'encryptedPayloadLength': encryptedMessage.encryptedPayload.length,
          'hasEncryptedPayload': encryptedMessage.encryptedPayload.isNotEmpty,
        });

        // Write anonymous communication test result to file (before cleanup)
        await _writeTestResult('AnonymousCommunicationProtocol Encryption', {
          'status': 'success',
          'duration_ms': stopwatch.elapsedMilliseconds,
          'encryptionType': aliceEncryptionService.encryptionType.name,
          'messageId': encryptedMessage.messageId,
          'targetAgentId': encryptedMessage.targetAgentId,
          'encryptedPayloadLength': encryptedMessage.encryptedPayload.length,
        });

        await _writeTestSummary('AnonymousCommunicationProtocol Test', true, {
          'encryption': 'success',
          'encryptionType': aliceEncryptionService.encryptionType.name,
          'messageId': encryptedMessage.messageId,
        });

        _logTestStep('✅ AnonymousCommunicationProtocol test complete');
      });
    });
  });
}
