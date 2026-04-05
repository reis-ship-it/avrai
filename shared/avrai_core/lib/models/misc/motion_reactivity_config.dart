// Motion Reactivity Configuration
//
// Defines context-aware motion reactivity levels for 3D visualizations.
// Part of Motion-Reactive 3D Visualization System.
//
// Each visualization context has appropriate reactivity:
// - Subtle: Light parallax/tilt (logos, small widgets)
// - Moderate: Gentle physics with damping (profile views)
// - Dynamic: Full physics simulation (birth experience, network)
// - Minimal: Breathing sync only (meditation)

/// Motion reactivity level
enum MotionReactivity {
  /// No motion response (static screenshots, disabled)
  none,

  /// Minimal motion - breathing sync only (meditation)
  minimal,

  /// Subtle parallax and tilt effects (logos, small widgets)
  subtle,

  /// Moderate physics with damping (profile knots, fabric)
  moderate,

  /// Full physics simulation (birth experience, network)
  dynamic,
}

/// Bubble container visual style
enum BubbleStyle {
  /// No bubble container
  none,

  /// Glass-like transparent bubble
  glass,

  /// Frosted/matte bubble surface
  frosted,

  /// Iridescent soap-bubble effect
  iridescent,

  /// Liquid-filled bubble (contents slosh)
  liquid,
}

/// Physics behavior mode for 3D objects
enum PhysicsBehavior {
  /// No physics - static position
  static,

  /// Parallax shift based on tilt (2D offset)
  parallax,

  /// Pendulum swing (hangs from center, swings with gravity)
  pendulum,

  /// Float/drift with gentle momentum
  float,

  /// Full gravity and collision physics
  fullPhysics,
}

/// Configuration for motion-reactive visualization behavior
class MotionReactivityConfig {
  /// Overall reactivity level
  final MotionReactivity reactivity;

  /// Bubble container style
  final BubbleStyle bubbleStyle;

  /// Physics behavior for the main object
  final PhysicsBehavior physicsBehavior;

  /// Tilt sensitivity multiplier (0-1)
  final double tiltSensitivity;

  /// Physics damping factor (0-1, higher = more damping)
  final double damping;

  /// Whether shake gesture is enabled
  final bool shakeEnabled;

  /// What shake does (reset view, sparkle, reorganize, etc.)
  final ShakeAction shakeAction;

  /// Auto-rotate when idle
  final bool autoRotate;

  /// Auto-rotate speed (radians per second)
  final double autoRotateSpeed;

  /// Whether to show particle effects
  final bool particlesEnabled;

  /// Particle count (affects performance)
  final int particleCount;

  const MotionReactivityConfig({
    this.reactivity = MotionReactivity.moderate,
    this.bubbleStyle = BubbleStyle.none,
    this.physicsBehavior = PhysicsBehavior.parallax,
    this.tiltSensitivity = 0.5,
    this.damping = 0.9,
    this.shakeEnabled = true,
    this.shakeAction = ShakeAction.resetView,
    this.autoRotate = false,
    this.autoRotateSpeed = 0.5,
    this.particlesEnabled = false,
    this.particleCount = 50,
  });

  /// Preset for knot logo in app bar (subtle, small)
  factory MotionReactivityConfig.knotLogo() {
    return const MotionReactivityConfig(
      reactivity: MotionReactivity.subtle,
      bubbleStyle: BubbleStyle.glass,
      physicsBehavior: PhysicsBehavior.parallax,
      tiltSensitivity: 0.3,
      damping: 0.95,
      shakeEnabled: false,
      shakeAction: ShakeAction.none,
      autoRotate: true,
      autoRotateSpeed: 0.3,
      particlesEnabled: false,
      particleCount: 0,
    );
  }

  /// Preset for profile page knot (moderate interaction)
  factory MotionReactivityConfig.profileKnot() {
    return const MotionReactivityConfig(
      reactivity: MotionReactivity.moderate,
      bubbleStyle: BubbleStyle.glass,
      physicsBehavior: PhysicsBehavior.pendulum,
      tiltSensitivity: 0.5,
      damping: 0.9,
      shakeEnabled: true,
      shakeAction: ShakeAction.resetView,
      autoRotate: false,
      autoRotateSpeed: 0.0,
      particlesEnabled: false,
      particleCount: 0,
    );
  }

  /// Preset for meditation breathing knot (minimal, calm)
  factory MotionReactivityConfig.meditation() {
    return const MotionReactivityConfig(
      reactivity: MotionReactivity.minimal,
      bubbleStyle: BubbleStyle.none,
      physicsBehavior: PhysicsBehavior.static,
      tiltSensitivity: 0.0,
      damping: 1.0,
      shakeEnabled: false,
      shakeAction: ShakeAction.none,
      autoRotate: false,
      autoRotateSpeed: 0.0,
      particlesEnabled: true,
      particleCount: 30,
    );
  }

  /// Preset for birth experience (full physics)
  factory MotionReactivityConfig.birthExperience() {
    return const MotionReactivityConfig(
      reactivity: MotionReactivity.dynamic,
      bubbleStyle: BubbleStyle.none,
      physicsBehavior: PhysicsBehavior.fullPhysics,
      tiltSensitivity: 0.8,
      damping: 0.85,
      shakeEnabled: true,
      shakeAction: ShakeAction.sparkle,
      autoRotate: false,
      autoRotateSpeed: 0.0,
      particlesEnabled: true,
      particleCount: 200,
    );
  }

  /// Preset for fabric visualization (moderate, hangs)
  factory MotionReactivityConfig.fabric() {
    return const MotionReactivityConfig(
      reactivity: MotionReactivity.moderate,
      bubbleStyle: BubbleStyle.none,
      physicsBehavior: PhysicsBehavior.pendulum,
      tiltSensitivity: 0.6,
      damping: 0.88,
      shakeEnabled: true,
      shakeAction: ShakeAction.tangle,
      autoRotate: false,
      autoRotateSpeed: 0.0,
      particlesEnabled: false,
      particleCount: 0,
    );
  }

  /// Preset for worldsheet 4D visualization (subtle, time-scrub)
  factory MotionReactivityConfig.worldsheet() {
    return const MotionReactivityConfig(
      reactivity: MotionReactivity.subtle,
      bubbleStyle: BubbleStyle.none,
      physicsBehavior: PhysicsBehavior.parallax,
      tiltSensitivity: 0.4,
      damping: 0.92,
      shakeEnabled: true,
      shakeAction: ShakeAction.resetView,
      autoRotate: false,
      autoRotateSpeed: 0.0,
      particlesEnabled: false,
      particleCount: 0,
    );
  }

  /// Preset for network visualization (dynamic, reorganize)
  factory MotionReactivityConfig.network() {
    return const MotionReactivityConfig(
      reactivity: MotionReactivity.dynamic,
      bubbleStyle: BubbleStyle.none,
      physicsBehavior: PhysicsBehavior.float,
      tiltSensitivity: 0.7,
      damping: 0.9,
      shakeEnabled: true,
      shakeAction: ShakeAction.reorganize,
      autoRotate: false,
      autoRotateSpeed: 0.0,
      particlesEnabled: true,
      particleCount: 100,
    );
  }

  /// Create a copy with modified values
  MotionReactivityConfig copyWith({
    MotionReactivity? reactivity,
    BubbleStyle? bubbleStyle,
    PhysicsBehavior? physicsBehavior,
    double? tiltSensitivity,
    double? damping,
    bool? shakeEnabled,
    ShakeAction? shakeAction,
    bool? autoRotate,
    double? autoRotateSpeed,
    bool? particlesEnabled,
    int? particleCount,
  }) {
    return MotionReactivityConfig(
      reactivity: reactivity ?? this.reactivity,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      physicsBehavior: physicsBehavior ?? this.physicsBehavior,
      tiltSensitivity: tiltSensitivity ?? this.tiltSensitivity,
      damping: damping ?? this.damping,
      shakeEnabled: shakeEnabled ?? this.shakeEnabled,
      shakeAction: shakeAction ?? this.shakeAction,
      autoRotate: autoRotate ?? this.autoRotate,
      autoRotateSpeed: autoRotateSpeed ?? this.autoRotateSpeed,
      particlesEnabled: particlesEnabled ?? this.particlesEnabled,
      particleCount: particleCount ?? this.particleCount,
    );
  }

  /// Convert to JSON for Three.js bridge
  Map<String, dynamic> toJson() {
    return {
      'reactivity': reactivity.name,
      'bubbleStyle': bubbleStyle.name,
      'physicsBehavior': physicsBehavior.name,
      'tiltSensitivity': tiltSensitivity,
      'damping': damping,
      'shakeEnabled': shakeEnabled,
      'shakeAction': shakeAction.name,
      'autoRotate': autoRotate,
      'autoRotateSpeed': autoRotateSpeed,
      'particlesEnabled': particlesEnabled,
      'particleCount': particleCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MotionReactivityConfig &&
        other.reactivity == reactivity &&
        other.bubbleStyle == bubbleStyle &&
        other.physicsBehavior == physicsBehavior &&
        other.tiltSensitivity == tiltSensitivity &&
        other.damping == damping &&
        other.shakeEnabled == shakeEnabled &&
        other.shakeAction == shakeAction &&
        other.autoRotate == autoRotate &&
        other.autoRotateSpeed == autoRotateSpeed &&
        other.particlesEnabled == particlesEnabled &&
        other.particleCount == particleCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      reactivity,
      bubbleStyle,
      physicsBehavior,
      tiltSensitivity,
      damping,
      shakeEnabled,
      shakeAction,
      autoRotate,
      autoRotateSpeed,
      particlesEnabled,
      particleCount,
    );
  }
}

/// Actions triggered by shake gesture
enum ShakeAction {
  /// No action
  none,

  /// Reset camera to default view
  resetView,

  /// Trigger sparkle/shimmer effect
  sparkle,

  /// Reorganize layout (network nodes)
  reorganize,

  /// Toggle tangle/untangle (fabric)
  tangle,
}
