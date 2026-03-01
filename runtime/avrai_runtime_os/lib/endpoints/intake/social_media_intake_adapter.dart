import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'dart:developer' as developer;

class SocialMediaFeedPayload extends RawDataPayload {
  final String _feedJsonChunk;

  const SocialMediaFeedPayload({
    required super.capturedAt,
    required String sourcePlatform,
    required String feedJsonChunk,
  })  : _feedJsonChunk = feedJsonChunk,
        super(sourceId: 'social_media_$sourcePlatform');

  @override
  String get rawContent => _feedJsonChunk;
}

/// Collects raw social media feed data (Instagram/Twitter exports),
/// strips personal identifiers, and routes the raw text blocks to the Air Gap.
class SocialMediaIntakeAdapter {
  final AirGapContract _airGap;

  SocialMediaIntakeAdapter(this._airGap);

  /// Processes chunks of a user's authorized social media export.
  Future<void> ingestSocialFeedChunk(
      String platform, String rawJsonData) async {
    developer.log('SocialMediaAdapter: Ingesting raw feed from $platform',
        name: 'IntakeAdapter');

    // Note: The adapter could theoretically do light pre-scrubbing (like regexing out SSNs)
    // before even hitting the Air Gap, but the Air Gap is the ultimate safety net.

    final payload = SocialMediaFeedPayload(
      capturedAt: DateTime.now(),
      sourcePlatform: platform,
      feedJsonChunk: rawJsonData,
    );

    try {
      developer.log(
          'SocialMediaAdapter: Pushing social feed context to Air Gap...',
          name: 'IntakeAdapter');
      final List<SemanticTuple> tuples = await _airGap.scrubAndExtract(payload);
      developer.log(
          'SocialMediaAdapter: Extracted ${tuples.length} abstract personality/vibe tuples from $platform feed.',
          name: 'IntakeAdapter');
    } on PrivacyBreachException catch (e) {
      developer.log('SocialMediaAdapter: Air Gap aborted on social feed! $e',
          name: 'IntakeAdapter');
    }
  }
}
