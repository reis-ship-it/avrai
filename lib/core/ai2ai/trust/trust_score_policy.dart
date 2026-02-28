// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
class TrustScorePolicy {
  const TrustScorePolicy._();

  static double fromProximity(double proximityScore) {
    return proximityScore * 0.7 + 0.3;
  }
}
