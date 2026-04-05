import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/models/air_gap/air_gap_compression_models.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/services/intake/air_gap_compression_runtime_service.dart';
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
  final WhatRuntimeIngestionService? _whatIngestion;
  final RuntimeAirGapCompressionService _compressionService;

  SocialMediaIntakeAdapter(
    this._airGap, {
    WhatRuntimeIngestionService? whatIngestion,
    RuntimeAirGapCompressionService compressionService =
        const RuntimeAirGapCompressionService(),
  })  : _whatIngestion = whatIngestion,
        _compressionService = compressionService;

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
      final compressionBundle = _compressionService.compressSemanticTuples(
        contractId:
            'social_media_${platform}_${payload.capturedAt.microsecondsSinceEpoch}',
        tuples: tuples,
        environmentId: _compressionService.buildEnvironmentId(
          surface: 'social_media',
          scopeKey: platform,
        ),
        primaryLayer: AirGapKnowledgeLayer.personal,
        privacyLadderTag: 'amber',
        provenanceRefs: tuples.map((tuple) => tuple.id).toList(growable: false),
        metadata: <String, dynamic>{
          'platform': platform,
          'payloadLength': rawJsonData.length,
        },
      );
      developer.log(
          'SocialMediaAdapter: Extracted ${tuples.length} abstract personality/vibe tuples from $platform feed.',
          name: 'IntakeAdapter');
      if (_whatIngestion != null && tuples.isNotEmpty) {
        await _whatIngestion.ingestSemanticTuples(
          source: 'social_media_intake_adapter',
          entityRef: DefaultWhatRuntimeIngestionService.deterministicEntityRef(
            'social_media',
            <String, Object?>{
              'platform': platform,
              'capturedAt': payload.capturedAt.toIso8601String(),
              'length': rawJsonData.length,
            },
          ),
          tuples: tuples,
          lineageRef:
              'social_media:$platform:${payload.capturedAt.microsecondsSinceEpoch}',
        );
        await _whatIngestion.ingestPluginSemanticObservation(
          source: 'social_media_intake_adapter',
          entityRef: DefaultWhatRuntimeIngestionService.deterministicEntityRef(
            'social_media',
            <String, Object?>{
              'platform': platform,
              'capturedAt': payload.capturedAt.toIso8601String(),
              'length': rawJsonData.length,
            },
          ),
          observedAtUtc: payload.capturedAt,
          semanticTuples: const <SemanticTuple>[],
          structuredSignals: <String, dynamic>{
            'platform': platform,
            'payloadLength': rawJsonData.length,
            'airGapCompression': compressionBundle.toStructuredSignals(),
          },
          activityContext: 'social_media',
          confidence: 0.59,
          lineageRef:
              'social_media:$platform:${payload.capturedAt.microsecondsSinceEpoch}',
        );
      }
    } on PrivacyBreachException catch (e) {
      developer.log('SocialMediaAdapter: Air Gap aborted on social feed! $e',
          name: 'IntakeAdapter');
    }
  }
}
