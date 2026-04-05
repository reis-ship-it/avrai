// This file defines the strictly typed boundaries for the Privacy Air Gap.
//
// The goal of the Air Gap is to ensure that raw personal data (texts, emails, GPS)
// completely disappears before it can ever be stored in the permanent engine database.
//
// It forces all data to be distilled into an abstract mathematical representation
// (a SemanticTuple) by a Local AI model running in an isolated execution block.

import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:meta/meta.dart';

/// Represents the raw, toxic data coming from the user's OS or sensors.
///
/// This data is considered radioactive. It must NEVER be persisted to disk.
@immutable
abstract class RawDataPayload {
  final DateTime capturedAt;
  final String
      sourceId; // e.g., 'apple_health', 'calendar_api', 'notification_listener'

  const RawDataPayload({required this.capturedAt, required this.sourceId});

  /// The raw string content (e.g., the body of the text message).
  String get rawContent;
}

/// The core interface for the Privacy Air Gap boundary crossing.
///
/// Implementations of this interface must guarantee that the [RawDataPayload]
/// is destroyed from active memory immediately after extraction, and that ONLY
/// the [SemanticTuple] is returned.
abstract class AirGapContract {
  /// Takes a raw, toxic payload and distills it into abstract semantic meaning.
  ///
  /// The underlying implementation must spin up the isolated Local AI, run the
  /// extraction prompt, and securely wipe the [payload] from memory.
  ///
  /// Throws [PrivacyBreachException] if the operation could not be guaranteed secure.
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload payload);
}

/// Thrown when the Air Gap detects a potential leak or an insecure execution environment.
class PrivacyBreachException implements Exception {
  final String reason;
  PrivacyBreachException(this.reason);

  @override
  String toString() =>
      'PrivacyBreachException: $reason. The Air Gap aborted the operation to protect user data.';
}
