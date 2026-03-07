class SignatureConfidenceService {
  const SignatureConfidenceService();

  double blend(Iterable<double> inputs, {double defaultValue = 0.5}) {
    final values = inputs.toList();
    if (values.isEmpty) {
      return defaultValue;
    }
    return (values.fold<double>(0.0, (sum, value) => sum + value) /
            values.length)
        .clamp(0.0, 1.0);
  }

  double completeness({
    required int presentFields,
    required int expectedFields,
    double floor = 0.35,
  }) {
    if (expectedFields <= 0) {
      return floor;
    }
    return (floor + ((presentFields / expectedFields) * (1.0 - floor)))
        .clamp(0.0, 1.0);
  }

  double dimensionConfidence(Map<String, double> confidences) {
    if (confidences.isEmpty) {
      return 0.5;
    }
    return blend(confidences.values);
  }
}
