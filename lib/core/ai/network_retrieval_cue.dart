import 'package:avrai/core/services/interfaces/storage_service_interface.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';

/// Source of a network retrieval cue.
enum NetworkCueSource {
  ai2aiMesh,
  federated,
}

/// A retrievable cue derived from AI2AI or federated signals (anonymized, local-only).
///
/// RAG Phase 2: Network-aware retrieval.
class NetworkRetrievalCue {
  final String id;
  final String category;
  final String summary;
  final NetworkCueSource source;
  final double strength;
  final DateTime createdAt;

  const NetworkRetrievalCue({
    required this.id,
    required this.category,
    required this.summary,
    required this.source,
    required this.strength,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'summary': summary,
        'source': source.name,
        'strength': strength,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NetworkRetrievalCue.fromJson(Map<String, dynamic> json) {
    return NetworkRetrievalCue(
      id: json['id'] as String,
      category: json['category'] as String? ?? 'general',
      summary: json['summary'] as String? ?? '',
      source: _parseSource(json['source'] as String?),
      strength: (json['strength'] as num?)?.toDouble() ?? 0.5,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  static NetworkCueSource _parseSource(String? s) {
    if (s == 'federated') return NetworkCueSource.federated;
    return NetworkCueSource.ai2aiMesh;
  }
}

const String _kCuesKey = 'network_retrieval_cues_v1';
const String _kCuesBox = 'spots_ai';
const int _kMaxCues = 100;

/// Local store for [NetworkRetrievalCue]. Device-only; never syncs raw to cloud.
///
/// RAG Phase 2: Network-aware retrieval.
class NetworkCuesStore {
  NetworkCuesStore({IStorageService? storage})
      : _storage = storage ?? StorageService.instance;

  final IStorageService _storage;

  List<NetworkRetrievalCue> _load() {
    final raw = _storage.getObject<dynamic>(_kCuesKey, box: _kCuesBox);
    if (raw == null) return [];
    final list = raw is List ? raw : [];
    final out = <NetworkRetrievalCue>[];
    for (final e in list) {
      if (e is! Map) continue;
      try {
        out.add(NetworkRetrievalCue.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {
        /* skip malformed */
      }
    }
    return out;
  }

  Future<void> _save(List<NetworkRetrievalCue> cues) async {
    final list = cues.map((c) => c.toJson()).toList();
    await _storage.setObject(_kCuesKey, list, box: _kCuesBox);
  }

  /// Appends a cue and evicts oldest beyond [_kMaxCues].
  Future<void> add(NetworkRetrievalCue cue) async {
    final cues = _load();
    cues.add(cue);
    cues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    while (cues.length > _kMaxCues) {
      cues.removeLast();
    }
    await _save(cues);
  }

  /// Returns all stored cues (caller filters/limits as needed).
  List<NetworkRetrievalCue> getAll() {
    return List<NetworkRetrievalCue>.from(_load());
  }

  /// Clears all cues. For testing only.
  Future<void> clear() async {
    await _save([]);
  }
}
