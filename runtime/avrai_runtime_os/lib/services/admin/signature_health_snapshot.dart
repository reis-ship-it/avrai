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
  final DateTime? updatedAt;
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
    this.updatedAt,
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

class FeedbackTrendWindow {
  final String label;
  final Duration duration;

  const FeedbackTrendWindow({
    required this.label,
    required this.duration,
  });
}

class FeedbackTrendCount {
  final int softIgnoreCount;
  final int hardNotInterestedCount;

  const FeedbackTrendCount({
    required this.softIgnoreCount,
    required this.hardNotInterestedCount,
  });

  int get totalCount => softIgnoreCount + hardNotInterestedCount;
}

class FeedbackTrendRow {
  final String entityType;
  final Map<String, FeedbackTrendCount> countsByWindow;

  const FeedbackTrendRow({
    required this.entityType,
    required this.countsByWindow,
  });

  int get totalCount =>
      countsByWindow.values.fold(0, (sum, count) => sum + count.totalCount);
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

  static const List<FeedbackTrendWindow> feedbackTrendWindows =
      <FeedbackTrendWindow>[
    FeedbackTrendWindow(label: '24h', duration: Duration(hours: 24)),
    FeedbackTrendWindow(label: '7d', duration: Duration(days: 7)),
    FeedbackTrendWindow(label: '30d', duration: Duration(days: 30)),
  ];

  List<FeedbackTrendRow> buildFeedbackTrendRows({
    DateTime? now,
  }) {
    final effectiveNow = now ?? generatedAt;
    final grouped = <String, Map<String, FeedbackTrendCount>>{};
    for (final record in feedbackRecords) {
      final recordedAt = record.updatedAt ??
          record.lastSignatureRebuildAt ??
          record.lastSyncAt;
      if (recordedAt == null) {
        continue;
      }
      final entityCounts = grouped.putIfAbsent(
        record.entityType,
        () => <String, FeedbackTrendCount>{
          for (final window in feedbackTrendWindows)
            window.label: const FeedbackTrendCount(
                softIgnoreCount: 0, hardNotInterestedCount: 0),
        },
      );
      for (final window in feedbackTrendWindows) {
        if (effectiveNow.difference(recordedAt) > window.duration) {
          continue;
        }
        final current = entityCounts[window.label]!;
        entityCounts[window.label] = FeedbackTrendCount(
          softIgnoreCount: current.softIgnoreCount +
              (record.categoryLabel == 'soft_ignore' ? 1 : 0),
          hardNotInterestedCount: current.hardNotInterestedCount +
              (record.categoryLabel == 'hard_not_interested' ? 1 : 0),
        );
      }
    }

    final rows = grouped.entries
        .map(
          (entry) => FeedbackTrendRow(
            entityType: entry.key,
            countsByWindow: entry.value,
          ),
        )
        .where((row) => row.totalCount > 0)
        .toList()
      ..sort((a, b) => b.totalCount.compareTo(a.totalCount));
    return rows;
  }
}
