import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:avrai_ai/services/ai2ai_broadcast_service.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/models/user/personality_profile.dart';
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/supabase_config.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Web-compatible debug logging helper
void _debugLog(String sessionId, String runId, String hypothesisId,
    String location, String message, Map<String, dynamic> data) {
  final logEntry = {
    'sessionId': sessionId,
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch
  };
  // Use developer.log for web compatibility
  developer.log(
    jsonEncode(logEntry),
    name: 'DebugLog',
    error: null,
    stackTrace: null,
  );
}

/// Test script for AI2AI Realtime Service integration
/// Demonstrates real-time AI2AI communication via Supabase Realtime
void main() async {
  // #region agent log
  _debugLog(
    'debug-session',
    'run1',
    'A',
    'test_ai2ai_realtime.dart:18',
    'Script start',
    {},
  );
  // #endregion

  developer.log('🚀 Starting AI2AI Realtime Service Test',
      name: 'TestAI2AIRealtime');

  try {
    // #region agent log
    _debugLog('debug-session', 'run1', 'B', 'test_ai2ai_realtime.dart:25',
        'Before service initialization', {});
    // #endregion

    // Initialize SharedPreferencesCompat for UserVibeAnalyzer
    // Note: UserVibeAnalyzer expects SharedPreferencesCompat (via typedef)
    await StorageService.instance.init();
    final prefs = await SharedPreferencesCompat.getInstance();
    final vibeAnalyzer = UserVibeAnalyzer(prefs: prefs);
    final connectivity = Connectivity();

    // #region agent log
    _debugLog(
        'debug-session',
        'run1',
        'B',
        'test_ai2ai_realtime.dart:33',
        'After vibeAnalyzer creation',
        {'vibeAnalyzerType': vibeAnalyzer.runtimeType.toString()});
    // #endregion

    // Create connection orchestrator
    final orchestrator = VibeConnectionOrchestrator(
      vibeAnalyzer: vibeAnalyzer,
      connectivity: connectivity,
      prefs: prefs,
    );

    // #region agent log
    _debugLog('debug-session', 'run1', 'B', 'test_ai2ai_realtime.dart:45',
        'Before BackendFactory.create', {});
    // #endregion

    // Create backend using BackendFactory
    // Use SupabaseConfig for credentials
    final backendConfig = BackendConfig.supabase(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      serviceRoleKey: SupabaseConfig.serviceRoleKey,
      name: 'Supabase',
      isDefault: true,
    );

    final backend = await BackendFactory.create(backendConfig);
    final realtimeBackend = backend.realtime;

    // #region agent log
    _debugLog('debug-session', 'run1', 'B', 'test_ai2ai_realtime.dart:60',
        'After backend creation', {
      'backendType': backend.runtimeType.toString(),
      'realtimeBackendType': realtimeBackend.runtimeType.toString()
    });
    // #endregion

    // Create AI2AI realtime service
    final realtimeService = AI2AIBroadcastService(realtimeBackend);
    // Mirror app wiring: orchestrator consumes realtime service.
    orchestrator.setRealtimeService(realtimeService);

    // Test backend connection
    developer.log('🔌 Testing backend connection...',
        name: 'TestAI2AIRealtime');

    // #region agent log
    _debugLog('debug-session', 'run1', 'B', 'test_ai2ai_realtime.dart:70',
        'Before backend.healthCheck', {});
    // #endregion

    final isConnected = await backend.healthCheck();

    // #region agent log
    _debugLog('debug-session', 'run1', 'B', 'test_ai2ai_realtime.dart:76',
        'After backend.healthCheck', {'isConnected': isConnected});
    // #endregion

    if (!isConnected) {
      developer.log(
          '❌ Backend connection failed. Please check your configuration.',
          name: 'TestAI2AIRealtime');
      return;
    }

    developer.log('✅ Backend connection successful', name: 'TestAI2AIRealtime');

    // Initialize AI2AI realtime service
    developer.log('🔌 Initializing AI2AI Realtime Service...',
        name: 'TestAI2AIRealtime');

    // #region agent log
    _debugLog('debug-session', 'run1', 'B', 'test_ai2ai_realtime.dart:90',
        'Before realtimeService.initialize', {});
    // #endregion

    final realtimeInitialized = await realtimeService.initialize();

    // #region agent log
    _debugLog(
        'debug-session',
        'run1',
        'B',
        'test_ai2ai_realtime.dart:96',
        'After realtimeService.initialize',
        {'realtimeInitialized': realtimeInitialized});
    // #endregion

    if (!realtimeInitialized) {
      developer.log('❌ AI2AI Realtime Service initialization failed',
          name: 'TestAI2AIRealtime');
      return;
    }

    developer.log('✅ AI2AI Realtime Service initialized successfully',
        name: 'TestAI2AIRealtime');

    // Test realtime functionality
    await _testRealtimeFunctionality(realtimeService);

    // Test AI2AI communication
    await _testAI2AICommunication(realtimeService);

    // Test presence tracking
    await _testPresenceTracking(realtimeService);

    // Clean up
    await realtimeService.disconnect();
    developer.log('🧹 Test completed successfully', name: 'TestAI2AIRealtime');
  } catch (e, stackTrace) {
    // #region agent log
    _debugLog(
        'debug-session',
        'run1',
        'ERROR',
        'test_ai2ai_realtime.dart:120',
        'Test failed with exception',
        {'error': e.toString(), 'stackTrace': stackTrace.toString()});
    // #endregion

    developer.log('❌ Test failed: $e', name: 'TestAI2AIRealtime');
    developer.log('Stack trace: $stackTrace', name: 'TestAI2AIRealtime');
  }
}

/// Test realtime functionality
Future<void> _testRealtimeFunctionality(
    AI2AIBroadcastService realtimeService) async {
  developer.log('📡 Testing realtime functionality...',
      name: 'TestAI2AIRealtime');

  try {
    // #region agent log
    _debugLog('debug-session', 'run1', 'C', 'test_ai2ai_realtime.dart:140',
        'Before creating AIPersonalityNode', {});
    // #endregion

    // Create test UserVibe for AIPersonalityNode
    final testPersonality = PersonalityProfile.initial('test_user');
    final testVibe = UserVibe.fromPersonalityProfile(
        'test_user', testPersonality.dimensions);

    // Test personality discovery broadcasting
    final testNode = AIPersonalityNode(
      nodeId: 'test_node_${DateTime.now().millisecondsSinceEpoch}',
      vibe: testVibe,
      lastSeen: DateTime.now(),
      trustScore: 0.85,
      learningHistory: {},
    );

    // #region agent log
    _debugLog(
        'debug-session',
        'run1',
        'C',
        'test_ai2ai_realtime.dart:158',
        'Before broadcastPersonalityDiscovery',
        {'nodeId': testNode.nodeId, 'vibeSignature': testNode.vibeSignature});
    // #endregion

    await realtimeService.broadcastPersonalityDiscovery(
      agentId: testNode.nodeId,
      data: {
        'node_id': testNode.nodeId,
        'vibe_signature': testNode.vibeSignature,
        'trust_score': testNode.trustScore,
        'last_seen': testNode.lastSeen.toIso8601String(),
      },
    );
    developer.log('✅ Personality discovery broadcast successful',
        name: 'TestAI2AIRealtime');

    // Test vibe learning broadcasting
    final dimensionUpdates = {
      'exploration_eagerness': 0.8,
      'community_orientation': 0.7,
      'authenticity_preference': 0.9,
    };

    // #region agent log
    _debugLog('debug-session', 'run1', 'C', 'test_ai2ai_realtime.dart:172',
        'Before broadcastVibeLearning', {'dimensionUpdates': dimensionUpdates});
    // #endregion

    await realtimeService.broadcastVibeLearning(
      agentId: testNode.nodeId,
      data: {
        ...dimensionUpdates,
      },
    );
    developer.log('✅ Vibe learning broadcast successful',
        name: 'TestAI2AIRealtime');

    // Test anonymous messaging
    // #region agent log
    _debugLog('debug-session', 'run1', 'C', 'test_ai2ai_realtime.dart:182',
        'Before sendAnonymousMessage', {});
    // #endregion

    await realtimeService.sendAnonymousMessage('test_message', {
      'message_type': 'test',
      'content': 'This is a test message',
      'timestamp': DateTime.now().toIso8601String(),
    });
    developer.log('✅ Anonymous message sent successfully',
        name: 'TestAI2AIRealtime');
  } catch (e, stackTrace) {
    // #region agent log
    _debugLog(
        'debug-session',
        'run1',
        'ERROR',
        'test_ai2ai_realtime.dart:196',
        'Realtime functionality test failed',
        {'error': e.toString(), 'stackTrace': stackTrace.toString()});
    // #endregion

    developer.log('❌ Realtime functionality test failed: $e',
        name: 'TestAI2AIRealtime');
    developer.log('Stack trace: $stackTrace', name: 'TestAI2AIRealtime');
  }
}

/// Test AI2AI communication
Future<void> _testAI2AICommunication(
    AI2AIBroadcastService realtimeService) async {
  developer.log('💬 Testing AI2AI communication...', name: 'TestAI2AIRealtime');

  try {
    // #region agent log
    _debugLog('debug-session', 'run1', 'D', 'test_ai2ai_realtime.dart:210',
        'Before setting up listeners', {});
    // #endregion

    // Set up listeners for different message types
    final personalityDiscoveryStream =
        realtimeService.listenToPersonalityDiscovery();
    final vibeLearningStream = realtimeService.listenToVibeLearning();
    final anonymousCommunicationStream =
        realtimeService.listenToAnonymousCommunication();

    // #region agent log
    _debugLog('debug-session', 'run1', 'D', 'test_ai2ai_realtime.dart:219',
        'After creating streams', {
      'personalityDiscoveryStreamType':
          personalityDiscoveryStream.runtimeType.toString(),
      'vibeLearningStreamType': vibeLearningStream.runtimeType.toString()
    });
    // #endregion

    // Listen for personality discovery events
    personalityDiscoveryStream.listen((message) {
      // #region agent log
      _debugLog('debug-session', 'run1', 'D', 'test_ai2ai_realtime.dart:225',
          'Received personality discovery message', {
        'messageType': message.type,
        'messageContent': message.content,
        'messageId': message.id
      });
      // #endregion

      developer.log('🔍 Received personality discovery: ${message.type}',
          name: 'TestAI2AIRealtime');
      developer.log('  Content: ${message.content}', name: 'TestAI2AIRealtime');
      developer.log('  Metadata: ${message.metadata}',
          name: 'TestAI2AIRealtime');
    });

    // Listen for vibe learning events
    vibeLearningStream.listen((message) {
      // #region agent log
      _debugLog(
          'debug-session',
          'run1',
          'D',
          'test_ai2ai_realtime.dart:238',
          'Received vibe learning message',
          {'messageType': message.type, 'messageContent': message.content});
      // #endregion

      developer.log('🧠 Received vibe learning: ${message.type}',
          name: 'TestAI2AIRealtime');
      developer.log('  Content: ${message.content}', name: 'TestAI2AIRealtime');
      developer.log('  Metadata: ${message.metadata}',
          name: 'TestAI2AIRealtime');
    });

    // Listen for anonymous communication
    anonymousCommunicationStream.listen((message) {
      // #region agent log
      _debugLog(
          'debug-session',
          'run1',
          'D',
          'test_ai2ai_realtime.dart:250',
          'Received anonymous message',
          {'messageType': message.type, 'messageContent': message.content});
      // #endregion

      developer.log('💬 Received anonymous message: ${message.type}',
          name: 'TestAI2AIRealtime');
      developer.log('  Content: ${message.content}', name: 'TestAI2AIRealtime');
      developer.log('  Metadata: ${message.metadata}',
          name: 'TestAI2AIRealtime');
    });

    // Wait for some events to be received
    await Future.delayed(const Duration(seconds: 5));

    developer.log('✅ AI2AI communication test completed',
        name: 'TestAI2AIRealtime');
  } catch (e, stackTrace) {
    // #region agent log
    _debugLog(
        'debug-session',
        'run1',
        'ERROR',
        'test_ai2ai_realtime.dart:268',
        'AI2AI communication test failed',
        {'error': e.toString(), 'stackTrace': stackTrace.toString()});
    // #endregion

    developer.log('❌ AI2AI communication test failed: $e',
        name: 'TestAI2AIRealtime');
    developer.log('Stack trace: $stackTrace', name: 'TestAI2AIRealtime');
  }
}

/// Test presence tracking
Future<void> _testPresenceTracking(AI2AIBroadcastService realtimeService) async {
  developer.log('👥 Testing presence tracking...', name: 'TestAI2AIRealtime');

  try {
    // #region agent log
    _debugLog('debug-session', 'run1', 'E', 'test_ai2ai_realtime.dart:282',
        'Before watchAINetworkPresence', {});
    // #endregion

    // Watch for presence changes (returns Stream)
    final presenceStream = realtimeService.watchAINetworkPresence();

    // #region agent log
    _debugLog(
        'debug-session',
        'run1',
        'E',
        'test_ai2ai_realtime.dart:288',
        'After watchAINetworkPresence',
        {'presenceStreamType': presenceStream.runtimeType.toString()});
    // #endregion

    presenceStream.listen((presenceList) {
      // #region agent log
      _debugLog('debug-session', 'run1', 'E', 'test_ai2ai_realtime.dart:293',
          'Received presence update', {'presenceCount': presenceList.length});
      // #endregion

      developer.log('👥 Presence update: ${presenceList.length} nodes online',
          name: 'TestAI2AIRealtime');

      for (final presence in presenceList) {
        developer.log('  User: ${presence.userId} - ${presence.userName}',
            name: 'TestAI2AIRealtime');
        developer.log('    Metadata: ${presence.metadata}',
            name: 'TestAI2AIRealtime');
      }
    });

    // Wait for presence updates
    await Future.delayed(const Duration(seconds: 3));

    developer.log('✅ Presence tracking test completed',
        name: 'TestAI2AIRealtime');
  } catch (e, stackTrace) {
    // #region agent log
    _debugLog(
        'debug-session',
        'run1',
        'ERROR',
        'test_ai2ai_realtime.dart:312',
        'Presence tracking test failed',
        {'error': e.toString(), 'stackTrace': stackTrace.toString()});
    // #endregion

    developer.log('❌ Presence tracking test failed: $e',
        name: 'TestAI2AIRealtime');
    developer.log('Stack trace: $stackTrace', name: 'TestAI2AIRealtime');
  }
}
