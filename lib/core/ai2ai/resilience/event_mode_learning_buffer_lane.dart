import 'package:avrai/core/ai2ai/resilience/event_mode_buffered_learning_insight.dart';

class EventModeLearningBufferLane {
  const EventModeLearningBufferLane._();

  static void buffer({
    required List<EventModeBufferedLearningInsight> buffer,
    required EventModeBufferedLearningInsight insight,
  }) {
    // In-memory buffer only (v1). This prevents event-time personality writes,
    // while still preserving observations for post-event consolidation.
    const int maxItems = 500;
    if (buffer.length >= maxItems) {
      buffer.removeAt(0);
    }
    buffer.add(insight);
  }
}
