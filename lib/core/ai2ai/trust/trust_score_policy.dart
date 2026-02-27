class TrustScorePolicy {
  const TrustScorePolicy._();

  static double fromProximity(double proximityScore) {
    return proximityScore * 0.7 + 0.3;
  }
}
