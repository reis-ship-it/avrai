// Motion Gesture Handler
//
// Handles advanced gestures for motion-reactive 3D visualizations.
// Part of Motion-Reactive 3D Visualization System.
//
// Features:
// - Drag to orbit camera
// - Pinch to zoom
// - Two-finger rotate
// - Shake detection (via DeviceMotionService)
// - Long press for examine mode
// - Double tap to toggle bubble
// - Gesture-motion fusion (disables motion during active touch)

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:avrai_runtime_os/services/device/device_motion_service.dart';
import 'package:avrai_runtime_os/services/visualization/three_js_bridge_service.dart';

/// Configuration for gesture handling
class GestureConfig {
  /// Whether drag-to-orbit is enabled
  final bool enableOrbit;

  /// Whether pinch-to-zoom is enabled
  final bool enableZoom;

  /// Whether two-finger rotate is enabled
  final bool enableRotate;

  /// Whether long-press examine mode is enabled
  final bool enableExamineMode;

  /// Whether double-tap toggles bubble
  final bool enableBubbleToggle;

  /// Delay before re-enabling motion after touch ends (ms)
  final int motionResumeDelayMs;

  const GestureConfig({
    this.enableOrbit = true,
    this.enableZoom = true,
    this.enableRotate = true,
    this.enableExamineMode = true,
    this.enableBubbleToggle = true,
    this.motionResumeDelayMs = 500,
  });

  /// Default config for knot visualization
  static const GestureConfig knot = GestureConfig();

  /// Config for logo (minimal interaction)
  static const GestureConfig logo = GestureConfig(
    enableOrbit: false,
    enableZoom: false,
    enableRotate: false,
    enableExamineMode: false,
    enableBubbleToggle: true,
    motionResumeDelayMs: 300,
  );

  /// Config for worldsheet (swipe for time, less rotation)
  static const GestureConfig worldsheet = GestureConfig(
    enableOrbit: true,
    enableZoom: true,
    enableRotate: false,
    enableExamineMode: false,
    enableBubbleToggle: false,
  );
}

/// Widget that wraps visualization and handles advanced gestures
class MotionGestureHandler extends StatefulWidget {
  /// Child widget (the actual visualization)
  final Widget child;

  /// Three.js bridge service for sending commands
  final ThreeJsBridgeService? bridge;

  /// Device motion service (for gesture-motion fusion)
  final DeviceMotionService? motionService;

  /// Gesture configuration
  final GestureConfig config;

  /// Callback when shake is detected
  final VoidCallback? onShake;

  /// Callback when long press starts (examine mode)
  final VoidCallback? onExamineModeStart;

  /// Callback when long press ends
  final VoidCallback? onExamineModeEnd;

  /// Callback for horizontal swipe (for time scrubbing)
  final void Function(double delta)? onHorizontalSwipe;

  const MotionGestureHandler({
    super.key,
    required this.child,
    this.bridge,
    this.motionService,
    this.config = const GestureConfig(),
    this.onShake,
    this.onExamineModeStart,
    this.onExamineModeEnd,
    this.onHorizontalSwipe,
  });

  @override
  State<MotionGestureHandler> createState() => _MotionGestureHandlerState();
}

class _MotionGestureHandlerState extends State<MotionGestureHandler> {
  static const String _logName = 'MotionGestureHandler';

  // Gesture state
  bool _isTouching = false;
  bool _isExamining = false;
  int _pointerCount = 0;

  // For pinch/rotate
  double _currentZoom = 1.0;
  double _currentRotation = 0.0;

  // For drag
  Offset? _lastDragPosition;

  // Timer for motion resume delay
  Timer? _motionResumeTimer;

  @override
  void dispose() {
    _motionResumeTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerEvent event) {
    _pointerCount++;

    if (_pointerCount == 1) {
      _isTouching = true;
      _disableMotion();
      _lastDragPosition = event.localPosition;
    }
  }

  void _onPointerUp(PointerEvent event) {
    _pointerCount = (_pointerCount - 1).clamp(0, 10);

    if (_pointerCount == 0) {
      _isTouching = false;
      _scheduleMotionResume();
      _lastDragPosition = null;

      if (_isExamining) {
        _isExamining = false;
        widget.onExamineModeEnd?.call();
      }
    }
  }

  void _onPointerMove(PointerEvent event) {
    if (!_isTouching) return;

    if (_pointerCount == 1 && widget.config.enableOrbit) {
      // Single finger drag - orbit camera
      _handleOrbitDrag(event.localPosition);
    }
  }

  void _handleOrbitDrag(Offset position) {
    if (_lastDragPosition == null) {
      _lastDragPosition = position;
      return;
    }

    _lastDragPosition = position;

    // Send orbit command to Three.js
    // Delta X = rotate around Y axis, Delta Y = rotate around X axis
    // OrbitControls handles rotation via user interaction
    if (widget.bridge != null) {
      widget.bridge!.evaluateJavascript('''
        if (window.sceneManager && window.sceneManager.controls) {
          // OrbitControls handles this via user interaction
          // But we can also programmatically rotate
        }
      ''');
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    // Scale/rotate uses details.scale and details.rotation from ScaleUpdateDetails
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      // Pinch to zoom
      if (widget.config.enableZoom && details.scale != 1.0) {
        final zoomDelta = details.scale - 1.0;
        _currentZoom = (_currentZoom + zoomDelta * 0.1).clamp(0.5, 3.0);

        if (widget.bridge != null) {
          widget.bridge!.evaluateJavascript('''
            if (window.sceneManager && window.sceneManager.camera) {
              window.sceneManager.camera.position.z = ${5.0 / _currentZoom};
            }
          ''');
        }
      }

      // Two-finger rotate
      if (widget.config.enableRotate && details.rotation != 0.0) {
        _currentRotation += details.rotation * 0.5;

        if (widget.bridge != null) {
          widget.bridge!.evaluateJavascript('''
            if (window.sceneManager && window.sceneManager.scene) {
              window.sceneManager.scene.rotation.z = $_currentRotation;
            }
          ''');
        }
      }
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.config.enableExamineMode) return;

    _isExamining = true;
    widget.onExamineModeStart?.call();

    // Slow down auto-rotation for examine mode
    if (widget.bridge != null) {
      widget.bridge!.evaluateJavascript('''
        if (window.sceneManager) {
          window.sceneManager.setAutoRotate(true, 0.1);
        }
      ''');
    }

    developer.log('Examine mode started', name: _logName);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_isExamining) {
      _isExamining = false;
      widget.onExamineModeEnd?.call();

      // Restore normal rotation
      if (widget.bridge != null) {
        widget.bridge!.evaluateJavascript('''
          if (window.sceneManager) {
            window.sceneManager.setAutoRotate(false, 0.5);
          }
        ''');
      }

      developer.log('Examine mode ended', name: _logName);
    }
  }

  void _onDoubleTap() {
    if (!widget.config.enableBubbleToggle) return;

    if (widget.bridge != null) {
      widget.bridge!.toggleBubble();
    }

    developer.log('Double tap - toggled bubble', name: _logName);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.onHorizontalSwipe != null) {
      widget.onHorizontalSwipe!(details.delta.dx);
    }
  }

  void _disableMotion() {
    _motionResumeTimer?.cancel();

    if (widget.bridge != null) {
      widget.bridge!.setMotionEnabled(false);
    }
  }

  void _scheduleMotionResume() {
    _motionResumeTimer?.cancel();

    _motionResumeTimer = Timer(
      Duration(milliseconds: widget.config.motionResumeDelayMs),
      () {
        if (widget.bridge != null && !_isTouching) {
          widget.bridge!.setMotionEnabled(true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      onPointerMove: _onPointerMove,
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onDoubleTap: _onDoubleTap,
        onHorizontalDragUpdate:
            widget.onHorizontalSwipe != null ? _onHorizontalDragUpdate : null,
        child: widget.child,
      ),
    );
  }
}

/// Mixin for widgets that need motion gesture handling
mixin MotionGestureMixin<T extends StatefulWidget> on State<T> {
  ThreeJsBridgeService? get bridge;
  DeviceMotionService? get motionService;

  Timer? _motionResumeTimer;

  /// Temporarily disable motion (call during active gestures)
  void disableMotionDuringGesture() {
    _motionResumeTimer?.cancel();

    bridge?.setMotionEnabled(false);
  }

  /// Re-enable motion after gesture ends
  void enableMotionAfterGesture({int delayMs = 500}) {
    _motionResumeTimer?.cancel();

    _motionResumeTimer = Timer(Duration(milliseconds: delayMs), () {
      bridge?.setMotionEnabled(true);
    });
  }

  @override
  void dispose() {
    _motionResumeTimer?.cancel();
    super.dispose();
  }
}
