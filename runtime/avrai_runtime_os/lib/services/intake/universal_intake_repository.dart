import 'dart:developer' as developer;
import 'dart:async';

import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';

/// Local-first persistence for source descriptors, jobs, review queue, and spot import metadata.
class UniversalIntakeRepository {
  static const String _logName = 'UniversalIntakeRepository';
  static const String _sourcesKey = 'intake:sources_v1';
  static const String _jobsKey = 'intake:jobs_v1';
  static const String _reviewsKey = 'intake:reviews_v1';
  static const String _spotMetadataKey = 'intake:spot_metadata_v1';

  final StorageService? _storage;

  final Map<String, ExternalSourceDescriptor> _sources =
      <String, ExternalSourceDescriptor>{};
  final Map<String, ExternalSyncJob> _jobs = <String, ExternalSyncJob>{};
  final Map<String, OrganizerReviewItem> _reviews =
      <String, OrganizerReviewItem>{};
  final Map<String, ExternalSyncMetadata> _spotMetadata =
      <String, ExternalSyncMetadata>{};
  bool _hydrated = false;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  UniversalIntakeRepository({StorageService? storageService})
      : _storage = storageService;

  Future<void> upsertSource(ExternalSourceDescriptor source) async {
    await _hydrateIfNeeded();
    _sources[source.id] = source;
    await _persistSources();
    _changes.add(null);
  }

  Future<List<ExternalSourceDescriptor>> getSourcesForOwner(
      String ownerUserId) async {
    await _hydrateIfNeeded();
    return _sources.values
        .where((source) => source.ownerUserId == ownerUserId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<ExternalSourceDescriptor>> getAllSources() async {
    await _hydrateIfNeeded();
    return _sources.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<ExternalSourceDescriptor?> getSourceById(String sourceId) async {
    await _hydrateIfNeeded();
    return _sources[sourceId];
  }

  Future<void> upsertJob(ExternalSyncJob job) async {
    await _hydrateIfNeeded();
    _jobs[job.id] = job;
    await _persistJobs();
    _changes.add(null);
  }

  Future<void> upsertReviewItem(OrganizerReviewItem item) async {
    await _hydrateIfNeeded();
    _reviews[item.id] = item;
    await _persistReviews();
    _changes.add(null);
  }

  Future<void> deleteReviewItem(String reviewItemId) async {
    await _hydrateIfNeeded();
    _reviews.remove(reviewItemId);
    await _persistReviews();
    _changes.add(null);
  }

  Future<List<OrganizerReviewItem>> getReviewItemsForOwner(
      String ownerUserId) async {
    await _hydrateIfNeeded();
    return _reviews.values
        .where((review) => review.ownerUserId == ownerUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<OrganizerReviewItem>> getAllReviewItems() async {
    await _hydrateIfNeeded();
    return _reviews.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> upsertSpotMetadata({
    required String spotId,
    required ExternalSyncMetadata metadata,
  }) async {
    await _hydrateIfNeeded();
    _spotMetadata[spotId] = metadata;
    await _persistSpotMetadata();
    _changes.add(null);
  }

  Future<ExternalSyncMetadata?> getSpotMetadata(String spotId) async {
    await _hydrateIfNeeded();
    return _spotMetadata[spotId];
  }

  Future<Map<String, ExternalSyncMetadata>> getSpotMetadataMap() async {
    await _hydrateIfNeeded();
    return Map<String, ExternalSyncMetadata>.from(_spotMetadata);
  }

  Stream<List<ExternalSourceDescriptor>> watchSources(
      {String? ownerUserId}) async* {
    await _hydrateIfNeeded();
    yield ownerUserId == null
        ? await getAllSources()
        : await getSourcesForOwner(ownerUserId);
    yield* _changes.stream.asyncMap((_) async {
      return ownerUserId == null
          ? await getAllSources()
          : await getSourcesForOwner(ownerUserId);
    });
  }

  Stream<List<OrganizerReviewItem>> watchReviewItems(
      {String? ownerUserId}) async* {
    await _hydrateIfNeeded();
    yield ownerUserId == null
        ? await getAllReviewItems()
        : await getReviewItemsForOwner(ownerUserId);
    yield* _changes.stream.asyncMap((_) async {
      return ownerUserId == null
          ? await getAllReviewItems()
          : await getReviewItemsForOwner(ownerUserId);
    });
  }

  Future<void> _hydrateIfNeeded() async {
    if (_hydrated) return;
    _hydrated = true;
    if (_storage == null) return;

    try {
      final rawSources =
          _storage.getObject<List<dynamic>>(_sourcesKey) ?? const [];
      for (final item in rawSources) {
        if (item is Map<String, dynamic>) {
          final source = ExternalSourceDescriptor.fromJson(item);
          _sources[source.id] = source;
        }
      }

      final rawJobs = _storage.getObject<List<dynamic>>(_jobsKey) ?? const [];
      for (final item in rawJobs) {
        if (item is Map<String, dynamic>) {
          final job = ExternalSyncJob.fromJson(item);
          _jobs[job.id] = job;
        }
      }

      final rawReviews =
          _storage.getObject<List<dynamic>>(_reviewsKey) ?? const [];
      for (final item in rawReviews) {
        if (item is Map<String, dynamic>) {
          final review = OrganizerReviewItem.fromJson(item);
          _reviews[review.id] = review;
        }
      }

      final rawSpotMetadata =
          _storage.getObject<Map<String, dynamic>>(_spotMetadataKey) ??
              const {};
      for (final entry in rawSpotMetadata.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          _spotMetadata[entry.key] = ExternalSyncMetadata.fromJson(value);
        }
      }
    } catch (e, st) {
      developer.log(
        'Failed to hydrate intake repository: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _persistSources() async {
    if (_storage == null) return;
    await _storage.setObject(
      _sourcesKey,
      _sources.values.map((source) => source.toJson()).toList(),
    );
  }

  Future<void> _persistJobs() async {
    if (_storage == null) return;
    await _storage.setObject(
      _jobsKey,
      _jobs.values.map((job) => job.toJson()).toList(),
    );
  }

  Future<void> _persistReviews() async {
    if (_storage == null) return;
    await _storage.setObject(
      _reviewsKey,
      _reviews.values.map((review) => review.toJson()).toList(),
    );
  }

  Future<void> _persistSpotMetadata() async {
    if (_storage == null) return;
    await _storage.setObject(
      _spotMetadataKey,
      _spotMetadata.map((key, value) => MapEntry(key, value.toJson())),
    );
  }
}
