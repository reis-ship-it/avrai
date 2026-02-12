import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:avrai/core/models/user/onboarding_suggestion_event.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';

/// Stores onboarding “suggestion events” (provenance + user reactions) keyed by agentId.
///
/// This is separate from `OnboardingData` because we want to log events *during*
/// onboarding (before the final `OnboardingData` object is complete/validated),
/// and we want an append-only event log for later bootstrap and analytics.
class OnboardingSuggestionEventStore {
  static const String _logName = 'OnboardingSuggestionEventStore';
  static const String _eventsKeyPrefix = 'onboarding_suggestion_events_';
  static const String _eventsField = 'events';
  static const String _updatedAtMsField = 'updatedAtMs';
  static const String _boxName = 'onboarding_suggestion_events';

  static GetStorage? _storage;

  /// Optional storage for testing (avoids path_provider in VM tests).
  final GetStorage? _injectedStorage;

  GetStorage get _box {
    if (_injectedStorage != null) return _injectedStorage;
    _storage ??= GetStorage(_boxName);
    return _storage!;
  }

  /// Initialize storage
  static Future<void> initStorage() async {
    await GetStorage.init(_boxName);
  }

  final AgentIdService _agentIdService;

  static AgentIdService _resolveAgentIdService() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<AgentIdService>()) {
        return sl<AgentIdService>();
      }
    } catch (_) {
      // Fall through to a safe default instance.
    }
    return AgentIdService();
  }

  OnboardingSuggestionEventStore({
    AgentIdService? agentIdService,
    GetStorage? storage,
  })  : _agentIdService = agentIdService ?? _resolveAgentIdService(),
        _injectedStorage = storage;

  Future<void> appendForUser({
    required String userId,
    required OnboardingSuggestionEvent event,
  }) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);

      final key = '$_eventsKeyPrefix$agentId';
      final existing = _box.read<Map<String, dynamic>>(key);
      final existingEvents = (existing?[_eventsField] as List?) ?? const [];
      final events = existingEvents.map((e) => e).toList();

      events.add(event.toJson());
      await _box.write(key, <String, dynamic>{
        _eventsField: events,
        _updatedAtMsField: DateTime.now().millisecondsSinceEpoch,
      });

      developer.log(
        'Appended onboarding suggestion event: ${event.surface}/${event.provenance.name}/${event.userAction?.type.name ?? 'none'}',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Failed to append onboarding suggestion event: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<List<OnboardingSuggestionEvent>> getAllForUser(String userId) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);

      final key = '$_eventsKeyPrefix$agentId';
      final existing = _box.read<Map<String, dynamic>>(key);
      final events = (existing?[_eventsField] as List?) ?? const [];

      return events
          .whereType<Map>()
          .map((e) =>
              OnboardingSuggestionEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e, st) {
      developer.log(
        'Failed to load onboarding suggestion events: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  Future<void> clearForUser(String userId) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);

      final key = '$_eventsKeyPrefix$agentId';
      await _box.remove(key);
    } catch (e, st) {
      developer.log(
        'Failed to clear onboarding suggestion events: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}
