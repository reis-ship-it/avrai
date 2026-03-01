// Three.js Bridge Service
//
// Service for communicating between Dart and Three.js WebView
// Part of 3D Visualization System
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:vector_math/vector_math.dart';
import 'package:avrai_knot/models/knot/knot_3d.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/worldsheet_4d_data.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/misc/visualization_style.dart';

/// Service for bridging Dart and Three.js WebView for 3D visualization
///
/// **Responsibilities:**
/// - Initialize and manage WebView controller
/// - Serialize Dart models to JSON for JavaScript consumption
/// - Send render commands to JavaScript
/// - Handle callbacks from JavaScript (taps, camera changes, completion)
/// - Manage cleanup and disposal
class ThreeJsBridgeService {
  static const String _logName = 'ThreeJsBridgeService';

  InAppWebViewController? _controller;
  bool _isReady = false;

  // Stream controllers for events from JavaScript
  final _objectTappedController = StreamController<String>.broadcast();
  final _renderCompleteController = StreamController<String>.broadcast();
  final _phaseChangeController = StreamController<String>.broadcast();
  final _birthCompleteController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _readyController = StreamController<String>.broadcast();
  final _webGLNotSupportedController = StreamController<String>.broadcast();
  final _errorController = StreamController<VisualizationError>.broadcast();
  final _metricsController = StreamController<VisualizationMetrics>.broadcast();

  /// Stream of object tap events (emits object ID)
  Stream<String> get onObjectTapped => _objectTappedController.stream;

  /// Stream of render completion events (emits visualization type)
  Stream<String> get onRenderComplete => _renderCompleteController.stream;

  /// Stream of birth experience phase changes
  Stream<String> get onPhaseChange => _phaseChangeController.stream;

  /// Stream of birth experience completion
  Stream<Map<String, dynamic>> get onBirthComplete =>
      _birthCompleteController.stream;

  /// Stream of ready events
  Stream<String> get onReady => _readyController.stream;

  /// Stream of WebGL not supported events (emits reason string)
  Stream<String> get onWebGLNotSupported => _webGLNotSupportedController.stream;

  /// Stream of JavaScript errors
  Stream<VisualizationError> get onError => _errorController.stream;

  /// Stream of performance metrics (emitted every second)
  Stream<VisualizationMetrics> get metricsStream => _metricsController.stream;

  /// Whether the WebView is ready for commands
  bool get isReady => _isReady;

  /// Initialize the bridge with a WebView controller
  ///
  /// Call this after the WebView is created and before sending any commands.
  Future<void> initialize(InAppWebViewController controller) async {
    _controller = controller;

    // Register JavaScript handlers for callbacks from Three.js
    _controller!.addJavaScriptHandler(
      handlerName: 'onObjectTapped',
      callback: (args) {
        if (args.isNotEmpty) {
          final objectId = args[0].toString();
          developer.log('Object tapped: $objectId', name: _logName);
          _objectTappedController.add(objectId);
        }
        return null;
      },
    );

    _controller!.addJavaScriptHandler(
      handlerName: 'onRenderComplete',
      callback: (args) {
        if (args.isNotEmpty) {
          final type = args[0].toString();
          developer.log('Render complete: $type', name: _logName);
          _renderCompleteController.add(type);
        }
        return null;
      },
    );

    _controller!.addJavaScriptHandler(
      handlerName: 'onPhaseChange',
      callback: (args) {
        if (args.isNotEmpty) {
          final phase = args[0].toString();
          developer.log('Phase change: $phase', name: _logName);
          _phaseChangeController.add(phase);
        }
        return null;
      },
    );

    _controller!.addJavaScriptHandler(
      handlerName: 'onBirthComplete',
      callback: (args) {
        if (args.isNotEmpty) {
          try {
            final data = args[0] is String
                ? jsonDecode(args[0] as String) as Map<String, dynamic>
                : args[0] as Map<String, dynamic>;
            developer.log('Birth complete', name: _logName);
            _birthCompleteController.add(data);
          } catch (e) {
            developer.log('Error parsing birth complete data: $e',
                name: _logName);
          }
        }
        return null;
      },
    );

    _controller!.addJavaScriptHandler(
      handlerName: 'onReady',
      callback: (args) {
        if (args.isNotEmpty) {
          final type = args[0].toString();
          developer.log('WebView ready: $type', name: _logName);
          _isReady = true;
          _readyController.add(type);
        }
        return null;
      },
    );

    _controller!.addJavaScriptHandler(
      handlerName: 'onWebGLNotSupported',
      callback: (args) {
        final reason = args.isNotEmpty ? args[0].toString() : 'Unknown reason';
        developer.log('WebGL not supported: $reason', name: _logName);
        _webGLNotSupportedController.add(reason);
        return null;
      },
    );

    _controller!.addJavaScriptHandler(
      handlerName: 'onError',
      callback: (args) {
        if (args.isNotEmpty) {
          try {
            final errorData = args[0] is String
                ? jsonDecode(args[0] as String) as Map<String, dynamic>
                : args[0] as Map<String, dynamic>;
            final error = VisualizationError(
              context: errorData['context'] as String? ?? 'unknown',
              message: errorData['message'] as String? ?? 'Unknown error',
              stack: errorData['stack'] as String?,
            );
            developer.log('JS Error in ${error.context}: ${error.message}',
                name: _logName);
            _errorController.add(error);
          } catch (e) {
            developer.log('Error parsing JS error: $e', name: _logName);
          }
        }
        return null;
      },
    );

    _controller!.addJavaScriptHandler(
      handlerName: 'onPerformanceMetrics',
      callback: (args) {
        if (args.isNotEmpty) {
          try {
            final metricsData = args[0] is String
                ? jsonDecode(args[0] as String) as Map<String, dynamic>
                : args[0] as Map<String, dynamic>;
            final metrics = VisualizationMetrics.fromJson(metricsData);
            _metricsController.add(metrics);
          } catch (e) {
            developer.log('Error parsing metrics: $e', name: _logName);
          }
        }
        return null;
      },
    );

    developer.log('Bridge initialized', name: _logName);
  }

  // ─────────────────────────────────────────────────────────────
  // KNOT RENDERING
  // ─────────────────────────────────────────────────────────────

  /// Default timeout for waiting on WebView ready
  static const Duration _readyTimeout = Duration(seconds: 10);

  /// Wait for WebView to be ready with timeout
  Future<void> _waitForReady() async {
    if (_isReady) return;

    developer.log('WebView not ready, waiting...', name: _logName);
    try {
      await onReady.first.timeout(
        _readyTimeout,
        onTimeout: () {
          developer.log(
              'WebView ready timeout after ${_readyTimeout.inSeconds}s',
              name: _logName);
          throw TimeoutException(
              'WebView not ready after ${_readyTimeout.inSeconds}s');
        },
      );
    } on TimeoutException {
      rethrow;
    }
  }

  /// Render a 3D knot
  ///
  /// **Parameters:**
  /// - `knot`: The Knot3D data to render
  /// - `style`: Visualization style configuration
  /// - `tubeRadius`: Optional tube radius (default 0.1)
  /// - `animate`: Whether to enable animation
  Future<void> renderKnot({
    required Knot3D knot,
    required KnotVisualizationStyle style,
    double tubeRadius = 0.1,
    bool animate = false,
  }) async {
    await _waitForReady();

    final data = {
      'coordinates': knot.coordinates.map((v) => [v.x, v.y, v.z]).toList(),
      'crossings': knot.crossings
          .map((c) => <String, dynamic>{
                'position': [c.position.x, c.position.y, c.position.z],
                'isOver': c.isOver,
              })
          .toList(),
      'invariants': {
        'crossingNumber': knot.invariants.crossingNumber,
        'writhe': knot.invariants.writhe,
        'signature': knot.invariants.signature,
      },
      'style': style.toJson(),
      'tubeRadius': tubeRadius,
      'animate': animate,
    };

    await _evaluateJS('window.knotRenderer.render(${jsonEncode(data)})');
  }

  /// Render a knot from PersonalityKnot model
  ///
  /// Convenience method that creates Knot3D internally
  Future<void> renderPersonalityKnot({
    required PersonalityKnot knot,
    required KnotVisualizationStyle style,
    double tubeRadius = 0.1,
    bool animate = false,
  }) async {
    final knot3d = Knot3D.fromBraidData(
      braidData: knot.braidData,
      invariants: knot.invariants,
      agentId: knot.agentId,
    );
    await renderKnot(
      knot: knot3d,
      style: style,
      tubeRadius: tubeRadius,
      animate: animate,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FABRIC RENDERING
  // ─────────────────────────────────────────────────────────────

  /// Render a community fabric
  ///
  /// **Parameters:**
  /// - `fabric`: The KnotFabric to render
  /// - `style`: Visualization style configuration
  Future<void> renderFabric({
    required KnotFabric fabric,
    required FabricVisualizationStyle style,
  }) async {
    await _waitForReady();

    final strands = <Map<String, dynamic>>[];

    for (final userKnot in fabric.userKnots) {
      try {
        final knot3d = Knot3D.fromBraidData(
          braidData: userKnot.braidData,
          invariants: userKnot.invariants,
          agentId: userKnot.agentId,
        );
        strands.add({
          'userId': userKnot.agentId,
          'coordinates':
              knot3d.coordinates.map((v) => [v.x, v.y, v.z]).toList(),
          'color': _getUserColor(userKnot.agentId),
        });
      } catch (e) {
        developer.log('Error converting knot for ${userKnot.agentId}: $e',
            name: _logName);
      }
    }

    final data = {
      'strands': strands,
      'braid': {
        'strandCount': fabric.braid.strandCount,
      },
      'invariants': {
        'density': fabric.invariants.density,
        'stability': fabric.invariants.stability,
      },
      'style': style.toJson(),
    };

    await _evaluateJS('window.fabricRenderer.render(${jsonEncode(data)})');
  }

  // ─────────────────────────────────────────────────────────────
  // WORLDSHEET RENDERING
  // ─────────────────────────────────────────────────────────────

  /// Render a worldsheet surface
  ///
  /// **Parameters:**
  /// - `worldsheet`: The Worldsheet4DData to render
  /// - `style`: Visualization style configuration
  /// - `timePosition`: Initial time position (0.0 to 1.0)
  Future<void> renderWorldsheet({
    required Worldsheet4DData worldsheet,
    required WorldsheetVisualizationStyle style,
    double timePosition = 0.5,
  }) async {
    await _waitForReady();

    final data = {
      'timePoints':
          worldsheet.timePoints.map((t) => t.millisecondsSinceEpoch).toList(),
      'fabricData': worldsheet.fabricData
          .map((f) => <String, dynamic>{
                'strandPositions': f.strandPositions
                    .map(
                        (strand) => strand.map((v) => [v.x, v.y, v.z]).toList())
                    .toList(),
                'invariants': <String, dynamic>{
                  'stability': f.invariants.stability,
                  'density': f.invariants.density,
                },
              })
          .toList(),
      'currentTime': timePosition,
      'style': style.toJson(),
    };

    await _evaluateJS('window.worldsheetRenderer.render(${jsonEncode(data)})');
  }

  // ─────────────────────────────────────────────────────────────
  // NETWORK RENDERING
  // ─────────────────────────────────────────────────────────────

  /// Render a network graph
  ///
  /// **Parameters:**
  /// - `nodes`: List of network nodes with positions
  /// - `edges`: List of edges connecting nodes
  /// - `style`: Visualization style configuration
  Future<void> renderNetwork({
    required List<NetworkNode> nodes,
    required List<NetworkEdge> edges,
    required NetworkVisualizationStyle style,
  }) async {
    await _waitForReady();

    final data = {
      'nodes': nodes
          .map((n) => <String, dynamic>{
                'userId': n.userId,
                'position': [n.position.x, n.position.y, n.position.z],
                'color': n.color,
                'isCenter': n.isCenter,
              })
          .toList(),
      'edges': edges
          .map((e) => <String, dynamic>{
                'from': e.fromIndex,
                'to': e.toIndex,
              })
          .toList(),
      'style': style.toJson(),
    };

    await _evaluateJS('window.networkRenderer.render(${jsonEncode(data)})');
  }

  // ─────────────────────────────────────────────────────────────
  // BIRTH EXPERIENCE
  // ─────────────────────────────────────────────────────────────

  /// Start the birth experience animation
  ///
  /// **Parameters:**
  /// - `knot`: The personality knot being born
  /// - `style`: Visualization style configuration
  Future<void> startBirthExperience({
    required PersonalityKnot knot,
    required KnotVisualizationStyle style,
  }) async {
    await _waitForReady();

    final knot3d = Knot3D.fromBraidData(
      braidData: knot.braidData,
      invariants: knot.invariants,
      agentId: knot.agentId,
    );

    final data = {
      'coordinates': knot3d.coordinates.map((v) => [v.x, v.y, v.z]).toList(),
      'invariants': {
        'crossingNumber': knot.invariants.crossingNumber,
        'writhe': knot.invariants.writhe,
        'signature': knot.invariants.signature,
      },
      'style': style.toJson(),
    };

    await _evaluateJS('window.birthExperience.start(${jsonEncode(data)})');
  }

  // ─────────────────────────────────────────────────────────────
  // ANIMATION CONTROL
  // ─────────────────────────────────────────────────────────────

  /// Set animation time (for worldsheet, string evolution)
  ///
  /// **Parameters:**
  /// - `t`: Time value (0.0 to 1.0)
  Future<void> setAnimationTime(double t) async {
    if (!_isReady) return;
    await _evaluateJS('window.animationController.setTime($t)');
  }

  /// Start/stop animation loop
  Future<void> setAnimationPlaying(bool playing) async {
    if (!_isReady) return;
    await _evaluateJS('window.animationController.setPlaying($playing)');
  }

  // ─────────────────────────────────────────────────────────────
  // CAMERA CONTROL
  // ─────────────────────────────────────────────────────────────

  /// Set camera position
  Future<void> setCameraPosition(Vector3 position, {Vector3? target}) async {
    if (!_isReady) return;
    final t = target ?? Vector3.zero();
    await _evaluateJS('''
      window.cameraController.setPosition(
        ${position.x}, ${position.y}, ${position.z},
        ${t.x}, ${t.y}, ${t.z}
      )
    ''');
  }

  /// Reset camera to default view
  Future<void> resetCamera() async {
    if (!_isReady) return;
    await _evaluateJS('window.cameraController.reset()');
  }

  // ─────────────────────────────────────────────────────────────
  // UNIFORM UPDATES (Fast, for real-time animation)
  // ─────────────────────────────────────────────────────────────

  /// Update shader uniforms (fast operation for real-time updates)
  ///
  /// **Parameters:**
  /// - `uniforms`: Map of uniform name to value
  Future<void> updateUniforms(Map<String, dynamic> uniforms) async {
    if (!_isReady) return;
    await _evaluateJS(
        'window.knotRenderer.updateUniforms(${jsonEncode(uniforms)})');
  }

  /// Update breath phase for breathing knot animation
  Future<void> updateBreathPhase(double phase, double stressLevel) async {
    await updateUniforms({
      'uBreathPhase': phase,
      'uStressLevel': stressLevel,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // CLEANUP
  // ─────────────────────────────────────────────────────────────

  /// Clean up the WebView resources
  Future<void> cleanup() async {
    if (!_isReady) return;
    await _evaluateJS('window.cleanup()');
  }

  /// Dispose of the service
  void dispose() {
    _objectTappedController.close();
    _renderCompleteController.close();
    _phaseChangeController.close();
    _birthCompleteController.close();
    _readyController.close();
    _webGLNotSupportedController.close();
    _errorController.close();
    _metricsController.close();
    _controller = null;
    _isReady = false;
  }

  // ─────────────────────────────────────────────────────────────
  // PUBLIC JS EVALUATION
  // ─────────────────────────────────────────────────────────────

  /// Execute arbitrary JavaScript in the WebView
  ///
  /// Use this for custom operations not covered by other methods.
  Future<void> evaluateJS(String js) async {
    await _evaluateJS(js);
  }

  /// Alias for [evaluateJS] for backward compatibility
  ///
  /// Some widgets reference the bridge via this name; delegates to [_evaluateJS].
  Future<void> evaluateJavascript(String js) async {
    await _evaluateJS(js);
  }

  // ─────────────────────────────────────────────────────────────
  // MOTION-REACTIVE CONVENIENCE METHODS
  // ─────────────────────────────────────────────────────────────

  /// Configure motion reactivity in the Three.js scene
  ///
  /// **Parameters:**
  /// - `reactivity`: Reactivity level name (e.g., 'low', 'medium', 'high')
  /// - `physicsBehavior`: Physics behavior name (e.g., 'float', 'parallax')
  /// - `tiltSensitivity`: Tilt sensitivity multiplier
  /// - `damping`: Damping factor for motion smoothing
  /// - `shakeEnabled`: Whether shake gesture is enabled
  Future<void> setMotionReactivity({
    required String reactivity,
    required String physicsBehavior,
    required double tiltSensitivity,
    required double damping,
    required bool shakeEnabled,
  }) async {
    final config = jsonEncode({
      'reactivity': reactivity,
      'physicsBehavior': physicsBehavior,
      'tiltSensitivity': tiltSensitivity,
      'damping': damping,
      'shakeEnabled': shakeEnabled,
    });
    await _evaluateJS(
      'if(window.setMotionReactivity) window.setMotionReactivity($config)',
    );
  }

  /// Enable/disable and style the bubble container around the knot
  ///
  /// **Parameters:**
  /// - `enabled`: Whether to show the bubble
  /// - `style`: Bubble style name (e.g., 'glass', 'solid')
  Future<void> setBubbleContainer({
    required bool enabled,
    required String style,
  }) async {
    await _evaluateJS(
      'if(window.setBubbleContainer) window.setBubbleContainer($enabled, "$style")',
    );
  }

  /// Add physics simulation to the knot visualization
  ///
  /// **Parameters:**
  /// - `behavior`: Physics behavior name (e.g., 'float', 'parallax', 'bounce')
  Future<void> addPhysicsToKnot({
    required String behavior,
  }) async {
    await _evaluateJS(
      'if(window.addPhysicsToKnot) window.addPhysicsToKnot("$behavior")',
    );
  }

  /// Send device motion data to the Three.js scene for real-time response
  ///
  /// **Parameters:**
  /// - `tiltX`: Device tilt on X axis
  /// - `tiltY`: Device tilt on Y axis
  /// - `gravityX`: Gravity vector X component
  /// - `gravityY`: Gravity vector Y component
  /// - `gravityZ`: Gravity vector Z component
  /// - `shake`: Whether a shake gesture was detected
  Future<void> updateDeviceMotion({
    required double tiltX,
    required double tiltY,
    required double gravityX,
    required double gravityY,
    required double gravityZ,
    required bool shake,
  }) async {
    final motionData = jsonEncode({
      'tilt': {'x': tiltX, 'y': tiltY},
      'gravity': {'x': gravityX, 'y': gravityY, 'z': gravityZ},
      'shake': shake,
    });
    await _evaluateJS(
      'if(window.updateDeviceMotion) window.updateDeviceMotion($motionData)',
    );
  }

  /// Toggle the bubble container visibility
  Future<void> toggleBubble() async {
    await _evaluateJS('if(window.toggleBubble) window.toggleBubble()');
  }

  /// Enable or disable motion response in the Three.js scene
  ///
  /// Used for gesture-motion fusion: disables motion during active touch
  /// to prevent conflicting inputs.
  Future<void> setMotionEnabled(bool enabled) async {
    await _evaluateJS(
      'if(window.setMotionEnabled) window.setMotionEnabled($enabled)',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────

  Future<void> _evaluateJS(String js) async {
    try {
      await _controller?.evaluateJavascript(source: js);
    } catch (e) {
      developer.log('Error evaluating JS: $e', name: _logName);
    }
  }

  String _getUserColor(String agentId) {
    // Generate consistent color from user ID using golden angle
    final hash = agentId.hashCode.abs();
    final hue = (hash % 360).toDouble();
    return 'hsl($hue, 70%, 60%)';
  }
}

/// Network node for graph visualization
class NetworkNode {
  final String userId;
  final Vector3 position;
  final String? color;
  final bool isCenter;

  NetworkNode({
    required this.userId,
    required this.position,
    this.color,
    this.isCenter = false,
  });
}

/// Network edge for graph visualization
class NetworkEdge {
  final int fromIndex;
  final int toIndex;

  NetworkEdge({
    required this.fromIndex,
    required this.toIndex,
  });
}

/// Error from JavaScript visualization code
class VisualizationError {
  /// Context where error occurred (e.g., 'KnotRenderer.render')
  final String context;

  /// Error message
  final String message;

  /// Optional stack trace
  final String? stack;

  VisualizationError({
    required this.context,
    required this.message,
    this.stack,
  });

  @override
  String toString() => 'VisualizationError($context): $message';
}

/// Performance metrics from JavaScript visualization
class VisualizationMetrics {
  /// Frames per second
  final int fps;

  /// Average frame time in milliseconds
  final double avgFrameTime;

  /// Maximum frame time in milliseconds (worst frame)
  final double maxFrameTime;

  /// Number of geometries in memory
  final int geometryCount;

  /// Number of textures in memory
  final int textureCount;

  /// Draw calls per frame
  final int drawCalls;

  /// Triangles rendered per frame
  final int triangles;

  VisualizationMetrics({
    required this.fps,
    required this.avgFrameTime,
    required this.maxFrameTime,
    required this.geometryCount,
    required this.textureCount,
    required this.drawCalls,
    required this.triangles,
  });

  factory VisualizationMetrics.fromJson(Map<String, dynamic> json) {
    return VisualizationMetrics(
      fps: json['fps'] as int? ?? 0,
      avgFrameTime:
          double.tryParse(json['avgFrameTime']?.toString() ?? '0') ?? 0,
      maxFrameTime:
          double.tryParse(json['maxFrameTime']?.toString() ?? '0') ?? 0,
      geometryCount: json['geometryCount'] as int? ?? 0,
      textureCount: json['textureCount'] as int? ?? 0,
      drawCalls: json['drawCalls'] as int? ?? 0,
      triangles: json['triangles'] as int? ?? 0,
    );
  }

  /// Whether performance is acceptable (30+ FPS, frame times under 33ms)
  bool get isPerformingWell => fps >= 30 && maxFrameTime < 33;

  @override
  String toString() =>
      'VisualizationMetrics(fps: $fps, avgFrameTime: ${avgFrameTime.toStringAsFixed(1)}ms)';
}
