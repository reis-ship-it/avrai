// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/event_mode_buffered_learning_insight.dart';

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
