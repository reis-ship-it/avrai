// Three.js Visualization Widget
//
// Base widget for Three.js WebView-based 3D visualizations
// Part of 3D Visualization System
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:avrai_admin_app/theme/colors.dart';

import 'package:shimmer/shimmer.dart';
import 'package:avrai_runtime_os/services/visualization/three_js_bridge_service.dart';
import 'package:avrai_runtime_os/services/visualization/visualization_prewarmer.dart';

/// Base widget for Three.js 3D visualizations
///
/// **Features:**
/// - Manages WebView lifecycle
/// - Shows shimmer placeholder during load
/// - Handles gesture forwarding to Three.js
/// - Provides completion callbacks
/// - Supports prewarmed WebView for fast startup
class ThreeJsVisualizationWidget extends StatefulWidget {
  /// Size of the visualization
  final double size;

  /// Width (overrides size if provided)
  final double? width;

  /// Height (overrides size if provided)
  final double? height;

  /// HTML file to load (relative to assets/three_js/)
  final String htmlFile;

  /// Callback when WebView and Three.js are ready
  final void Function(ThreeJsBridgeService bridge)? onReady;

  /// Callback when an object is tapped
  final void Function(String objectId)? onObjectTapped;

  /// Callback when render completes
  final void Function(String type)? onRenderComplete;

  /// Whether to use prewarmed WebView if available
  final bool usePrewarmed;

  /// Background color
  final Color backgroundColor;

  /// Placeholder shimmer color
  final Color shimmerColor;

  /// Whether to show controls (reset camera, etc.)
  final bool showControls;

  const ThreeJsVisualizationWidget({
    super.key,
    this.size = 200.0,
    this.width,
    this.height,
    this.htmlFile = 'index.html',
    this.onReady,
    this.onObjectTapped,
    this.onRenderComplete,
    this.usePrewarmed = true,
    this.backgroundColor = AppColors.black,
    this.shimmerColor = AppColors.grey800,
    this.showControls = false,
  });

  @override
  State<ThreeJsVisualizationWidget> createState() =>
      _ThreeJsVisualizationWidgetState();
}

class _ThreeJsVisualizationWidgetState
    extends State<ThreeJsVisualizationWidget> {
  static const String _logName = 'ThreeJsVisualizationWidget';

  ThreeJsBridgeService? _bridge;
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _isReady = false;
  String? _error;

  StreamSubscription<String>? _objectTappedSub;
  StreamSubscription<String>? _renderCompleteSub;

  double get _width => widget.width ?? widget.size;
  double get _height => widget.height ?? widget.size;

  @override
  void initState() {
    super.initState();
    _tryUsePrewarmed();
  }

  void _tryUsePrewarmed() {
    if (!widget.usePrewarmed) return;

    final prewarmer = VisualizationPrewarmer();
    if (prewarmer.isReady) {
      final bridge = prewarmer.getPrewarmedBridge();
      if (bridge != null) {
        developer.log('Using prewarmed bridge', name: _logName);
        _bridge = bridge;
        _setupListeners();
        setState(() {
          _isLoading = false;
          _isReady = true;
        });
        widget.onReady?.call(_bridge!);
        return;
      }
    }

    // Fall through to create new WebView
    developer.log('Prewarmed not available, creating new WebView',
        name: _logName);
  }

  void _setupListeners() {
    if (_bridge == null) return;

    _objectTappedSub = _bridge!.onObjectTapped.listen((objectId) {
      widget.onObjectTapped?.call(objectId);
    });

    _renderCompleteSub = _bridge!.onRenderComplete.listen((type) {
      widget.onRenderComplete?.call(type);
    });
  }

  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    _controller = controller;
    developer.log('WebView created', name: _logName);

    _bridge = ThreeJsBridgeService();
    await _bridge!.initialize(controller);
    _setupListeners();

    // Wait for ready signal
    _bridge!.onReady.first.then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isReady = true;
        });
        widget.onReady?.call(_bridge!);
      }
    });
  }

  void _onLoadError(InAppWebViewController controller,
      WebResourceRequest request, WebResourceError error) {
    developer.log('WebView error: ${error.description}', name: _logName);
    if (mounted) {
      setState(() {
        _error = error.description;
        _isLoading = false;
      });
    }
  }

  void _onConsoleMessage(
      InAppWebViewController controller, ConsoleMessage message) {
    developer.log('JS: ${message.message}', name: _logName);
  }

  @override
  void dispose() {
    _objectTappedSub?.cancel();
    _renderCompleteSub?.cancel();

    // Only dispose bridge if we created it (not prewarmed)
    if (_bridge != null && _controller != null) {
      _bridge!.cleanup();
      _bridge!.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // WebView (hidden while loading)
          Opacity(
            opacity: _isReady ? 1 : 0,
            child: _buildWebView(),
          ),

          // Loading placeholder
          if (_isLoading) _buildLoadingPlaceholder(),

          // Error state
          if (_error != null) _buildErrorState(),

          // Controls overlay
          if (widget.showControls && _isReady) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    // If we have a prewarmed bridge, don't create a new WebView
    if (_bridge != null && _isReady) {
      // For prewarmed, we'd need to attach the headless WebView
      // For now, still create WebView but bridge is already initialized
    }

    return InAppWebView(
      initialFile: 'assets/three_js/${widget.htmlFile}',
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        transparentBackground: true,
        hardwareAcceleration: true,
        useShouldOverrideUrlLoading: false,
        useOnLoadResource: false,
        useOnDownloadStart: false,
        // Disable scrolling (we handle gestures ourselves)
        disableVerticalScroll: true,
        disableHorizontalScroll: true,
      ),
      onWebViewCreated: _onWebViewCreated,
      onReceivedError: _onLoadError,
      onConsoleMessage: _onConsoleMessage,
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Shimmer.fromColors(
      baseColor: widget.shimmerColor,
      highlightColor: widget.shimmerColor.withValues(alpha: 0.5),
      child: Container(
        width: _width,
        height: _height,
        decoration: BoxDecoration(
          color: widget.shimmerColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.blur_circular,
            size: _width * 0.3,
            color: AppColors.grey600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: _width,
      height: _height,
      color: widget.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: _width * 0.2,
              color: AppColors.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Visualization failed',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: Icons.refresh,
            tooltip: 'Reset view',
            onPressed: () => _bridge?.resetCamera(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: AppColors.grey800.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

/// Specialized widget for knot visualization
class Knot3DVisualizationWidget extends StatelessWidget {
  final double size;
  final void Function(ThreeJsBridgeService bridge)? onReady;
  final void Function(String objectId)? onObjectTapped;
  final bool showControls;

  const Knot3DVisualizationWidget({
    super.key,
    this.size = 200.0,
    this.onReady,
    this.onObjectTapped,
    this.showControls = false,
  });

  @override
  Widget build(BuildContext context) {
    return ThreeJsVisualizationWidget(
      size: size,
      htmlFile: 'index.html',
      onReady: onReady,
      onObjectTapped: onObjectTapped,
      showControls: showControls,
    );
  }
}

/// Specialized widget for birth experience
///
/// Note: This is a StatefulWidget to properly manage stream subscriptions
/// and prevent memory leaks.
class BirthExperienceVisualizationWidget extends StatefulWidget {
  final void Function(ThreeJsBridgeService bridge)? onReady;
  final void Function(String phase)? onPhaseChange;
  final void Function(Map<String, dynamic> data)? onBirthComplete;

  const BirthExperienceVisualizationWidget({
    super.key,
    this.onReady,
    this.onPhaseChange,
    this.onBirthComplete,
  });

  @override
  State<BirthExperienceVisualizationWidget> createState() =>
      _BirthExperienceVisualizationWidgetState();
}

class _BirthExperienceVisualizationWidgetState
    extends State<BirthExperienceVisualizationWidget> {
  StreamSubscription<String>? _phaseSubscription;
  StreamSubscription<Map<String, dynamic>>? _completeSubscription;

  void _onBridgeReady(ThreeJsBridgeService bridge) {
    // Subscribe to birth-specific events and store subscriptions
    _phaseSubscription = bridge.onPhaseChange.listen((phase) {
      widget.onPhaseChange?.call(phase);
    });
    _completeSubscription = bridge.onBirthComplete.listen((data) {
      widget.onBirthComplete?.call(data);
    });
    widget.onReady?.call(bridge);
  }

  @override
  void dispose() {
    // Cancel subscriptions to prevent memory leaks
    _phaseSubscription?.cancel();
    _completeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThreeJsVisualizationWidget(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      htmlFile: 'birth_experience.html',
      usePrewarmed: false, // Birth experience has its own prewarmer
      showControls: false,
      onReady: _onBridgeReady,
    );
  }
}
