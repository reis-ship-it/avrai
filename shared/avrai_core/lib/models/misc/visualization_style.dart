// Visualization Style Models
//
// Style configurations for Three.js 3D visualizations
// Part of 3D Visualization System
// Patent #31: Topological Knot Theory for Personality Representation

/// Level of detail for visualization
enum VisualizationLOD {
  low, // 50 tubular segments, 4 radial - for small views (<100px)
  medium, // 100 tubular segments, 8 radial - for medium views (100-200px)
  high, // 200 tubular segments, 16 radial - for large views (>200px)
}

/// Base class for visualization styles
abstract class VisualizationStyle {
  /// Convert style to JSON for JavaScript consumption
  Map<String, dynamic> toJson();
}

/// Style configuration for knot visualization
///
/// Used for personal knots on profile, meditation, etc.
class KnotVisualizationStyle extends VisualizationStyle {
  /// Material type: 'metallic', 'glowing', 'translucent', 'standard'
  final String type;

  /// Primary color (hex value as int, e.g., 0x6366f1)
  final int primaryColor;

  /// Secondary color for gradients
  final int secondaryColor;

  /// Glow color (for glowing type)
  final int? glowColor;

  /// Emissive intensity (0.0 to 1.0)
  final double emissiveIntensity;

  /// Glow intensity for bloom effect (0.0 to 1.0)
  final double glowIntensity;

  /// Level of detail
  final VisualizationLOD lod;

  /// Whether to auto-rotate
  final bool autoRotate;

  /// Auto-rotate speed (radians per frame)
  final double autoRotateSpeed;

  KnotVisualizationStyle({
    this.type = 'metallic',
    this.primaryColor = 0x00FF66, // 0xFF000000
    this.secondaryColor = 0x66FF99, // 0xFF000000
    this.glowColor,
    this.emissiveIntensity = 0.3,
    this.glowIntensity = 0.5,
    this.lod = VisualizationLOD.medium,
    this.autoRotate = false,
    this.autoRotateSpeed = 0.5,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'glowColor': glowColor ?? primaryColor,
      'emissiveIntensity': emissiveIntensity,
      'glowIntensity': glowIntensity,
      'lod': lod.name,
      'autoRotate': autoRotate,
      'autoRotateSpeed': autoRotateSpeed,
    };
  }

  /// Create a copy with updated fields
  KnotVisualizationStyle copyWith({
    String? type,
    int? primaryColor,
    int? secondaryColor,
    int? glowColor,
    double? emissiveIntensity,
    double? glowIntensity,
    VisualizationLOD? lod,
    bool? autoRotate,
    double? autoRotateSpeed,
  }) {
    return KnotVisualizationStyle(
      type: type ?? this.type,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      glowColor: glowColor ?? this.glowColor,
      emissiveIntensity: emissiveIntensity ?? this.emissiveIntensity,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      lod: lod ?? this.lod,
      autoRotate: autoRotate ?? this.autoRotate,
      autoRotateSpeed: autoRotateSpeed ?? this.autoRotateSpeed,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PRESET STYLES
  // ─────────────────────────────────────────────────────────────

  /// Metallic style for profile display
  ///
  /// Polished, reflective appearance showing "refined" personality
  static KnotVisualizationStyle metallic({
    int? primaryColor,
    VisualizationLOD lod = VisualizationLOD.medium,
  }) {
    return KnotVisualizationStyle(
      type: 'metallic',
      primaryColor: primaryColor ?? 0x00FF66,
      secondaryColor: 0x66FF99,
      emissiveIntensity: 0.1,
      glowIntensity: 0.3,
      lod: lod,
    );
  }

  /// Glowing style for meditation/breathing
  ///
  /// Translucent with soft glow, pulsing with breath
  static KnotVisualizationStyle glowing({
    int? primaryColor,
    VisualizationLOD lod = VisualizationLOD.medium,
  }) {
    return KnotVisualizationStyle(
      type: 'glowing',
      primaryColor: primaryColor ?? 0x00FF66,
      secondaryColor: 0x66FF99,
      glowColor: 0x00FF66,
      emissiveIntensity: 0.5,
      glowIntensity: 0.8,
      lod: lod,
    );
  }

  /// Translucent style for overlays and glass effects
  static KnotVisualizationStyle translucent({
    int? primaryColor,
    VisualizationLOD lod = VisualizationLOD.medium,
  }) {
    return KnotVisualizationStyle(
      type: 'translucent',
      primaryColor: primaryColor ?? 0x00FF66,
      secondaryColor: 0x66FF99,
      emissiveIntensity: 0.2,
      glowIntensity: 0.4,
      lod: lod,
    );
  }

  /// Small profile icon style
  ///
  /// Optimized for small views (60px profile icons)
  static KnotVisualizationStyle profileIcon({int? primaryColor}) {
    return KnotVisualizationStyle(
      type: 'metallic',
      primaryColor: primaryColor ?? 0x00FF66,
      secondaryColor: 0x66FF99,
      emissiveIntensity: 0.2,
      glowIntensity: 0.3,
      lod: VisualizationLOD.low,
      autoRotate: true,
      autoRotateSpeed: 0.3,
    );
  }

  /// Birth experience style
  ///
  /// Maximum glow and drama for the knot birth animation
  static KnotVisualizationStyle birthExperience({int? primaryColor}) {
    return KnotVisualizationStyle(
      type: 'glowing',
      primaryColor: primaryColor ?? 0x00FF66,
      secondaryColor: 0x66FF99,
      glowColor: 0xFFFFFF,
      emissiveIntensity: 0.7,
      glowIntensity: 1.0,
      lod: VisualizationLOD.high,
    );
  }
}

/// Style configuration for fabric visualization
///
/// Used for community fabrics showing woven strands
class FabricVisualizationStyle extends VisualizationStyle {
  /// Strand radius
  final double strandRadius;

  /// Whether to show weave pattern
  final bool showWeave;

  /// Highlight color for selected strands
  final int highlightColor;

  /// Background glow intensity
  final double glowIntensity;

  /// Level of detail
  final VisualizationLOD lod;

  FabricVisualizationStyle({
    this.strandRadius = 0.05,
    this.showWeave = true,
    this.highlightColor = 0xFFFFFF,
    this.glowIntensity = 0.3,
    this.lod = VisualizationLOD.medium,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'strandRadius': strandRadius,
      'showWeave': showWeave,
      'highlightColor': highlightColor,
      'glowIntensity': glowIntensity,
      'lod': lod.name,
    };
  }

  /// Default woven textile style
  static FabricVisualizationStyle woven({
    VisualizationLOD lod = VisualizationLOD.medium,
  }) {
    return FabricVisualizationStyle(
      strandRadius: 0.05,
      showWeave: true,
      highlightColor: 0xFFFFFF,
      glowIntensity: 0.3,
      lod: lod,
    );
  }
}

/// Style configuration for worldsheet visualization
///
/// Used for group evolution surfaces
class WorldsheetVisualizationStyle extends VisualizationStyle {
  /// Primary surface color
  final int primaryColor;

  /// Secondary color for gradients
  final int secondaryColor;

  /// Surface transparency (0.0 to 1.0)
  final double transparency;

  /// Whether to show wireframe overlay
  final bool showWireframe;

  /// Wireframe opacity
  final double wireframeOpacity;

  /// Glow intensity
  final double glowIntensity;

  /// Level of detail
  final VisualizationLOD lod;

  WorldsheetVisualizationStyle({
    this.primaryColor = 0x00FF66,
    this.secondaryColor = 0x66FF99,
    this.transparency = 0.3,
    this.showWireframe = true,
    this.wireframeOpacity = 0.1,
    this.glowIntensity = 0.4,
    this.lod = VisualizationLOD.medium,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'transparency': transparency,
      'showWireframe': showWireframe,
      'wireframeOpacity': wireframeOpacity,
      'glowIntensity': glowIntensity,
      'lod': lod.name,
    };
  }

  /// Flowing surface style
  static WorldsheetVisualizationStyle flowing({
    int? primaryColor,
    VisualizationLOD lod = VisualizationLOD.medium,
  }) {
    return WorldsheetVisualizationStyle(
      primaryColor: primaryColor ?? 0x00FF66,
      secondaryColor: 0x66FF99,
      transparency: 0.3,
      showWireframe: true,
      wireframeOpacity: 0.1,
      glowIntensity: 0.4,
      lod: lod,
    );
  }
}

/// Style configuration for network graph visualization
///
/// Used for AI2AI connections display
class NetworkVisualizationStyle extends VisualizationStyle {
  /// Node color
  final int nodeColor;

  /// Edge color
  final int edgeColor;

  /// Center node color (user's node)
  final int centerColor;

  /// Edge opacity
  final double edgeOpacity;

  /// Whether to show flow particles
  final bool showFlow;

  /// Glow intensity
  final double glowIntensity;

  NetworkVisualizationStyle({
    this.nodeColor = 0x00FF66,
    this.edgeColor = 0x00FF66,
    this.centerColor = 0xFFFFFF,
    this.edgeOpacity = 0.5,
    this.showFlow = true,
    this.glowIntensity = 0.6,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'nodeColor': nodeColor,
      'edgeColor': edgeColor,
      'centerColor': centerColor,
      'edgeOpacity': edgeOpacity,
      'showFlow': showFlow,
      'glowIntensity': glowIntensity,
    };
  }

  /// Sci-fi network style
  static NetworkVisualizationStyle scifi({int? primaryColor}) {
    return NetworkVisualizationStyle(
      nodeColor: primaryColor ?? 0x00FF66,
      edgeColor: primaryColor ?? 0x00FF66,
      centerColor: 0xFFFFFF,
      edgeOpacity: 0.5,
      showFlow: true,
      glowIntensity: 0.6,
    );
  }
}

/// Helper to create style from AppColors
class VisualizationStyleFactory {
  /// Create knot style using brand colors
  static KnotVisualizationStyle knotFromBrand({
    String type = 'metallic',
    VisualizationLOD lod = VisualizationLOD.medium,
    bool autoRotate = false,
  }) {
    return KnotVisualizationStyle(
      type: type,
      primaryColor: 0xFF000000,
      secondaryColor: 0xFF000000,
      glowColor: 0xFF000000,
      lod: lod,
      autoRotate: autoRotate,
    );
  }

  /// Create fabric style using brand colors
  static FabricVisualizationStyle fabricFromBrand({
    VisualizationLOD lod = VisualizationLOD.medium,
  }) {
    return FabricVisualizationStyle(
      highlightColor: 0xFF000000,
      lod: lod,
    );
  }

  /// Create worldsheet style using brand colors
  static WorldsheetVisualizationStyle worldsheetFromBrand({
    VisualizationLOD lod = VisualizationLOD.medium,
  }) {
    return WorldsheetVisualizationStyle(
      primaryColor: 0xFF000000,
      secondaryColor: 0xFF000000,
      lod: lod,
    );
  }

  /// Create network style using brand colors
  static NetworkVisualizationStyle networkFromBrand() {
    return NetworkVisualizationStyle(
      nodeColor: 0xFF000000,
      edgeColor: 0xFF000000,
      centerColor: 0xFF000000,
    );
  }
}
