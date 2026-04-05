class DesignFeatureFlags {
  const DesignFeatureFlags._();

  static const bool enableImmersiveShell =
      bool.fromEnvironment('ENABLE_PORTAL_SHELL', defaultValue: false);

  static const bool enableKnotBirthExperience =
      bool.fromEnvironment('ENABLE_KNOT_BIRTH_EXPERIENCE', defaultValue: true);

  static const bool enableWorldPlanesRoute =
      bool.fromEnvironment('ENABLE_WORLD_PLANES_ROUTE', defaultValue: true);

  static const bool enableHeavyWorldPlaneEffects = bool.fromEnvironment(
    'ENABLE_HEAVY_WORLD_PLANE_EFFECTS',
    defaultValue: true,
  );
}
