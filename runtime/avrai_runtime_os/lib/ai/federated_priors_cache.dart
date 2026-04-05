import 'package:avrai_runtime_os/services/interfaces/storage_service_interface.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

const String _kKey = 'federated_priors_cache_v1';
const String _kBox = 'spots_ai';

/// Cache of `global_average_deltas` from federated-sync for retrieval bias.
/// Offline retrieval uses last cached priors.
///
/// RAG Phase 3: Federated-shaped retrieval.
class FederatedPriorsCache {
  FederatedPriorsCache({IStorageService? storage})
      : _storage = storage ?? StorageService.instance;

  final IStorageService _storage;

  /// Writes priors (category -> vector) and cachedAt.
  Future<void> set(
    Map<String, List<double>> priors, {
    DateTime? cachedAt,
  }) async {
    final at = cachedAt ?? DateTime.now();
    final payload = <String, dynamic>{
      'cachedAt': at.toIso8601String(),
      'priors': priors.map((k, v) => MapEntry(k, v)),
    };
    await _storage.setObject(_kKey, payload, box: _kBox);
  }

  /// Reads priors and cachedAt. Returns null if missing.
  ({Map<String, List<double>> priors, DateTime cachedAt})? get() {
    final raw = _storage.getObject<dynamic>(_kKey, box: _kBox);
    if (raw == null || raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final cachedAtStr = map['cachedAt'];
    final priorsRaw = map['priors'];
    if (cachedAtStr is! String || priorsRaw is! Map) return null;
    final cachedAt = DateTime.tryParse(cachedAtStr);
    if (cachedAt == null) return null;
    final priors = <String, List<double>>{};
    final priorsMap = Map<dynamic, dynamic>.from(priorsRaw);
    for (final e in priorsMap.entries) {
      final k = e.key?.toString();
      final v = e.value;
      if (k == null || v is! List) continue;
      priors[k] = v.map((x) => (x as num).toDouble()).toList();
    }
    return (priors: priors, cachedAt: cachedAt);
  }
}
