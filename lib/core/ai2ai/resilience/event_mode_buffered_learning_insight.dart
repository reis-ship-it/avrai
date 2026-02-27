class EventModeBufferedLearningInsight {
  final String source; // passive | inbox
  final String? insightId;
  final String senderDeviceId;
  final DateTime receivedAt;
  final double learningQuality;
  final Map<String, double> deltas;

  const EventModeBufferedLearningInsight({
    required this.source,
    required this.insightId,
    required this.senderDeviceId,
    required this.receivedAt,
    required this.learningQuality,
    required this.deltas,
  });
}
