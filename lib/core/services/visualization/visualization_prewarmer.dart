// Visualization Prewarmer Service
//
// Pre-creates WebView during app startup to eliminate cold-start latency
// Part of 3D Visualization System
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:avrai/core/services/visualization/three_js_bridge_service.dart';

/// Service for pre-warming Three.js WebView to eliminate cold-start latency
///
/// **Usage:**
/// 1. Call `prewarm()` during app startup (e.g., splash screen)
/// 2. When visualization is needed, check `isReady`
/// 3. If ready, use `getPrewarmedBridge()` to get an initialized bridge
/// 4. If not ready, fall back to normal WebView creation
///
/// **Performance:**
/// - Cold start (no prewarming): ~300-500ms
/// - Warm start (prewarmed): ~50-100ms
class VisualizationPrewarmer {
  static const String _logName = 'VisualizationPrewarmer';

  /// Singleton instance
  static final VisualizationPrewarmer _instance =
      VisualizationPrewarmer._internal();

  factory VisualizationPrewarmer() => _instance;

  VisualizationPrewarmer._internal();

  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? _controller;
  ThreeJsBridgeService? _bridge;
  bool _isPrewarming = false;
  bool _isReady = false;
  bool _wasUsed = false;

  Completer<void> _readyCompleter = Completer<void>();

  /// Whether the prewarmed WebView is ready for use
  bool get isReady => _isReady && !_wasUsed;

  /// Future that completes when prewarm is done
  Future<void> get whenReady => _readyCompleter.future;

  /// Pre-warm the WebView during app startup
  ///
  /// Call this during splash screen or app initialization.
  /// Does nothing if already prewarming or ready.
  Future<void> prewarm() async {
    if (_isPrewarming || _isReady) {
      developer.log('Already prewarming or ready, skipping', name: _logName);
      return;
    }

    _isPrewarming = true;
    developer.log('Starting prewarm...', name: _logName);

    final stopwatch = Stopwatch()..start();

    try {
      // Create headless WebView
      _headlessWebView = HeadlessInAppWebView(
        initialFile: 'assets/three_js/index.html',
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          transparentBackground: true,
          // Optimize for performance
          hardwareAcceleration: true,
          useShouldOverrideUrlLoading: false,
          useOnLoadResource: false,
          useOnDownloadStart: false,
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
          developer.log('Headless WebView created', name: _logName);
        },
        onLoadStop: (controller, url) async {
          developer.log('WebView loaded, initializing bridge...', name: _logName);

          // Create and initialize bridge
          _bridge = ThreeJsBridgeService();
          await _bridge!.initialize(controller);

          // Wait for Three.js to signal ready
          try {
            await _bridge!.onReady.first.timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                developer.log('Timeout waiting for Three.js ready', name: _logName);
                return 'timeout';
              },
            );
          } catch (e) {
            developer.log('Error waiting for ready: $e', name: _logName);
          }

          _isReady = true;
          _isPrewarming = false;

          stopwatch.stop();
          developer.log(
            'Prewarm complete in ${stopwatch.elapsedMilliseconds}ms',
            name: _logName,
          );

          if (!_readyCompleter.isCompleted) {
            _readyCompleter.complete();
          }
        },
        onReceivedError: (controller, request, error) {
          developer.log(
            'WebView error: ${error.description}',
            name: _logName,
          );
        },
        onConsoleMessage: (controller, message) {
          if (kDebugMode) {
            developer.log('JS Console: ${message.message}', name: _logName);
          }
        },
      );

      // Start the headless WebView
      await _headlessWebView!.run();
    } catch (e, stackTrace) {
      developer.log(
        'Prewarm failed: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      _isPrewarming = false;
    }
  }

  /// Get the prewarmed bridge
  ///
  /// Returns the initialized bridge if available, otherwise null.
  /// Once retrieved, the prewarmed instance is marked as used and
  /// subsequent calls will return null.
  ThreeJsBridgeService? getPrewarmedBridge() {
    if (!_isReady || _wasUsed) {
      return null;
    }

    _wasUsed = true;
    developer.log('Prewarmed bridge claimed', name: _logName);

    return _bridge;
  }

  /// Get the prewarmed controller
  ///
  /// Returns the WebView controller if available.
  /// Use this to attach the headless WebView to a visible widget.
  InAppWebViewController? getPrewarmedController() {
    if (!_isReady || _wasUsed) {
      return null;
    }

    return _controller;
  }

  /// Dispose of prewarmed resources
  ///
  /// Call this if prewarm is no longer needed (e.g., user logs out)
  Future<void> dispose() async {
    if (_bridge != null) {
      await _bridge!.cleanup();
      _bridge!.dispose();
      _bridge = null;
    }

    if (_headlessWebView != null) {
      await _headlessWebView!.dispose();
      _headlessWebView = null;
    }

    _controller = null;
    _isReady = false;
    _wasUsed = false;
    _isPrewarming = false;

    developer.log('Prewarmer disposed', name: _logName);
  }

  /// Reset for reuse
  ///
  /// Call this to allow prewarming again after the previous instance was used
  void reset() {
    if (_wasUsed) {
      _bridge = null;
      _controller = null;
      _headlessWebView = null;
      _isReady = false;
      _wasUsed = false;
      // Create new completer to allow waiting on next prewarm
      _readyCompleter = Completer<void>();
      developer.log('Prewarmer reset', name: _logName);
    }
  }

  /// Prewarm for birth experience specifically
  ///
  /// Uses the birth experience HTML instead of the general visualization
  Future<void> prewarmBirthExperience() async {
    if (_isPrewarming || _isReady) {
      return;
    }

    _isPrewarming = true;
    developer.log('Starting birth experience prewarm...', name: _logName);

    try {
      _headlessWebView = HeadlessInAppWebView(
        initialFile: 'assets/three_js/birth_experience.html',
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          transparentBackground: true,
          hardwareAcceleration: true,
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        onLoadStop: (controller, url) async {
          _bridge = ThreeJsBridgeService();
          await _bridge!.initialize(controller);

          try {
            await _bridge!.onReady.first.timeout(
              const Duration(seconds: 5),
            );
          } catch (e) {
            developer.log('Timeout waiting for birth experience ready', name: _logName);
          }

          _isReady = true;
          _isPrewarming = false;

          if (!_readyCompleter.isCompleted) {
            _readyCompleter.complete();
          }

          developer.log('Birth experience prewarm complete', name: _logName);
        },
      );

      await _headlessWebView!.run();
    } catch (e) {
      developer.log('Birth experience prewarm failed: $e', name: _logName);
      _isPrewarming = false;
    }
  }
}
