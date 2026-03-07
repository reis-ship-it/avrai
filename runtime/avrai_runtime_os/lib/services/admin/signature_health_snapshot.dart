import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';

class SignatureHealthRecord {
  final String sourceId;
  final String provider;
  final String entityType;
  final String categoryLabel;
  final String? sourceLabel;
  final String? cityCode;
  final String? localityCode;
  final double confidence;
  final double freshness;
  final double fallbackRate;
  final bool reviewNeeded;
  final DateTime? lastSyncAt;
  final DateTime? lastSignatureRebuildAt;
  final String syncState;
  final SignatureHealthCategory healthCategory;
  final String summary;

  const SignatureHealthRecord({
    required this.sourceId,
    required this.provider,
    required this.entityType,
    required this.categoryLabel,
    this.sourceLabel,
    this.cityCode,
    this.localityCode,
    required this.confidence,
    required this.freshness,
    required this.fallbackRate,
    required this.reviewNeeded,
    this.lastSyncAt,
    this.lastSignatureRebuildAt,
    required this.syncState,
    required this.healthCategory,
    required this.summary,
  });

  bool get isFeedbackTelemetry => provider == 'user_feedback';

  String get metroLabel {
    if (localityCode != null && localityCode!.isNotEmpty) {
      return localityCode!;
    }
    if (cityCode != null && cityCode!.isNotEmpty) {
      return cityCode!;
    }
    return 'unknown';
  }
}

class SignatureHealthOverview {
  final int strongCount;
  final int weakDataCount;
  final int staleCount;
  final int fallbackCount;
  final int reviewNeededCount;
  final int bundleCount;
  final int softIgnoreCount;
  final int hardNotInterestedCount;

  const SignatureHealthOverview({
    required this.strongCount,
    required this.weakDataCount,
    required this.staleCount,
    required this.fallbackCount,
    required this.reviewNeededCount,
    required this.bundleCount,
    required this.softIgnoreCount,
    required this.hardNotInterestedCount,
  });
}

class SignatureHealthSnapshot {
  final DateTime generatedAt;
  final SignatureHealthOverview overview;
  final List<SignatureHealthRecord> records;
  final int reviewQueueCount;

  const SignatureHealthSnapshot({
    required this.generatedAt,
    required this.overview,
    required this.records,
    required this.reviewQueueCount,
  });

  List<SignatureHealthRecord> get sourceRecords =>
      records.where((record) => !record.isFeedbackTelemetry).toList();

  List<SignatureHealthRecord> get feedbackRecords =>
      records.where((record) => record.isFeedbackTelemetry).toList();

  Map<SignatureHealthCategory, List<SignatureHealthRecord>> get byCategory {
    final grouped = <SignatureHealthCategory, List<SignatureHealthRecord>>{};
    for (final record in sourceRecords) {
      grouped.putIfAbsent(
          record.healthCategory, () => <SignatureHealthRecord>[]);
      grouped[record.healthCategory]!.add(record);
    }
    return grouped;
  }

  Map<String, List<SignatureHealthRecord>> get byEntityType {
    final grouped = <String, List<SignatureHealthRecord>>{};
    for (final record in sourceRecords) {
      grouped.putIfAbsent(record.entityType, () => <SignatureHealthRecord>[]);
      grouped[record.entityType]!.add(record);
    }
    return grouped;
  }

  Map<String, List<SignatureHealthRecord>> get byProvider {
    final grouped = <String, List<SignatureHealthRecord>>{};
    for (final record in sourceRecords) {
      grouped.putIfAbsent(record.provider, () => <SignatureHealthRecord>[]);
      grouped[record.provider]!.add(record);
    }
    return grouped;
  }

  Map<String, List<SignatureHealthRecord>> get byMetro {
    final grouped = <String, List<SignatureHealthRecord>>{};
    for (final record in sourceRecords) {
      grouped.putIfAbsent(record.metroLabel, () => <SignatureHealthRecord>[]);
      grouped[record.metroLabel]!.add(record);
    }
    return grouped;
  }

  Map<String, List<SignatureHealthRecord>> get feedbackByIntent {
    final grouped = <String, List<SignatureHealthRecord>>{};
    for (final record in feedbackRecords) {
      grouped.putIfAbsent(
          record.categoryLabel, () => <SignatureHealthRecord>[]);
      grouped[record.categoryLabel]!.add(record);
    }
    return grouped;
  }
}
