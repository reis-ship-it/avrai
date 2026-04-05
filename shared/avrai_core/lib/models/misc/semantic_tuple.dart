// This file defines the strictly typed abstract knowledge node that comes out
// of the Privacy Air Gap.
//
// Once a Tuple is created, the raw source (e.g. an email or text) MUST be destroyed.

/// The abstract "Currency" of the AVRAI system.
///
/// A SemanticTuple is a scrubbed, mathematical representation of a fact, event,
/// or preference inferred from raw data.
///
/// Example: Instead of storing the text message 'Me and John are getting coffee
/// at Starbucks on 5th Ave at 9AM', the Air Gap produces:
/// SemanticTuple(
///   subject: 'user_self',
///   predicate: 'prefers_activity',
///   object: 'morning_coffee',
///   confidence: 0.85,
/// )
class SemanticTuple {
  final String id;

  /// Determines what kind of abstract node this is (e.g., 'preference', 'routine', 'social_bond')
  final String category;

  final String subject;
  final String predicate;
  final String object;

  /// The AI Scrubber's confidence in this abstract extraction.
  final double confidence;

  /// Required: The timestamp when this abstract meaning was established.
  final DateTime extractedAt;

  SemanticTuple({
    required this.id,
    required this.category,
    required this.subject,
    required this.predicate,
    required this.object,
    required this.confidence,
    required this.extractedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'subject': subject,
        'predicate': predicate,
        'object': object,
        'confidence': confidence,
        'extracted_at': extractedAt.toIso8601String(),
      };
}
