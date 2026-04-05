import 'package:avrai_core/models/air_gap/air_gap_compression_models.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';

/// Normalizes raw external payloads into a stable intake candidate contract.
class AirGapNormalizer {
  const AirGapNormalizer();

  IntakeCandidate normalize({
    required Map<String, dynamic> payload,
    required ExternalSourceDescriptor source,
  }) {
    final normalizedPayload = Map<String, dynamic>.from(payload);

    DateTime? parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    List<String> parseTags(dynamic value) {
      if (value is List) {
        return value
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      if (value is String && value.isNotEmpty) {
        return value
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return const [];
    }

    Map<String, dynamic>? parseCompressionSignals(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is! Map) {
        throw const FormatException(
          'air gap compression payload must be a JSON object.',
        );
      }
      final map = Map<String, dynamic>.from(value);
      final hasKnownKeys = map['primaryEnvelope'] != null ||
          map['knowledgePacket'] != null ||
          map['budgetProfile'] != null;
      if (!hasKnownKeys) {
        throw const FormatException(
          'air gap compression payload must contain envelope, packet, or budget data.',
        );
      }
      return <String, dynamic>{
        if (map['primaryEnvelope'] is Map)
          'primaryEnvelope': SafeArtifactEnvelope.fromJson(
            Map<String, dynamic>.from(map['primaryEnvelope'] as Map),
          ).toJson(),
        if (map['knowledgePacket'] is Map)
          'knowledgePacket': CompressedKnowledgePacket.fromJson(
            Map<String, dynamic>.from(map['knowledgePacket'] as Map),
          ).toJson(),
        if (map['budgetProfile'] is Map)
          'budgetProfile': CompressionBudgetProfile.fromJson(
            Map<String, dynamic>.from(map['budgetProfile'] as Map),
          ).toJson(),
        if (map['encodedKnowledgePacket'] != null)
          'encodedKnowledgePacket': map['encodedKnowledgePacket'].toString(),
      };
    }

    final normalizedCompressionSignals = parseCompressionSignals(
      normalizedPayload['air_gap_compression'] ??
          normalizedPayload.remove('airGapCompression'),
    );
    if (normalizedCompressionSignals != null) {
      normalizedPayload['air_gap_compression'] = normalizedCompressionSignals;
    }

    return IntakeCandidate(
      title: (payload['title'] ?? payload['name'] ?? '').toString(),
      description:
          (payload['description'] ?? payload['summary'] ?? '').toString(),
      category:
          (payload['category'] ?? payload['type'] ?? 'General').toString(),
      organizerName: (payload['organizerName'] ??
                  payload['host'] ??
                  payload['owner'] ??
                  '')
              .toString()
              .trim()
              .isEmpty
          ? null
          : (payload['organizerName'] ?? payload['host'] ?? payload['owner'])
              .toString(),
      locationLabel:
          (payload['location'] ?? payload['address'] ?? payload['place'] ?? '')
                  .toString()
                  .trim()
                  .isEmpty
              ? null
              : (payload['location'] ?? payload['address'] ?? payload['place'])
                  .toString(),
      websiteUrl: (payload['websiteUrl'] ??
              payload['url'] ??
              payload['website'] ??
              source.sourceUrl)
          ?.toString(),
      externalId: (payload['externalId'] ?? payload['id'])?.toString(),
      sourceUrl: source.sourceUrl,
      latitude: parseDouble(payload['latitude']),
      longitude: parseDouble(payload['longitude']),
      cityCode: (payload['cityCode'] ?? source.cityCode)?.toString(),
      localityCode:
          (payload['localityCode'] ?? source.localityCode)?.toString(),
      startTime: parseDate(payload['startTime'] ?? payload['startsAt']),
      endTime: parseDate(payload['endTime'] ?? payload['endsAt']),
      tags: parseTags(payload['tags']),
      compressedArtifactEnvelope:
          normalizedCompressionSignals?['primaryEnvelope'] is Map
              ? SafeArtifactEnvelope.fromJson(
                  Map<String, dynamic>.from(
                    normalizedCompressionSignals!['primaryEnvelope'] as Map,
                  ),
                )
              : null,
      compressedKnowledgePacket:
          normalizedCompressionSignals?['knowledgePacket'] is Map
              ? CompressedKnowledgePacket.fromJson(
                  Map<String, dynamic>.from(
                    normalizedCompressionSignals!['knowledgePacket'] as Map,
                  ),
                )
              : null,
      compressionBudgetProfile:
          normalizedCompressionSignals?['budgetProfile'] is Map
              ? CompressionBudgetProfile.fromJson(
                  Map<String, dynamic>.from(
                    normalizedCompressionSignals!['budgetProfile'] as Map,
                  ),
                )
              : null,
      rawPayload: normalizedPayload,
    );
  }
}
